import 'package:flutter/material.dart';

import 'auth_guard.dart';

/// Shows the reason picker and runs [submit] with the chosen reason. Handles sign-in,
/// confirmation feedback and the "already reported" failure.
Future<void> reportWithFeedback(
  BuildContext context, {
  required List<String> reasons,
  required Future<void> Function(String reason) submit,
}) async {
  if (!await ensureSignedIn(context)) return;
  if (!context.mounted) return;

  final reason = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('檢舉原因', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          for (final r in reasons)
            ListTile(title: Text(r), onTap: () => Navigator.pop(context, r)),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (reason == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  try {
    await submit(reason);
    messenger.showSnackBar(const SnackBar(content: Text('已收到檢舉，謝謝你')));
  } catch (_) {
    messenger.showSnackBar(const SnackBar(content: Text('送出失敗，你可能已經檢舉過這則內容')));
  }
}
