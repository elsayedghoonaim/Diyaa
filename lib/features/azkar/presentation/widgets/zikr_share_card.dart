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
  final bool isDark;

  const ZikrShareCard({
    super.key,
    required this.arabicText,
    required this.repeatCount,
    required this.categoryAr,
    required this.categoryEn,
    required this.isArabic,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor = isDark ? const Color(0xFF080A10) : const Color(0xFFFAFAF5);
    final Color mainTextColor = isDark ? const Color(0xFFF0EDE6) : const Color(0xFF2C302E);
    final Color borderColor = isDark
        ? const Color(0xFFD4A84B).withValues(alpha: 0.20)
        : const Color(0xFFC49B45).withValues(alpha: 0.15);
    final Color patternColor = isDark
        ? const Color(0xFFD4A84B).withValues(alpha: 0.025)
        : const Color(0xFFC49B45).withValues(alpha: 0.035);
    final Color accentGoldColor = isDark ? const Color(0xFFD4A84B) : const Color(0xFFB48530);
    return SizedBox(
      width: 600,
      height: 800,
      child: Container(
        color: bgColor,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _CardPatternPainter(color: patternColor),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: borderColor,
                      width: 1.2,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 44),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildBranding(accentGoldColor, mainTextColor),
                  const SizedBox(height: 28),
                  _buildCategoryPill(),
                  const SizedBox(height: 28),
                  _buildOrnamentalLine(accentGoldColor),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          arabicText,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: GoogleFonts.amiri(
                            fontSize: _fontSize(arabicText.length),
                            color: mainTextColor,
                            height: 1.8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildOrnamentalLine(accentGoldColor),
                  const SizedBox(height: 28),
                  _buildRepeatBadge(accentGoldColor),
                  const SizedBox(height: 24),
                  _buildFooter(mainTextColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranding(Color goldColor, Color textColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: goldColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.auto_awesome,
            size: 16,
            color: goldColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'ضياء  ·  Diyaa',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.5,
            color: textColor.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPill() {
    final Color pillBg = isDark ? const Color(0xFF121620) : const Color(0xFFF3EFEB);
    final Color tealColor = isDark ? const Color(0xFF4DB6AC) : const Color(0xFF1F6B6B);
    final Color pillBorder = isDark
        ? const Color(0xFF4DB6AC).withValues(alpha: 0.3)
        : const Color(0xFF1F6B6B).withValues(alpha: 0.25);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(
          color: pillBorder,
          width: 1,
        ),
      ),
      child: Text(
        categoryAr,
        style: GoogleFonts.amiri(
          fontSize: 15,
          color: tealColor,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildOrnamentalLine(Color goldColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _GradLine(toRight: true, color: goldColor),
        const SizedBox(width: 12),
        _StarDot(color: goldColor),
        const SizedBox(width: 12),
        _GradLine(toRight: false, color: goldColor),
      ],
    );
  }

  Widget _buildRepeatBadge(Color goldColor) {
    final Color pillBg = isDark ? const Color(0xFF121620) : const Color(0xFFF3EFEB);
    final String repeatText = isArabic
        ? 'كرر $repeatCount ${repeatCount == 1 ? 'مرة' : 'مرات'}'
        : 'Repeat $repeatCount×';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(
          color: goldColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '📿',
            style: TextStyle(
              fontSize: 13,
              color: goldColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            repeatText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: goldColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(Color textColor) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 13,
              color: textColor.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 6),
            Text(
              isArabic ? 'حصن المسلم' : 'Hisn al-Muslim',
              style: TextStyle(
                fontSize: 11,
                color: textColor.withValues(alpha: 0.5),
                letterSpacing: 0.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _fontSize(int len) {
    if (len < 40) {
      return 32.0;
    }
    if (len < 80) {
      return 28.0;
    }
    if (len < 160) {
      return 22.0;
    }
    if (len < 300) {
      return 18.0;
    }
    if (len < 500) {
      return 15.0;
    }
    return 13.0;
  }
}

// ─────────────────────────────────────────────
// Private helpers
// ─────────────────────────────────────────────

class _StarDot extends StatelessWidget {
  final Color color;

  const _StarDot({required this.color});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: const Size(12, 12),
        painter: _StarPainter(color: color),
      );
}

class _GradLine extends StatelessWidget {
  final bool toRight;
  final Color color;

  const _GradLine({required this.toRight, required this.color});

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
            colors: <Color>[
              Colors.transparent,
              color.withValues(alpha: 0.35),
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
    final double s = size.width / 14;
    final Path path = Path()
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
        ..color = color.withValues(alpha: 0.7)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.color != color;
}

class _CardPatternPainter extends CustomPainter {
  final Color color;

  const _CardPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    const double spacing = 70.0;
    for (double y = 0.0; y < size.height + spacing; y += spacing) {
      for (double x = 0.0; x < size.width + spacing; x += spacing) {
        canvas.save();
        canvas.translate(x, y);
        final double s = 45.0 / 14;
        final Path path = Path()
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
  bool shouldRepaint(_CardPatternPainter old) => old.color != color;
}
