import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'category_posts_screen.dart';
import 'search_results_screen.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  static const _tileColors = [
    Color(0xFFF6E3DC),
    Color(0xFFE2ECE4),
    Color(0xFFE3E8F3),
    Color(0xFFF3EBD5),
    Color(0xFFEBE1F0),
  ];

  void _search(BuildContext context, String query) {
    if (query.trim().isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => SearchResultsScreen(query: query.trim())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('探索')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: '搜尋標題、作者、#標籤',
                isDense: true,
              ),
              onSubmitted: (value) => _search(context, value),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: appFirestore.collection('categories').orderBy('order').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('尚未設定分類'));
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.35,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final name = (docs[index].data() as Map<String, dynamic>)['name'] as String;
                    final color = _tileColors[index % _tileColors.length];
                    return Material(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CategoryPostsScreen(category: name),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -6,
                              bottom: -18,
                              child: Text(
                                name.isNotEmpty ? name[0] : '',
                                style: TextStyle(
                                  fontSize: 86,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.ink.withValues(alpha: 0.07),
                                  height: 1,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Align(
                                alignment: Alignment.bottomLeft,
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
