import 'package:flutter/material.dart';

import '../utils/tag_utils.dart';

/// Chips for the current hashtags, a field to add more, and optional one-tap suggestions.
class TagEditor extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  final int max;
  final List<String> suggestions;

  const TagEditor({
    super.key,
    required this.tags,
    required this.onChanged,
    this.max = 10,
    this.suggestions = const [],
  });

  @override
  State<TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends State<TagEditor> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(String raw) {
    final tag = normalizeTag(raw);
    _controller.clear();
    if (tag.isEmpty || widget.tags.contains(tag)) return;
    if (widget.tags.length >= widget.max) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('最多只能加入 ${widget.max} 個標籤')),
      );
      return;
    }
    widget.onChanged([...widget.tags, tag]);
  }

  @override
  Widget build(BuildContext context) {
    final suggestions =
        widget.suggestions.where((s) => !widget.tags.contains(normalizeTag(s))).take(10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(hintText: '輸入標籤，例如：光影練習', isDense: true),
                onSubmitted: _add,
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: () => _add(_controller.text),
              child: const Text('新增'),
            ),
          ],
        ),
        if (widget.tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final tag in widget.tags)
                InputChip(
                  label: Text('#$tag'),
                  deleteIcon: const Text('✕', style: TextStyle(fontSize: 12)),
                  onDeleted: () => widget.onChanged(widget.tags.where((t) => t != tag).toList()),
                ),
            ],
          ),
        ],
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final s in suggestions)
                ActionChip(label: Text('#$s'), onPressed: () => _add(s)),
            ],
          ),
        ],
      ],
    );
  }
}
