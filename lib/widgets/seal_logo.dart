import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Red "seal" mark with the character 藝, used as the app's logo.
class SealLogo extends StatelessWidget {
  final double size;

  const SealLogo({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.vermilion,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Text(
        '藝',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.62,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}
