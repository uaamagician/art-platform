import 'package:flutter/material.dart';

import '../services/category_service.dart';
import '../services/post_service.dart';
import '../theme/app_theme.dart';
import '../widgets/commission_list.dart';
import '../widgets/consult_list.dart';
import '../widgets/creator_directory.dart';
import '../widgets/segment_tabs.dart';
import 'category_posts_screen.dart';
import 'search_results_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  static const _tabs = ['分類', '創作者', '委託', '改圖'];

  final _search = TextEditingController();
  final _visited = <int>{0};
  late final Future<List<String>> _trending = PostService().trendingTags();

  int _tab = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openSearch(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => SearchResultsScreen(query: q)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('探索')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: '搜尋標題、創作者、#標籤',
                isDense: true,
              ),
              onSubmitted: _openSearch,
            ),
          ),
          FutureBuilder<List<String>>(
            future: _trending,
            builder: (context, snapshot) {
              final tags = snapshot.data ?? const <String>[];
              if (tags.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: tags.length + 1,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return const Center(
                        child: Text('熱門',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                      );
                    }
                    final tag = tags[i - 1];
                    return ActionChip(
                      label: Text('#$tag'),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _openSearch('#$tag'),
                    );
                  },
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: SegmentTabs(
              labels: _tabs,
              selected: _tab,
              onChanged: (i) => setState(() {
                _tab = i;
                _visited.add(i);
              }),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                _visited.contains(0) ? const _CategoryGrid() : const SizedBox.shrink(),
                _visited.contains(1) ? const CreatorDirectory() : const SizedBox.shrink(),
                _visited.contains(2) ? const CommissionList() : const SizedBox.shrink(),
                _visited.contains(3) ? const ConsultList() : const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatefulWidget {
  const _CategoryGrid();

  @override
  State<_CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<_CategoryGrid> {
  static const _tileColors = [
    Color(0xFFF6E3DC),
    Color(0xFFE2ECE4),
    Color(0xFFE3E8F3),
    Color(0xFFF3EBD5),
    Color(0xFFEBE1F0),
  ];

  late Future<List<String>> _future = CategoryService().names();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('讀取失敗，請確認網路連線'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => setState(() {
                    _future = CategoryService().names();
                  }),
                  child: const Text('重試'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final names = snapshot.data!;
        if (names.isEmpty) return const Center(child: Text('尚未設定分類'));

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
          ),
          itemCount: names.length,
          itemBuilder: (context, index) {
            final name = names[index];
            return Material(
              color: _tileColors[index % _tileColors.length],
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => CategoryPostsScreen(category: name)),
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
    );
  }
}
