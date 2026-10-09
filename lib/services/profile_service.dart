import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';
import 'firestore_service.dart';

class ProfileService {
  static const maxBioLength = 40;
  static final _ensured = <String>{};

  CollectionReference<Map<String, dynamic>> get _profiles =>
      appFirestore.collection('profiles');

  DocumentReference<Map<String, dynamic>> profileRef(String uid) =>
      _profiles.doc(uid);

  Stream<UserProfile?> profileStream(String uid) => _profiles
      .doc(uid)
      .snapshots()
      .map((s) => s.exists ? UserProfile.fromDoc(s) : null);

  Future<UserProfile?> fetchProfile(String uid) async {
    final snap = await _profiles.doc(uid).get();
    return snap.exists ? UserProfile.fromDoc(snap) : null;
  }

  Future<Map<String, UserProfile>> fetchProfiles(Iterable<String> ids) async {
    final list = ids.toSet().toList();
    final result = <String, UserProfile>{};
    for (var i = 0; i < list.length; i += 30) {
      final chunk = list.sublist(i, min(i + 30, list.length));
      final snap = await _profiles.where(FieldPath.documentId, whereIn: chunk).get();
      for (final doc in snap.docs) {
        result[doc.id] = UserProfile.fromDoc(doc);
      }
    }
    return result;
  }

  Future<List<UserProfile>> topCreators({int limit = 60}) async {
    final snap =
        await _profiles.orderBy('postCount', descending: true).limit(limit).get();
    return snap.docs
        .map(UserProfile.fromDoc)
        .where((p) => p.postCount > 0)
        .toList();
  }

  /// Creators whose name starts with [query] (case-sensitive prefix match).
  Future<List<UserProfile>> searchByName(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final snap = await _profiles
        .where('displayName', isGreaterThanOrEqualTo: q)
        .where('displayName', isLessThan: '$q\uf8ff')
        .limit(10)
        .get();
    return snap.docs.map(UserProfile.fromDoc).toList();
  }

  Future<UserStats> fetchStats(String uid, {UserProfile? profile}) async {
    final results = await Future.wait([
      appFirestore.collection('posts').where('userId', isEqualTo: uid).count().get(),
      _profiles.doc(uid).collection('followers').count().get(),
      _profiles.doc(uid).collection('following').count().get(),
    ]);
    return UserStats(
      posts: results[0].count ?? 0,
      followers: results[1].count ?? 0,
      following: results[2].count ?? 0,
      comments: profile?.commentCount ?? 0,
      liked: profile?.likedCount ?? 0,
    );
  }

  /// Creates (or refreshes) the public profile for a signed-in user. Safe to call repeatedly.
  Future<void> ensureProfile(User user) async {
    if (!_ensured.add(user.uid)) return;
    try {
      final ref = _profiles.doc(user.uid);
      final snap = await ref.get();
      final data = snap.data();
      final name = user.displayName ?? '';
      final photo = user.photoURL ?? '';

      if (data != null && data.containsKey('createdAt')) {
        if (data['displayName'] != name || data['photoUrl'] != photo) {
          await ref.update({'displayName': name, 'photoUrl': photo});
        }
        return;
      }

      var bio = '';
      try {
        final legacy = await appFirestore.collection('users').doc(user.uid).get();
        bio = (legacy.data()?['bio'] as String?) ?? '';
      } catch (_) {}

      var postCount = 0;
      try {
        final count = await appFirestore
            .collection('posts')
            .where('userId', isEqualTo: user.uid)
            .count()
            .get();
        postCount = count.count ?? 0;
      } catch (_) {}

      await ref.set({
        'displayName': name,
        'photoUrl': photo,
        'bio': (data?['bio'] as String?) ?? bio,
        'postCount': postCount,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      _ensured.remove(user.uid);
    }
  }

  /// Saves the bio and refreshes the copy stored on the user's own posts
  /// (posts keep a denormalized userBio so the feed needs no extra reads).
  Future<void> updateBio(String uid, String bio) async {
    await _profiles.doc(uid).set({'bio': bio}, SetOptions(merge: true));

    final posts = await appFirestore
        .collection('posts')
        .where('userId', isEqualTo: uid)
        .get();
    for (var i = 0; i < posts.docs.length; i += 400) {
      final batch = appFirestore.batch();
      for (final doc in posts.docs.skip(i).take(400)) {
        batch.update(doc.reference, {'userBio': bio});
      }
      await batch.commit();
    }
  }
}
