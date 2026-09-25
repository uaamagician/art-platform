import 'package:flutter/material.dart';

import '../models/post.dart';
import '../screens/post_detail_screen.dart';
import '../services/content_filter_service.dart';
import '../theme/app_theme.dart';
import 'feed_post_card.dart';

/// Single-column feed of [FeedPostCard]s with pull-to-refresh and the content filter applied.
class PostFeedList extends StatelessWidget {
  final List<Post> posts;
  final Future<void> Function() onRefresh;
  final String emptyText;
  final ScrollController? controller;

  const PostFeedList({
    super.key,
    required this.posts,
    required this.onRefresh,
    this.emptyText = '目前還沒有作品',
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ContentFilterService.instance,
      builder: (context, _) {
        final filter = ContentFilterService.instance;
        final visible = posts.where(filter.allows).toList();
        final hidden = posts.length - visible.length;

        return RefreshIndicator(
          color: AppColors.vermilion,
          onRefresh: onRefresh,
          child: visible.isEmpty
              ? ListView(
                  controller: controller,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 160),
                    Center(
                      child: Text(
                        hidden > 0 ? '$hidden 件作品因內容篩選被隱藏' : emptyText,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  controller: controller,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 6, bottom: 24),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final post = visible[index];
                    return FeedPostCard(
                      post: post,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PostDetailScreen(post: post),
                          ),
                        );
                        if (context.mounted) await onRefresh();
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}
