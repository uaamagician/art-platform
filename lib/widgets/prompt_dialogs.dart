import 'package:flutter/material.dart';

/// Single text field dialog. The dialog owns its controller, so it is disposed only after
/// the closing animation has finished. Returns the trimmed text, or null when cancelled.
Future<String?> showTextPrompt(
  BuildContext context, {
  required String title,
  String initialText = '',
  String hint = '',
  int maxLength = 100,
  String confirmLabel = '儲存',
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _TextPromptDialog(
      title: title,
      initialText: initialText,
      hint: hint,
      maxLength: maxLength,
      confirmLabel: confirmLabel,
    ),
  );
}

class _TextPromptDialog extends StatefulWidget {
  final String title;
  final String initialText;
  final String hint;
  final int maxLength;
  final String confirmLabel;

  const _TextPromptDialog({
    required this.title,
    required this.initialText,
    required this.hint,
    required this.maxLength,
    required this.confirmLabel,
  });

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: widget.maxLength,
        decoration: InputDecoration(hintText: widget.hint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// Name + description for a new group. Returns null when cancelled.
Future<({String name, String description})?> showCreateGroupDialog(BuildContext context) {
  return showDialog<({String name, String description})>(
    context: context,
    builder: (context) => const _CreateGroupDialog(),
  );
}

class _CreateGroupDialog extends StatefulWidget {
  const _CreateGroupDialog();

  @override
  State<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<_CreateGroupDialog> {
  final _name = TextEditingController();
  final _description = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('建立群組'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            maxLength: 30,
            decoration: const InputDecoration(labelText: '群組名稱'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _description,
            maxLines: 3,
            maxLength: 200,
            decoration: const InputDecoration(labelText: '簡介（選填）', alignLabelWithHint: true),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
            (name: _name.text.trim(), description: _description.text.trim()),
          ),
          child: const Text('建立'),
        ),
      ],
    );
  }
}
