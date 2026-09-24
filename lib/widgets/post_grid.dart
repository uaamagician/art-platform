import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../models/post.dart';
import '../screens/post_detail_screen.dart';
import '../services/content_filter_service.dart';
import 'post_card.dart';

/// Staggered grid of posts with pull-to-refresh and the global adult/AI content filter applied.
class PostGrid extends StatelessWidget {
  final List<Post> posts;
  final Future<void> Function() onRefresh;
  final String emptyText;
  final ScrollController? controller;

  const PostGrid({
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
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                )
              : MasonryGridView.count(
                  controller: controller,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(8),
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final post = visible[index];
                    return PostCard(
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
