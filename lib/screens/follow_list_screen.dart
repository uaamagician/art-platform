import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/follow_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/follow_button.dart';
import '../widgets/user_avatar.dart';
import 'user_profile_screen.dart';

/// Followers (粉絲) or following (追蹤中) of one user.
class FollowListScreen extends StatefulWidget {
  final String uid;
  final bool followers;

  const FollowListScreen({super.key, required this.uid, required this.followers});

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  late Future<List<(String, UserProfile?)>> _future = _load();

  Future<List<(String, UserProfile?)>> _load() async {
    final service = FollowService();
    final ids = widget.followers
        ? await service.followerIds(widget.uid)
        : await service.followingIds(widget.uid);
    final profiles = await ProfileService().fetchProfiles(ids);
    return [for (final id in ids) (id, profiles[id])];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.followers ? '粉絲' : '追蹤中')),
      body: FutureBuilder<List<(String, UserProfile?)>>(
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
                      _future = _load();
                    }),
                    child: const Text('重試'),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final rows = snapshot.data!;
          if (rows.isEmpty) {
            return Center(
              child: Text(
                widget.followers ? '還沒有粉絲' : '還沒有追蹤任何人',
                style: const TextStyle(color: AppColors.muted),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: rows.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, indent: 76, color: AppColors.line),
            itemBuilder: (context, index) {
              final (uid, profile) = rows[index];
              final name = profile?.nameOrDefault ?? '創作者';
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: UserAvatar(photoUrl: profile?.photoUrl ?? '', name: name, radius: 24),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: (profile?.bio ?? '').isEmpty
                    ? null
                    : Text(profile!.bio, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: FollowButton(targetUid: uid),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => UserProfileScreen(
                      uid: uid,
                      fallbackName: name,
                      fallbackPhoto: profile?.photoUrl ?? '',
                      fallbackBio: profile?.bio ?? '',
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
