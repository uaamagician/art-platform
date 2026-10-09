import 'package:flutter/material.dart';

import '../models/post.dart';
import '../models/user_profile.dart';
import '../services/content_filter_service.dart';
import '../services/post_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/follow_button.dart';
import '../widgets/post_grid.dart';
import '../widgets/user_avatar.dart';
import 'user_profile_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;

  const SearchResultsScreen({super.key, required this.query});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  List<Post>? _posts;
  List<UserProfile> _creators = const [];
  Object? _error;

  bool get _isHashtag => RegExp(r'^[#＃]').hasMatch(widget.query.trim());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        PostService().search(widget.query),
        if (!_isHashtag) ProfileService().searchByName(widget.query) else Future.value(<UserProfile>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _posts = results[0] as List<Post>;
        _creators = results[1] as List<UserProfile>;
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
    return Scaffold(
      appBar: AppBar(title: Text(widget.query)),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
    final posts = _posts;
    if (posts == null) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      color: AppColors.vermilion,
      onRefresh: _load,
      child: ListenableBuilder(
        listenable: ContentFilterService.instance,
        builder: (context, _) {
          final visible = posts.where(ContentFilterService.instance.allows).toList();
          final hidden = posts.length - visible.length;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              if (_creators.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Text('創作者', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
                for (final p in _creators)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: UserAvatar(photoUrl: p.photoUrl, name: p.nameOrDefault, radius: 22),
                    title: Text(p.nameOrDefault, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: p.bio.isEmpty
                        ? null
                        : Text(p.bio, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: FollowButton(targetUid: p.uid),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => UserProfileScreen(
                          uid: p.uid,
                          fallbackName: p.displayName,
                          fallbackPhoto: p.photoUrl,
                          fallbackBio: p.bio,
                        ),
                      ),
                    ),
                  ),
                const Divider(height: 24, color: AppColors.line),
              ],
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Text('作品', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Center(
                    child: Text(
                      hidden > 0
                          ? '$hidden 件作品因內容篩選被隱藏'
                          : '找不到符合「${widget.query}」的作品',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ),
                )
              else
                PostMasonry(posts: visible, onChanged: _load),
            ],
          );
        },
      ),
    );
  }
}
