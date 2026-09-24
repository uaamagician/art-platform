import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_service.dart';

class FollowService {
  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      appFirestore.collection('users').doc(uid);

  Stream<bool> isFollowingStream(String me, String target) => _user(me)
      .collection('following')
      .doc(target)
      .snapshots()
      .map((s) => s.exists);

  Future<void> setFollowing(String me, String target, bool follow) {
    final batch = appFirestore.batch();
    final followingRef = _user(me).collection('following').doc(target);
    final followerRef = _user(target).collection('followers').doc(me);
    final delta = FieldValue.increment(follow ? 1 : -1);

    if (follow) {
      batch.set(followingRef, {'createdAt': FieldValue.serverTimestamp()});
      batch.set(followerRef, {'createdAt': FieldValue.serverTimestamp()});
    } else {
      batch.delete(followingRef);
      batch.delete(followerRef);
    }
    batch.set(_user(me), {'followingCount': delta}, SetOptions(merge: true));
    batch.update(_user(target), {'followersCount': delta});
    return batch.commit();
  }
}
