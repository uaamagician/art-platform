import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../screens/user_profile_screen.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import 'follow_button.dart';
import 'user_avatar.dart';

/// 創作者名錄: creators ranked by how many works they have published.
class CreatorDirectory extends StatefulWidget {
  const CreatorDirectory({super.key});

  @override
  State<CreatorDirectory> createState() => _CreatorDirectoryState();
}

class _CreatorDirectoryState extends State<CreatorDirectory> {
  List<UserProfile>? _creators;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await ProfileService().topCreators();
      if (!mounted) return;
      setState(() {
        _creators = list;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_creators == null) _error = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _creators == null) {
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
    final creators = _creators;
    if (creators == null) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      color: AppColors.vermilion,
      onRefresh: _load,
      child: creators.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(child: Text('還沒有創作者', style: TextStyle(color: AppColors.muted))),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
              itemCount: creators.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 76, color: AppColors.line),
              itemBuilder: (context, index) {
                final p = creators[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: UserAvatar(photoUrl: p.photoUrl, name: p.nameOrDefault, radius: 24),
                  title: Text(p.nameOrDefault, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    p.bio.isNotEmpty ? p.bio : '${p.postCount} 件作品',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                );
              },
            ),
    );
  }
}
