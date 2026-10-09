import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/group.dart';

/// Strokes store widths relative to a 360-unit-wide board so they look the same at any size.
const boardReferenceWidth = 360.0;

class BoardPainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentWidth;

  const BoardPainter({
    required this.strokes,
    this.currentPoints = const [],
    this.currentColor = Colors.black,
    this.currentWidth = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final scale = size.width / boardReferenceWidth;

    for (final stroke in strokes) {
      final points = <Offset>[
        for (var i = 0; i + 1 < stroke.points.length; i += 2)
          Offset(stroke.points[i] * size.width, stroke.points[i + 1] * size.height),
      ];
      _drawStroke(canvas, points, Color(stroke.color), stroke.width * scale);
    }

    if (currentPoints.isNotEmpty) {
      final points = [for (final p in currentPoints) Offset(p.dx * size.width, p.dy * size.height)];
      _drawStroke(canvas, points, currentColor, currentWidth * scale);
    }
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Color color, double width) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      canvas.drawCircle(points.first, width / 2, Paint()..color = color);
      return;
    }
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length - 1; i++) {
      final mid = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        (points[i].dy + points[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) => true;
}

/// Renders the whiteboard to a PNG (3:4, white background) for publishing as a post.
Future<Uint8List> renderBoardPng(List<Stroke> strokes, {int width = 1200, int height = 1600}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  BoardPainter(strokes: strokes).paint(canvas, Size(width.toDouble(), height.toDouble()));
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}
