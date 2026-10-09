import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/consult.dart';
import '../services/auth_service.dart';
import '../services/consult_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import '../widgets/auth_guard.dart';
import '../widgets/follow_button.dart';
import '../widgets/user_avatar.dart';
import 'image_viewer_screen.dart';
import 'user_profile_screen.dart';

class ConsultDetailScreen extends StatefulWidget {
  final String consultId;

  const ConsultDetailScreen({super.key, required this.consultId});

  @override
  State<ConsultDetailScreen> createState() => _ConsultDetailScreenState();
}

class _ConsultDetailScreenState extends State<ConsultDetailScreen> {
  final _service = ConsultService();
  final _text = TextEditingController();

  Uint8List? _attachment;
  String _attachmentExt = 'jpg';
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  void _openProfile(String uid, String name, String photo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            UserProfileScreen(uid: uid, fallbackName: name, fallbackPhoto: photo),
      ),
    );
  }

  void _openImage(String url) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ImageViewerScreen(imageUrls: [url])),
    );
  }

  Future<void> _pickAttachment() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 20 * 1024 * 1024) return _message('圖片超過 20MB');
      setState(() {
        _attachment = bytes;
        _attachmentExt = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : 'jpg';
      });
    } catch (_) {
      if (mounted) _message('無法取得圖片，請確認已允許存取相簿');
    }
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty && _attachment == null) return;
    if (!await ensureSignedIn(context)) {
      if (mounted) setState(() {});
      return;
    }
    if (!mounted) return;
    final user = AuthService().currentUser;
    if (user == null) return;

    setState(() => _sending = true);
    final storage = StorageService();
    String? uploadedPath;
    try {
      var imageUrl = '';
      if (_attachment != null) {
        final file = await storage.uploadBytes(
          path:
              'consults/${user.uid}/${widget.consultId}/${DateTime.now().millisecondsSinceEpoch}.$_attachmentExt',
          bytes: _attachment!,
          contentType: StorageService.imageMimeType(_attachmentExt),
        );
        uploadedPath = file.path;
        imageUrl = file.url;
      }
      await _service.addFloor(widget.consultId, user: user, text: text, imageUrl: imageUrl);
      _text.clear();
      if (mounted) {
        FocusScope.of(context).unfocus();
        setState(() => _attachment = null);
      }
    } catch (_) {
      if (uploadedPath != null) await storage.deleteQuietly(uploadedPath);
      if (mounted) _message('回覆失敗，請稍後再試');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _confirm(String title, Future<void> Function() action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('確定')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await action();
    } catch (_) {
      if (mounted) _message('操作失敗，請稍後再試');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Consult?>(
      stream: _service.stream(widget.consultId),
      builder: (context, snapshot) {
        final consult = snapshot.data;
        final isOwner = consult != null && AuthService().currentUser?.uid == consult.userId;

        return Scaffold(
          appBar: AppBar(
            title: const Text('改圖諮詢'),
            actions: [
              if (isOwner)
                TextButton(
                  onPressed: () => _confirm('刪除這則諮詢？', () async {
                    await _service.delete(consult);
                    if (context.mounted) Navigator.of(context).pop();
                  }),
                  child: const Text('刪除'),
                ),
            ],
          ),
          body: snapshot.hasError
              ? const Center(child: Text('讀取失敗，請確認網路連線'))
              : consult == null
                  ? (snapshot.connectionState == ConnectionState.waiting
                      ? const Center(child: CircularProgressIndicator())
                      : const Center(child: Text('這則諮詢已被刪除')))
                  : _buildBody(consult, isOwner),
          bottomNavigationBar: consult == null ? null : _composer(),
        );
      },
    );
  }

  Widget _buildBody(Consult c, bool isOwner) {
    return StreamBuilder<List<ConsultFloor>>(
      stream: _service.floorsStream(c.id),
      builder: (context, snapshot) {
        final floors = snapshot.data ?? const <ConsultFloor>[];
        return ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            GestureDetector(
              onTap: () => _openImage(c.imageUrl),
              child: Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                color: AppColors.tint,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: c.imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const SizedBox(
                    height: 240,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (context, url, error) =>
                      const SizedBox(height: 240, child: Center(child: Text('圖片載入失敗'))),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => _openProfile(c.userId, c.userName, c.userPhotoUrl),
                        child: UserAvatar(
                          photoUrl: c.userPhotoUrl,
                          name: c.userName,
                          radius: 20,
                          ring: true,
                        ),
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
                  const SizedBox(height: 16),
                  Text(c.title,
                      style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, height: 1.3)),
                  if (c.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(c.description, style: const TextStyle(height: 1.6)),
                  ],
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  Text('回覆 ${c.floorsCount}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  if (floors.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: Text('還沒有人回覆，來蓋第一樓吧',
                            style: TextStyle(color: AppColors.muted)),
                      ),
                    )
                  else
                    for (final floor in floors) _floorCard(c, floor, isOwner),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _floorCard(Consult c, ConsultFloor floor, bool isOwner) {
    final me = AuthService().currentUser?.uid;
    final canRemove = !floor.deleted && me != null && (me == floor.userId || isOwner);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${floor.floor} 樓',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () => _openProfile(floor.userId, floor.userName, floor.userPhotoUrl),
                child: UserAvatar(photoUrl: floor.userPhotoUrl, name: floor.userName, radius: 12),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${floor.userName.isNotEmpty ? floor.userName : '創作者'}  ·  ${timeAgo(floor.createdAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                ),
              ),
              if (floor.userId == c.userId)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Text('原PO',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.vermilion)),
                ),
              if (canRemove)
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    foregroundColor: AppColors.muted,
                  ),
                  onPressed: () => _confirm(
                    '刪除這一樓？',
                    () => _service.removeFloor(c.id, floor.id),
                  ),
                  child: const Text('刪除', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (floor.deleted)
            const Text('此樓已刪除', style: TextStyle(color: AppColors.muted))
          else ...[
            if (floor.text.isNotEmpty) Text(floor.text, style: const TextStyle(height: 1.55)),
            if (floor.imageUrl.isNotEmpty) ...[
              if (floor.text.isNotEmpty) const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _openImage(floor.imageUrl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: floor.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 200,
                      color: AppColors.tint,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 120,
                      color: AppColors.tint,
                      alignment: Alignment.center,
                      child: const Text('圖片載入失敗'),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _composer() {
    final isGuest = AuthService().currentUser == null;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_attachment != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(_attachment!, width: 56, height: 56, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('已附上改圖', style: TextStyle(color: AppColors.muted)),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _attachment = null),
                      child: const Text('移除'),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                TextButton(onPressed: isGuest ? _send : _pickAttachment, child: const Text('附圖')),
                Expanded(
                  child: TextField(
                    controller: _text,
                    readOnly: isGuest,
                    minLines: 1,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: isGuest ? '登入後即可蓋樓' : '寫下你的建議，或附上改圖…',
                      isDense: true,
                      counterText: '',
                    ),
                    onTap: isGuest
                        ? () async {
                            await ensureSignedIn(context);
                            if (mounted) setState(() {});
                          }
                        : null,
                  ),
                ),
                const SizedBox(width: 4),
                _sending
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : TextButton(onPressed: _send, child: const Text('蓋樓')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
