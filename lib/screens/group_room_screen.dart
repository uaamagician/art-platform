import 'package:flutter/material.dart';

import '../models/group.dart';
import '../services/auth_service.dart';
import '../services/group_service.dart';
import '../theme/app_theme.dart';
import '../widgets/group_chat_view.dart';
import '../widgets/group_members_view.dart';
import '../widgets/segment_tabs.dart';
import '../widgets/whiteboard_view.dart';

class GroupRoomScreen extends StatefulWidget {
  final String groupId;

  const GroupRoomScreen({super.key, required this.groupId});

  @override
  State<GroupRoomScreen> createState() => _GroupRoomScreenState();
}

class _GroupRoomScreenState extends State<GroupRoomScreen> {
  final _service = GroupService();
  int _tab = 0;
  bool _joining = false;

  Future<void> _join(Group group, String uid) async {
    setState(() => _joining = true);
    try {
      await _service.join(group.id, uid);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('加入失敗，請稍後再試')));
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid;

    return StreamBuilder<Group?>(
      stream: _service.groupStream(widget.groupId),
      builder: (context, snapshot) {
        final group = snapshot.data;

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('讀取失敗，請確認網路連線')),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
        }
        if (group == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('這個群組已不存在')));
        }
        if (uid == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('請先登入')));
        }
        if (!group.isMember(uid)) return _joinPrompt(group, uid);

        return Scaffold(
          appBar: AppBar(
            title: Column(
              children: [
                Text(group.name),
                Text(
                  '${group.memberCount} 位成員',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SegmentTabs(
                  labels: const ['聊天', '白板', '成員'],
                  selected: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _tab,
                  children: [
                    GroupChatView(group: group),
                    WhiteboardView(group: group, uid: uid),
                    GroupMembersView(
                      group: group,
                      uid: uid,
                      onGone: () {
                        if (mounted) Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _joinPrompt(Group group, String uid) {
    return Scaffold(
      appBar: AppBar(title: Text(group.name)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(group.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('${group.memberCount} 位成員', style: const TextStyle(color: AppColors.muted)),
              if (group.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(group.description, textAlign: TextAlign.center, style: const TextStyle(height: 1.5)),
              ],
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _joining ? null : () => _join(group, uid),
                child: Text(_joining ? '加入中…' : '加入群組'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
