import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/arabic_utils.dart' as ar;
import '../../../../features/settings/presentation/manager/settings_cubit.dart';
import '../../../../features/settings/presentation/manager/settings_state.dart';
import '../../presentation/manager/progress_cubit.dart';
import '../../presentation/manager/progress_state.dart';
import 'package:diyaa_app/theme/app_colors.dart';

class CelebrationScreen extends StatefulWidget {
  final String sessionId;
  final String sessionNameAr;
  final String sessionNameEn;
  final int zikrCount;
  final int pointsEarned;

  const CelebrationScreen({
    super.key,
    required this.sessionId,
    required this.sessionNameAr,
    required this.sessionNameEn,
    required this.zikrCount,
    this.pointsEarned = 100,
  });

  @override
  State<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends State<CelebrationScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _contentController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _pulseAnim;

  final List<_ConfettiParticle> _particles = <_ConfettiParticle>[];
  final math.Random _rng = math.Random();

  bool _showXP = false;
  bool _showStreak = false;
  bool _showButton = false;
  int _displayedXP = 0;

  @override
  void initState() {
    super.initState();

    Future<void>.microtask(() {
      if (mounted) {
        final SettingsState settingsState = context.read<SettingsCubit>().state;
        if (settingsState is SettingsLoaded && settingsState.settings.soundEnabled) {
          HapticFeedback.heavyImpact();
        }
      }
    });

    for (int i = 0; i < 60; i++) {
      _particles.add(_ConfettiParticle(
        x: _rng.nextDouble(),
        y: -_rng.nextDouble() * 0.3,
        size: 4 + _rng.nextDouble() * 8,
        speed: 0.3 + _rng.nextDouble() * 0.7,
        rotation: _rng.nextDouble() * math.pi * 2,
        rotSpeed: (_rng.nextDouble() - 0.5) * 0.1,
        color: <Color>[
          const Color(0xFF4DB6AC),
          const Color(0xFFD4A84B),
          const Color(0xFF81C784),
          const Color(0xFFFFD54F),
          const Color(0xFF4FC3F7),
          const Color(0xFFBA68C8),
        ][_rng.nextInt(6)],
        shape: _rng.nextInt(3),
      ));
    }

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..forward();

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: const Interval(0.0, 0.5)),
    );
    _slideAnim = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _contentController.forward();
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _showXP = true);
      }
      _animateXP();
    });
    Future<void>.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() => _showStreak = true);
      }
    });
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => _showButton = true);
      }
    });
  }

  void _animateXP() {
    Timer.periodic(const Duration(milliseconds: 20), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _displayedXP += 5;
        if (_displayedXP >= widget.pointsEarned) {
          _displayedXP = widget.pointsEarned;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _contentController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SettingsState settingsState = context.watch<SettingsCubit>().state;
    final ProgressState progressState = context.watch<ProgressCubit>().state;

    if (settingsState is! SettingsLoaded || progressState is! ProgressLoaded) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final bool dark = settingsState.settings.darkMode;
    final bool arabic = settingsState.settings.arabicMode;
    final bool soundEnabled = settingsState.settings.soundEnabled;

    final Color bg = dark ? AppColors.bgDark : AppColors.bgLight;
    final Color teal = dark ? AppColors.accentTealDark : AppColors.accentTealLight;
    final Color gold = dark ? AppColors.accentGoldDark : AppColors.accentGoldLight;
    final Color textSecondary = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final int streak = progressState.progress.streak;
    final int totalPoints = progressState.progress.totalPoints;

    String t(String en, String arVal) => ar.localise(en, arVal, isArabic: arabic);

    return Directionality(
      textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: <Widget>[
            AnimatedBuilder(
              animation: _confettiController,
              builder: (BuildContext context, Widget? child) {
                return CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: _ConfettiPainter(
                    particles: _particles,
                    progress: _confettiController.value,
                  ),
                );
              },
            ),
            SafeArea(
              child: Center(
                child: AnimatedBuilder(
                  animation: _contentController,
                  builder: (BuildContext context, Widget? child) {
                    return Opacity(
                      opacity: _fadeAnim.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnim.value),
                        child: child,
                      ),
                    );
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const SizedBox(height: 40),
                        AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (BuildContext context, Widget? child) {
                            return Transform.scale(
                              scale: _scaleAnim.value * _pulseAnim.value,
                              child: child,
                            );
                          },
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: <Color>[teal, teal.withValues(alpha: 0.7)],
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: teal.withValues(alpha: 0.4),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 60,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'ما شاء الله',
                          style: GoogleFonts.amiri(
                            fontSize: 36,
                            color: gold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t('Session Complete!', 'أكملت الجلسة!'),
                          style: TextStyle(
                            fontSize: 16,
                            color: textSecondary,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: teal.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: teal.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            children: <Widget>[
                              Text(
                                widget.sessionNameAr,
                                style: GoogleFonts.amiri(
                                  fontSize: 20,
                                  color: teal,
                                ),
                              ),
                              if (!arabic)
                                Text(
                                  widget.sessionNameEn,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondary,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.zikrCount} ${t('Adhkar completed', 'ذكراً')}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        AnimatedOpacity(
                          opacity: _showXP ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 400),
                          child: AnimatedSlide(
                            offset: _showXP ? Offset.zero : const Offset(0, 0.3),
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                            child: _buildStatCard(
                              icon: Icons.auto_awesome,
                              iconColor: gold,
                              label: t('Points Earned', 'نقاط مكتسبة'),
                              value: '+$_displayedXP PTS',
                              valueColor: gold,
                              dark: dark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        AnimatedOpacity(
                          opacity: _showStreak ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 400),
                          child: AnimatedSlide(
                            offset: _showStreak ? Offset.zero : const Offset(0, 0.3),
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                            child: _buildStatCard(
                              icon: Icons.local_fire_department_rounded,
                              iconColor: const Color(0xFFFF6D00),
                              label: t('Day Streak', 'أيام متتالية'),
                              value: '$streak ${t('days', 'يوم')}',
                              valueColor: const Color(0xFFFF6D00),
                              dark: dark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        AnimatedOpacity(
                          opacity: _showStreak ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 400),
                          child: AnimatedSlide(
                            offset: _showStreak ? Offset.zero : const Offset(0, 0.3),
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                            child: _buildStatCard(
                              icon: Icons.diamond_outlined,
                              iconColor: teal,
                              label: t('Total Points', 'مجموع النقاط'),
                              value: '$totalPoints PTS',
                              valueColor: teal,
                              dark: dark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),
                        AnimatedOpacity(
                          opacity: _showButton ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 500),
                          child: AnimatedSlide(
                            offset: _showButton ? Offset.zero : const Offset(0, 0.5),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (soundEnabled) {
                                    HapticFeedback.lightImpact();
                                  }
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: teal,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  t('CONTINUE', 'متابعة'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        AnimatedOpacity(
                          opacity: _showButton ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            t(
                              '"Whoever reads his daily Adhkar has fortified himself."',
                              '«من حافظ على أذكاره فقد حصّن نفسه»',
                            ),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.amiri(
                              fontSize: 13,
                              color: textSecondary.withValues(alpha: 0.7),
                              fontStyle: FontStyle.italic,
                              height: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
    required bool dark,
  }) {
    final Color cardBg = dark ? AppColors.cardBgDark : AppColors.cardBgLight;
    final Color borderColor = dark ? AppColors.borderDark : AppColors.borderLight;
    final Color textSec = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: textSec),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiParticle {
  double x, y, size, speed, rotation, rotSpeed;
  Color color;
  int shape;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.rotation,
    required this.rotSpeed,
    required this.color,
    required this.shape,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double opacity = progress > 0.7 ? (1.0 - progress) / 0.3 : 1.0;

    for (final _ConfettiParticle p in particles) {
      final Paint paint = Paint()..color = p.color.withValues(alpha: opacity * 0.85);

      final double px = p.x * size.width;
      final double py = p.y * size.height + progress * size.height * p.speed * 1.5;
      final double wobble = math.sin(progress * math.pi * 4 + p.rotation) * 20;

      canvas.save();
      canvas.translate(px + wobble, py);
      canvas.rotate(p.rotation + progress * p.rotSpeed * math.pi * 8);

      switch (p.shape) {
        case 0:
          canvas.drawCircle(Offset.zero, p.size / 2, paint);
          break;
        case 1:
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size),
            paint,
          );
          break;
        case 2:
          final Path path = Path()
            ..moveTo(0, -p.size / 2)
            ..lineTo(p.size / 3, 0)
            ..lineTo(0, p.size / 2)
            ..lineTo(-p.size / 3, 0)
            ..close();
          canvas.drawPath(path, paint);
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}
