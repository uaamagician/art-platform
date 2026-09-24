import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/comment.dart';
import '../models/post.dart';
import 'firestore_service.dart';

class FollowingFeed {
  final int followingCount;
  final List<Post> posts;

  const FollowingFeed({required this.followingCount, required this.posts});
}

class _Interest {
  final Map<String, int> tags;
  final Map<String, int> categories;

  const _Interest(this.tags, this.categories);
}

class PostService {
  CollectionReference<Map<String, dynamic>> get _posts =>
      appFirestore.collection('posts');

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      appFirestore.collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> newPostRef() => _posts.doc();

  Stream<DocumentSnapshot<Map<String, dynamic>>> postStream(String postId) =>
      _posts.doc(postId).snapshots();

  Future<List<Post>> fetchLatest({int limit = 100}) async {
    final snap =
        await _posts.orderBy('createdAt', descending: true).limit(limit).get();
    return snap.docs.map(Post.fromFirestore).toList();
  }

  Future<List<Post>> fetchByCategory(String category) async {
    final snap =
        await _posts.where('category', isEqualTo: category).limit(100).get();
    return _sortByNewest(snap.docs.map(Post.fromFirestore).toList());
  }

  Future<List<Post>> search(String query) async {
    final q = query.trim().toLowerCase().replaceFirst(RegExp(r'^[#＃]+'), '');
    if (q.isEmpty) return [];
    final posts = await fetchLatest(limit: 200);
    return posts.where((post) {
      return post.title.toLowerCase().contains(q) ||
          post.description.toLowerCase().contains(q) ||
          post.userName.toLowerCase().contains(q) ||
          post.category.toLowerCase().contains(q) ||
          post.tags.any((tag) => tag.toLowerCase().contains(q));
    }).toList();
  }

  /// Posts ranked by overlap with the user's own / liked / bookmarked hashtags,
  /// then freshness and popularity. Guests get a freshness + popularity ranking.
  Future<List<Post>> fetchRecommended(String? uid) async {
    final posts = await fetchLatest(limit: 100);
    final interest =
        uid == null ? const _Interest({}, {}) : await _loadInterest(uid);
    final now = DateTime.now();

    final scored = [for (final p in posts) (p, _score(p, interest, now))]
      ..sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final entry in scored) entry.$1];
  }

  Future<FollowingFeed> fetchFollowing(String uid) async {
    final followingSnap = await _user(uid).collection('following').get();
    final ids = followingSnap.docs.map((d) => d.id).toList();
    if (ids.isEmpty) return const FollowingFeed(followingCount: 0, posts: []);

    final chunks = <List<String>>[
      for (var i = 0; i < ids.length; i += 30)
        ids.sublist(i, min(i + 30, ids.length)),
    ];
    final results = await Future.wait(
      chunks.map((chunk) => _posts.where('userId', whereIn: chunk).get()),
    );
    final posts = _sortByNewest(
      results.expand((s) => s.docs).map(Post.fromFirestore).toList(),
    );
    return FollowingFeed(
      followingCount: ids.length,
      posts: posts.take(100).toList(),
    );
  }

  Future<void> publish({
    required DocumentReference<Map<String, dynamic>> ref,
    required Post post,
    required Set<String> presetTags,
  }) async {
    final batch = appFirestore.batch();
    batch.set(ref, post.toFirestore());
    batch.set(
      _user(post.userId),
      {'postCount': FieldValue.increment(1)},
      SetOptions(merge: true),
    );
    final tagsCollection = appFirestore.collection('tags');
    for (final tag in post.tags) {
      batch.set(
        tagsCollection.doc(tag),
        {
          'name': tag,
          'usageCount': FieldValue.increment(1),
          if (!presetTags.contains(tag)) 'type': 'custom',
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Stream<bool> likedStream(String postId, String uid) => _posts
      .doc(postId)
      .collection('likes')
      .doc(uid)
      .snapshots()
      .map((s) => s.exists);

  Future<void> toggleLike(Post post, String uid) {
    final postRef = _posts.doc(post.id);
    final likeRef = postRef.collection('likes').doc(uid);
    final mirrorRef = _user(uid).collection('liked').doc(post.id);

    return appFirestore.runTransaction((tx) async {
      final likeSnap = await tx.get(likeRef);
      if (likeSnap.exists) {
        tx.delete(likeRef);
        tx.delete(mirrorRef);
        tx.update(postRef, {'likesCount': FieldValue.increment(-1)});
      } else {
        tx.set(likeRef, {'likedAt': FieldValue.serverTimestamp()});
        tx.set(mirrorRef, _interestSnapshot(post));
        tx.update(postRef, {'likesCount': FieldValue.increment(1)});
      }
    });
  }

  Stream<bool> bookmarkedStream(String postId, String uid) => _user(uid)
      .collection('bookmarks')
      .doc(postId)
      .snapshots()
      .map((s) => s.exists);

  Future<void> toggleBookmark(Post post, String uid) async {
    final ref = _user(uid).collection('bookmarks').doc(post.id);
    final snap = await ref.get();
    if (snap.exists) {
      await ref.delete();
    } else {
      await ref.set(_interestSnapshot(post));
    }
  }

  Stream<List<Comment>> commentsStream(String postId) => _posts
      .doc(postId)
      .collection('comments')
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map(Comment.fromFirestore).toList());

  Future<void> addComment(Post post, User user, String text) {
    final batch = appFirestore.batch();
    final commentRef = _posts.doc(post.id).collection('comments').doc();
    batch.set(commentRef, {
      'userId': user.uid,
      'userName': user.displayName ?? '',
      'userPhotoUrl': user.photoURL ?? '',
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_posts.doc(post.id), {'commentsCount': FieldValue.increment(1)});
    return batch.commit();
  }

  Future<void> deleteComment(String postId, String commentId) {
    final batch = appFirestore.batch();
    batch.delete(_posts.doc(postId).collection('comments').doc(commentId));
    batch.update(_posts.doc(postId), {'commentsCount': FieldValue.increment(-1)});
    return batch.commit();
  }

  Map<String, dynamic> _interestSnapshot(Post post) => {
        'postId': post.id,
        'category': post.category,
        'tags': post.tags,
        'createdAt': FieldValue.serverTimestamp(),
      };

  Future<_Interest> _loadInterest(String uid) async {
    final tags = <String, int>{};
    final categories = <String, int>{};

    try {
      final results = await Future.wait([
        _user(uid)
            .collection('bookmarks')
            .orderBy('createdAt', descending: true)
            .limit(30)
            .get(),
        _user(uid)
            .collection('liked')
            .orderBy('createdAt', descending: true)
            .limit(30)
            .get(),
        _posts.where('userId', isEqualTo: uid).limit(30).get(),
      ]);
      for (final snap in results) {
        for (final doc in snap.docs) {
          final data = doc.data();
          for (final tag in List<String>.from(data['tags'] ?? const [])) {
            tags[tag] = (tags[tag] ?? 0) + 1;
          }
          final category = data['category'] as String?;
          if (category != null && category.isNotEmpty) {
            categories[category] = (categories[category] ?? 0) + 1;
          }
        }
      }
    } catch (_) {}

    return _Interest(tags, categories);
  }

  double _score(Post post, _Interest interest, DateTime now) {
    var score = 0.0;
    for (final tag in post.tags) {
      final count = interest.tags[tag];
      if (count != null) score += 1.5 + 0.5 * min(count, 4);
    }
    if (interest.categories.containsKey(post.category)) score += 1;

    final created = post.createdAt?.toDate() ?? now;
    final ageHours = now.difference(created).inHours.clamp(0, 24 * 60);
    score += 2 / (1 + ageHours / 24);
    score += log(1 + post.likesCount) * 0.4;
    return score;
  }

  List<Post> _sortByNewest(List<Post> posts) {
    posts.sort((a, b) => (b.createdAt?.millisecondsSinceEpoch ?? 0)
        .compareTo(a.createdAt?.millisecondsSinceEpoch ?? 0));
    return posts;
  }
}
