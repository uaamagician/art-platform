import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/group.dart';
import '../services/auth_service.dart';
import '../services/group_service.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import '../widgets/auth_guard.dart';
import '../widgets/prompt_dialogs.dart';
import '../widgets/segment_tabs.dart';
import 'group_room_screen.dart';

class GroupScreen extends StatelessWidget {
  const GroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      initialData: AuthService().currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('群組')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '登入後就能加入群組，一起聊天、一起在白板上畫畫',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ensureSignedIn(context),
                      child: const Text('登入'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return _GroupHome(key: ValueKey(user.uid), user: user);
      },
    );
  }
}

class _GroupHome extends StatefulWidget {
  final User user;

  const _GroupHome({super.key, required this.user});

  @override
  State<_GroupHome> createState() => _GroupHomeState();
}

class _GroupHomeState extends State<_GroupHome> {
  final _service = GroupService();
  int _tab = 0;
  late Future<List<Group>> _discover = _service.discover(widget.user.uid);

  void _open(String groupId) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => GroupRoomScreen(groupId: groupId)))
        .then((_) {
      if (mounted) {
        setState(() {
          _discover = _service.discover(widget.user.uid);
        });
      }
    });
  }

  Future<void> _create() async {
    final input = await showCreateGroupDialog(context);
    if (input == null || input.name.isEmpty || !mounted) return;
    final groupName = input.name;
    final groupDescription = input.description;

    try {
      final id = await _service.create(
        user: widget.user,
        name: groupName,
        description: groupDescription,
      );
      if (mounted) _open(id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('建立失敗，請稍後再試')));
      }
    }
  }

  Future<void> _join(Group group) async {
    try {
      await _service.join(group.id, widget.user.uid);
      if (mounted) _open(group.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('加入失敗，請稍後再試')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('群組'),
        actions: [TextButton(onPressed: _create, child: const Text('建立'))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SegmentTabs(
              labels: const ['我的群組', '探索群組'],
              selected: _tab,
              onChanged: (i) {
                setState(() {
                  _tab = i;
                  if (i == 1) _discover = _service.discover(widget.user.uid);
                });
              },
            ),
          ),
          Expanded(child: _tab == 0 ? _mine() : _explore()),
        ],
      ),
    );
  }

  Widget _mine() {
    return StreamBuilder<List<Group>>(
      stream: _service.myGroupsStream(widget.user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('讀取失敗，請確認網路連線'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final groups = snapshot.data!;
        if (groups.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('還沒有加入任何群組',
                      style: TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _create, child: const Text('建立群組')),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() {
                      _tab = 1;
                      _discover = _service.discover(widget.user.uid);
                    }),
                    child: const Text('看看別人的群組'),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [for (final g in groups) _tile(g, onTap: () => _open(g.id))],
        );
      },
    );
  }

  Widget _explore() {
    return FutureBuilder<List<Group>>(
      future: _discover,
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
                    _discover = _service.discover(widget.user.uid);
                  }),
                  child: const Text('重試'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final groups = snapshot.data!;
        return RefreshIndicator(
          color: AppColors.vermilion,
          onRefresh: () async {
            final next = _service.discover(widget.user.uid);
            setState(() {
              _discover = next;
            });
            await next;
          },
          child: groups.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    Center(child: Text('目前沒有可加入的群組', style: TextStyle(color: AppColors.muted))),
                  ],
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    for (final g in groups)
                      _tile(
                        g,
                        onTap: () => _open(g.id),
                        trailing: OutlinedButton(
                          onPressed: () => _join(g),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 34),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Text('加入'),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }

  static const _tileColors = [
    Color(0xFFF6E3DC),
    Color(0xFFE2ECE4),
    Color(0xFFE3E8F3),
    Color(0xFFF3EBD5),
    Color(0xFFEBE1F0),
  ];

  Widget _tile(Group g, {required VoidCallback onTap, Widget? trailing}) {
    final preview = g.lastMessage.isNotEmpty
        ? g.lastMessage
        : (g.description.isNotEmpty ? g.description : '${g.memberCount} 位成員');

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _tileColors[g.name.hashCode.abs() % _tileColors.length],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  g.name.isNotEmpty ? g.name.characters.first : '群',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                  ],
                ),
              ),
              if (trailing != null)
                trailing
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${g.memberCount} 人',
                        style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    if (g.lastMessageAt != null) ...[
                      const SizedBox(height: 4),
                      Text(timeAgo(g.lastMessageAt),
                          style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
