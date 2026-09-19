import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/post.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;

  const PostCard({super.key, required this.post, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedNetworkImage(
              imageUrl: post.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey.shade100,
                height: 160,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade100,
                height: 160,
                alignment: Alignment.center,
                child: const Text('圖片載入失敗', style: TextStyle(color: Colors.grey)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: colorScheme.primaryContainer,
                        backgroundImage: post.userPhotoUrl.isNotEmpty
                            ? CachedNetworkImageProvider(post.userPhotoUrl)
                            : null,
                        child: post.userPhotoUrl.isEmpty
                            ? Text(
                                post.userName.isNotEmpty ? post.userName[0] : '?',
                                style: TextStyle(fontSize: 10, color: colorScheme.onPrimaryContainer),
                              )
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          post.userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Flexible(
                        child: Chip(
                          label: Text(
                            post.category,
                            style: const TextStyle(fontSize: 11),
                          ),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '讚 ${post.likesCount}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
