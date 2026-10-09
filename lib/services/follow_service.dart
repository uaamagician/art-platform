import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_service.dart';

class FollowService {
  DocumentReference<Map<String, dynamic>> _profile(String uid) =>
      appFirestore.collection('profiles').doc(uid);

  Future<void> setFollowing(String me, String target, bool follow) {
    final batch = appFirestore.batch();
    final followingRef = _profile(me).collection('following').doc(target);
    final followerRef = _profile(target).collection('followers').doc(me);

    if (follow) {
      batch.set(followingRef, {'createdAt': FieldValue.serverTimestamp()});
      batch.set(followerRef, {'createdAt': FieldValue.serverTimestamp()});
    } else {
      batch.delete(followingRef);
      batch.delete(followerRef);
    }
    return batch.commit();
  }

  Future<List<String>> followerIds(String uid) async {
    final snap = await _profile(uid)
        .collection('followers')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .get();
    return snap.docs.map((d) => d.id).toList();
  }

  Future<List<String>> followingIds(String uid) async {
    final snap = await _profile(uid)
        .collection('following')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .get();
    return snap.docs.map((d) => d.id).toList();
  }
}
