import 'package:flutter/material.dart';

class OrnamentalDivider extends StatelessWidget {
  final Color color;

  const OrnamentalDivider({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLine(),
          const SizedBox(width: 8),
          CustomPaint(
            size: const Size(20, 20),
            painter: _DividerStarPainter(color: color),
          ),
          const SizedBox(width: 8),
          _buildLine(),
        ],
      ),
    );
  }

  Widget _buildLine() {
    return Container(
      width: 40,
      height: 1,
      color: color.withOpacity(0.3), // Will be updated to withValues
    );
  }
}

class _DividerStarPainter extends CustomPainter {
  final Color color;

  _DividerStarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final paint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    // "M12 4 L14 10 L20 12 L14 14 L12 20 L10 14 L4 12 L10 10 Z"
    final path = Path()
      ..moveTo(12 * s, 4 * s)
      ..lineTo(14 * s, 10 * s)
      ..lineTo(20 * s, 12 * s)
      ..lineTo(14 * s, 14 * s)
      ..lineTo(12 * s, 20 * s)
      ..lineTo(10 * s, 14 * s)
      ..lineTo(4 * s,  12 * s)
      ..lineTo(10 * s, 10 * s)
      ..close();

    canvas.drawPath(path, paint);
    
    // Draw center dot
    canvas.drawCircle(Offset(12 * s, 12 * s), 1.5 * s, 
      Paint()..color = color.withOpacity(0.6)..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_DividerStarPainter old) => old.color != color;
}
