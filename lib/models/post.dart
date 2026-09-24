import 'package:cloud_firestore/cloud_firestore.dart';

class PostAttachment {
  final String name;
  final String url;
  final int size;

  const PostAttachment({
    required this.name,
    required this.url,
    required this.size,
  });

  factory PostAttachment.fromMap(Map<String, dynamic> map) {
    return PostAttachment(
      name: map['name'] as String? ?? '',
      url: map['url'] as String? ?? '',
      size: (map['size'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'url': url, 'size': size};
}

class Post {
  final String id;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String title;
  final String description;
  final List<String> imageUrls;
  final List<PostAttachment> attachments;
  final String category;
  final List<String> tags;
  final bool isNsfw;
  final bool isAiGenerated;
  final int likesCount;
  final int commentsCount;
  final double? aspectRatio;
  final Timestamp? createdAt;

  const Post({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.title,
    required this.description,
    required this.imageUrls,
    required this.attachments,
    required this.category,
    required this.tags,
    required this.isNsfw,
    required this.isAiGenerated,
    required this.likesCount,
    required this.commentsCount,
    required this.aspectRatio,
    required this.createdAt,
  });

  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final urls = List<String>.from(data['imageUrls'] ?? const []);
    final cover = data['imageUrl'] as String? ?? '';
    final attachments = (data['attachments'] as List<dynamic>? ?? const [])
        .map((e) => PostAttachment.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    return Post(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      userPhotoUrl: data['userPhotoUrl'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrls: urls.isNotEmpty ? urls : (cover.isNotEmpty ? [cover] : const []),
      attachments: attachments,
      category: data['category'] as String? ?? '',
      tags: List<String>.from(data['tags'] ?? const []),
      isNsfw: data['isNsfw'] == true,
      isAiGenerated: data['isAiGenerated'] == true,
      likesCount: (data['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (data['commentsCount'] as num?)?.toInt() ?? 0,
      aspectRatio: (data['aspectRatio'] as num?)?.toDouble(),
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'attachments': attachments.map((a) => a.toMap()).toList(),
      'category': category,
      'tags': tags,
      'isNsfw': isNsfw,
      'isAiGenerated': isAiGenerated,
      'likesCount': 0,
      'commentsCount': 0,
      if (aspectRatio != null) 'aspectRatio': aspectRatio,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
