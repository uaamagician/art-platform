import 'package:flutter/material.dart';

import '../models/post.dart';
import '../screens/user_profile_screen.dart';
import '../theme/app_theme.dart';
import 'follow_button.dart';
import 'user_avatar.dart';

/// Author row shown above a post's artwork: avatar, name, short bio, follow button.
/// Tapping the avatar or name opens the author's page.
class AuthorHeader extends StatelessWidget {
  final Post post;
  final EdgeInsetsGeometry padding;

  const AuthorHeader({
    super.key,
    required this.post,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final name = post.userName.isNotEmpty ? post.userName : '創作者';

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: post.userId.isEmpty
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => UserProfileScreen(
                            uid: post.userId,
                            fallbackName: post.userName,
                            fallbackPhoto: post.userPhotoUrl,
                            fallbackBio: post.userBio,
                          ),
                        ),
                      ),
              child: Row(
                children: [
                  UserAvatar(photoUrl: post.userPhotoUrl, name: name, radius: 19, ring: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        if (post.userBio.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            post.userBio,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          FollowButton(targetUid: post.userId),
        ],
      ),
    );
  }
}
