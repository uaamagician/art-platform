import 'firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _initialized = false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      if (kIsWeb) {
        await _googleSignIn.initialize(
          clientId: '把你的WebClientID貼在這裡',
        );
      } else {
        await _googleSignIn.initialize();
      }
      _initialized = true;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      await _ensureInitialized();
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        await _createUserProfileIfNotExists(user);
      }
      return user;
    } catch (e) {
      print('登入失敗: $e');
      return null;
    }
  }

  Future<void> _createUserProfileIfNotExists(User user) async {
    final docRef = appFirestore.collection('users').doc(user.uid);
    final doc = await docRef.get();
    if (!doc.exists) {
      await docRef.set({
        'displayName': user.displayName ?? '',
        'photoURL': user.photoURL ?? '',
        'email': user.email ?? '',
        'bio': '',
        'createdAt': FieldValue.serverTimestamp(),
        'postCount': 0,
      });
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
