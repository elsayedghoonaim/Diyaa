import 'package:diyaa_app/features/settings/presentation/manager/settings_cubit.dart';
import 'package:diyaa_app/features/settings/presentation/manager/settings_state.dart';
import 'package:diyaa_app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Full-screen Islamic geometric star pattern painted as a background.
/// Pattern tile: 60×60, 16-point star + center circle.
class IslamicPatternPainter extends CustomPainter {
  final bool dark;

  IslamicPatternPainter({required this.dark});

  // Star path from the design: M30 5 L35 20 L50 15 L40 27 L55 30 L40 33 L50 45 L35 40 L30 55 L25 40 L10 45 L20 33 L5 30 L20 27 L10 15 L25 20 Z
  static final Path _starPath = () {
    final p = Path();
    p.moveTo(30, 5);  p.lineTo(35, 20); p.lineTo(50, 15); p.lineTo(40, 27);
    p.lineTo(55, 30); p.lineTo(40, 33); p.lineTo(50, 45); p.lineTo(35, 40);
    p.lineTo(30, 55); p.lineTo(25, 40); p.lineTo(10, 45); p.lineTo(20, 33);
    p.lineTo(5,  30); p.lineTo(20, 27); p.lineTo(10, 15); p.lineTo(25, 20);
    p.close();
    return p;
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final tileW = 60.0;
    final tileH = 60.0;

    final starPaint = Paint()
      ..color = (dark ? AppColors.accentTealDark : AppColors.accentTealLight)
          .withValues(alpha: 1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final circlePaint = Paint()
      ..color = (dark ? AppColors.accentGoldDark : AppColors.accentGoldLight)
          .withValues(alpha: 1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    for (double y = 0; y < size.height + tileH; y += tileH) {
      for (double x = 0; x < size.width + tileW; x += tileW) {
        canvas.save();
        canvas.translate(x, y);
        canvas.drawPath(_starPath, starPaint);
        canvas.drawCircle(const Offset(30, 30), 4, circlePaint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(IslamicPatternPainter oldDelegate) =>
      oldDelegate.dark != dark;
}

class IslamicPatternOverlay extends StatelessWidget {
  /// homeScreen uses 0.07 in light, others use 0.06
  final double lightOpacity;

  const IslamicPatternOverlay({super.key, this.lightOpacity = 0.06});

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsCubit>().state;
    final dark = settingsState is SettingsLoaded ? settingsState.settings.darkMode : false;
    return Positioned.fill(
      child: Opacity(
        opacity: dark ? 0.09 : lightOpacity,
        child: CustomPaint(
          painter: IslamicPatternPainter(dark: dark),
        ),
      ),
    );
  }
}