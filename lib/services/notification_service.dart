import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'prayer_times_service.dart';

/// Robust notification service for Diyaa.
///
/// Fixes over the previous implementation:
///  1. Explicitly creates Android notification channels on init.
///  2. Respects user preferences before scheduling each category.
///  3. Uses DateTimeComponents.time for daily-repeating azkar reminders.
///  4. Adds diagnostic logging so issues are visible in the console.
///  5. Provides granular cancel/reschedule per category.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ── Notification IDs ──────────────────────────────────────────────────────
  // Prayer time notifications:  10-14  (Fajr=10, Dhuhr=11, Asr=12, Maghrib=13, Isha=14)
  // Post-prayer azkar:          20-24
  // Morning azkar:              30
  // Evening azkar:              31
  // Sleep azkar:                32
  // Night/wakeup azkar:         33
  // Streak warning:             40
  // Milestone:                  50
  static const _idPrayerBase       = 10;
  static const _idPostPrayerBase   = 20;
  static const _idMorningAzkar     = 30;
  static const _idEveningAzkar     = 31;
  static const _idSleepAzkar       = 32;
  static const _idNightAzkar       = 33;
  static const _idStreakWarning     = 40;

  // ── Channel IDs ───────────────────────────────────────────────────────────
  static const _channelPrayer  = 'diyaa_prayer';
  static const _channelAzkar   = 'diyaa_azkar';
  static const _channelStreak  = 'diyaa_streak';

  // ── Initialize ─────────────────────────────────────────────────────────────
  static Future<void> initialize() async {
    tz.initializeTimeZones();

    // ── Android settings ──
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // ── iOS / macOS settings ──
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // ── Windows settings ──
    const windowsSettings = WindowsInitializationSettings(
      appName: 'Diyaa',
      appUserModelId: 'com.diyaa.diyaa',
      guid: 'E7B3545A-8A46-4B81-BBCA-747F9EED4E22',
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      windows: windowsSettings,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTapped,
    );

    // ── Create Android notification channels ──
    await _createChannels();

    debugPrint('[Notifications] Service initialized successfully.');
  }

  static Future<void> _createChannels() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
      _channelPrayer,
      'Prayer Times',
      description: 'Reminders for daily prayer times',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ));

    await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
      _channelAzkar,
      'Azkar Reminders',
      description: 'Reminders for morning, evening, and sleep azkar',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ));

    await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
      _channelStreak,
      'Streak & Milestones',
      description: 'Streak warnings and milestone celebrations',
      importance: Importance.defaultImportance,
      playSound: false,
      enableVibration: false,
    ));

    debugPrint('[Notifications] Android channels created.');
  }

  // ── Permission Requests ────────────────────────────────────────────────────
  static Future<void> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final notifGranted = await android.requestNotificationsPermission();
      final alarmGranted = await android.requestExactAlarmsPermission();
      debugPrint('[Notifications] Android — notifications granted: $notifGranted, exact alarms granted: $alarmGranted');
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final result = await ios.requestPermissions(alert: true, badge: true, sound: true);
      debugPrint('[Notifications] iOS permissions granted: $result');
    }
  }

  // ── Master Scheduler ───────────────────────────────────────────────────────
  /// Call this whenever prayer times refresh or user preferences change.
  /// Each category is only scheduled if its corresponding preference is enabled.
  static Future<void> scheduleAll(
    PrayerInfo prayers, {
    required bool isArabic,
    required bool notifPrayer,   // Prayer time reminders
    required bool notifAzkar,    // Azkar reminders (morning/evening/sleep/night)
    required bool notifStreak,   // Streak warnings (future)
  }) async {
    // Cancel everything first for a clean slate
    await cancelAll();

    if (notifPrayer) {
      await _schedulePrayerTimes(prayers, isArabic: isArabic);
    } else {
      debugPrint('[Notifications] Prayer time notifications skipped (disabled by user).');
    }

    if (notifAzkar) {
      await _scheduleAzkarReminders(prayers, isArabic: isArabic);
    } else {
      debugPrint('[Notifications] Azkar reminder notifications skipped (disabled by user).');
    }

    // Streak notifications are scheduled on-demand via scheduleStreakWarning()
    // rather than at prayer-time refresh, so nothing to do here unless flag is on.
    if (!notifStreak) {
      await _plugin.cancel(id: _idStreakWarning);
      debugPrint('[Notifications] Streak warning notification cancelled (disabled by user).');
    }
  }

  // ── Prayer Time Notifications ──────────────────────────────────────────────
  static Future<void> _schedulePrayerTimes(PrayerInfo prayers, {required bool isArabic}) async {
    final prayerData = [
      (id: _idPrayerBase + 0, time: prayers.fajr,    nameAr: 'الفجر',   nameEn: 'Fajr'),
      (id: _idPrayerBase + 1, time: prayers.dhuhr,   nameAr: 'الظهر',   nameEn: 'Dhuhr'),
      (id: _idPrayerBase + 2, time: prayers.asr,     nameAr: 'العصر',   nameEn: 'Asr'),
      (id: _idPrayerBase + 3, time: prayers.maghrib, nameAr: 'المغرب',  nameEn: 'Maghrib'),
      (id: _idPrayerBase + 4, time: prayers.isha,    nameAr: 'العشاء',  nameEn: 'Isha'),
    ];

    for (final p in prayerData) {
      await _scheduleDailyNotification(
        id: p.id,
        channelId: _channelPrayer,
        channelName: 'Prayer Times',
        title: isArabic
            ? 'حان الآن موعد صلاة ${p.nameAr} 🕌'
            : 'It is time for ${p.nameEn} prayer 🕌',
        body: isArabic
            ? 'أرحنا بها يا بلال. لا تنس أداء الصلاة في وقتها.'
            : "Time to pray. Don't forget to perform your prayer on time.",
        scheduledTime: p.time,
      );
    }

    // Post-prayer azkar (15 min after each prayer)
    for (int i = 0; i < prayerData.length; i++) {
      final p = prayerData[i];
      await _scheduleDailyNotification(
        id: _idPostPrayerBase + i,
        channelId: _channelAzkar,
        channelName: 'Azkar Reminders',
        title: isArabic
            ? 'أذكار ما بعد صلاة ${p.nameAr} 📿'
            : 'Post-${p.nameEn} Azkar 📿',
        body: isArabic
            ? 'تقبل الله صلاتك! لا تنس أذكار ما بعد الصلاة.'
            : 'May Allah accept your prayer! Time for your post-prayer supplications.',
        scheduledTime: p.time.add(const Duration(minutes: 15)),
      );
    }

    debugPrint('[Notifications] Scheduled ${prayerData.length} prayer + ${prayerData.length} post-prayer notifications.');
  }

  // ── Azkar Reminders ────────────────────────────────────────────────────────
  static Future<void> _scheduleAzkarReminders(PrayerInfo prayers, {required bool isArabic}) async {
    // Morning: 30 min after Fajr
    await _scheduleDailyNotification(
      id: _idMorningAzkar,
      channelId: _channelAzkar,
      channelName: 'Azkar Reminders',
      title: isArabic ? 'أذكار الصباح 🌅' : 'Morning Azkar 🌅',
      body: isArabic
          ? 'ابدأ يومك بنور الذكر. حان وقت أذكار الصباح.'
          : 'Start your day with remembrance. Time for your Morning Azkar.',
      scheduledTime: prayers.fajr.add(const Duration(minutes: 30)),
    );

    // Evening: 30 min after Asr
    await _scheduleDailyNotification(
      id: _idEveningAzkar,
      channelId: _channelAzkar,
      channelName: 'Azkar Reminders',
      title: isArabic ? 'أذكار المساء 🌇' : 'Evening Azkar 🌇',
      body: isArabic
          ? 'لا تنس أذكار المساء. اجعل ختام يومك ذكراً.'
          : 'Protect yourself until the morning. Time for your Evening Azkar.',
      scheduledTime: prayers.asr.add(const Duration(minutes: 30)),
    );

    // Sleep: 30 min after Isha
    await _scheduleDailyNotification(
      id: _idSleepAzkar,
      channelId: _channelAzkar,
      channelName: 'Azkar Reminders',
      title: isArabic ? 'أذكار النوم 🌙' : 'Sleep Azkar 🌙',
      body: isArabic
          ? 'اختم يومك بذكر الله لتنام في طمأنينة.'
          : 'End your day with remembrance of Allah for a peaceful sleep.',
      scheduledTime: prayers.isha.add(const Duration(minutes: 30)),
    );

    // Night/Wakeup: 30 min before Fajr
    await _scheduleDailyNotification(
      id: _idNightAzkar,
      channelId: _channelAzkar,
      channelName: 'Azkar Reminders',
      title: isArabic ? 'قيام الليل 🌌' : 'Night Azkar 🌌',
      body: isArabic
          ? 'إن ربك ينزل إلى السماء الدنيا في هذا الوقت، فاذكره وادعه.'
          : 'The last third of the night is a time of blessing. Make dua.',
      scheduledTime: prayers.fajr.subtract(const Duration(minutes: 30)),
    );

    debugPrint('[Notifications] Scheduled 4 azkar reminder notifications.');
  }

  // ── Streak Warning ──────────────────────────────────────────────────────────
  /// Call this when the user hasn't completed a session and it's getting late.
  static Future<void> scheduleStreakWarning({
    required bool enabled,
    required bool isArabic,
    required int currentStreak,
  }) async {
    await _plugin.cancel(id: _idStreakWarning);
    if (!enabled || currentStreak == 0) return;

    // Fire 2 hours before midnight if streak is at risk
    final now = DateTime.now();
    var warningTime = DateTime(now.year, now.month, now.day, 21, 0); // 9 PM
    if (warningTime.isBefore(now)) {
      warningTime = warningTime.add(const Duration(days: 1));
    }

    await _scheduleDailyNotification(
      id: _idStreakWarning,
      channelId: _channelStreak,
      channelName: 'Streak & Milestones',
      title: isArabic
          ? 'لا تكسر سلسلتك 🔥 ($currentStreak يوم)'
          : 'Don\'t break your streak! 🔥 ($currentStreak days)',
      body: isArabic
          ? 'لا تزال أذكار اليوم في انتظارك. حافظ على سلسلتك!'
          : 'Your daily Azkar are still waiting. Keep your streak alive!',
      scheduledTime: warningTime,
    );

    debugPrint('[Notifications] Streak warning scheduled for $warningTime.');
  }

  // ── Instant Milestone Notification ─────────────────────────────────────────
  static Future<void> showMilestoneNotification({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id: 50, // milestone ID
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelStreak,
          'Streak & Milestones',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: false,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
    debugPrint('[Notifications] Milestone notification shown: $title');
  }

  // ── Cancel ──────────────────────────────────────────────────────────────────
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
    debugPrint('[Notifications] All notifications cancelled.');
  }

  static Future<void> cancelPrayerNotifications() async {
    for (int i = 0; i < 5; i++) {
      await _plugin.cancel(id: _idPrayerBase + i);
      await _plugin.cancel(id: _idPostPrayerBase + i);
    }
  }

  // ── Core Scheduler ──────────────────────────────────────────────────────────
  static Future<void> _scheduleDailyNotification({
    required int id,
    required String channelId,
    required String channelName,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      // Ensure we always schedule for a future time
      final now = DateTime.now();
      var fireAt = scheduledTime;
      if (fireAt.isBefore(now)) {
        fireAt = fireAt.add(const Duration(days: 1));
      }

      final tzTime = tz.TZDateTime.from(fireAt, tz.local);

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzTime,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: const BigTextStyleInformation(''),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // Repeat daily at the same time
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('[Notifications] Scheduled id=$id at $fireAt — "$title"');
    } catch (e) {
      debugPrint('[Notifications] ERROR scheduling id=$id: $e');
    }
  }

  // ── Notification tap handlers ───────────────────────────────────────────────
  static void _onNotificationTapped(NotificationResponse details) {
    debugPrint('[Notifications] Tapped: payload=${details.payload}, id=${details.id}');
    // Future: navigate to relevant screen based on payload
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse details) {
    debugPrint('[Notifications] Background tap: payload=${details.payload}');
  }
}
