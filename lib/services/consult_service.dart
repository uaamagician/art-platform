import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/consult.dart';
import 'firestore_service.dart';

class ConsultService {
  CollectionReference<Map<String, dynamic>> get _col =>
      appFirestore.collection('consults');

  DocumentReference<Map<String, dynamic>> newRef() => _col.doc();

  Future<List<Consult>> fetchAll({int limit = 100}) async {
    final snap = await _col.orderBy('createdAt', descending: true).limit(limit).get();
    return snap.docs.map(Consult.fromDoc).toList();
  }

  Stream<Consult?> stream(String id) =>
      _col.doc(id).snapshots().map((s) => s.exists ? Consult.fromDoc(s) : null);

  Stream<List<ConsultFloor>> floorsStream(String id) => _col
      .doc(id)
      .collection('floors')
      .orderBy('floor')
      .snapshots()
      .map((s) => s.docs.map(ConsultFloor.fromDoc).toList());

  Future<void> create(
    DocumentReference<Map<String, dynamic>> ref, {
    required User user,
    required String title,
    required String description,
    required String imageUrl,
  }) {
    return ref.set({
      'userId': user.uid,
      'userName': user.displayName ?? '',
      'userPhotoUrl': user.photoURL ?? '',
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'floorsCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Adds the next floor (樓). The floor number is taken inside a transaction so
  /// two people replying at the same moment never share a number.
  Future<void> addFloor(
    String consultId, {
    required User user,
    required String text,
    String imageUrl = '',
  }) {
    final consultRef = _col.doc(consultId);
    return appFirestore.runTransaction((tx) async {
      final snap = await tx.get(consultRef);
      final next = ((snap.data()?['floorsCount'] as num?)?.toInt() ?? 0) + 1;
      tx.update(consultRef, {'floorsCount': next});
      tx.set(consultRef.collection('floors').doc('f$next'), {
        'floor': next,
        'userId': user.uid,
        'userName': user.displayName ?? '',
        'userPhotoUrl': user.photoURL ?? '',
        'text': text,
        'imageUrl': imageUrl,
        'deleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> removeFloor(String consultId, String floorId) => _col
      .doc(consultId)
      .collection('floors')
      .doc(floorId)
      .update({'deleted': true, 'text': '', 'imageUrl': ''});

  Future<void> delete(Consult consult) async {
    await _col.doc(consult.id).delete();
    try {
      await FirebaseStorage.instance.refFromURL(consult.imageUrl).delete();
    } catch (_) {}
  }
}
