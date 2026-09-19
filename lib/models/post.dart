import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String imageUrl;
  final String title;
  final String description;
  final String category;
  final List<String> tags;
  final Timestamp? createdAt;

  Post({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.category,
    required this.tags,
    required this.createdAt,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      tags: List<String>.from(data['tags'] ?? const []),
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'imageUrl': imageUrl,
      'title': title,
      'description': description,
      'category': category,
      'tags': tags,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
