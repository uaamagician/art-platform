import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../models/post.dart';
import '../services/firestore_service.dart';
import '../widgets/post_card.dart';
import 'post_detail_screen.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Post> _filterPosts(List<Post> posts) {
    if (_searchQuery.isEmpty) return posts;
    final query = _searchQuery.toLowerCase();
    return posts.where((post) {
      return post.title.toLowerCase().contains(query) ||
          post.userName.toLowerCase().contains(query) ||
          post.tags.any((tag) => tag.toLowerCase().contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('藝術投稿平台'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: '搜尋標題、作者、#標籤',
                    isDense: true,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: '熱門'),
                  Tab(text: '最新'),
                  Tab(text: '追蹤中'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostStream(
            appFirestore
                .collection('posts')
                .orderBy('likesCount', descending: true),
          ),
          _buildPostStream(
            appFirestore
                .collection('posts')
                .orderBy('createdAt', descending: true),
          ),
          const Center(child: Text('追蹤功能尚未推出')),
        ],
      ),
    );
  }

  Widget _buildPostStream(Query query) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('讀取失敗：${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final posts = _filterPosts(
          snapshot.data!.docs.map((doc) => Post.fromFirestore(doc)).toList(),
        );
        if (posts.isEmpty) {
          return const Center(child: Text('目前還沒有作品'));
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
    );
  }
}
