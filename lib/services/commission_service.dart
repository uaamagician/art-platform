import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/commission.dart';
import 'firestore_service.dart';

class CommissionService {
  static const reportReasons = [
    '詐騙或可疑',
    '成人內容未標示',
    '垃圾訊息或廣告',
    '侵權或抄襲',
    '騷擾或不當內容',
    '其他',
  ];

  CollectionReference<Map<String, dynamic>> get _col =>
      appFirestore.collection('commissions');

  DocumentReference<Map<String, dynamic>> newRef() => _col.doc();

  Future<List<Commission>> fetchAll({int limit = 100}) async {
    final snap = await _col.orderBy('createdAt', descending: true).limit(limit).get();
    return snap.docs.map(Commission.fromDoc).toList();
  }

  Future<List<Commission>> fetchByUser(String uid) async {
    final snap = await _col.where('userId', isEqualTo: uid).limit(100).get();
    final list = snap.docs.map(Commission.fromDoc).toList()
      ..sort((a, b) => (b.createdAt?.millisecondsSinceEpoch ?? 0)
          .compareTo(a.createdAt?.millisecondsSinceEpoch ?? 0));
    return list;
  }

  Stream<Commission?> stream(String id) =>
      _col.doc(id).snapshots().map((s) => s.exists ? Commission.fromDoc(s) : null);

  Future<void> create(DocumentReference<Map<String, dynamic>> ref, Commission commission) =>
      ref.set(commission.toFirestore());

  Future<void> setOpen(String id, bool open) =>
      _col.doc(id).update({'status': open ? 'open' : 'closed'});

  Future<void> delete(Commission commission) async {
    await _col.doc(commission.id).delete();
    for (final url in commission.imageUrls) {
      try {
        await FirebaseStorage.instance.refFromURL(url).delete();
      } catch (_) {}
    }
  }

  /// Files a report and bumps the public report counter in one atomic write.
  /// After [Commission.hideAfterReports] reports the commission is hidden from lists.
  Future<void> report(Commission commission, String uid, String reason) {
    final batch = appFirestore.batch();
    batch.set(
      appFirestore.collection('reports').doc('commission_${commission.id}_$uid'),
      {
        'targetType': 'commission',
        'targetId': commission.id,
        'reporterId': uid,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
    batch.update(_col.doc(commission.id), {'reportCount': FieldValue.increment(1)});
    return batch.commit();
  }
}
