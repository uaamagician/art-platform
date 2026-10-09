import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/group.dart';
import 'firestore_service.dart';

class GroupService {
  CollectionReference<Map<String, dynamic>> get _col =>
      appFirestore.collection('groups');

  Stream<List<Group>> myGroupsStream(String uid) => _col
      .where('memberIds', arrayContains: uid)
      .snapshots()
      .map((s) => _sortByActivity(s.docs.map(Group.fromDoc).toList()));

  Future<List<Group>> discover(String uid) async {
    final snap = await _col.orderBy('createdAt', descending: true).limit(60).get();
    return snap.docs
        .map(Group.fromDoc)
        .where((g) => !g.isMember(uid))
        .toList();
  }

  Stream<Group?> groupStream(String id) =>
      _col.doc(id).snapshots().map((s) => s.exists ? Group.fromDoc(s) : null);

  Future<String> create({
    required User user,
    required String name,
    required String description,
  }) async {
    final ref = _col.doc();
    await ref.set({
      'name': name,
      'description': description,
      'ownerId': user.uid,
      'memberIds': [user.uid],
      'locked': false,
      'lastMessage': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> join(String groupId, String uid) =>
      _col.doc(groupId).update({'memberIds': FieldValue.arrayUnion([uid])});

  Future<void> leave(String groupId, String uid) =>
      _col.doc(groupId).update({'memberIds': FieldValue.arrayRemove([uid])});

  Future<void> kick(String groupId, String uid) => leave(groupId, uid);

  Future<void> setLocked(String groupId, bool locked) =>
      _col.doc(groupId).update({'locked': locked});

  Future<void> deleteGroup(String groupId) async {
    for (final name in ['messages', 'strokes']) {
      while (true) {
        final snap = await _col.doc(groupId).collection(name).limit(400).get();
        if (snap.docs.isEmpty) break;
        final batch = appFirestore.batch();
        for (final doc in snap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    }
    await _col.doc(groupId).delete();
  }

  Stream<List<GroupMessage>> messagesStream(String groupId) => _col
      .doc(groupId)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map(GroupMessage.fromDoc).toList());

  Future<void> sendMessage(String groupId, User user, String text) {
    final batch = appFirestore.batch();
    batch.set(_col.doc(groupId).collection('messages').doc(), {
      'userId': user.uid,
      'userName': user.displayName ?? '',
      'userPhotoUrl': user.photoURL ?? '',
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_col.doc(groupId), {
      'lastMessage': text.length > 40 ? '${text.substring(0, 40)}…' : text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
    return batch.commit();
  }

  Future<void> deleteMessage(String groupId, String messageId) =>
      _col.doc(groupId).collection('messages').doc(messageId).delete();

  Stream<List<Stroke>> strokesStream(String groupId) => _col
      .doc(groupId)
      .collection('strokes')
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map(Stroke.fromDoc).toList());

  Future<void> addStroke(
    String groupId, {
    required String uid,
    required int color,
    required double width,
    required List<double> points,
  }) {
    return _col.doc(groupId).collection('strokes').add({
      'userId': uid,
      'color': color,
      'width': width,
      'points': points,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteStroke(String groupId, String strokeId) =>
      _col.doc(groupId).collection('strokes').doc(strokeId).delete();

  Future<void> clearBoard(String groupId) async {
    while (true) {
      final snap = await _col.doc(groupId).collection('strokes').limit(400).get();
      if (snap.docs.isEmpty) break;
      final batch = appFirestore.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  List<Group> _sortByActivity(List<Group> groups) {
    int stamp(Group g) =>
        (g.lastMessageAt ?? g.createdAt)?.millisecondsSinceEpoch ?? 0;
    groups.sort((a, b) => stamp(b).compareTo(stamp(a)));
    return groups;
  }
}
