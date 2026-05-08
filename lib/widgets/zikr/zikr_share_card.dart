import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A self-contained, beautifully designed card used to render a zikr
/// as a shareable image. Wrap this in a [RepaintBoundary] and call
/// [ShareService.shareAsImage()] to capture it.
///
/// The card is sized at 600×800 logical pixels to produce a portrait
/// image that looks great on social media feeds.
class ZikrShareCard extends StatelessWidget {
  final String arabicText;
  final int repeatCount;
  final String categoryAr;
  final String categoryEn;
  final bool isArabic;

  const ZikrShareCard({
    super.key,
    required this.arabicText,
    required this.repeatCount,
    required this.categoryAr,
    required this.categoryEn,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 600,
      height: 800,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D1117),
              Color(0xFF0A2A2A),
              Color(0xFF0D1117),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned.fill(child: _buildPatternOverlay()),

            // Outer border frame
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFD4A84B).withOpacity(0.25),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),

            // Inner content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top watermark
                  _buildTopBadge(),
                  const SizedBox(height: 28),

                  // Category label
                  _buildCategoryPill(),
                  const SizedBox(height: 32),

                  // Ornamental top line
                  _buildOrnamentalLine(),
                  const SizedBox(height: 32),

                  // Arabic zikr text (expands to fill space)
                  Expanded(
                    child: Center(
                      child: Text(
                        arabicText,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.amiri(
                          fontSize: _fontSize(arabicText.length),
                          color: const Color(0xFFE8E4DD),
                          height: 1.8,
                        ),
                      ),
                    ),
                  ),

                  // Ornamental bottom line
                  const SizedBox(height: 24),
                  _buildOrnamentalLine(),
                  const SizedBox(height: 24),

                  // Repeat badge
                  _buildRepeatBadge(),
                  const SizedBox(height: 24),

                  // Bottom source & app name
                  _buildFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternOverlay() {
    return CustomPaint(painter: _CardPatternPainter());
  }

  Widget _buildTopBadge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _SmallDot(),
        const SizedBox(width: 10),
        Text(
          'ضياء  ·  Diyaa',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.5,
            color: const Color(0xFFD4A84B).withOpacity(0.8),
          ),
        ),
        const SizedBox(width: 10),
        const _SmallDot(),
      ],
    );
  }

  Widget _buildCategoryPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF4DB6AC).withOpacity(0.10),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(
          color: const Color(0xFF4DB6AC).withOpacity(0.30),
          width: 1,
        ),
      ),
      child: Text(
        categoryAr,
        style: GoogleFonts.amiri(
          fontSize: 15,
          color: const Color(0xFF4DB6AC),
        ),
      ),
    );
  }

  Widget _buildOrnamentalLine() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _GradLine(toRight: true),
        const SizedBox(width: 12),
        const _StarDot(),
        const SizedBox(width: 12),
        _GradLine(toRight: false),
      ],
    );
  }

  Widget _buildRepeatBadge() {
    final repeatText = isArabic
        ? 'كرر $repeatCount ${repeatCount == 1 ? 'مرة' : 'مرات'}'
        : 'Repeat $repeatCount×';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFD4A84B).withOpacity(0.08),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(
          color: const Color(0xFFD4A84B).withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📿', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text(
            repeatText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFD4A84B),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📖', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Text(
              isArabic ? 'حصن المسلم' : 'Hisn al-Muslim',
              style: TextStyle(
                fontSize: 11,
                color: const Color(0xFF8A8790),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _fontSize(int len) {
    if (len < 80) return 32;
    if (len < 180) return 26;
    if (len < 350) return 20;
    return 16;
  }
}

// ── Private helpers ───────────────────────────────────────────────────────────

class _SmallDot extends StatelessWidget {
  const _SmallDot();
  @override
  Widget build(BuildContext context) => Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFD4A84B).withOpacity(0.5),
        ),
      );
}

class _StarDot extends StatelessWidget {
  const _StarDot();
  @override
  Widget build(BuildContext context) => CustomPaint(
        size: const Size(12, 12),
        painter: _StarPainter(color: const Color(0xFFD4A84B)),
      );
}

class _GradLine extends StatelessWidget {
  final bool toRight;
  const _GradLine({required this.toRight});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 1,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: toRight ? Alignment.centerLeft : Alignment.centerRight,
            end: toRight ? Alignment.centerRight : Alignment.centerLeft,
            colors: [
              Colors.transparent,
              const Color(0xFFD4A84B).withOpacity(0.4),
            ],
          ),
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  final Color color;
  const _StarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 14;
    final path = Path()
      ..moveTo(7 * s, 1 * s)
      ..lineTo(8.2 * s, 5.8 * s)
      ..lineTo(13 * s, 7 * s)
      ..lineTo(8.2 * s, 8.2 * s)
      ..lineTo(7 * s, 13 * s)
      ..lineTo(5.8 * s, 8.2 * s)
      ..lineTo(1 * s, 7 * s)
      ..lineTo(5.8 * s, 5.8 * s)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withOpacity(0.7)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.color != color;
}

class _CardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4A84B).withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const spacing = 60.0;
    for (double y = 0; y < size.height + spacing; y += spacing) {
      for (double x = 0; x < size.width + spacing; x += spacing) {
        canvas.save();
        canvas.translate(x, y);
        final s = 60.0 / 14;
        final path = Path()
          ..moveTo(7 * s, 1 * s)
          ..lineTo(8.2 * s, 5.8 * s)
          ..lineTo(13 * s, 7 * s)
          ..lineTo(8.2 * s, 8.2 * s)
          ..lineTo(7 * s, 13 * s)
          ..lineTo(5.8 * s, 8.2 * s)
          ..lineTo(1 * s, 7 * s)
          ..lineTo(5.8 * s, 5.8 * s)
          ..close();
        canvas.drawPath(path, paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_CardPatternPainter old) => false;
}
