import 'package:flutter/material.dart';

import '../models/commission.dart';
import '../models/post.dart';
import '../models/user_profile.dart';
import '../screens/commission_detail_screen.dart';
import '../screens/follow_list_screen.dart';
import '../services/auth_service.dart';
import '../services/commission_service.dart';
import '../services/content_filter_service.dart';
import '../services/post_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../utils/level.dart';
import 'commission_card.dart';
import 'follow_button.dart';
import 'post_grid.dart';
import 'prompt_dialogs.dart';
import 'segment_tabs.dart';
import 'user_avatar.dart';

/// Profile header + stats + level + achievements + content tabs.
/// Used for the signed-in user's own tab and for anyone else's page.
class ProfileBody extends StatefulWidget {
  final String uid;
  final String fallbackName;
  final String fallbackPhoto;
  final String fallbackBio;

  const ProfileBody({
    super.key,
    required this.uid,
    this.fallbackName = '',
    this.fallbackPhoto = '',
    this.fallbackBio = '',
  });

  @override
  State<ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<ProfileBody> {
  final _profiles = ProfileService();
  final _posts = PostService();
  final _commissions = CommissionService();

  UserProfile? _profile;
  UserStats _stats = const UserStats();
  bool _headerLoaded = false;
  Object? _error;

  int _tab = 0;
  List<Post>? _myPosts;
  List<Post>? _bookmarks;
  List<Commission>? _myCommissions;

  bool get _isMe => AuthService().currentUser?.uid == widget.uid;

  List<String> get _tabLabels => _isMe ? ['作品', '收藏', '委託'] : ['作品'];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didUpdateWidget(ProfileBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid) {
      _myPosts = _bookmarks = null;
      _myCommissions = null;
      _headerLoaded = false;
      _refresh();
    }
  }

  Future<void> _refresh() async {
    try {
      final profile = await _profiles.fetchProfile(widget.uid);
      final stats = await _profiles.fetchStats(widget.uid, profile: profile);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _stats = stats;
        _headerLoaded = true;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _headerLoaded = true;
        _error = e;
      });
    }
    await _loadTab(_tab, force: true);
  }

  Future<void> _loadTab(int tab, {bool force = false}) async {
    try {
      switch (tab) {
        case 0:
          if (!force && _myPosts != null) return;
          final posts = await _posts.fetchByUser(widget.uid);
          if (mounted) setState(() => _myPosts = posts);
        case 1:
          if (!force && _bookmarks != null) return;
          final posts = await _posts.fetchBookmarked(widget.uid);
          if (mounted) setState(() => _bookmarks = posts);
        case 2:
          if (!force && _myCommissions != null) return;
          final list = await _commissions.fetchByUser(widget.uid);
          if (mounted) setState(() => _myCommissions = list);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (tab == 0) _myPosts ??= [];
        if (tab == 1) _bookmarks ??= [];
        if (tab == 2) _myCommissions ??= [];
      });
    }
  }

  String get _name {
    final fromProfile = _profile?.displayName ?? '';
    if (fromProfile.isNotEmpty) return fromProfile;
    if (widget.fallbackName.isNotEmpty) return widget.fallbackName;
    if (_isMe) return AuthService().currentUser?.displayName ?? '創作者';
    return '創作者';
  }

  String get _photo {
    final fromProfile = _profile?.photoUrl ?? '';
    if (fromProfile.isNotEmpty) return fromProfile;
    if (widget.fallbackPhoto.isNotEmpty) return widget.fallbackPhoto;
    if (_isMe) return AuthService().currentUser?.photoURL ?? '';
    return '';
  }

  String get _bio => _profile?.bio ?? widget.fallbackBio;

  Future<void> _editBio() async {
    final result = await showTextPrompt(
      context,
      title: '自我介紹',
      initialText: _bio,
      hint: '一句話讓大家認識你',
      maxLength: ProfileService.maxBioLength,
    );
    if (result == null || result == _bio || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await _profiles.updateBio(widget.uid, result);
      messenger.showSnackBar(const SnackBar(content: Text('已更新自我介紹')));
      await _refresh();
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('儲存失敗，請稍後再試')));
    }
  }

  void _openFollowList(bool followers) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FollowListScreen(uid: widget.uid, followers: followers),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_headerLoaded) return const Center(child: CircularProgressIndicator());

    final level = computeLevel(_stats);

    return RefreshIndicator(
      color: AppColors.vermilion,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (_error != null)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                '部分資料讀取失敗，下拉可重新整理',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
          _buildHeader(level),
          const SizedBox(height: 16),
          _buildStats(),
          const SizedBox(height: 16),
          _buildAchievements(),
          const SizedBox(height: 20),
          if (_tabLabels.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentTabs(
                labels: _tabLabels,
                selected: _tab,
                onChanged: (i) {
                  setState(() => _tab = i);
                  _loadTab(i);
                },
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('作品', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          const SizedBox(height: 8),
          _buildTabContent(),
        ],
      ),
    );
  }

  Widget _buildHeader(LevelInfo level) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          UserAvatar(photoUrl: _photo, name: _name, radius: 44, ring: true),
          const SizedBox(height: 14),
          Text(_name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.vermilion,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Lv.${level.level}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 110,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: level.progress,
                    minHeight: 6,
                    color: AppColors.vermilion,
                    backgroundColor: AppColors.tint,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_isMe)
            _buildMyBio()
          else if (_bio.isNotEmpty)
            Text(
              _bio,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF5C544C), height: 1.45),
            ),
          if (!_isMe) ...[
            const SizedBox(height: 14),
            FollowButton(targetUid: widget.uid),
          ],
          if (_isMe && AuthService().currentUser?.email != null) ...[
            const SizedBox(height: 10),
            Text(
              AuthService().currentUser!.email!,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMyBio() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 6, 6, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _bio.isEmpty ? '還沒有自我介紹，寫一句話讓大家認識你' : _bio,
              style: TextStyle(
                color: _bio.isEmpty ? AppColors.muted : AppColors.ink,
                height: 1.4,
              ),
            ),
          ),
          TextButton(onPressed: _editBio, child: const Text('編輯')),
        ],
      ),
    );
  }

  Widget _buildStats() {
    Widget cell(String label, int value, VoidCallback? onTap) => Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  Text('$value',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                ],
              ),
            ),
          ),
        );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          cell('作品', _stats.posts, null),
          cell('粉絲', _stats.followers, () => _openFollowList(true)),
          cell('追蹤中', _stats.following, () => _openFollowList(false)),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    final list = achievementsFor(_stats);
    final unlocked = list.where((a) => a.unlocked).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '成就  $unlocked / ${list.length}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final a in list)
                    Container(
                      width: width,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: a.unlocked
                            ? Theme.of(context).colorScheme.primaryContainer
                            : AppColors.tint,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Opacity(
                        opacity: a.unlocked ? 1 : 0.5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.title,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(a.description,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF5C544C))),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_tab) {
      case 0:
        return _postsSection(_myPosts, '還沒有作品');
      case 1:
        return _postsSection(_bookmarks, '還沒有收藏的作品');
      default:
        final list = _myCommissions;
        if (list == null) return _loading();
        if (list.isEmpty) return _empty('還沒有發布過委託');
        return Column(
          children: [
            for (final c in list)
              CommissionCard(
                commission: c,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CommissionDetailScreen(commissionId: c.id),
                    ),
                  );
                  _loadTab(2, force: true);
                },
              ),
          ],
        );
    }
  }

  Widget _postsSection(List<Post>? posts, String emptyText) {
    if (posts == null) return _loading();
    return ListenableBuilder(
      listenable: ContentFilterService.instance,
      builder: (context, _) {
        final visible = posts.where(ContentFilterService.instance.allows).toList();
        if (visible.isEmpty) {
          final hidden = posts.length - visible.length;
          return _empty(hidden > 0 ? '$hidden 件作品因內容篩選被隱藏' : emptyText);
        }
        return PostMasonry(posts: visible, onChanged: _refresh);
      },
    );
  }

  Widget _loading() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );

  Widget _empty(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(text, style: const TextStyle(color: AppColors.muted)),
        ),
      );
}
