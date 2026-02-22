import 'package:flutter/material.dart';
import '../utils/yolo_postprocessor.dart';
import 'dart:ui' as ui ;

class YoloPainter extends CustomPainter {
  final List<Detection> detections;

  YoloPainter(this.detections);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final det in detections) {
      final rect = ui.Rect.fromLTRB(
      det.x1,
      det.y1,
      det.x2,
      det.y2,
);

canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate){
    return true;
  }
}