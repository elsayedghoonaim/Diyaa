import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_scheduler.dart' as scheduler;
import 'prayer_times_service.dart';
import 'timezone_helper.dart' as tz_helper;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ── IDs ───────────────────────────────────────────────────────────────────
  static const int _idPrayerBase     = 10;
  static const int _idPostPrayerBase = 20;
  static const int _idMorningAzkar   = 30;
  static const int _idEveningAzkar   = 31;
  static const int _idSleepAzkar     = 32;
  static const int _idNightAzkar     = 33;
  static const int _idStreakWarning  = 40;

  // ── Channels ──────────────────────────────────────────────────────────────
  static const String _channelPrayer = 'diyaa_prayer';
  static const String _channelAzkar  = 'diyaa_azkar';
  static const String _channelStreak = 'diyaa_streak';

  static bool get _isMobile =>
      !kIsWeb && !Platform.isWindows && !Platform.isLinux;

  // ══════════════════════════════════════════════════════════════════════════
  // INITIALIZE
  // ══════════════════════════════════════════════════════════════════════════
  static Future<void> initialize() async {
    tz.initializeTimeZones();
    await _initTimezone();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const windowsSettings = WindowsInitializationSettings(
      appName: 'Diyaa',
      appUserModelId: 'com.diyaa.diyaa',
      guid: 'E7B3545A-8A46-4B81-BBCA-747F9EED4E22',
    );

    final ok = await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        windows: windowsSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationTapped,
    );

    if (_isMobile) await _createAndroidChannels();
    debugPrint('[Notifications] Initialized (ok=$ok). Mobile: $_isMobile');
  }

  static Future<void> _initTimezone() async {
    try {
      if (!_isMobile) {
        tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
        debugPrint('[Notifications] Dev platform → Africa/Cairo');
        return;
      }
      final String tzName = await tz_helper.getDeviceTimezone();
      tz.setLocalLocation(tz.getLocation(tzName));
      debugPrint('[Notifications] Timezone: $tzName');
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
      debugPrint('[Notifications] Timezone fallback → Africa/Cairo: $e');
    }
  }

  static Future<void> _createAndroidChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    for (final ch in [
      const AndroidNotificationChannel(
        _channelPrayer, 'Prayer Times',
        description: 'Reminders for daily prayer times',
        importance: Importance.high,
        playSound: true, enableVibration: true,
      ),
      const AndroidNotificationChannel(
        _channelAzkar, 'Azkar Reminders',
        description: 'Reminders for morning, evening, and sleep azkar',
        importance: Importance.high,
        playSound: true, enableVibration: true,
      ),
      const AndroidNotificationChannel(
        _channelStreak, 'Streak & Milestones',
        description: 'Streak warnings and milestone celebrations',
        importance: Importance.defaultImportance,
        playSound: false, enableVibration: false,
      ),
    ]) {
      await android.createNotificationChannel(ch);
    }
    debugPrint('[Notifications] Android channels created.');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PERMISSIONS
  // ══════════════════════════════════════════════════════════════════════════
  static Future<void> requestPermissions() async {
    if (!_isMobile) return;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final notif = await android.requestNotificationsPermission();
      // On Android 14+, SCHEDULE_EXACT_ALARM is denied by default.
      // Check before requesting to avoid unnecessary system-settings redirect.
      bool? canExact = await android.canScheduleExactNotifications();
      if (canExact != true) {
        await android.requestExactAlarmsPermission();
        // Re-check after the user returns from system settings
        canExact = await android.canScheduleExactNotifications();
      }
      debugPrint('[Notifications] Android — notif: $notif, exactAlarms: $canExact');
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final ok = await ios.requestPermissions(
          alert: true, badge: true, sound: true);
      debugPrint('[Notifications] iOS perms: $ok');
    }
  }

  /// Whether exact alarms can be scheduled on the current platform.
  /// Returns false on non-mobile or when Android has revoked the permission.
  static Future<bool> canScheduleExact() async {
    if (!_isMobile) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.canScheduleExactNotifications() ?? false;
    }
    return true; // iOS always supports scheduled notifications
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MASTER SCHEDULER
  // ══════════════════════════════════════════════════════════════════════════
  static Future<void> scheduleAll(
    PrayerInfo prayers, {
    required bool isArabic,
    required bool notifPrayer,
    required bool notifAzkar,
    required bool notifStreak,
    int currentStreak = 0,
  }) async {
    if (!_isMobile) {
      debugPrint('[Notifications] scheduleAll skipped on non-mobile platform.');
      return;
    }

    await _cancelAll();

    if (notifPrayer) await _schedulePrayerTimes(prayers, isArabic: isArabic);
    if (notifAzkar)  await _scheduleAzkarReminders(prayers, isArabic: isArabic);

    // FIX: _cancelAll() wiped the streak notification — always reschedule it.
    // Previously this only canceled when notifStreak was false, but never
    // recreated the notification after the cancelAll() above destroyed it.
    await scheduleStreakWarning(
      enabled: notifStreak,
      isArabic: isArabic,
      currentStreak: currentStreak,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PRAYER  (IDs 10–14)
  // ══════════════════════════════════════════════════════════════════════════
  static Future<void> _schedulePrayerTimes(
    PrayerInfo prayers, {required bool isArabic}) async {
    final list = [
      (id: _idPrayerBase + 0, time: prayers.fajr,    ar: 'الفجر',  en: 'Fajr'),
      (id: _idPrayerBase + 1, time: prayers.dhuhr,   ar: 'الظهر',  en: 'Dhuhr'),
      (id: _idPrayerBase + 2, time: prayers.asr,     ar: 'العصر',  en: 'Asr'),
      (id: _idPrayerBase + 3, time: prayers.maghrib, ar: 'المغرب', en: 'Maghrib'),
      (id: _idPrayerBase + 4, time: prayers.isha,    ar: 'العشاء', en: 'Isha'),
    ];
    for (final p in list) {
      await _schedule(
        id: p.id, channelId: _channelPrayer, channelName: 'Prayer Times',
        title: isArabic ? 'حان الآن موعد صلاة ${p.ar} 🕌'
                        : 'It is time for ${p.en} prayer 🕌',
        body: isArabic
            ? 'أرحنا بها يا بلال. لا تنس أداء الصلاة في وقتها.'
            : "Time to pray. Don't forget to perform your prayer on time.",
        scheduledTime: p.time,
      );
    }
    debugPrint('[Notifications] Scheduled 5 prayer notifications.');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AZKAR  (IDs 20–24, 30–33)
  // Post-prayer azkar live here so they respect the notifAzkar flag.
  // ══════════════════════════════════════════════════════════════════════════
  static Future<void> _scheduleAzkarReminders(
    PrayerInfo prayers, {required bool isArabic}) async {
    final list = [
      (time: prayers.fajr,    ar: 'الفجر',  en: 'Fajr'),
      (time: prayers.dhuhr,   ar: 'الظهر',  en: 'Dhuhr'),
      (time: prayers.asr,     ar: 'العصر',  en: 'Asr'),
      (time: prayers.maghrib, ar: 'المغرب', en: 'Maghrib'),
      (time: prayers.isha,    ar: 'العشاء', en: 'Isha'),
    ];

    for (int i = 0; i < list.length; i++) {
      final p = list[i];
      await _schedule(
        id: _idPostPrayerBase + i,
        channelId: _channelAzkar, channelName: 'Azkar Reminders',
        title: isArabic ? 'أذكار ما بعد صلاة ${p.ar} 📿'
                        : 'Post-${p.en} Azkar 📿',
        body: isArabic
            ? 'تقبل الله صلاتك! لا تنس أذكار ما بعد الصلاة.'
            : 'May Allah accept your prayer! Time for post-prayer supplications.',
        scheduledTime: p.time.add(const Duration(minutes: 15)),
      );
    }

    await _schedule(
      id: _idMorningAzkar,
      channelId: _channelAzkar, channelName: 'Azkar Reminders',
      title: isArabic ? 'أذكار الصباح 🌅' : 'Morning Azkar 🌅',
      body:  isArabic ? 'ابدأ يومك بنور الذكر. حان وقت أذكار الصباح.'
                      : 'Start your day with remembrance. Time for Morning Azkar.',
      scheduledTime: prayers.fajr.add(const Duration(minutes: 30)),
    );

    await _schedule(
      id: _idEveningAzkar,
      channelId: _channelAzkar, channelName: 'Azkar Reminders',
      title: isArabic ? 'أذكار المساء 🌇' : 'Evening Azkar 🌇',
      body:  isArabic ? 'لا تنس أذكار المساء. اجعل ختام يومك ذكراً.'
                      : 'Protect yourself until morning. Time for Evening Azkar.',
      scheduledTime: prayers.asr.add(const Duration(minutes: 30)),
    );

    await _schedule(
      id: _idSleepAzkar,
      channelId: _channelAzkar, channelName: 'Azkar Reminders',
      title: isArabic ? 'أذكار النوم 🌙' : 'Sleep Azkar 🌙',
      body:  isArabic ? 'اختم يومك بذكر الله لتنام في طمأنينة.'
                      : 'End your day with remembrance of Allah for peaceful sleep.',
      scheduledTime: prayers.isha.add(const Duration(minutes: 30)),
    );

    await _schedule(
      id: _idNightAzkar,
      channelId: _channelAzkar, channelName: 'Azkar Reminders',
      title: isArabic ? 'قيام الليل 🌌' : 'Night Azkar 🌌',
      body:  isArabic ? 'إن ربك ينزل إلى السماء الدنيا في هذا الوقت، فاذكره وادعه.'
                      : 'The last third of the night is a time of blessing. Make dua.',
      scheduledTime: prayers.fajr.subtract(const Duration(minutes: 30)),
    );

    debugPrint('[Notifications] Scheduled 9 azkar notifications.');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STREAK WARNING  (ID 40)
  // ══════════════════════════════════════════════════════════════════════════
  static Future<void> scheduleStreakWarning({
    required bool enabled,
    required bool isArabic,
    required int currentStreak,
  }) async {
    if (!_isMobile) return;
    await _cancelOne(_idStreakWarning);
    if (!enabled || currentStreak == 0) return;

    final now = DateTime.now();
    var fireAt = DateTime(now.year, now.month, now.day, 21, 0);
    if (fireAt.isBefore(now)) fireAt = fireAt.add(const Duration(days: 1));

    await _schedule(
      id: _idStreakWarning,
      channelId: _channelStreak, channelName: 'Streak & Milestones',
      title: isArabic ? 'لا تكسر سلسلتك 🔥 ($currentStreak يوم)'
                      : "Don't break your streak! 🔥 ($currentStreak days)",
      body:  isArabic ? 'لا تزال أذكار اليوم في انتظارك. حافظ على سلسلتك!'
                      : 'Your daily Azkar are waiting. Keep your streak alive!',
      scheduledTime: fireAt,
    );
    debugPrint('[Notifications] Streak warning scheduled for $fireAt.');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TEST NOTIFICATION — fires immediately to verify the pipeline works.
  // Call from settings or on startup for debugging.
  // ══════════════════════════════════════════════════════════════════════════
  static Future<void> sendTestNotification() async {
    try {
      debugPrint('[Notifications] Sending test notification…');
      await _plugin.show(
        id: 99,
        title: 'Diyaa Test ✅',
        body: 'If you see this, notifications are working!',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelPrayer,
            'Prayer Times',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      debugPrint('[Notifications] Test notification sent successfully.');
    } catch (e) {
      debugPrint('[Notifications] TEST FAILED: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MILESTONE  (ID 50)
  // ══════════════════════════════════════════════════════════════════════════
  static Future<void> showMilestoneNotification({
    required String title,
    required String body,
  }) async {
    if (!_isMobile) return;
    await scheduler.showNotification(
      _plugin,
      id: 50, title: title, body: body,
      channelId: _channelStreak, channelName: 'Streak & Milestones',
    );
    debugPrint('[Notifications] Milestone shown: $title');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CANCEL  — delegates to scheduler (no positional args on Windows)
  // ══════════════════════════════════════════════════════════════════════════
  static Future<void> _cancelAll() async =>
      scheduler.cancelAllNotifications(_plugin);

  static Future<void> _cancelOne(int id) async =>
      scheduler.cancelNotification(_plugin, id);

  static Future<void> cancelPrayerNotifications() async {
    for (int i = 0; i < 5; i++) await _cancelOne(_idPrayerBase + i);
  }

  static Future<void> cancelAzkarNotifications() async {
    for (int i = 0; i < 5; i++) await _cancelOne(_idPostPrayerBase + i);
    await _cancelOne(_idMorningAzkar);
    await _cancelOne(_idEveningAzkar);
    await _cancelOne(_idSleepAzkar);
    await _cancelOne(_idNightAzkar);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CORE — delegates to scheduler
  // ══════════════════════════════════════════════════════════════════════════
  static Future<void> _schedule({
    required int id,
    required String channelId,
    required String channelName,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      var fireAt = scheduledTime;
      if (fireAt.isBefore(DateTime.now())) {
        fireAt = fireAt.add(const Duration(days: 1));
      }
      final tzTime = tz.TZDateTime.from(fireAt, tz.local);
      await scheduler.scheduleNotification(
        _plugin,
        id: id, channelId: channelId, channelName: channelName,
        title: title, body: body, tzTime: tzTime,
      );
      debugPrint('[Notifications] id=$id scheduled at $fireAt');
    } catch (e) {
      debugPrint('[Notifications] ERROR id=$id: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAP HANDLERS
  // ══════════════════════════════════════════════════════════════════════════
  static void _onNotificationTapped(NotificationResponse r) =>
      debugPrint('[Notifications] Tap: id=${r.id}');

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse r) =>
      debugPrint('[Notifications] BG tap: payload=${r.payload}');
}