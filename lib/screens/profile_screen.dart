import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/content_filter_switches.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      initialData: AuthService().currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: const Text('個人檔案'),
            actions: [
              if (user != null)
                TextButton(
                  onPressed: () => AuthService().signOut(),
                  child: const Text('登出'),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              if (user == null) _buildGuest(context) else _buildProfile(context, user),
              const SizedBox(height: 28),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text('內容設定', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              const Card(child: ContentFilterSwitches()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGuest(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          const Text(
            '登入後即可管理你的作品與個人資訊',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            ),
            child: const Text('使用 Google 登入'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile(BuildContext context, User user) {
    final name = user.displayName ?? '';
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.vermilion.withValues(alpha: 0.4), width: 2),
          ),
          child: CircleAvatar(
            radius: 44,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            backgroundImage:
                user.photoURL != null ? CachedNetworkImageProvider(user.photoURL!) : null,
            child: user.photoURL == null
                ? Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(fontSize: 28))
                : null,
          ),
        ),
        const SizedBox(height: 14),
        Text(name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(user.email ?? '', style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 20),
        _BioCard(uid: user.uid),
      ],
    );
  }
}

class _BioCard extends StatelessWidget {
  final String uid;

  const _BioCard({required this.uid});

  Future<void> _edit(BuildContext context, String current) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('自我介紹'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: ProfileService.maxBioLength,
          decoration: const InputDecoration(hintText: '一句話讓大家認識你'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('儲存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result == current) return;

    try {
      await ProfileService().updateBio(uid, result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已更新自我介紹')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('儲存失敗，請稍後再試')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: ProfileService().bioStream(uid),
      builder: (context, snapshot) {
        final bio = snapshot.data ?? '';
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  bio.isEmpty ? '還沒有自我介紹，寫一句話讓大家認識你' : bio,
                  style: TextStyle(color: bio.isEmpty ? AppColors.muted : AppColors.ink, height: 1.4),
                ),
              ),
              TextButton(onPressed: () => _edit(context, bio), child: const Text('編輯')),
            ],
          ),
        );
      },
    );
  }
}
