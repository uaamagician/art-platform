import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/post.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import 'author_header.dart';

/// Home feed card: author row on top, the artwork framed like a gallery print, then the details.
class FeedPostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;

  const FeedPostCard({super.key, required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 7, 14, 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthorHeader(
            post: post,
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildArtwork(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: _buildDetails(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtwork() {
    final ratio = (post.aspectRatio ?? 1.0).clamp(0.75, 1.4).toDouble();
    final image = CachedNetworkImage(
      imageUrl: post.imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (context, url) => Container(
        color: AppColors.tint,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppColors.tint,
        alignment: Alignment.center,
        child: const Text('圖片載入失敗', style: TextStyle(color: AppColors.muted)),
      ),
    );

    return Stack(
      children: [
        AspectRatio(aspectRatio: ratio, child: image),
        Positioned(
          top: 10,
          left: 10,
          child: Row(
            children: [
              if (post.isNsfw) _pill('成人', Colors.red.shade400),
              if (post.isNsfw && post.isAiGenerated) const SizedBox(width: 6),
              if (post.isAiGenerated) _pill('AI', Colors.blueGrey.shade600),
            ],
          ),
        ),
        if (post.imageUrls.length > 1)
          Positioned(
            top: 10,
            right: 10,
            child: _pill('${post.imageUrls.length} 張', Colors.black.withValues(alpha: 0.5)),
          ),
        if (post.category.isNotEmpty)
          Positioned(
            left: 10,
            bottom: 10,
            child: _pill(post.category, Colors.black.withValues(alpha: 0.5)),
          ),
      ],
    );
  }

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          post.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.3),
        ),
        if (post.description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            post.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, height: 1.45, color: Color(0xFF5C544C)),
          ),
        ],
        if (post.tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            post.tags.map((t) => '#$t').join('  '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.vermilion,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Text('讚 ${post.likesCount}', style: _footerStyle),
            const SizedBox(width: 14),
            Text('留言 ${post.commentsCount}', style: _footerStyle),
            const Spacer(),
            Text(timeAgo(post.createdAt), style: _footerStyle),
          ],
        ),
      ],
    );
  }

  static const _footerStyle = TextStyle(fontSize: 12.5, color: AppColors.muted);

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
