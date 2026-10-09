import 'package:flutter/material.dart';

import '../models/group.dart';
import '../services/auth_service.dart';
import '../services/group_service.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import 'user_avatar.dart';

/// Group chat room (no one-to-one messages by design).
class GroupChatView extends StatefulWidget {
  final Group group;

  const GroupChatView({super.key, required this.group});

  @override
  State<GroupChatView> createState() => _GroupChatViewState();
}

class _GroupChatViewState extends State<GroupChatView> {
  final _service = GroupService();
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final user = AuthService().currentUser;
    if (text.isEmpty || user == null || _sending) return;

    setState(() => _sending = true);
    try {
      await _service.sendMessage(widget.group.id, user, text);
      _controller.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('訊息送出失敗，請稍後再試')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _deleteMessage(GroupMessage message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除這則訊息？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('刪除')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.deleteMessage(widget.group.id, message.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('刪除失敗，請稍後再試')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = AuthService().currentUser?.uid;
    final isOwner = widget.group.ownerId == me;

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<GroupMessage>>(
            stream: _service.messagesStream(widget.group.id),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('讀取失敗，請確認網路連線'));
              }
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final messages = snapshot.data!;
              if (messages.isEmpty) {
                return const Center(
                  child: Text('還沒有訊息，說聲哈囉吧', style: TextStyle(color: AppColors.muted)),
                );
              }
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final m = messages[index];
                  final mine = m.userId == me;
                  return GestureDetector(
                    onLongPress: (mine || isOwner) ? () => _deleteMessage(m) : null,
                    child: _Bubble(message: m, mine: mine),
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 1000,
                    textInputAction: TextInputAction.send,
                    decoration: const InputDecoration(
                      hintText: '傳訊息給大家…',
                      isDense: true,
                      counterText: '',
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 4),
                _sending
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : TextButton(onPressed: _send, child: const Text('送出')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final GroupMessage message;
  final bool mine;

  const _Bubble({required this.message, required this.mine});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.68),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: mine ? scheme.primaryContainer : Colors.white,
        border: mine ? null : Border.all(color: AppColors.line),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(mine ? 18 : 4),
          bottomRight: Radius.circular(mine ? 4 : 18),
        ),
      ),
      child: Text(message.text, style: const TextStyle(height: 1.45)),
    );
    final time = Text(
      timeAgo(message.createdAt),
      style: const TextStyle(fontSize: 11, color: AppColors.muted),
    );

    if (mine) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [bubble, const SizedBox(height: 2), time],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(photoUrl: message.userPhotoUrl, name: message.userName, radius: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.userName.isNotEmpty ? message.userName : '成員',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 2),
              bubble,
              const SizedBox(height: 2),
              time,
            ],
          ),
        ],
      ),
    );
  }
}
