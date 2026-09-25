import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/auth_guard.dart';
import 'explore_screen.dart';
import 'group_screen.dart';
import 'home_feed_screen.dart';
import 'profile_screen.dart';
import 'upload_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Pages in swipe order (same left-to-right order as the bottom nav, Publish is an action).
  // Home sits in the middle as two adjacent pages (following / recommended)
  // so swiping left/right on the feed switches between them.
  static const _explorePage = 0;
  static const _groupPage = 1;
  static const _followingPage = 2;
  static const _recommendedPage = 3;
  static const _profilePage = 4;

  static const _publishNavIndex = 3;
  static const _labels = ['探索', '群組', '主頁', '發布', '個人'];

  final _pageController = PageController(initialPage: _recommendedPage);
  final _followingKey = GlobalKey<HomeFeedScreenState>();
  final _recommendedKey = GlobalKey<HomeFeedScreenState>();

  int _page = _recommendedPage;
  int _lastHomePage = _recommendedPage;

  late final List<Widget> _pages = [
    const _KeepAlive(child: ExploreScreen()),
    const _KeepAlive(child: GroupScreen()),
    _KeepAlive(
      child: HomeFeedScreen(
        key: _followingKey,
        mode: FeedMode.following,
        onSwitchMode: _switchFeed,
      ),
    ),
    _KeepAlive(
      child: HomeFeedScreen(
        key: _recommendedKey,
        mode: FeedMode.recommended,
        onSwitchMode: _switchFeed,
      ),
    ),
    const _KeepAlive(child: ProfileScreen()),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _onHome => _page == _followingPage || _page == _recommendedPage;

  int get _navIndex => switch (_page) {
        _explorePage => 0,
        _groupPage => 1,
        _followingPage || _recommendedPage => 2,
        _ => 4,
      };

  void _switchFeed(FeedMode mode) {
    _goToPage(mode == FeedMode.following ? _followingPage : _recommendedPage);
  }

  void _goToPage(int page) {
    if (!_pageController.hasClients || page == _page) return;
    if ((page - _page).abs() == 1) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _pageController.jumpToPage(page);
    }
  }

  void _onNavTap(int navIndex) {
    switch (navIndex) {
      case 0:
        _goToPage(_explorePage);
      case 1:
        _goToPage(_groupPage);
      case 2:
        if (_onHome) {
          (_page == _followingPage ? _followingKey : _recommendedKey)
              .currentState
              ?.scrollToTop();
        } else {
          _goToPage(_lastHomePage);
        }
      case _publishNavIndex:
        _openPublish();
      case 4:
        _goToPage(_profilePage);
    }
  }

  Future<void> _openPublish() async {
    if (!await ensureSignedIn(context)) return;
    if (!mounted) return;
    final published = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const UploadScreen()),
    );
    if (published != true || !mounted) return;

    _followingKey.currentState?.refresh(silent: true);
    _recommendedKey.currentState?.refresh(silent: true);
    _goToPage(_recommendedPage);
    _recommendedKey.currentState?.scrollToTop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('發布成功')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (page) => setState(() {
          _page = page;
          if (page == _followingPage || page == _recommendedPage) {
            _lastHomePage = page;
          }
        }),
        children: _pages,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 64,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: Row(
            children: List.generate(_labels.length, (index) {
              final selected = index == _navIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => _onNavTap(index),
                  child: Center(
                    child: index == _publishNavIndex
                        ? _publishPill()
                        : _navLabel(_labels[index], selected),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _publishPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.vermilion,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.vermilion.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Text(
        '發布',
        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _navLabel(String label, bool selected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.ink : AppColors.muted,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? AppColors.vermilion : Colors.transparent,
          ),
        ),
      ],
    );
  }
}

class _KeepAlive extends StatefulWidget {
  final Widget child;

  const _KeepAlive({required this.child});

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
