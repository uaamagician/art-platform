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
