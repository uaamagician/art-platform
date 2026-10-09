import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'firestore_service.dart';

/// Keeps the document ids of one per-user collection in memory with a single
/// listener, so any number of buttons on screen can read them without their own stream.
class IdSetStore extends ChangeNotifier {
  IdSetStore(this._collection);

  final CollectionReference<Map<String, dynamic>> Function(String uid) _collection;

  Set<String> _ids = {};
  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  bool contains(String id) => _ids.contains(id);

  int get length => _ids.length;

  void init() {
    _authSub ??= FirebaseAuth.instance.authStateChanges().listen((user) {
      _sub?.cancel();
      _sub = null;
      if (_ids.isNotEmpty) {
        _ids = {};
        notifyListeners();
      }
      if (user == null) return;
      _sub = _collection(user.uid).snapshots().listen(
        (snap) {
          _ids = snap.docs.map((d) => d.id).toSet();
          notifyListeners();
        },
        onError: (_) {},
      );
    });
  }
}

class UserStores {
  UserStores._();

  /// Who I follow (profiles/{me}/following).
  static final following = IdSetStore(
    (uid) => appFirestore.collection('profiles').doc(uid).collection('following'),
  );

  /// Posts I liked (users/{me}/liked, private).
  static final liked = IdSetStore(
    (uid) => appFirestore.collection('users').doc(uid).collection('liked'),
  );

  static void init() {
    following.init();
    liked.init();
  }
}
