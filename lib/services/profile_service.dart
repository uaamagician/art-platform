import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_service.dart';

class ProfileService {
  static const maxBioLength = 40;

  Stream<String> bioStream(String uid) => appFirestore
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((s) => (s.data()?['bio'] as String?) ?? '');

  /// Saves the bio and refreshes the copy stored on the user's own posts
  /// (posts keep a denormalized userBio so the feed needs no extra reads).
  Future<void> updateBio(String uid, String bio) async {
    await appFirestore
        .collection('users')
        .doc(uid)
        .set({'bio': bio}, SetOptions(merge: true));

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
