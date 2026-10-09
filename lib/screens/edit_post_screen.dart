import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/category_service.dart';
import '../services/post_service.dart';
import '../widgets/tag_editor.dart';

/// Edit the text fields of your own post (images and safety labels stay as published).
/// Pops with `true` when saved.
class EditPostScreen extends StatefulWidget {
  final Post post;

  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  late final _title = TextEditingController(text: widget.post.title);
  late final _description = TextEditingController(text: widget.post.description);
  late final Future<List<String>> _categories = CategoryService().names();
  late String _category = widget.post.category;
  late List<String> _tags = List.of(widget.post.tags);
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請輸入標題')));
      return;
    }
    if (_category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請選擇分類')));
      return;
    }
    setState(() => _saving = true);
    try {
      await PostService().updatePost(
        widget.post,
        title: title,
        description: _description.text.trim(),
        category: _category,
        tags: _tags,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('儲存失敗，請稍後再試')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('編輯作品'),
        actions: [
          TextButton(onPressed: _saving ? null : _save, child: const Text('儲存')),
        ],
        bottom: _saving
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: ListView(
          padding: const EdgeInsets.all(16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            TextField(
              controller: _title,
              maxLength: 50,
              decoration: const InputDecoration(labelText: '標題'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _description,
              maxLines: 6,
              maxLength: 2000,
              decoration: const InputDecoration(labelText: '作品描述', alignLabelWithHint: true),
            ),
            const SizedBox(height: 16),
            const Text('分類', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            FutureBuilder<List<String>>(
              future: _categories,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return snapshot.hasError ? const Text('分類載入失敗') : const LinearProgressIndicator();
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final name in snapshot.data!)
                      ChoiceChip(
                        label: Text(name),
                        showCheckmark: false,
                        selected: _category == name,
                        onSelected: (_) => setState(() => _category = name),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            const Text('標籤', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            TagEditor(tags: _tags, onChanged: (tags) => setState(() => _tags = tags)),
            const SizedBox(height: 24),
            const Text(
              '圖片、成人內容與 AI 生成標籤在發布後無法修改。',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF8A8178)),
            ),
          ],
        ),
      ),
    );
  }
}
