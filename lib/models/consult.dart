import 'package:cloud_firestore/cloud_firestore.dart';

/// A "改圖諮詢" post: the author opts in to receiving edited drafts from other artists.
class Consult {
  final String id;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String title;
  final String description;
  final String imageUrl;
  final int floorsCount;
  final Timestamp? createdAt;

  const Consult({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.floorsCount,
    required this.createdAt,
  });

  factory Consult.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return Consult(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      userPhotoUrl: data['userPhotoUrl'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      floorsCount: (data['floorsCount'] as num?)?.toInt() ?? 0,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }
}

class ConsultFloor {
  final String id;
  final int floor;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String text;
  final String imageUrl;
  final bool deleted;
  final Timestamp? createdAt;

  const ConsultFloor({
    required this.id,
    required this.floor,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.text,
    required this.imageUrl,
    required this.deleted,
    required this.createdAt,
  });

  factory ConsultFloor.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return ConsultFloor(
      id: doc.id,
      floor: (data['floor'] as num?)?.toInt() ?? 0,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      userPhotoUrl: data['userPhotoUrl'] as String? ?? '',
      text: data['text'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      deleted: data['deleted'] == true,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }
}
