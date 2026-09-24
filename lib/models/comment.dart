import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String text;
  final Timestamp? createdAt;

  const Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return Comment(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      userPhotoUrl: data['userPhotoUrl'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp?,
    );
  }
}
