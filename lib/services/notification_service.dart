import 'dart:io' show Platform;

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
    if (!_isMobile) return;

    // FIX: Request permissions before scheduling. Without this, if the user
    // toggles Salah Nabi on for the first time or permissions were revoked,
    // zonedSchedule() fails silently on Android 13+ (no POST_NOTIFICATIONS)
    // and Android 12+ (no SCHEDULE_EXACT_ALARM).
    await requestPermissions();

    // FIX: Cancel ALL possible Salah Nabi IDs (60–400) every time.
    // Previously used _lastSalahSlotCount to only cancel previously-scheduled
    // IDs, but that static variable resets to 0 on process death, leaving
    // orphaned notifications firing at old times after app restart.
    // Cancelling 341 IDs is fast (~1ms each) and guarantees no orphans.
    // FIX (A7): Also cancel native sound alarms for each Salah Nabi ID.
    for (int i = _idSalahBase; i <= _idSalahMax; i++) {
      await _cancelOne(i);
      await cancelNativeSalahAlarm(i);
    }

    if (!enabled) {
      debugPrint('[Notifications] Salah Nabi reminders disabled — all IDs cancelled.');
      return;
    }

    // Validate interval (minimum 1 minute, max 24 hours)
    final interval = intervalMinutes.clamp(1, 1440);
    // Number of daily slots
    final slotsPerDay = (24 * 60) ~/ interval;
    final totalSlots = slotsPerDay.clamp(0, _idSalahMax - _idSalahBase + 1);

    // FIX (A3): On Android 8+ (API 26+), notification channel sound takes precedence
    // over per-notification playSound/silent flags. When soundEnabled=false,
    // we must use the silent channel ('diyaa_salah_silent') which has no sound
    // configured at the channel level. When soundEnabled=true, we use the
    // per-sound channel. When overrideSilent=true, we use the alarm-level
    // channel which has audioAttributesUsage:alarm to bypass DND/silent mode.
    final channelId = soundEnabled
        ? (overrideSilent ? 'diyaa_salah_${soundAsset}_alarm' : 'diyaa_salah_$soundAsset')
        : 'diyaa_salah_silent';
    final channelName = soundEnabled
        ? (overrideSilent
            ? 'Al-Salah Ala Al-Nabi — Alarm'
            : 'Al-Salah Ala Al-Nabi')
        : 'Al-Salah Ala Al-Nabi (Silent)';

    // Build notification details — channel selection handles sound on Android 8+.
    // For Android < 8 and iOS, per-notification flags still work.
    // FIX (A3): channelAction.update forces the plugin to update the channel
    // at fire time, ensuring the correct sound configuration is used.
    // Priority.high (not Priority.max) for consistency with test path and
    // to avoid USE_FULL_SCREEN_INTENT permission requirement on Android 11+.
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: soundEnabled ? Importance.high : Importance.min,
      priority: soundEnabled ? Priority.high : Priority.min,
      channelAction: AndroidNotificationChannelAction.update,
      // FIX: Always use Visibility.secret for Salah Nabi — this is a periodic
      // sound reminder (every 5-60 min). Visibility.public would fill the shade
      // with visible notifications. Visibility.secret hides the content while
      // still allowing the Importance.high channel to play sound.
      visibility: NotificationVisibility.secret,
      // FIX: Disable notification channel sound for scheduled Salah on Android.
      // The native MediaPlayer (via SalahSoundReceiver) handles sound playback
      // reliably. The notification channel sound is unreliable (the whole reason
      // for the native alarm fix). Setting playSound:false + silent:true + sound:null
      // prevents the channel from playing sound, avoiding overlap with MediaPlayer.
      // The notification still appears visually (title, body, icon) via the channel's
      // importance level and other properties.
      playSound: false,
      sound: null,
      audioAttributesUsage: overrideSilent
          ? AudioAttributesUsage.alarm
          : AudioAttributesUsage.notification,
      category: overrideSilent
          ? AndroidNotificationCategory.alarm
          : AndroidNotificationCategory.reminder,
      enableVibration: false,
      showWhen: false,
      ongoing: false,
      silent: true,
      icon: '@mipmap/launcher_icon',
    );

    // FIX: presentAlert is always false for Salah Nabi — this is a periodic
    // sound-only reminder. Showing a banner every 5-60 minutes is disruptive.
    // When soundEnabled=true: sound plays, no banner (sound-only reminder).
    // When soundEnabled=false: no sound, no banner (user disabled reminders).
    final iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: soundEnabled,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    // FIX: Check exact-alarm permission ONCE before the loop, not per-slot.
    // canScheduleExactNotifications() is a platform channel call — calling it
    // 24+ times in a loop is slow and wasteful since the result doesn't change.
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    bool canExact = true;
    if (android != null) {
      canExact = await android.canScheduleExactNotifications() ?? false;
    }
    final scheduleMode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    // Schedule one slot per interval, starting from the next interval boundary
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

      final tzTime = tz.TZDateTime.from(fireAt, tz.local);
      final id = _idSalahBase + slot;

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
        // FIX (A6): Also schedule native sound alarm via AlarmManager +
        // MediaPlayer. This bypasses the unreliable notification channel
        // sound mechanism and plays the sound directly even when the app
        // process is dead or in Doze mode.
        if (soundEnabled && Platform.isAndroid) {
          await scheduleNativeSalahAlarm(
            id: id,
            scheduledTime: fireAt,
            soundAsset: soundAsset,
            overrideSilent: overrideSilent,
          );
        }
        scheduledCount++;
      } catch (e) {
        debugPrint('[Notifications] Salah slot id=$id ERROR: $e');
      }
    }

    debugPrint('[Notifications] Scheduled $scheduledCount salah nabi reminders '
        '(every $interval min, channel=$channelId, overrideSilent=$overrideSilent, '
        'soundEnabled=$soundEnabled, canExact=$canExact).');
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

  // ══════════════════════════════════════════════════════════════════════════
  // PREVIEW SOUND
  // ══════════════════════════════════════════════════════════════════════════
  static final AudioPlayer _previewPlayer = AudioPlayer();

  static Future<void> previewSalahSound(String soundAsset) async {
    try {
      await _previewPlayer.stop();
      await _previewPlayer.play(AssetSource('sounds/$soundAsset.mp3'));
    } catch (e) {
      debugPrint('[Notifications] Preview failed: $e');
    }
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

      // ── FIX: Always play audio directly via AudioPlayer when soundEnabled.
      // The notification system's sound playback is unreliable:
      //   * On Windows, custom notification sounds aren't supported at all
      //   * On Android, sound can be suppressed by DND/silent mode or missing perms
      //   * Direct audio playback ensures the user hears the sound immediately.
      if (soundEnabled) {
        await _previewPlayer.stop();
        await _previewPlayer.play(AssetSource('sounds/$soundAsset.mp3'));
      }

      // ── On mobile, also show the notification to test the notification channel
      if (_isMobile) {
        // Ensure permissions are granted before showing the notification
        await requestPermissions();

        // FIX (A4): Use alarm-level channel when overrideSilent=true,
        // same as scheduleSalahNabiReminders(). Also use channelAction.update
        // to force channel update at fire time. Importance.high avoids
        // USE_FULL_SCREEN_INTENT permission requirement. Visibility.secret
        // hides content in shade.
        final testChannelId = soundEnabled
            ? (overrideSilent ? 'diyaa_salah_${soundAsset}_alarm' : 'diyaa_salah_$soundAsset')
            : 'diyaa_salah_silent';
        final testChannelName = soundEnabled
            ? (overrideSilent
                ? 'Al-Salah Ala Al-Nabi — Alarm'
                : 'Al-Salah Ala Al-Nabi')
            : 'Al-Salah Ala Al-Nabi (Silent)';
        final androidDetails = AndroidNotificationDetails(
          testChannelId,
          testChannelName,
          importance: soundEnabled ? Importance.high : Importance.min,
          priority: soundEnabled ? Priority.high : Priority.min,
          channelAction: AndroidNotificationChannelAction.update,
          visibility: NotificationVisibility.secret,
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

        await _plugin.show(
          id: 98,
          title: 'اللهم صل على محمد',
          body: 'صلّوا على النبي ﷺ',
          notificationDetails: NotificationDetails(
              android: androidDetails, iOS: iosDetails),
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
  }) async {
    if (!_isMobile || !Platform.isAndroid) return;
    try {
      final millis = scheduledTime.millisecondsSinceEpoch;
      await _alarmChannel.invokeMethod('scheduleSalahSoundAlarm', {
        'id': id,
        'scheduledTime': millis,
        'soundAsset': soundAsset,
        'overrideSilent': overrideSilent,
      });
      debugPrint('[Notifications] Native salah alarm scheduled: id=$id, '
          'time=$scheduledTime, sound=$soundAsset, overrideSilent=$overrideSilent');
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