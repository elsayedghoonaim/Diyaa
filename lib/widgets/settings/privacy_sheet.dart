import 'dart:ui' as ui show TextDirection;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';

class PrivacySheet extends StatelessWidget {
  const PrivacySheet({super.key});

  static const List<Map<String, String>> _privacyEn = [
    {'heading': 'Information We Collect', 'body': 'Diyaa collects only the data necessary to provide your personalised Azkar experience: your in-app progress, streak history, and notification preferences. We do not collect your name, email, or any personally identifiable information.'},
    {'heading': 'How We Use Your Data', 'body': 'Your data is used solely to track your spiritual journey progress, restore your streak and achievements, and deliver prayer-time notifications at the times you configure. We never sell, share, or monetise your personal data.'},
    {'heading': 'Location Data', 'body': 'If you enable GPS location, Diyaa uses your device location only to compute accurate prayer times. Location data is processed on-device and is never transmitted to our servers or stored beyond the current session.'},
    {'heading': 'Third-Party Services', 'body': 'Diyaa does not embed third-party analytics, advertising SDKs, or social trackers. The app functions fully offline after initial download.'},
    {'heading': 'Contact Us', 'body': 'For privacy enquiries, write to us at privacy@diyaa-app.io. We respond to all requests within 72 hours.'},
  ];

  static const List<Map<String, String>> _privacyAr = [
    {'heading': 'المعلومات التي نجمعها', 'body': 'يجمع تطبيق ضياء فقط البيانات اللازمة لتقديم تجربة الأذكار المخصصة لك: تقدمك داخل التطبيق، وسجل سلسلتك اليومية، وتفضيلات الإشعارات. لا نجمع اسمك أو بريدك الإلكتروني أو أي معلومات تعريفية شخصية.'},
    {'heading': 'كيف نستخدم بياناتك', 'body': 'تُستخدم بياناتك حصريًا لتتبع تقدمك في رحلتك الروحية، واستعادة سلسلتك وإنجازاتك، وإرسال إشعارات أوقات الصلاة في الأوقات التي تحددها. نحن لا نبيع أو نشارك أو نستثمر بياناتك الشخصية أبدًا.'},
    {'heading': 'بيانات الموقع', 'body': 'إذا قمت بتفعيل موقع GPS، يستخدم تطبيق ضياء موقع جهازك فقط لحساب مواقيت الصلاة الدقيقة. تتم معالجة بيانات الموقع على الجهاز ولا تُرسل أبدًا إلى خوادمنا أو تُخزّن بعد انتهاء الجلسة الحالية.'},
    {'heading': 'خدمات الطرف الثالث', 'body': 'لا يتضمن تطبيق ضياء أي تحليلات من أطراف ثالثة أو حزم SDK إعلانية أو متتبعات اجتماعية. يعمل التطبيق بالكامل دون اتصال بالإنترنت بعد التنزيل الأولي.'},
    {'heading': 'تواصل معنا', 'body': 'للاستفسارات المتعلقة بالخصوصية، راسلنا على privacy@diyaa-app.io. نرد على جميع الطلبات خلال 72 ساعة.'},
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final dark = provider.darkMode;
    final arabic = provider.arabicMode;

    final bg = dark ? AppColors.bgDark : AppColors.bgLight;
    final cardBg = dark ? AppColors.cardBgDark : AppColors.cardBgLight;
    final border = dark ? AppColors.borderDark : AppColors.borderLight;
    final textSecondary = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final teal = dark ? AppColors.accentTealDark : AppColors.accentTealLight;
    final gold = dark ? AppColors.accentGoldDark : AppColors.accentGoldLight;

    final sections = arabic ? _privacyAr : _privacyEn;

    return Directionality(
      textDirection: arabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.82),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: const [
            BoxShadow(color: Color(0x2E000000), blurRadius: 40, offset: Offset(0, -8)),
          ],
        ),
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(width: 36, height: 4, decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(2))),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سياسة الخصوصية',
                        style: GoogleFonts.amiri(fontSize: 24, color: gold),
                      ),
                      if (!arabic) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Privacy Policy · Last updated 1 May 2026',
                          style: TextStyle(fontSize: 11, color: textSecondary, letterSpacing: 0.4),
                        ),
                      ]
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: cardBg, border: Border.all(color: border)),
                      child: Icon(Icons.close, size: 14, color: textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...sections.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s['heading']!,
                            style: arabic 
                                ? GoogleFonts.amiri(fontSize: 13, fontWeight: FontWeight.w700, color: teal, letterSpacing: 0.3)
                                : TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: teal, letterSpacing: 0.3),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s['body']!,
                            style: arabic 
                                ? GoogleFonts.amiri(fontSize: 13, color: textSecondary, height: 1.75)
                                : TextStyle(fontSize: 13, color: textSecondary, height: 1.75),
                          ),
                        ],
                      ),
                    )),
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'بِسْمِ اللَّهِ',
                            style: GoogleFonts.amiri(fontSize: 18, color: gold, height: 1.2),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Diyaa — Made with care for the Ummah',
                            style: TextStyle(fontSize: 11, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
