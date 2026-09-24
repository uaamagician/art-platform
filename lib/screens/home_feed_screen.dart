import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/post_service.dart';
import '../widgets/auth_guard.dart';
import '../widgets/content_filter_sheet.dart';
import '../widgets/post_grid.dart';

enum FeedMode { following, recommended }

class HomeFeedScreen extends StatefulWidget {
  final FeedMode mode;
  final ValueChanged<FeedMode> onSwitchMode;

  const HomeFeedScreen({
    super.key,
    required this.mode,
    required this.onSwitchMode,
  });

  @override
  State<HomeFeedScreen> createState() => HomeFeedScreenState();
}

class HomeFeedScreenState extends State<HomeFeedScreen> {
  final _service = PostService();
  final _scrollController = ScrollController();
  StreamSubscription<User?>? _authSub;

  List<Post>? _posts;
  int _followingCount = 0;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((_) => refresh());
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> refresh({bool silent = false}) async {
    if (!silent && mounted && _posts == null) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final user = FirebaseAuth.instance.currentUser;
      List<Post> posts;
      var followingCount = 0;
      if (widget.mode == FeedMode.following) {
        if (user == null) {
          posts = [];
        } else {
          final feed = await _service.fetchFollowing(user.uid);
          posts = feed.posts;
          followingCount = feed.followingCount;
        }
      } else {
        posts = await _service.fetchRecommended(user?.uid);
      }
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _followingCount = followingCount;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_posts == null) _error = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildSwitcher(),
        actions: [
          TextButton(
            onPressed: () => showContentFilterSheet(context),
            child: const Text('篩選'),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildSwitcher() {
    final colorScheme = Theme.of(context).colorScheme;

    Widget tab(String label, FeedMode mode) {
      final selected = widget.mode == mode;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onSwitchMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                width: 2,
                color: selected ? colorScheme.primary : Colors.transparent,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 17,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? colorScheme.onSurface : Colors.grey.shade500,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        tab('追蹤中', FeedMode.following),
        const SizedBox(width: 24),
        tab('推薦', FeedMode.recommended),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null && _posts == null) {
      return _MessageView(
        text: '讀取失敗，請確認網路連線',
        actionLabel: '重試',
        onAction: refresh,
      );
    }

    if (widget.mode == FeedMode.following) {
      if (FirebaseAuth.instance.currentUser == null) {
        return _MessageView(
          text: '登入後就能看到你追蹤的創作者的最新作品',
          actionLabel: '登入',
          onAction: () => ensureSignedIn(context),
        );
      }
      if (_followingCount == 0) {
        return _MessageView(
          text: '還沒有追蹤任何創作者\n到「推薦」找找喜歡的作品吧',
          actionLabel: '去看推薦',
          onAction: () => widget.onSwitchMode(FeedMode.recommended),
        );
      }
    }

    return PostGrid(
      posts: _posts ?? const [],
      controller: _scrollController,
      onRefresh: () => refresh(silent: true),
      emptyText: widget.mode == FeedMode.following
          ? '追蹤的創作者還沒有新作品'
          : '目前還沒有作品',
    );
  }
}

class _MessageView extends StatelessWidget {
  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  const _MessageView({
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, height: 1.5),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
