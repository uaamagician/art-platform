import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/commission.dart';
import '../services/auth_service.dart';
import '../services/commission_service.dart';
import '../theme/app_theme.dart';
import '../utils/disclaimer.dart';
import '../utils/time_utils.dart';
import '../widgets/follow_button.dart';
import '../widgets/report_sheet.dart';
import '../widgets/user_avatar.dart';
import 'image_viewer_screen.dart';
import 'search_results_screen.dart';
import 'user_profile_screen.dart';

class CommissionDetailScreen extends StatefulWidget {
  final String commissionId;

  const CommissionDetailScreen({super.key, required this.commissionId});

  @override
  State<CommissionDetailScreen> createState() => _CommissionDetailScreenState();
}

class _CommissionDetailScreenState extends State<CommissionDetailScreen> {
  final _service = CommissionService();

  Future<void> _delete(Commission c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除這則委託？'),
        content: const Text('刪除後無法復原。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('刪除')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.delete(c);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('刪除失敗，請稍後再試')));
      }
    }
  }

  Future<void> _toggleOpen(Commission c) async {
    try {
      await _service.setOpen(c.id, !c.isOpen);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('操作失敗，請稍後再試')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('委託詳情')),
      body: StreamBuilder<Commission?>(
        stream: _service.stream(widget.commissionId),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('讀取失敗，請確認網路連線'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final c = snapshot.data;
          if (c == null) return const Center(child: Text('這則委託已被刪除'));
          return _buildBody(c);
        },
      ),
    );
  }

  Widget _buildBody(Commission c) {
    final isMe = AuthService().currentUser?.uid == c.userId;
    final isRequest = c.type == CommissionType.request;
    final typeColor = isRequest ? AppColors.vermilion : const Color(0xFF3F7D5B);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        Row(
          children: [
            _badge(c.type.label, typeColor),
            if (!c.isOpen) ...[const SizedBox(width: 6), _badge('已結案', AppColors.muted)],
            if (c.isNsfw) ...[const SizedBox(width: 6), _badge('成人', Colors.red.shade400)],
          ],
        ),
        const SizedBox(height: 14),
        Text(c.title,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, height: 1.3)),
        const SizedBox(height: 16),
        Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => UserProfileScreen(
                    uid: c.userId,
                    fallbackName: c.userName,
                    fallbackPhoto: c.userPhotoUrl,
                  ),
                ),
              ),
              child: UserAvatar(photoUrl: c.userPhotoUrl, name: c.userName, radius: 20, ring: true),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.userName.isNotEmpty ? c.userName : '創作者',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(timeAgo(c.createdAt),
                      style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                ],
              ),
            ),
            FollowButton(targetUid: c.userId),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              _row('預算', c.budgetText.isNotEmpty ? c.budgetText : '未註明'),
              if (c.deadline != null)
                _row(
                  isRequest ? '期限' : '可接單至',
                  '${formatDate(c.deadline!)}（${deadlineLabel(c.deadline!)}）',
                ),
              if (c.category.isNotEmpty) _row('分類', c.category),
            ],
          ),
        ),
        if (c.description.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(c.description, style: const TextStyle(fontSize: 15, height: 1.65)),
        ],
        if (c.tags.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final tag in c.tags)
                ActionChip(
                  label: Text('#$tag'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => SearchResultsScreen(query: '#$tag')),
                  ),
                ),
            ],
          ),
        ],
        if (c.imageUrls.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(isRequest ? '參考圖' : '作品範例',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: c.imageUrls.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ImageViewerScreen(imageUrls: c.imageUrls, initialIndex: i),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: c.imageUrls[i],
                    width: 130,
                    height: 130,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        Container(width: 130, color: AppColors.tint),
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('站外聯絡方式', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      c.contact,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: c.contact));
                      if (!mounted) return;
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('已複製聯絡方式')));
                    },
                    child: const Text('複製'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.tint,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('免責聲明', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(commissionDisclaimer,
                  style: const TextStyle(fontSize: 12.5, height: 1.6, color: Color(0xFF5C544C))),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (isMe)
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => _toggleOpen(c),
                  child: Text(c.isOpen ? '標示為已結案' : '重新開放'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _delete(c),
                  child: const Text('刪除委託'),
                ),
              ),
            ],
          )
        else
          Center(
            child: TextButton(
              onPressed: () => reportWithFeedback(
                context,
                reasons: CommissionService.reportReasons,
                submit: (reason) {
                  final uid = AuthService().currentUser!.uid;
                  return _service.report(c, uid, reason);
                },
              ),
              child: const Text('檢舉這則委託', style: TextStyle(color: AppColors.muted)),
            ),
          ),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 72,
              child: Text(label, style: const TextStyle(color: AppColors.muted)),
            ),
            Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      );
}
