import 'package:flutter/material.dart';

import '../services/post_service.dart';
import '../widgets/post_list_loader.dart';

class CategoryPostsScreen extends StatelessWidget {
  final String category;

  const CategoryPostsScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: PostListLoader(
        loader: () => PostService().fetchByCategory(category),
        emptyText: '這個分類還沒有作品',
      ),
    );
  }
}
