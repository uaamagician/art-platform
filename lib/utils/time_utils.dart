import 'package:cloud_firestore/cloud_firestore.dart';

String timeAgo(Timestamp? timestamp) {
  if (timestamp == null) return '剛剛';
  final diff = DateTime.now().difference(timestamp.toDate());
  if (diff.inMinutes < 1) return '剛剛';
  if (diff.inMinutes < 60) return '${diff.inMinutes} 分鐘前';
  if (diff.inHours < 24) return '${diff.inHours} 小時前';
  if (diff.inDays < 30) return '${diff.inDays} 天前';
  final date = timestamp.toDate();
  return '${date.year}/${date.month}/${date.day}';
}

String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String formatDate(Timestamp timestamp) {
  final d = timestamp.toDate();
  return '${d.year}/${d.month}/${d.day}';
}

/// "剩 5 天" / "今天截止" / "已過期" for a deadline.
String deadlineLabel(Timestamp deadline) {
  final days = DateTime(deadline.toDate().year, deadline.toDate().month, deadline.toDate().day)
      .difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))
      .inDays;
  if (days < 0) return '已過期';
  if (days == 0) return '今天截止';
  return '剩 $days 天';
}
