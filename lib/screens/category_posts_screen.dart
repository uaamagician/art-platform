import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../models/post.dart';
import '../services/firestore_service.dart';
import '../widgets/post_card.dart';
import 'post_detail_screen.dart';

class CategoryPostsScreen extends StatelessWidget {
  final String category;

  const CategoryPostsScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: StreamBuilder<QuerySnapshot>(
        stream: appFirestore
            .collection('posts')
            .where('category', isEqualTo: category)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snapshot.data!.docs
              .map((doc) => Post.fromFirestore(doc))
              .toList()
            ..sort((a, b) {
              final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
              final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
              return bTime.compareTo(aTime);
            });
          if (posts.isEmpty) {
            return const Center(child: Text('這個分類還沒有作品'));
          }
          return MasonryGridView.count(
            padding: const EdgeInsets.all(8),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return PostCard(
                post: post,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PostDetailScreen(post: post),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
