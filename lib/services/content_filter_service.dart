import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/post.dart';
import 'firestore_service.dart';

/// Global "show adult / AI content" preference. Both are hidden by default.
/// Stored on users/{uid}: showNsfw (default false), showAi (default false).
/// Guests use in-memory defaults. Your own posts are always visible to you.
class ContentFilterService extends ChangeNotifier {
  ContentFilterService._();
  static final ContentFilterService instance = ContentFilterService._();

  bool _showNsfw = false;
  bool _showAi = false;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _docSub;

  bool get showNsfw => _showNsfw;
  bool get showAi => _showAi;

  void init() {
    _authSub ??= FirebaseAuth.instance.authStateChanges().listen((user) {
      _docSub?.cancel();
      _docSub = null;
      if (user == null) {
        _update(false, false);
        return;
      }
      _docSub = appFirestore.collection('users').doc(user.uid).snapshots().listen(
        (snap) {
          final data = snap.data();
          _update(data?['showNsfw'] == true, data?['showAi'] == true);
        },
        onError: (_) {},
      );
    });
  }

  Future<void> setShowNsfw(bool value) async {
    _update(value, _showAi);
    await _persist({'showNsfw': value});
  }

  Future<void> setShowAi(bool value) async {
    _update(_showNsfw, value);
    await _persist({'showAi': value});
  }

  bool allows(Post post) {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me != null && post.userId == me) return true;
    if (post.isNsfw && !_showNsfw) return false;
    if (post.isAiGenerated && !_showAi) return false;
    return true;
  }

  void _update(bool showNsfw, bool showAi) {
    if (showNsfw == _showNsfw && showAi == _showAi) return;
    _showNsfw = showNsfw;
    _showAi = showAi;
    notifyListeners();
  }

  Future<void> _persist(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await appFirestore
        .collection('users')
        .doc(user.uid)
        .set(data, SetOptions(merge: true));
  }
}
