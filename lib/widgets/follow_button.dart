import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/follow_service.dart';
import '../services/following_store.dart';
import '../theme/app_theme.dart';
import 'auth_guard.dart';

/// Follow / unfollow pill. Hidden on your own posts. Asks guests to sign in first.
class FollowButton extends StatefulWidget {
  final String targetUid;

  const FollowButton({super.key, required this.targetUid});

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool _busy = false;

  Future<void> _toggle(bool following) async {
    if (_busy) return;
    if (!await ensureSignedIn(context)) return;
    if (!mounted) return;
    final me = AuthService().currentUser?.uid;
    if (me == null || me == widget.targetUid) return;

    setState(() => _busy = true);
    try {
      await FollowService().setFollowing(me, widget.targetUid, !following);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('操作失敗，請稍後再試')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.targetUid.isEmpty) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: FollowingStore.instance,
      builder: (context, _) {
        if (AuthService().currentUser?.uid == widget.targetUid) {
          return const SizedBox.shrink();
        }
        final following = FollowingStore.instance.isFollowing(widget.targetUid);
        const shape = StadiumBorder();
        const padding = EdgeInsets.symmetric(horizontal: 16);
        const size = Size(0, 34);

        return following
            ? OutlinedButton(
                onPressed: () => _toggle(true),
                style: OutlinedButton.styleFrom(
                  minimumSize: size,
                  padding: padding,
                  shape: shape,
                  foregroundColor: AppColors.muted,
                  side: const BorderSide(color: AppColors.line),
                  textStyle: const TextStyle(fontSize: 13),
                ),
                child: const Text('追蹤中'),
              )
            : FilledButton(
                onPressed: () => _toggle(false),
                style: FilledButton.styleFrom(
                  minimumSize: size,
                  padding: padding,
                  shape: shape,
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                child: const Text('追蹤'),
              );
      },
    );
  }
}
