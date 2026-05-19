import 'dart:io' show Platform;
import 'dart:async' show Timer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
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
  static const int _idPrayerBase      = 10;
  static const int _idPostPrayerBase  = 20;
  // ID 21 is reserved for post-Dhuhr (Mon–Thu, Sat–Sun daily)
  // ID 25 is the weekly Jumu'ah post-prayer azkar (Friday only)
  static const int _idJumuah          = 25;
  static const int _idMorningAzkar    = 30;
  static const int _idEveningAzkar    = 31;
  static const int _idSleepAzkar      = 32;
  static const int _idNightAzkar      = 33;
  static const int _idStreakWarning   = 40;

  // Al-Salah 'ala Al-Nabi IDs — expanded to handle custom intervals down to 1-5 mins
  static const int _idSalahBase       = 60;
  static const int _idSalahMax        = 400; // Allow up to 341 slots

  // ── Channels ──────────────────────────────────────────────────────────────
  static const String _channelPrayer  = 'diyaa_prayer';
  static const String _channelAzkar   = 'diyaa_azkar';
  static const String _channelStreak  = 'diyaa_streak';

  // ── Native Alarm MethodChannel ─────────────────────────────────────────────
  // FIX (A5): MethodChannel for native Android AlarmManager + MediaPlayer.
  // Bypasses the unreliable notification channel sound mechanism for scheduled
  // reminders by playing the sound directly via native MediaPlayer.
  static const MethodChannel _alarmChannel = MethodChannel('diyaa_alarm_channel');

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

    // Low-latency players do not require boot-time preloading

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

    // FIX (A1): Delete Salah channels before recreating them.
    // Android doesn't allow changing sound/audioAttributes on existing
    // channels — the only way to update a channel's configuration is to
    // delete it and recreate it. This ensures channels always have the
    // correct sound even if they were previously created with different
    // settings (e.g., wrong audioAttributesUsage or missing custom sound).
    for (final channelId in [
      'diyaa_salah_salah_enhanced',
      'diyaa_salah_salah_nabi',
      'diyaa_salah_silent',
      // FIX (A2): Also delete alarm-level channels before recreating
      'diyaa_salah_salah_enhanced_alarm',
      'diyaa_salah_salah_nabi_alarm',
    ]) {
      await android.deleteNotificationChannel(channelId: channelId);
    }

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
      // Al-Salah channels — Importance.high (level 4) plays sound reliably
      // without requiring USE_FULL_SCREEN_INTENT permission (which Importance.max
      // level 5 would need on Android 11+).
      const AndroidNotificationChannel(
        'diyaa_salah_salah_enhanced', 'Al-Salah Ala Al-Nabi (Al-Naqshabandi)',
        description: 'Periodic Al-Salah Ala Al-Nabi sound reminders',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('salah_enhanced'),
        enableVibration: false,
        showBadge: false,
      ),
      const AndroidNotificationChannel(
        'diyaa_salah_salah_nabi', 'Al-Salah Ala Al-Nabi (Classic)',
        description: 'Periodic Al-Salah Ala Al-Nabi sound reminders',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('salah_nabi'),
        enableVibration: false,
        showBadge: false,
      ),
      // FIX (A2): Alarm-level channels for overrideSilent.
      // These channels have audioAttributesUsage: alarm which allows them
      // to bypass DND/silent mode on Android. When overrideSilent=true,
      // notifications are routed to these channels instead of the normal ones.
      // The channel sound is the same as their normal counterparts, but the
      // alarm audio attribute ensures the sound plays even in DND/silent mode.
      const AndroidNotificationChannel(
        'diyaa_salah_salah_enhanced_alarm',
        'Al-Salah Ala Al-Nabi (Al-Naqshabandi) — Alarm',
        description: 'Periodic Al-Salah Ala Al-Nabi sound reminders (bypasses silent mode)',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('salah_enhanced'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        enableVibration: false,
        showBadge: false,
      ),
      const AndroidNotificationChannel(
        'diyaa_salah_salah_nabi_alarm',
        'Al-Salah Ala Al-Nabi (Classic) — Alarm',
        description: 'Periodic Al-Salah Ala Al-Nabi sound reminders (bypasses silent mode)',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('salah_nabi'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        enableVibration: false,
        showBadge: false,
      ),
      // Silent channel for when soundEnabled=false.
      // On Android 8+ (API 26+), notification channel sound takes precedence
      // over per-notification playSound/silent flags. A channel configured with
      // playSound:true + custom sound will ALWAYS play that sound regardless of
      // what AndroidNotificationDetails.playSound or .silent says.
      // The only way to truly silence a notification on Android 8+ is to post
      // it on a channel that has no sound configured.
      const AndroidNotificationChannel(
        'diyaa_salah_silent', 'Al-Salah Ala Al-Nabi (Silent)',
        description: 'Silent Al-Salah Ala Al-Nabi reminders — no sound',
        importance: Importance.min,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      ),
    ]) {
      await android.createNotificationChannel(ch);
    }
    debugPrint('[Notifications] Android channels created (8 total, incl. silent salah + alarm channels).');
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
      bool? canExact = await android.canScheduleExactNotifications();
      if (canExact != true) {
        await android.requestExactAlarmsPermission();
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

  static Future<bool> canScheduleExact() async {
    if (!_isMobile) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.canScheduleExactNotifications() ?? false;
    }
    return true;
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
    required bool soundEnabled, // FIX: Now passed through from AppProvider
    int currentStreak = 0,
  }) async {
    if (!_isMobile) {
      debugPrint('[Notifications] scheduleAll skipped on non-mobile platform.');
      return;
    }

    // FIX: Selective cancellation — only cancel IDs that scheduleAll() manages.
    // Previously _cancelAll() cancelled EVERYTHING including Salah Nabi (IDs 60-400),
    // which meant Salah Nabi was destroyed and had to be rescheduled separately.
    // If that separate reschedule failed, Salah Nabi was permanently lost.
    // Now we only cancel the 15 IDs we actually manage, leaving Salah Nabi intact.
    await _cancelScheduleAllIds();

    if (notifPrayer) await _schedulePrayerTimes(prayers, isArabic: isArabic, soundEnabled: soundEnabled);
    if (notifAzkar)  await _scheduleAzkarReminders(prayers, isArabic: isArabic, soundEnabled: soundEnabled);

    await scheduleStreakWarning(
      enabled: notifStreak,
      isArabic: isArabic,
      currentStreak: currentStreak,
      soundEnabled: soundEnabled, // FIX: thread sound preference to streak notifications
    );
  }

  /// FIX: Selective cancellation — only IDs managed by scheduleAll().
  /// Prayer IDs 10-14, Azkar IDs 20-24/25/30-33, Streak ID 40.
  /// Salah Nabi IDs 60-400 are NOT touched here.
  static Future<void> _cancelScheduleAllIds() async {
    for (int i = 0; i < 5; i++) { await _cancelOne(_idPrayerBase + i); }
    for (int i = 0; i < 5; i++) { await _cancelOne(_idPostPrayerBase + i); }
    await _cancelOne(_idJumuah);
    await _cancelOne(_idMorningAzkar);
    await _cancelOne(_idEveningAzkar);
    await _cancelOne(_idSleepAzkar);
    await _cancelOne(_idNightAzkar);
    await _cancelOne(_idStreakWarning);
    debugPrint('[Notifications] Cancelled 15 scheduleAll-managed IDs '
        '(Salah Nabi untouched).');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PRAYER  (IDs 10–14) — no emojis
  // ══════════════════════════════════════════════════════════════════════════
  static Future<void> _schedulePrayerTimes(
    PrayerInfo prayers, {required bool isArabic, required bool soundEnabled}) async {
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
        title: isArabic ? 'حان الآن موعد صلاة ${p.ar}'
                        : 'It is time for ${p.en} prayer',
        body: isArabic
            ? 'أرحنا بها يا بلال. لا تنس أداء الصلاة في وقتها.'
            : "Time to pray. Don't forget to perform your prayer on time.",
        scheduledTime: p.time,
        soundEnabled: soundEnabled, // FIX: thread sound preference
      );
    }
    debugPrint('[Notifications] Scheduled 5 prayer notifications.');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AZKAR  (IDs 20–24, 30–33) — no emojis
  // ══════════════════════════════════════════════════════════════════════════
  static Future<void> _scheduleAzkarReminders(
    PrayerInfo prayers, {required bool isArabic, required bool soundEnabled}) async {
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
        title: isArabic ? 'أذكار ما بعد صلاة ${p.ar}'
                        : 'Post-${p.en} Azkar',
        body: isArabic
            ? 'تقبل الله صلاتك! لا تنس أذكار ما بعد الصلاة.'
            : 'May Allah accept your prayer! Time for post-prayer supplications.',
        scheduledTime: p.time.add(const Duration(minutes: 15)),
        soundEnabled: soundEnabled, // FIX: thread sound preference
      );
    }

    await _schedule(
      id: _idMorningAzkar,
      channelId: _channelAzkar, channelName: 'Azkar Reminders',
      title: isArabic ? 'أذكار الصباح' : 'Morning Azkar',
      body:  isArabic ? 'ابدأ يومك بنور الذكر. حان وقت أذكار الصباح.'
                      : 'Start your day with remembrance. Time for Morning Azkar.',
      scheduledTime: prayers.fajr.add(const Duration(minutes: 30)),
      soundEnabled: soundEnabled,
    );

    await _schedule(
      id: _idEveningAzkar,
      channelId: _channelAzkar, channelName: 'Azkar Reminders',
      title: isArabic ? 'أذكار المساء' : 'Evening Azkar',
      body:  isArabic ? 'لا تنس أذكار المساء. اجعل ختام يومك ذكراً.'
                      : 'Protect yourself until morning. Time for Evening Azkar.',
      scheduledTime: prayers.asr.add(const Duration(minutes: 30)),
      soundEnabled: soundEnabled,
    );

    await _schedule(
      id: _idSleepAzkar,
      channelId: _channelAzkar, channelName: 'Azkar Reminders',
      title: isArabic ? 'أذكار النوم' : 'Sleep Azkar',
      body:  isArabic ? 'اختم يومك بذكر الله لتنام في طمأنينة.'
                      : 'End your day with remembrance of Allah for peaceful sleep.',
      scheduledTime: prayers.isha.add(const Duration(minutes: 30)),
      soundEnabled: soundEnabled,
    );

    await _schedule(
      id: _idNightAzkar,
      channelId: _channelAzkar, channelName: 'Azkar Reminders',
      title: isArabic ? 'قيام الليل' : 'Night Azkar',
      body:  isArabic ? 'إن ربك ينزل إلى السماء الدنيا في هذا الوقت، فاذكره وادعه.'
                      : 'The last third of the night is a time of blessing. Make dua.',
      scheduledTime: prayers.fajr.subtract(const Duration(minutes: 30)),
      soundEnabled: soundEnabled,
    );

    debugPrint('[Notifications] Scheduled 9 azkar notifications.');

    await _scheduleJumuahAzkar(prayers.dhuhr, isArabic: isArabic, soundEnabled: soundEnabled);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // JUMU'AH  (ID 25) — no emojis
  // ══════════════════════════════════════════════════════════════════════════
  static Future<void> _scheduleJumuahAzkar(
    DateTime dhuhrTime, {required bool isArabic, required bool soundEnabled}) async {
    var fireAt = dhuhrTime.add(const Duration(minutes: 60));
    final daysUntilFriday = (5 - fireAt.weekday + 7) % 7;
    fireAt = fireAt.add(Duration(days: daysUntilFriday == 0 ? 0 : daysUntilFriday));
    if (fireAt.isBefore(DateTime.now())) {
      fireAt = fireAt.add(const Duration(days: 7));
    }

    final tzTime = tz.TZDateTime.from(fireAt, tz.local);
    try {
      await scheduler.scheduleNotification(
        _plugin,
        id: _idJumuah,
        channelId: _channelAzkar,
        channelName: 'Azkar Reminders',
        title: isArabic ? 'أذكار ما بعد صلاة الجمعة'
                        : "Post-Jumu'ah Azkar",
        body: isArabic
            ? 'تقبل الله صلاتكم. لا تنسوا أذكار ما بعد صلاة الجمعة المباركة.'
            : "May Allah accept your Jumu'ah prayer! Time for post-prayer supplications.",
        tzTime: tzTime,
        matchComponents: DateTimeComponents.dayOfWeekAndTime,
        playSound: soundEnabled, // FIX: thread sound preference
      );
      debugPrint("[Notifications] Jumu'ah azkar scheduled for $fireAt (weekly Fri).");
    } catch (e) {
      debugPrint('[Notifications] ERROR Jumu\'ah id=$_idJumuah: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AL-SALAH 'ALA AL-NABI  (IDs 60–400)
  // When soundEnabled: Importance.high + Visibility.secret plays sound via
  // channel config while keeping notification content hidden in the shade.
  // When !soundEnabled: routed to silent channel (Importance.min, no sound).
  // overrideSilent uses AudioAttributesUsage.alarm to bypass DND.
  // ══════════════════════════════════════════════════════════════════════════
  static Future<void> scheduleSalahNabiReminders({
    required bool enabled,
    required String soundAsset,
    required int intervalMinutes,
    required bool overrideSilent,
    required bool soundEnabled,
  }) async {
    // Start or stop the desktop timer for Windows/desktop platforms
    if (!_isMobile) {
      _startDesktopSalahTimer(enabled, soundAsset, intervalMinutes, soundEnabled);
      return;
    }

    // FIX: Request permissions before scheduling. Without this, if the user
    // toggles Salah Nabi on for the first time or permissions were revoked,
    // zonedSchedule() fails silently on Android 13+ (no POST_NOTIFICATIONS)
    // and Android 12+ (no SCHEDULE_EXACT_ALARM).
    await requestPermissions();

    if (Platform.isAndroid) {
      // ── Android: Single Native AlarmManager alarm architecture ──
      // This solves the UI lag completely by making exactly 2-3 native calls.
      await setSalahNabiEnabledNative(enabled);

      // Cancel the single native alarm and any leftovers
      await _cancelOne(_idSalahBase);
      await cancelNativeSalahAlarm(_idSalahBase);

      if (!enabled) {
        debugPrint('[Notifications] Salah Nabi reminders disabled — Android single alarm cancelled.');
        return;
      }

      if (soundEnabled) {
        final interval = intervalMinutes.clamp(1, 1440);
        final now = DateTime.now();
        final minutesSinceMidnight = now.hour * 60 + now.minute;
        final firstSlotMinutes = ((minutesSinceMidnight ~/ interval) + 1) * interval;

        final hour = firstSlotMinutes ~/ 60;
        final minute = firstSlotMinutes % 60;

        var fireAt = DateTime(now.year, now.month, now.day, hour, minute);
        if (fireAt.isBefore(now)) {
          fireAt = fireAt.add(const Duration(days: 1));
        }

        try {
          await scheduleNativeSalahAlarm(
            id: _idSalahBase,
            scheduledTime: fireAt,
            soundAsset: soundAsset,
            overrideSilent: overrideSilent,
            intervalMinutes: interval,
          );
          debugPrint('[Notifications] Scheduled single Android Salah alarm (id=$_idSalahBase) at $fireAt');
        } catch (e) {
          debugPrint('[Notifications] Single Android Salah alarm failed: $e');
        }
      }
      return;
    }

    // ── iOS: Standard zonedSchedule loop (max 64 slots) ──
    for (int i = _idSalahBase; i <= _idSalahMax; i++) {
      await _cancelOne(i);
    }

    if (!enabled) {
      debugPrint('[Notifications] Salah Nabi reminders disabled — iOS IDs cancelled.');
      return;
    }

    // Validate interval (minimum 1 minute, max 24 hours)
    final interval = intervalMinutes.clamp(1, 1440);
    // Number of daily slots
    final slotsPerDay = (24 * 60) ~/ interval;
    final totalSlots = slotsPerDay.clamp(0, _idSalahMax - _idSalahBase + 1);

    final channelId = soundEnabled
        ? (overrideSilent ? 'diyaa_salah_${soundAsset}_alarm' : 'diyaa_salah_$soundAsset')
        : 'diyaa_salah_silent';
    final channelName = soundEnabled
        ? (overrideSilent
            ? 'Al-Salah Ala Al-Nabi — Alarm'
            : 'Al-Salah Ala Al-Nabi')
        : 'Al-Salah Ala Al-Nabi (Silent)';

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: soundEnabled ? Importance.high : Importance.min,
      priority: soundEnabled ? Priority.high : Priority.min,
      channelAction: AndroidNotificationChannelAction.update,
      visibility: NotificationVisibility.private,
      playSound: soundEnabled,
      sound: soundEnabled
          ? RawResourceAndroidNotificationSound(soundAsset)
          : null,
      audioAttributesUsage: overrideSilent
          ? AudioAttributesUsage.alarm
          : AudioAttributesUsage.notification,
      category: overrideSilent
          ? AndroidNotificationCategory.alarm
          : AndroidNotificationCategory.reminder,
      enableVibration: false,
      showWhen: false,
      ongoing: false,
      silent: !soundEnabled,
      icon: '@mipmap/launcher_icon',
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: soundEnabled,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final canExact = await canScheduleExact();
    final scheduleMode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final now = DateTime.now();
    final minutesSinceMidnight = now.hour * 60 + now.minute;
    final firstSlotMinutes = ((minutesSinceMidnight ~/ interval) + 1) * interval;

    int scheduledCount = 0;
    for (int slot = 0; slot < totalSlots; slot++) {
      final slotMinutes = (firstSlotMinutes + slot * interval) % (24 * 60);
      final hour = slotMinutes ~/ 60;
      final minute = slotMinutes % 60;

      var fireAt = DateTime(now.year, now.month, now.day, hour, minute);
      if (fireAt.isBefore(now)) {
        fireAt = fireAt.add(const Duration(days: 1));
      }

      final id = _idSalahBase + slot;
      final tzTime = tz.TZDateTime.from(fireAt, tz.local);
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: 'اللهم صل على محمد',
          body: 'صلّوا على النبي ﷺ',
          scheduledDate: tzTime,
          notificationDetails: details,
          androidScheduleMode: scheduleMode,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        scheduledCount++;
      } catch (e) {
        debugPrint('[Notifications] iOS Salah slot id=$id zonedSchedule FAILED: $e');
      }
    }

    debugPrint('[Notifications] Scheduled $scheduledCount iOS salah nabi reminders (every $interval min).');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STREAK WARNING  (ID 40) — no emojis
  // ══════════════════════════════════════════════════════════════════════════
  static Future<void> scheduleStreakWarning({
    required bool enabled,
    required bool isArabic,
    required int currentStreak,
    required bool soundEnabled, // FIX: thread sound preference
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
      title: isArabic ? 'لا تكسر سلسلتك ($currentStreak يوم)'
                      : "Don't break your streak! ($currentStreak days)",
      body:  isArabic ? 'لا تزال أذكار اليوم في انتظارك. حافظ على سلسلتك!'
                      : 'Your daily Azkar are waiting. Keep your streak alive!',
      scheduledTime: fireAt,
      soundEnabled: soundEnabled, // FIX: thread sound preference
    );
    debugPrint('[Notifications] Streak warning scheduled for $fireAt.');
  }

  static final AudioPlayer _previewPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  static Future<void> previewSalahSound(String soundAsset) async {
    try {
      await _previewPlayer.stop();
      await _previewPlayer.play(
        AssetSource('sounds/$soundAsset.mp3'),
        mode: PlayerMode.lowLatency,
      );
      debugPrint('[Notifications] Played preview sound: $soundAsset with lowLatency');
    } catch (e) {
      debugPrint('[Notifications] Preview failed: $e');
    }
  }

  // ── Desktop/Windows Timer ──
  static final AudioPlayer _salahPlayer = AudioPlayer();
  static Timer? _desktopSalahTimer;

  static void _startDesktopSalahTimer(
      bool enabled, String soundAsset, int intervalMinutes, bool soundEnabled) {
    _desktopSalahTimer?.cancel();
    _desktopSalahTimer = null;

    if (!enabled || !soundEnabled || _isMobile) return;

    debugPrint('[Notifications] Starting desktop periodic timer for Salah sound ($soundAsset) every $intervalMinutes min.');

    void scheduleNext() {
      _desktopSalahTimer?.cancel();

      final now = DateTime.now();
      final intervalMs = intervalMinutes * 60 * 1000;
      final currentMs = now.millisecondsSinceEpoch;

      // Calculate next exact boundary
      final nextBoundaryMs = ((currentMs ~/ intervalMs) + 1) * intervalMs;
      final delay = Duration(milliseconds: nextBoundaryMs - currentMs);

      debugPrint('[Notifications] Next desktop reminder scheduled in ${(delay.inMilliseconds / 1000).toStringAsFixed(1)}s (at ${DateTime.fromMillisecondsSinceEpoch(nextBoundaryMs)})');

      _desktopSalahTimer = Timer(delay, () async {
        try {
          await _salahPlayer.stop();
          await _salahPlayer.play(AssetSource('sounds/$soundAsset.mp3'));
          debugPrint('[Notifications] Played Salah sound on desktop: $soundAsset');
        } catch (e) {
          debugPrint('[Notifications] Playing Salah sound failed: $e');
        }
        // Reschedule recursively to keep exact clock boundaries
        scheduleNext();
      });
    }

    scheduleNext();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TEST NOTIFICATION — no emojis
  // ══════════════════════════════════════════════════════════════════════════
  static Future<void> sendTestNotification({bool isArabic = false}) async {
    try {
      debugPrint('[Notifications] Sending test notification...');
      await _plugin.show(
        id: 99,
        title: isArabic ? 'اختبار اشعارات ضياء' : 'Diyaa Notifications Test',
        body: isArabic
            ? 'الاشعارات تعمل بشكل صحيح!'
            : 'If you see this, notifications are working!',
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
  // TEST SALAH NOTIFICATION
  // ══════════════════════════════════════════════════════════════════════════
  // FIX: Cross-platform test — always plays audio directly via AudioPlayer
  // when soundEnabled (works on ALL platforms including Windows), and also
  // shows the notification on mobile to test the notification channel.
  // On Windows/desktop, the notification is skipped because custom sounds
  // aren't supported by flutter_local_notifications on those platforms.
  static Future<void> sendTestSalahNotification({
    required bool isArabic,
    required String soundAsset,
    required bool overrideSilent,
    required bool soundEnabled,
  }) async {
    try {
      debugPrint('[Notifications] Sending test Salah notification...');

      // ── Always play audio directly via low-latency player when soundEnabled.
      if (soundEnabled) {
        await _previewPlayer.stop();
        await _previewPlayer.play(
          AssetSource('sounds/$soundAsset.mp3'),
          mode: PlayerMode.lowLatency,
        );
        debugPrint('[Notifications] Played test Salah sound: $soundAsset');
      }

      // ── On mobile (iOS only!), show the notification to test the notification channel
      if (_isMobile && Platform.isIOS) {
        // Ensure permissions are granted before showing the notification
        await requestPermissions();

        final iosDetails = DarwinNotificationDetails(
          presentAlert: false,
          presentBadge: false,
          presentSound: soundEnabled,
        );

        await _plugin.show(
          id: 98,
          title: 'اللهم صل على محمد',
          body: 'صلّوا على النبي ﷺ',
          notificationDetails: NotificationDetails(
              android: null, iOS: iosDetails),
        );
      }

      debugPrint('[Notifications] Test Salah completed '
          '(soundEnabled=$soundEnabled, platform=${_isMobile ? "mobile" : "desktop"}).');
    } catch (e) {
      debugPrint('[Notifications] TEST SALAH FAILED: $e');
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
  // NATIVE ALARM SCHEDULING  (A5, A6, A7)
  // ══════════════════════════════════════════════════════════════════════════
  // FIX (A5): MethodChannel methods for native Android AlarmManager +
  // MediaPlayer fallback. The notification channel sound mechanism is
  // unreliable for scheduled reminders (Doze mode, process death, channel
  // config mismatches). These methods schedule a native AlarmManager alarm
  // that fires a BroadcastReceiver which plays the sound via MediaPlayer
  // directly, bypassing the notification channel entirely.

  /// Schedule a native Android alarm that plays the Salah sound via
  /// MediaPlayer when the alarm fires. This is a fallback for the
  /// unreliable notification channel sound mechanism.
  static Future<void> scheduleNativeSalahAlarm({
    required int id,
    required DateTime scheduledTime,
    required String soundAsset,
    required bool overrideSilent,
    required int intervalMinutes,
  }) async {
    if (!_isMobile || !Platform.isAndroid) return;
    try {
      final millis = scheduledTime.millisecondsSinceEpoch;
      await _alarmChannel.invokeMethod('scheduleSalahSoundAlarm', {
        'id': id,
        'scheduledTime': millis,
        'soundAsset': soundAsset,
        'overrideSilent': overrideSilent,
        'intervalMinutes': intervalMinutes,
      });
      debugPrint('[Notifications] Native salah alarm scheduled: id=$id, '
          'time=$scheduledTime, sound=$soundAsset, overrideSilent=$overrideSilent, '
          'interval=$intervalMinutes min');
    } catch (e) {
      debugPrint('[Notifications] Native salah alarm FAILED: id=$id, $e');
    }
  }

  /// Cancel a native Android alarm previously scheduled via
  /// [scheduleNativeSalahAlarm].
  static Future<void> cancelNativeSalahAlarm(int id) async {
    if (!_isMobile || !Platform.isAndroid) return;
    try {
      await _alarmChannel.invokeMethod('cancelSalahSoundAlarm', {'id': id});
    } catch (e) {
      debugPrint('[Notifications] Native salah alarm cancel FAILED: id=$id, $e');
    }
  }

  /// Write the Salah Nabi enabled state to native SharedPreferences.
  /// This is read by SalahSoundReceiver at fire time to determine whether
  /// to play sound and auto-reschedule, or to cancel the alarm chain.
  /// When enabled=false: SalahSoundReceiver cancels its alarm instead of
  /// rescheduling, breaking the auto-reschedule chain.
  /// When enabled=true: SalahSoundReceiver plays sound and reschedules.
  static Future<void> setSalahNabiEnabledNative(bool enabled) async {
    if (!_isMobile || !Platform.isAndroid) return;
    try {
      await _alarmChannel.invokeMethod('setSalahNabiEnabled', {'enabled': enabled});
      debugPrint('[Notifications] Native salah enabled state set: $enabled');
    } catch (e) {
      debugPrint('[Notifications] Native salah enabled state FAILED: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CANCEL
  // ══════════════════════════════════════════════════════════════════════════
  // NOTE: _cancelAll() removed — scheduleAll() now uses selective cancellation
  // (_cancelScheduleAllIds) to avoid destroying Salah Nabi notifications.

  static Future<void> _cancelOne(int id) async =>
      scheduler.cancelNotification(_plugin, id);

  static Future<void> cancelPrayerNotifications() async {
    for (int i = 0; i < 5; i++) { await _cancelOne(_idPrayerBase + i); }
  }

  static Future<void> cancelAzkarNotifications() async {
    for (int i = 0; i < 5; i++) { await _cancelOne(_idPostPrayerBase + i); }
    await _cancelOne(_idJumuah);
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
    DateTimeComponents matchComponents = DateTimeComponents.time,
    bool soundEnabled = true, // FIX: thread sound preference to scheduler
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
        matchComponents: matchComponents,
        playSound: soundEnabled, // FIX: pass sound preference to scheduler
      );
      debugPrint('[Notifications] id=$id scheduled at $fireAt (match=$matchComponents)');
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