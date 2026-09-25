import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/post.dart';
import '../theme/app_theme.dart';
import 'follow_button.dart';

/// Author row shown above a post's artwork: avatar, name, short bio, follow button.
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
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.vermilion.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: CircleAvatar(
              radius: 19,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: post.userPhotoUrl.isNotEmpty
                  ? CachedNetworkImageProvider(post.userPhotoUrl)
                  : null,
              child: post.userPhotoUrl.isEmpty
                  ? Text(
                      name[0],
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
          ),
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
          const SizedBox(width: 8),
          FollowButton(targetUid: post.userId),
        ],
      ),
    );
  }
}
