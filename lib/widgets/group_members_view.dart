import 'package:flutter/material.dart';

import '../models/group.dart';
import '../models/user_profile.dart';
import '../screens/user_profile_screen.dart';
import '../services/group_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import 'user_avatar.dart';

/// Member list with the owner's controls (remove members, disband) and leave for everyone else.
class GroupMembersView extends StatefulWidget {
  final Group group;
  final String uid;

  /// Called after the user leaves or the group is disbanded.
  final VoidCallback onGone;

  const GroupMembersView({
    super.key,
    required this.group,
    required this.uid,
    required this.onGone,
  });

  @override
  State<GroupMembersView> createState() => _GroupMembersViewState();
}

class _GroupMembersViewState extends State<GroupMembersView> {
  final _service = GroupService();

  late Future<Map<String, UserProfile>> _profiles =
      ProfileService().fetchProfiles(widget.group.memberIds);
  late String _memberKey = widget.group.memberIds.join(',');

  bool get _isOwner => widget.group.ownerId == widget.uid;

  @override
  void didUpdateWidget(GroupMembersView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final key = widget.group.memberIds.join(',');
    if (key != _memberKey) {
      _memberKey = key;
      _profiles = ProfileService().fetchProfiles(widget.group.memberIds);
    }
  }

  Future<void> _confirm(String title, String body, Future<void> Function() action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('確定')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('操作失敗，請稍後再試')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        if (group.description.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.tint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(group.description, style: const TextStyle(height: 1.5)),
          ),
        Text('成員 ${group.memberCount}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        FutureBuilder<Map<String, UserProfile>>(
          future: _profiles,
          builder: (context, snapshot) {
            final profiles = snapshot.data ?? const <String, UserProfile>{};
            return Column(
              children: [
                for (final id in group.memberIds)
                  _row(id, profiles[id]),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        if (_isOwner)
          OutlinedButton(
            onPressed: () => _confirm(
              '解散群組？',
              '聊天紀錄與白板都會一併刪除，無法復原。',
              () async {
                await _service.deleteGroup(group.id);
                widget.onGone();
              },
            ),
            child: const Text('解散群組', style: TextStyle(color: AppColors.vermilion)),
          )
        else
          OutlinedButton(
            onPressed: () => _confirm(
              '退出群組？',
              '退出後需要重新加入才能看到聊天室與白板。',
              () async {
                await _service.leave(group.id, widget.uid);
                widget.onGone();
              },
            ),
            child: const Text('退出群組'),
          ),
      ],
    );
  }

  Widget _row(String id, UserProfile? profile) {
    final name = profile?.nameOrDefault ?? '成員';
    final isOwnerRow = id == widget.group.ownerId;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: UserAvatar(photoUrl: profile?.photoUrl ?? '', name: name, radius: 22),
      title: Row(
        children: [
          Flexible(
            child: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          if (isOwnerRow) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.vermilion,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('房主',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
      subtitle: (profile?.bio ?? '').isEmpty
          ? null
          : Text(profile!.bio, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: (_isOwner && !isOwnerRow)
          ? TextButton(
              onPressed: () => _confirm('移出 $name？', '對方會立刻失去聊天室與白板的存取權。',
                  () => _service.kick(widget.group.id, id)),
              child: const Text('移出'),
            )
          : null,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(
            uid: id,
            fallbackName: profile?.displayName ?? '',
            fallbackPhoto: profile?.photoUrl ?? '',
            fallbackBio: profile?.bio ?? '',
          ),
        ),
      ),
    );
  }
}
