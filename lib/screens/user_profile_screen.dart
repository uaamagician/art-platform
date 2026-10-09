import 'package:flutter/material.dart';

import '../widgets/profile_body.dart';

/// Someone's public page. Falls back to the data stored on their posts when they
/// have no profile document yet.
class UserProfileScreen extends StatelessWidget {
  final String uid;
  final String fallbackName;
  final String fallbackPhoto;
  final String fallbackBio;

  const UserProfileScreen({
    super.key,
    required this.uid,
    this.fallbackName = '',
    this.fallbackPhoto = '',
    this.fallbackBio = '',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(fallbackName.isNotEmpty ? fallbackName : '創作者')),
      body: ProfileBody(
        uid: uid,
        fallbackName: fallbackName,
        fallbackPhoto: fallbackPhoto,
        fallbackBio: fallbackBio,
      ),
    );
  }
}
