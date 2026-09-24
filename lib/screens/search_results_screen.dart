import 'package:flutter/material.dart';

import '../services/post_service.dart';
import '../widgets/post_list_loader.dart';

class SearchResultsScreen extends StatelessWidget {
  final String query;

  const SearchResultsScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(query)),
      body: PostListLoader(
        loader: () => PostService().search(query),
        emptyText: '找不到符合「$query」的作品',
      ),
    );
  }
}
