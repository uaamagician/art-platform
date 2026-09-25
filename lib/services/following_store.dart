import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'firestore_service.dart';

/// One shared listener on users/{me}/following so every follow button on screen
/// reads from memory instead of opening its own Firestore listener.
class FollowingStore extends ChangeNotifier {
  FollowingStore._();
  static final FollowingStore instance = FollowingStore._();

  Set<String> _ids = {};
  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  bool isFollowing(String uid) => _ids.contains(uid);

  void init() {
    _authSub ??= FirebaseAuth.instance.authStateChanges().listen((user) {
      _sub?.cancel();
      _sub = null;
      _ids = {};
      notifyListeners();
      if (user == null) return;
      _sub = appFirestore
          .collection('users')
          .doc(user.uid)
          .collection('following')
          .snapshots()
          .listen(
        (snap) {
          _ids = snap.docs.map((d) => d.id).toSet();
          notifyListeners();
        },
        onError: (_) {},
      );
    });
  }
}
