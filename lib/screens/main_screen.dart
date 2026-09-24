import 'package:flutter/material.dart';

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
  // Pages in swipe order. Home is two adjacent pages (following / recommended)
  // so swiping left/right on the feed switches between them.
  static const _followingPage = 0;
  static const _recommendedPage = 1;
  static const _explorePage = 2;
  static const _groupPage = 3;
  static const _profilePage = 4;

  static const _labels = ['主頁', '探索', '發布', '群組', '個人'];

  final _pageController = PageController(initialPage: _recommendedPage);
  final _followingKey = GlobalKey<HomeFeedScreenState>();
  final _recommendedKey = GlobalKey<HomeFeedScreenState>();

  int _page = _recommendedPage;
  int _lastHomePage = _recommendedPage;

  late final List<Widget> _pages = [
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
    const _KeepAlive(child: ExploreScreen()),
    const _KeepAlive(child: GroupScreen()),
    const _KeepAlive(child: ProfileScreen()),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int get _navIndex => switch (_page) {
        _followingPage || _recommendedPage => 0,
        _explorePage => 1,
        _groupPage => 3,
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
        if (_page <= _recommendedPage) {
          (_page == _followingPage ? _followingKey : _recommendedKey)
              .currentState
              ?.scrollToTop();
        } else {
          _goToPage(_lastHomePage);
        }
      case 1:
        _goToPage(_explorePage);
      case 2:
        _openPublish();
      case 3:
        _goToPage(_groupPage);
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (page) => setState(() {
          _page = page;
          if (page <= _recommendedPage) _lastHomePage = page;
        }),
        children: _pages,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: List.generate(_labels.length, (index) {
              final selected = index == _navIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => _onNavTap(index),
                  child: Center(
                    child: Text(
                      _labels[index],
                      style: TextStyle(
                        fontSize: index == 2 ? 16 : 13,
                        fontWeight: (selected || index == 2) ? FontWeight.bold : FontWeight.normal,
                        color: (selected || index == 2)
                            ? colorScheme.primary
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
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
