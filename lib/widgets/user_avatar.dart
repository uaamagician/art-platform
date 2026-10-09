import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Round avatar with the first letter of the name as a fallback; optional vermilion ring.
class UserAvatar extends StatelessWidget {
  final String photoUrl;
  final String name;
  final double radius;
  final bool ring;

  const UserAvatar({
    super.key,
    required this.photoUrl,
    required this.name,
    this.radius = 20,
    this.ring = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      backgroundImage:
          photoUrl.isNotEmpty ? CachedNetworkImageProvider(photoUrl) : null,
      child: photoUrl.isEmpty
          ? Text(
              name.isNotEmpty ? name.characters.first : '?',
              style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.8,
              ),
            )
          : null,
    );
    if (!ring) return avatar;
    return Container(
      padding: EdgeInsets.all(radius > 30 ? 3 : 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.vermilion.withValues(alpha: 0.4),
          width: radius > 30 ? 2 : 1.5,
        ),
      ),
      child: avatar,
    );
  }
}
