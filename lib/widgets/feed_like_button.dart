import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/post.dart';
import '../services/auth_service.dart';
import '../services/id_set_store.dart';
import '../services/post_service.dart';
import '../theme/app_theme.dart';
import 'auth_guard.dart';

/// Like pill for feed cards. The liked state comes from the shared [UserStores.liked];
/// taps update it instantly and are rolled back if the write fails.
class FeedLikeButton extends StatefulWidget {
  final Post post;

  const FeedLikeButton({super.key, required this.post});

  @override
  State<FeedLikeButton> createState() => _FeedLikeButtonState();
}

class _FeedLikeButtonState extends State<FeedLikeButton> {
  bool? _override;
  int _delta = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    UserStores.liked.addListener(_onStore);
  }

  @override
  void dispose() {
    UserStores.liked.removeListener(_onStore);
    super.dispose();
  }

  @override
  void didUpdateWidget(FeedLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id ||
        oldWidget.post.likesCount != widget.post.likesCount) {
      _delta = 0;
      _override = null;
    }
  }

  void _onStore() {
    if (!mounted) return;
    if (_override != null && UserStores.liked.contains(widget.post.id) == _override) {
      _override = null;
    }
    setState(() {});
  }

  bool get _liked => _override ?? UserStores.liked.contains(widget.post.id);

  Future<void> _tap() async {
    if (_busy) return;
    if (!await ensureSignedIn(context)) return;
    if (!mounted) return;
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;

    final next = !_liked;
    HapticFeedback.selectionClick();
    setState(() {
      _busy = true;
      _override = next;
      _delta += next ? 1 : -1;
    });
    try {
      await PostService().toggleLike(widget.post, uid);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _override = null;
        _delta += next ? -1 : 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('操作失敗，請稍後再試')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final liked = _liked;
    final count = (widget.post.likesCount + _delta).clamp(0, 1 << 30);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: _tap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: liked ? AppColors.vermilion.withValues(alpha: 0.12) : AppColors.tint,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${liked ? '已讚' : '讚'} $count',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: liked ? AppColors.vermilion : const Color(0xFF5C544C),
          ),
        ),
      ),
    );
  }
}
