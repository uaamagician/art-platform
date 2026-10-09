import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/consult_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

/// Publish a 改圖諮詢 post. Pops with `true` when published.
class ConsultCreateScreen extends StatefulWidget {
  const ConsultCreateScreen({super.key});

  @override
  State<ConsultCreateScreen> createState() => _ConsultCreateScreenState();
}

class _ConsultCreateScreenState extends State<ConsultCreateScreen> {
  static const _maxBytes = 20 * 1024 * 1024;

  final _title = TextEditingController();
  final _description = TextEditingController();

  Uint8List? _bytes;
  String _extension = 'jpg';
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _pick() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 92);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > _maxBytes) return _message('圖片超過 20MB');
      setState(() {
        _bytes = bytes;
        _extension = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : 'jpg';
      });
    } catch (_) {
      if (mounted) _message('無法取得圖片，請確認已允許存取相簿');
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final title = _title.text.trim();
    if (_bytes == null) return _message('請先選擇要諮詢的作品圖片');
    if (title.isEmpty) return _message('請輸入標題');
    final user = AuthService().currentUser;
    if (user == null) return;

    setState(() => _submitting = true);
    final service = ConsultService();
    final storage = StorageService();
    String? uploadedPath;
    try {
      final ref = service.newRef();
      final file = await storage.uploadBytes(
        path: 'consults/${user.uid}/${ref.id}/original.$_extension',
        bytes: _bytes!,
        contentType: StorageService.imageMimeType(_extension),
      );
      uploadedPath = file.path;
      await service.create(
        ref,
        user: user,
        title: title,
        description: _description.text.trim(),
        imageUrl: file.url,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (uploadedPath != null) await storage.deleteQuietly(uploadedPath);
      if (mounted) _message('發布失敗，請確認網路後再試一次');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('發布改圖諮詢'),
        actions: [
          TextButton(onPressed: _submitting ? null : _submit, child: const Text('發布')),
        ],
        bottom: _submitting
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: AbsorbPointer(
        absorbing: _submitting,
        child: ListView(
          padding: const EdgeInsets.all(16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            GestureDetector(
              onTap: _pick,
              child: Container(
                height: 260,
                decoration: BoxDecoration(
                  color: AppColors.tint,
                  borderRadius: BorderRadius.circular(18),
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: _bytes == null
                    ? const Text('點擊選擇要諮詢的作品')
                    : Image.memory(_bytes!, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              maxLength: 50,
              decoration: const InputDecoration(
                labelText: '標題',
                hintText: '例如：手的比例總是怪怪的',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _description,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: '想請大家看哪裡？（選填）',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.tint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                '發布後，其他創作者可以直接用圖片或文字回覆你（蓋樓），也就是授權他們在你的作品上畫改圖草稿。',
                style: TextStyle(fontSize: 12.5, height: 1.5, color: Color(0xFF5C544C)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
