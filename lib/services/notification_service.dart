import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'prayer_times_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Initialize for Windows (empty is fine, just needs to be passed)
    // Note: We're not doing background tasks on Windows for now, but we need
    // this to avoid crashes when running on Windows.
    const initializationSettingsWindows = 
        WindowsInitializationSettings(
      appName: 'Diyaa',
      appUserModelId: 'com.diyaa.diyaa',
      guid: 'E7B3545A-8A46-4B81-BBCA-747F9EED4E22', // Example GUID
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      windows: initializationSettingsWindows,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );
  }

  static Future<void> requestPermissions() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  static Future<void> scheduleAzkarNotifications(PrayerInfo prayers) async {
    // Clear previously scheduled notifications
    await _notificationsPlugin.cancelAll();

    final now = DateTime.now();

    // 1. Morning Azkar: 30 minutes after Fajr
    DateTime morningTime = prayers.fajr.add(const Duration(minutes: 30));
    if (morningTime.isBefore(now)) {
      morningTime = morningTime.add(const Duration(days: 1)); // Rough estimate for tomorrow
    }
    await _scheduleNotification(
      id: 1,
      title: 'أذكار الصباح',
      body: 'حان وقت أذكار الصباح. ابدأ يومك بذكر الله.',
      scheduledDate: morningTime,
    );

    // 2. Evening Azkar: 30 minutes after Asr
    DateTime eveningTime = prayers.asr.add(const Duration(minutes: 30));
    if (eveningTime.isBefore(now)) {
      eveningTime = eveningTime.add(const Duration(days: 1));
    }
    await _scheduleNotification(
      id: 2,
      title: 'أذكار المساء',
      body: 'حان وقت أذكار المساء. اختم يومك بذكر الله.',
      scheduledDate: eveningTime,
    );

    // 3. Post-Prayer Dhikr (Dhuhr)
    DateTime dhuhrDhikrTime = prayers.dhuhr.add(const Duration(minutes: 10));
    if (dhuhrDhikrTime.isBefore(now)) {
      dhuhrDhikrTime = dhuhrDhikrTime.add(const Duration(days: 1));
    }
    await _scheduleNotification(
      id: 3,
      title: 'أذكار بعد الصلاة',
      body: 'تقبل الله صلاتك. لا تنس أذكار ما بعد صلاة الظهر.',
      scheduledDate: dhuhrDhikrTime,
    );
  }

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'azkar_reminders',
          'Azkar Reminders',
          channelDescription: 'Notifications for daily Azkar',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
