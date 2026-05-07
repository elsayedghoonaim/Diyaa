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

  static Future<void> scheduleAzkarNotifications(PrayerInfo prayers, {bool isArabic = false}) async {
    // Clear previously scheduled notifications
    await _notificationsPlugin.cancelAll();

    final now = DateTime.now();

    // Helper to ensure we schedule for the future
    DateTime getFutureTime(DateTime time) {
      return time.isBefore(now) ? time.add(const Duration(days: 1)) : time;
    }

    // 1. Morning Azkar: 30 minutes after Fajr
    await _scheduleNotification(
      id: 1,
      title: isArabic ? 'أذكار الصباح 🌅' : 'Morning Azkar 🌅',
      body: isArabic 
          ? 'ابدأ يومك بنور الذكر. حان وقت أذكار الصباح لتكون في حفظ الله ورعايته.'
          : 'Start your day with the light of remembrance. Time for your Morning Azkar.',
      scheduledDate: getFutureTime(prayers.fajr.add(const Duration(minutes: 30))),
    );

    // 2. Evening Azkar: 30 minutes after Asr
    await _scheduleNotification(
      id: 2,
      title: isArabic ? 'أذكار المساء 🌇' : 'Evening Azkar 🌇',
      body: isArabic
          ? 'لا تنس أذكار المساء لتكون في حفظ الله حتى تصبح. اجعل ختام يومك ذكراً.'
          : 'Protect yourself until the morning. It\'s time for your Evening Azkar.',
      scheduledDate: getFutureTime(prayers.asr.add(const Duration(minutes: 30))),
    );

    // 3. Sleep Azkar: 30 minutes after Isha
    await _scheduleNotification(
      id: 3,
      title: isArabic ? 'أذكار النوم 🌙' : 'Sleep Azkar 🌙',
      body: isArabic
          ? 'اختم يومك بذكر الله لتنام في طمأنينة وتحفظك الملائكة حتى تستيقظ.'
          : 'End your day with the remembrance of Allah for a peaceful night\'s sleep.',
      scheduledDate: getFutureTime(prayers.isha.add(const Duration(minutes: 30))),
    );

    // 4. Wake up Azkar: 30 minutes before Fajr
    await _scheduleNotification(
      id: 4,
      title: isArabic ? 'قيام الليل والاستيقاظ 🌌' : 'Night/Wake-up Azkar 🌌',
      body: isArabic
          ? 'إن ربك ينزل إلى السماء الدنيا في هذا الوقت، فاذكره وادعه يستجب لك.'
          : 'The last third of the night is a time of immense blessing. Make dua and remember Him.',
      scheduledDate: getFutureTime(prayers.fajr.subtract(const Duration(minutes: 30))),
    );

    // 5. Post-Prayer Reminders for all 5 prayers (15 minutes after)
    final postPrayerMessages = [
      {'id': 5, 'time': prayers.fajr, 'nameAr': 'الفجر', 'nameEn': 'Fajr'},
      {'id': 6, 'time': prayers.dhuhr, 'nameAr': 'الظهر', 'nameEn': 'Dhuhr'},
      {'id': 7, 'time': prayers.asr, 'nameAr': 'العصر', 'nameEn': 'Asr'},
      {'id': 8, 'time': prayers.maghrib, 'nameAr': 'المغرب', 'nameEn': 'Maghrib'},
      {'id': 9, 'time': prayers.isha, 'nameAr': 'العشاء', 'nameEn': 'Isha'},
    ];

    for (var p in postPrayerMessages) {
      await _scheduleNotification(
        id: p['id'] as int,
        title: isArabic 
            ? 'أذكار ما بعد صلاة ${p['nameAr']} 📿' 
            : 'Post-${p['nameEn']} Azkar 📿',
        body: isArabic
            ? 'تقبل الله صلاتك! لا تنس ختام الصلاة لتكتب لك الحسنات وتغفر الخطايا.'
            : 'May Allah accept your prayer! Don\'t forget your post-prayer supplications.',
        scheduledDate: getFutureTime((p['time'] as DateTime).add(const Duration(minutes: 15))),
      );
    }
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
