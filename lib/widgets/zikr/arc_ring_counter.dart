import 'package:flutter/material.dart';
import 'dart:math' as math;

class ArcRingCounter extends StatelessWidget {
  final int current;
  final int total;
  final double size;
  final Color teal;
  final Color track;
  final Widget child;

  const ArcRingCounter({
    super.key,
    required this.current,
    required this.total,
    required this.size,
    required this.teal,
    required this.track,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -math.pi / 2, // Rotate -90deg to start from top
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: total > 0 ? (current / total).clamp(0.0, 1.0) : 0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              builder: (context, progress, _) {
                return CustomPaint(
                  size: Size(size, size),
                  painter: _ArcRingPainter(
                    progress: progress,
                    teal: teal,
                    track: track,
                  ),
                );
              },
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _ArcRingPainter extends CustomPainter {
  final double progress;
  final Color teal;
  final Color track;

  _ArcRingPainter({
    required this.progress,
    required this.teal,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 7.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth * 2) / 2; // (148 - 14) / 2 = 67

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final progressPaint = Paint()
      ..color = teal
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw track
    canvas.drawCircle(center, radius, trackPaint);

    // Draw progress arc
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0, // Already rotated by Transform.rotate
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcRingPainter old) {
    return old.progress != progress || old.teal != teal || old.track != track;
  }
}
