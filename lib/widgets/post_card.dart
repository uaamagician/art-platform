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
            Stack(
              children: [
                _buildCover(),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Row(
                    children: [
                      if (post.isNsfw) _badge('成人', Colors.red.shade400),
                      if (post.isNsfw && post.isAiGenerated) const SizedBox(width: 4),
                      if (post.isAiGenerated) _badge('AI', Colors.blueGrey),
                    ],
                  ),
                ),
                if (post.imageUrls.length > 1)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _badge('${post.imageUrls.length} 張', Colors.black54),
                  ),
              ],
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
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colorScheme.onPrimaryContainer,
                                ),
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
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11),
                          ),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '讚 ${post.likesCount}  留言 ${post.commentsCount}',
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

  Widget _buildCover() {
    final ratio = post.aspectRatio;
    final image = CachedNetworkImage(
      imageUrl: post.imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (context, url) => Container(
        color: Colors.grey.shade100,
        height: ratio == null ? 160 : null,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey.shade100,
        height: ratio == null ? 160 : null,
        alignment: Alignment.center,
        child: const Text('圖片載入失敗', style: TextStyle(color: Colors.grey)),
      ),
    );
    if (ratio == null) return image;
    return AspectRatio(aspectRatio: ratio.clamp(0.6, 1.6).toDouble(), child: image);
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }
}
