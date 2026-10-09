import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final List<String> memberIds;
  final bool locked;
  final String lastMessage;
  final Timestamp? lastMessageAt;
  final Timestamp? createdAt;

  const Group({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.memberIds,
    required this.locked,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.createdAt,
  });

  int get memberCount => memberIds.length;

  bool isMember(String? uid) => uid != null && memberIds.contains(uid);

  factory Group.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return Group(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? const []),
      locked: data['locked'] == true,
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageAt: data['lastMessageAt'] as Timestamp?,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }
}

class GroupMessage {
  final String id;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String text;
  final Timestamp? createdAt;

  const GroupMessage({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.text,
    required this.createdAt,
  });

  factory GroupMessage.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return GroupMessage(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      userPhotoUrl: data['userPhotoUrl'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp?,
    );
  }
}

/// One pen stroke on the shared whiteboard. Points are normalized to 0..1.
class Stroke {
  final String id;
  final String userId;
  final int color;
  final double width;
  final List<double> points;
  final Timestamp? createdAt;

  const Stroke({
    required this.id,
    required this.userId,
    required this.color,
    required this.width,
    required this.points,
    required this.createdAt,
  });

  factory Stroke.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return Stroke(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      color: (data['color'] as num?)?.toInt() ?? 0xFF221E1B,
      width: (data['width'] as num?)?.toDouble() ?? 4,
      points: [
        for (final v in (data['points'] as List<dynamic>? ?? const []))
          (v as num).toDouble(),
      ],
      createdAt: data['createdAt'] as Timestamp?,
    );
  }
}
