import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/comment.dart';
import '../models/post.dart';
import '../services/auth_service.dart';
import '../services/follow_service.dart';
import '../services/post_service.dart';
import '../utils/time_utils.dart';
import '../widgets/auth_guard.dart';
import 'category_posts_screen.dart';
import 'image_viewer_screen.dart';
import 'search_results_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _postService = PostService();
  final _followService = FollowService();
  final _commentController = TextEditingController();
  final _pageController = PageController();

  int _imageIndex = 0;
  bool _sending = false;

  @override
  void dispose() {
    _commentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    if (!await ensureSignedIn(context)) {
      if (mounted) setState(() {});
      return;
    }
    if (!mounted) return;
    final user = AuthService().currentUser;
    if (user == null) return;

    setState(() => _sending = true);
    try {
      await _postService.addComment(widget.post, user, text);
      _commentController.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (_) {
      if (mounted) _showMessage('留言失敗，請稍後再試');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _confirmDeleteComment(Comment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除留言？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _postService.deleteComment(widget.post.id, comment.id);
    } catch (_) {
      if (mounted) _showMessage('刪除失敗，請稍後再試');
    }
  }

  Future<void> _share(Post post) async {
    await SharePlus.instance.share(
      ShareParams(
        subject: post.title,
        text: '${post.title}｜${post.userName} 在 Art-Platform 發布的作品\n${post.imageUrl}',
      ),
    );
  }

  Future<void> _openAttachment(PostAttachment attachment) async {
    final opened = await launchUrl(
      Uri.parse(attachment.url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) _showMessage('無法開啟檔案');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.post.title)),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _postService.postStream(widget.post.id),
        builder: (context, snapshot) {
          final post = (snapshot.hasData && snapshot.data!.exists)
              ? Post.fromFirestore(snapshot.data!)
              : widget.post;
          return ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              _buildImages(post),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAuthorRow(post),
                    const SizedBox(height: 16),
                    Text(
                      post.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (post.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(post.description, style: const TextStyle(height: 1.5)),
                    ],
                    const SizedBox(height: 12),
                    _buildLabels(post),
                    const SizedBox(height: 16),
                    _buildActions(post),
                    if (post.attachments.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildAttachments(post),
                    ],
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Text(
                      '留言 ${post.commentsCount}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildComments(post),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildCommentInput(),
    );
  }

  Widget _buildImages(Post post) {
    final urls = post.imageUrls;
    if (urls.isEmpty) return const SizedBox.shrink();

    final width = MediaQuery.of(context).size.width;
    final ratio = (post.aspectRatio ?? 1).clamp(0.6, 1.5).toDouble();
    final height = min(width / ratio, MediaQuery.of(context).size.height * 0.6);

    return Container(
      height: height,
      color: Colors.grey.shade100,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: urls.length,
            onPageChanged: (i) => setState(() => _imageIndex = i),
            itemBuilder: (context, i) => GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ImageViewerScreen(imageUrls: urls, initialIndex: i),
                ),
              ),
              child: CachedNetworkImage(
                imageUrl: urls[i],
                fit: BoxFit.contain,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                errorWidget: (context, url, error) =>
                    const Center(child: Text('圖片載入失敗')),
              ),
            ),
          ),
          if (urls.length > 1)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(urls.length, (i) {
                      return Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _imageIndex ? Colors.white : Colors.white54,
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAuthorRow(Post post) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMine = AuthService().currentUser?.uid == post.userId;

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: colorScheme.primaryContainer,
          backgroundImage: post.userPhotoUrl.isNotEmpty
              ? CachedNetworkImageProvider(post.userPhotoUrl)
              : null,
          child: post.userPhotoUrl.isEmpty
              ? Text(post.userName.isNotEmpty ? post.userName[0] : '?')
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.userName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                timeAgo(post.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        if (!isMine)
          _ToggleActionButton(
            compact: true,
            stateStream: (uid) => _followService.isFollowingStream(uid, post.userId),
            onToggle: (uid, active) async {
              if (uid == post.userId) return;
              await _followService.setFollowing(uid, post.userId, !active);
            },
            label: (active) => active ? '追蹤中' : '追蹤',
          ),
      ],
    );
  }

  Widget _buildLabels(Post post) {
    Chip labelChip(String text, Color color) => Chip(
          label: Text(text, style: TextStyle(color: color, fontSize: 12)),
          backgroundColor: color.withValues(alpha: 0.1),
          visualDensity: VisualDensity.compact,
        );

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        if (post.isNsfw) labelChip('成人內容', Colors.red.shade600),
        if (post.isAiGenerated) labelChip('AI 生成', Colors.blueGrey.shade600),
        if (post.category.isNotEmpty)
          ActionChip(
            label: Text(post.category),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CategoryPostsScreen(category: post.category),
              ),
            ),
          ),
        ...post.tags.map(
          (tag) => ActionChip(
            label: Text('#$tag'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SearchResultsScreen(query: '#$tag'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(Post post) {
    return Row(
      children: [
        Expanded(
          child: _ToggleActionButton(
            stateStream: (uid) => _postService.likedStream(post.id, uid),
            onToggle: (uid, active) => _postService.toggleLike(post, uid),
            label: (active) => '${active ? '已按讚' : '讚'} ${post.likesCount}',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ToggleActionButton(
            stateStream: (uid) => _postService.bookmarkedStream(post.id, uid),
            onToggle: (uid, active) => _postService.toggleBookmark(post, uid),
            label: (active) => active ? '已收藏' : '收藏',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _share(post),
            child: const Text('分享'),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachments(Post post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('附件（圖層檔）', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (final attachment in post.attachments)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(attachment.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(
                        formatFileSize(attachment.size),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _openAttachment(attachment),
                  child: const Text('下載'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildComments(Post post) {
    return StreamBuilder<List<Comment>>(
      stream: _postService.commentsStream(post.id),
      builder: (context, snapshot) {
        final comments = snapshot.data ?? const [];
        if (comments.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('還沒有留言，來當第一個吧', style: TextStyle(color: Colors.grey.shade600)),
            ),
          );
        }
        final me = AuthService().currentUser?.uid;
        return Column(
          children: [
            for (final comment in comments)
              _CommentTile(
                comment: comment,
                isAuthor: comment.userId == post.userId,
                canDelete: me != null && (me == comment.userId || me == post.userId),
                onDelete: () => _confirmDeleteComment(comment),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCommentInput() {
    final isGuest = AuthService().currentUser == null;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                readOnly: isGuest,
                minLines: 1,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: isGuest ? '登入後即可留言' : '寫下你的留言…',
                  isDense: true,
                  counterText: '',
                ),
                onTap: isGuest
                    ? () async {
                        await ensureSignedIn(context);
                        if (mounted) setState(() {});
                      }
                    : null,
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
                : TextButton(onPressed: _sendComment, child: const Text('送出')),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final bool isAuthor;
  final bool canDelete;
  final VoidCallback onDelete;

  const _CommentTile({
    required this.comment,
    required this.isAuthor,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.primaryContainer,
            backgroundImage: comment.userPhotoUrl.isNotEmpty
                ? CachedNetworkImageProvider(comment.userPhotoUrl)
                : null,
            child: comment.userPhotoUrl.isEmpty
                ? Text(
                    comment.userName.isNotEmpty ? comment.userName[0] : '?',
                    style: const TextStyle(fontSize: 12),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    if (isAuthor) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '創作者',
                          style: TextStyle(fontSize: 10, color: colorScheme.onPrimary),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      timeAgo(comment.createdAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(comment.text, style: const TextStyle(height: 1.4)),
              ],
            ),
          ),
          if (canDelete)
            TextButton(
              onPressed: onDelete,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                foregroundColor: Colors.grey.shade600,
              ),
              child: const Text('刪除', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

/// A button whose "active" state (liked / bookmarked / following) is streamed from Firestore
/// for the signed-in user. Tapping while signed out prompts login first.
class _ToggleActionButton extends StatefulWidget {
  final Stream<bool> Function(String uid) stateStream;
  final Future<void> Function(String uid, bool active) onToggle;
  final String Function(bool active) label;
  final bool compact;

  const _ToggleActionButton({
    required this.stateStream,
    required this.onToggle,
    required this.label,
    this.compact = false,
  });

  @override
  State<_ToggleActionButton> createState() => _ToggleActionButtonState();
}

class _ToggleActionButtonState extends State<_ToggleActionButton> {
  StreamSubscription<User?>? _authSub;
  StreamSubscription<bool>? _stateSub;
  bool _active = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _authSub = AuthService().authStateChanges.listen(_bind);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _stateSub?.cancel();
    super.dispose();
  }

  void _bind(User? user) {
    _stateSub?.cancel();
    _stateSub = null;
    if (user == null) {
      if (mounted) setState(() => _active = false);
      return;
    }
    _stateSub = widget.stateStream(user.uid).listen(
      (active) {
        if (mounted) setState(() => _active = active);
      },
      onError: (_) {},
    );
  }

  Future<void> _tap() async {
    if (_busy) return;
    if (!await ensureSignedIn(context)) return;
    if (!mounted) return;
    final user = AuthService().currentUser;
    if (user == null) return;

    setState(() => _busy = true);
    try {
      await widget.onToggle(user.uid, _active);
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
    final style = widget.compact
        ? ButtonStyle(
            minimumSize: const WidgetStatePropertyAll(Size(0, 34)),
            padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14)),
          )
        : null;
    final child = Text(widget.label(_active));

    return _active
        ? FilledButton.tonal(onPressed: _tap, style: style, child: child)
        : OutlinedButton(onPressed: _tap, style: style, child: child);
  }
}
