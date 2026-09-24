import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import '../services/auth_service.dart';

/// Returns true if the user is (or becomes) signed in; shows the login page otherwise.
Future<bool> ensureSignedIn(BuildContext context) async {
  if (AuthService().currentUser != null) return true;
  final signedIn = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (context) => const LoginScreen()),
  );
  return signedIn == true;
}
