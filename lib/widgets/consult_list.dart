import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/consult.dart';
import '../screens/consult_create_screen.dart';
import '../screens/consult_detail_screen.dart';
import '../services/consult_service.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import 'auth_guard.dart';
import 'user_avatar.dart';

/// The 改圖諮詢 area: posts where the author invites others to reply with edited drafts.
class ConsultList extends StatefulWidget {
  const ConsultList({super.key});

  @override
  State<ConsultList> createState() => _ConsultListState();
}

class _ConsultListState extends State<ConsultList> {
  final _service = ConsultService();

  List<Consult>? _items;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _service.fetchAll();
      if (!mounted) return;
      setState(() {
        _items = list;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_items == null) _error = e;
      });
    }
  }

  Future<void> _create() async {
    if (!await ensureSignedIn(context)) return;
    if (!mounted) return;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const ConsultCreateScreen()),
    );
    if (created == true) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('諮詢已發布')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildList(),
        Positioned(
          right: 18,
          bottom: 18,
          child: GestureDetector(
            onTap: _create,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Text(
                '發布諮詢',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    if (_error != null && _items == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('讀取失敗，請確認網路連線'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() => _error = null);
                _load();
              },
              child: const Text('重試'),
            ),
          ],
        ),
      );
    }
    final items = _items;
    if (items == null) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      color: AppColors.vermilion,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 90),
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.tint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              '在這裡發布的作品視為開放改圖：其他創作者可在下方以圖片或文字回覆（蓋樓），一起討論怎麼畫得更好。',
              style: TextStyle(fontSize: 12.5, height: 1.5, color: Color(0xFF5C544C)),
            ),
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(child: Text('還沒有諮詢', style: TextStyle(color: AppColors.muted))),
            )
          else
            for (final item in items) _card(item),
        ],
      ),
    );
  }

  Widget _card(Consult item) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => ConsultDetailScreen(consultId: item.id)),
          );
          _load();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  width: 92,
                  height: 92,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) =>
                      Container(width: 92, height: 92, color: AppColors.tint),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.3),
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: AppColors.muted),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        UserAvatar(photoUrl: item.userPhotoUrl, name: item.userName, radius: 10),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.userName.isNotEmpty ? item.userName : '創作者',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                          ),
                        ),
                        Text(
                          '${item.floorsCount} 樓 · ${timeAgo(item.createdAt)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
