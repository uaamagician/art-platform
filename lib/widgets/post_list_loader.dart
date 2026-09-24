import 'package:flutter/material.dart';

import '../models/post.dart';
import 'post_grid.dart';

/// Loads a list of posts once, then shows it in a [PostGrid] with pull-to-refresh.
class PostListLoader extends StatefulWidget {
  final Future<List<Post>> Function() loader;
  final String emptyText;

  const PostListLoader({
    super.key,
    required this.loader,
    this.emptyText = '目前還沒有作品',
  });

  @override
  State<PostListLoader> createState() => _PostListLoaderState();
}

class _PostListLoaderState extends State<PostListLoader> {
  List<Post>? _posts;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final posts = await widget.loader();
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_posts == null) _error = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _posts == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('讀取失敗，請確認網路連線'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() => _error = null);
                _load();
              },
              child: const Text('重試'),
            ),
          ],
        ),
      );
    }
    if (_posts == null) return const Center(child: CircularProgressIndicator());
    return PostGrid(posts: _posts!, onRefresh: _load, emptyText: widget.emptyText);
  }
}
