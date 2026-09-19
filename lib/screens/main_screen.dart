import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'categories_screen.dart';
import 'classroom_screen.dart';
import 'home_feed_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'upload_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const _pages = [
    HomeFeedScreen(),
    CategoriesScreen(),
    ClassroomScreen(),
    ProfileScreen(),
  ];

  Future<void> _openUpload() async {
    if (AuthService().currentUser == null) {
      final loggedIn = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      if (loggedIn != true || !mounted) return;
    }
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const UploadScreen()),
    );
  }

  void _onNavTap(int index) {
    if (index == 2) {
      _openUpload();
      return;
    }
    // Classroom and Profile shift left by one since Upload (index 2) isn't a page.
    final pageIndex = index < 2 ? index : index - 1;
    setState(() => _selectedIndex = pageIndex);
  }

  static const _labels = ['主頁', '分類', '上傳', '教室', '個人'];

  @override
  Widget build(BuildContext context) {
    final navIndex = _selectedIndex < 2 ? _selectedIndex : _selectedIndex + 1;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: List.generate(_labels.length, (index) {
              final selected = index == navIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => _onNavTap(index),
                  child: Center(
                    child: Text(
                      _labels[index],
                      style: TextStyle(
                        fontSize: index == 2 ? 15 : 13,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        color: selected ? colorScheme.primary : Colors.grey.shade600,
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
