import 'package:flutter/material.dart';

import '../models/group.dart';
import '../screens/upload_screen.dart';
import '../services/group_service.dart';
import '../theme/app_theme.dart';
import 'board_painter.dart';

/// Shared whiteboard: everyone in the group draws on the same canvas in real time.
/// The owner can lock it, clear it and publish the result as a post.
class WhiteboardView extends StatefulWidget {
  final Group group;
  final String uid;

  const WhiteboardView({super.key, required this.group, required this.uid});

  @override
  State<WhiteboardView> createState() => _WhiteboardViewState();
}

class _WhiteboardViewState extends State<WhiteboardView> {
  static const _palette = [
    Color(0xFF221E1B),
    Color(0xFFC9402F),
    Color(0xFF2F5D9E),
    Color(0xFF3F7D5B),
    Color(0xFFE0A526),
    Color(0xFF7A4FA3),
    Color(0xFF8A5A3C),
    Colors.white,
  ];
  static const _widths = [('細', 3.0), ('中', 6.0), ('粗', 12.0)];
  static const _maxPointsPerStroke = 400;

  final _service = GroupService();
  final _current = <Offset>[];

  List<Stroke> _strokes = const [];
  Color _color = _palette.first;
  double _width = 6;

  bool get _isOwner => widget.group.ownerId == widget.uid;
  bool get _canDraw => !widget.group.locked || _isOwner;

  Offset _normalize(Offset local, Size size) => Offset(
        (local.dx / size.width).clamp(0.0, 1.0),
        (local.dy / size.height).clamp(0.0, 1.0),
      );

  void _onStart(Offset local, Size size) {
    if (!_canDraw) return;
    setState(() => _current
      ..clear()
      ..add(_normalize(local, size)));
  }

  void _onUpdate(Offset local, Size size) {
    if (!_canDraw || _current.isEmpty) return;
    final next = _normalize(local, size);
    if ((next - _current.last).distance < 0.002) return;
    setState(() => _current.add(next));
  }

  Future<void> _commit(List<Offset> points) async {
    if (points.isEmpty) return;
    var kept = points;
    if (points.length > _maxPointsPerStroke) {
      final step = (points.length / _maxPointsPerStroke).ceil();
      kept = [
        for (var i = 0; i < points.length; i += step) points[i],
        if ((points.length - 1) % step != 0) points.last,
      ];
    }
    try {
      await _service.addStroke(
        widget.group.id,
        uid: widget.uid,
        color: _color.toARGB32(),
        width: _width,
        points: [for (final p in kept) ...[p.dx, p.dy]],
      );
    } catch (_) {
      if (mounted) _message('筆畫送出失敗，請稍後再試');
    }
  }

  void _onEnd() {
    if (_current.isEmpty) return;
    final points = List<Offset>.of(_current);
    setState(_current.clear);
    _commit(points);
  }

  void _onTap(Offset local, Size size) {
    if (!_canDraw) return;
    _commit([_normalize(local, size)]);
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _undo() async {
    final mine = _strokes.where((s) => s.userId == widget.uid);
    if (mine.isEmpty) return _message('沒有可以復原的筆畫');
    try {
      await _service.deleteStroke(widget.group.id, mine.last.id);
    } catch (_) {
      if (mounted) _message('復原失敗，請稍後再試');
    }
  }

  Future<void> _confirm(String title, Future<void> Function() action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
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
      if (mounted) _message('操作失敗，請稍後再試');
    }
  }

  Future<void> _publish() async {
    if (_strokes.isEmpty) return _message('白板還是空的');
    final bytes = await renderBoardPng(_strokes);
    if (!mounted) return;
    final published = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => UploadScreen(
          seed: UploadSeed(
            imageName: 'whiteboard.png',
            imageBytes: bytes,
            title: '${widget.group.name} 共同創作',
            description: '由「${widget.group.name}」群組成員在共享白板上一起完成。',
            tags: const ['共同創作'],
          ),
        ),
      ),
    );
    if (published == true && mounted) _message('已發布到動態');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Stroke>>(
      stream: _service.strokesStream(widget.group.id),
      builder: (context, snapshot) {
        _strokes = snapshot.data ?? _strokes;
        return Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.line),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ink.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final size = constraints.biggest;
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanStart: (d) => _onStart(d.localPosition, size),
                            onPanUpdate: (d) => _onUpdate(d.localPosition, size),
                            onPanEnd: (_) => _onEnd(),
                            onPanCancel: _onEnd,
                            onTapUp: (d) => _onTap(d.localPosition, size),
                            child: CustomPaint(
                              size: size,
                              painter: BoardPainter(
                                strokes: _strokes,
                                currentPoints: _current,
                                currentColor: _color,
                                currentWidth: _width,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _tools(),
          ],
        );
      },
    );
  }

  Widget _tools() {
    if (!_canDraw) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.tint, borderRadius: BorderRadius.circular(14)),
          child: const Text(
            '白板已被房主鎖定，只有房主可以繪圖。',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF5C544C)),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final c in _palette)
                  GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _color == c ? AppColors.vermilion : AppColors.line,
                          width: _color == c ? 3 : 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: c == Colors.white
                          ? const Text('擦', style: TextStyle(fontSize: 11, color: AppColors.muted))
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final (label, w) in _widths)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      selected: _width == w,
                      onSelected: (_) => setState(() => _width = w),
                    ),
                  ),
                const Spacer(),
                TextButton(onPressed: _undo, child: const Text('復原')),
              ],
            ),
            if (_isOwner)
              Wrap(
                spacing: 4,
                children: [
                  TextButton(
                    onPressed: () => _service.setLocked(widget.group.id, !widget.group.locked),
                    child: Text(widget.group.locked ? '解除鎖定' : '鎖定白板'),
                  ),
                  TextButton(
                    onPressed: () => _confirm('清空整個白板？', () => _service.clearBoard(widget.group.id)),
                    child: const Text('清空'),
                  ),
                  TextButton(onPressed: _publish, child: const Text('發布為作品')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
