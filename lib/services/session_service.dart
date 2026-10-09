import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'profile_service.dart';

/// Runs once per sign-in: makes sure the signed-in user has a public profile.
class SessionService {
  SessionService._();

  static StreamSubscription<User?>? _sub;

  static void init() {
    _sub ??= FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) ProfileService().ensureProfile(user);
    });
  }
}
