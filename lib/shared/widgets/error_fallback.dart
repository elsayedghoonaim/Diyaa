import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable premium error screen widget with a retry action.
class ErrorFallback extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isArabic;

  const ErrorFallback({
    super.key,
    required this.message,
    required this.onRetry,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = dark ? const Color(0xFF0F1319) : const Color(0xFFF7F5F0);
    final Color textPrimary = dark ? const Color(0xFFFFFFFF) : const Color(0xFF1E2530);
    final Color secondary = dark ? const Color(0xFF9EAEB8) : const Color(0xFF6B7280);
    final Color gold = dark ? const Color(0xFFD4A84B) : const Color(0xFFB8973A);
    final Color teal = dark ? const Color(0xFF4DB6AC) : const Color(0xFF0B6E6E);
    final Color cardBg = dark ? const Color(0xFF171E28) : const Color(0xFFFFFFFF);
    final Color border = dark ? const Color(0xFF263242) : const Color(0xFFE5E7EB);
    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.wifi_off_rounded,
                  size: 64,
                  color: gold,
                ),
                const SizedBox(height: 24),
                Text(
                  isArabic ? 'عذراً، حدث خطأ ما' : 'Oops, something went wrong',
                  style: GoogleFonts.amiri(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isArabic ? 'إعادة المحاولة' : 'Retry',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
