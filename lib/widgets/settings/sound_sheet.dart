import 'dart:ui' as ui show TextDirection;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';
import '../../services/notification_service.dart';

// ─────────────────────────────────────────────
// Sound option data model
// ─────────────────────────────────────────────
class SoundOption {
  final String id;
  final String nameEn;
  final String nameAr;
  final String descEn;
  final String descAr;

  const SoundOption({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.descEn,
    required this.descAr,
  });
}

// ─────────────────────────────────────────────
// Available Salah sounds — extend this list to add more
// ─────────────────────────────────────────────
const kSalahSounds = [
  SoundOption(
    id: 'salah_enhanced',
    nameEn: 'Sound 1',
    nameAr: 'صوت ١',
    descEn: 'Al-Naqshabandi',
    descAr: 'النقشبندي',
  ),
  SoundOption(
    id: 'salah_nabi',
    nameEn: 'Sound 2',
    nameAr: 'صوت ٢',
    descEn: 'Classic',
    descAr: 'كلاسيكي',
  ),
];

// ─────────────────────────────────────────────
// Sound selection bottom sheet
// ─────────────────────────────────────────────
class SoundSheet extends StatefulWidget {
  const SoundSheet({super.key});

  @override
  State<SoundSheet> createState() => _SoundSheetState();
}

class _SoundSheetState extends State<SoundSheet> {
  String? _playingId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final dark     = provider.darkMode;
    final arabic   = provider.arabicMode;

    final bg          = dark ? AppColors.bgDark          : AppColors.bgLight;
    final cardBg      = dark ? AppColors.cardBgDark      : AppColors.cardBgLight;
    final border      = dark ? AppColors.borderDark      : AppColors.borderLight;
    final textPrimary = dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSec     = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final gold        = dark ? AppColors.accentGoldDark  : AppColors.accentGoldLight;

    final selectedId = provider.salahSound;

    return Directionality(
      textDirection: arabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.70,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: const [
            BoxShadow(color: Color(0x30000000), blurRadius: 40, offset: Offset(0, -8)),
          ],
        ),
        child: Column(
          children: [
            // ── Drag handle ──
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        arabic ? 'اختر الصوت' : 'Select Sound',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: gold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        arabic ? 'صوت تذكير الصلاة على النبي' : 'Salah \'ala Al-Nabi reminder sound',
                        style: TextStyle(fontSize: 11, color: textSec),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cardBg,
                        border: Border.all(color: border),
                      ),
                      child: Icon(Icons.close, size: 14, color: textSec),
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: border),

            // ── Sound list ──
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
                itemCount: kSalahSounds.length,
                itemBuilder: (ctx, i) {
                  final sound = kSalahSounds[i];
                  final isSelected = selectedId == sound.id;
                  final isPlaying  = _playingId == sound.id;

                  return GestureDetector(
                    onTap: () async {
                      final soundId = sound.id;
                      // 1. Instantly trigger state update for the spinner/icon
                      setState(() => _playingId = soundId);

                      // 2. Play the preview sound immediately and concurrently
                      NotificationService.previewSalahSound(soundId);

                      // 3. Update the provider settings in the background
                      provider.setSalahSound(soundId);

                      // Clear playing indicator after sound finishes (~5s)
                      Future.delayed(const Duration(seconds: 5), () {
                        if (mounted && _playingId == soundId) {
                          setState(() => _playingId = null);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? gold.withOpacity(dark ? 0.15 : 0.08)
                            : cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? gold : border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Icon / playing indicator
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? gold.withOpacity(0.15)
                                  : (dark ? const Color(0xFF1E2530) : const Color(0xFFF0EDE6)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: isPlaying
                                ? Icon(Icons.volume_up, size: 18, color: gold)
                                : Icon(
                                    Icons.music_note,
                                    size: 18,
                                    color: isSelected ? gold : textSec,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          // Name + description
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  arabic ? sound.nameAr : sound.nameEn,
                                  style: arabic
                                      ? GoogleFonts.amiri(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected ? gold : textPrimary,
                                        )
                                      : TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected ? gold : textPrimary,
                                        ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  arabic ? sound.descAr : sound.descEn,
                                  style: TextStyle(fontSize: 11, color: textSec),
                                ),
                              ],
                            ),
                          ),
                          // Checkmark for selected
                          if (isSelected)
                            Container(
                              width: 22, height: 22,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: gold),
                              child: const Icon(Icons.check, size: 13, color: Colors.white),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}