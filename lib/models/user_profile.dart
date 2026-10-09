import 'package:cloud_firestore/cloud_firestore.dart';

/// Public profile (profiles/{uid}); safe for guests to read. Private data stays in users/{uid}.
class UserProfile {
  final String uid;
  final String displayName;
  final String photoUrl;
  final String bio;
  final int postCount;
  final int commentCount;
  final int likedCount;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
    required this.bio,
    required this.postCount,
    required this.commentCount,
    required this.likedCount,
  });

  factory UserProfile.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return UserProfile(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      postCount: (data['postCount'] as num?)?.toInt() ?? 0,
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
      likedCount: (data['likedCount'] as num?)?.toInt() ?? 0,
    );
  }

  String get nameOrDefault => displayName.isNotEmpty ? displayName : '創作者';
}

/// Numbers used for the (hidden) experience points, level and achievements.
class UserStats {
  final int posts;
  final int followers;
  final int following;
  final int comments;
  final int liked;

  const UserStats({
    this.posts = 0,
    this.followers = 0,
    this.following = 0,
    this.comments = 0,
    this.liked = 0,
  });
}
