import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

/// Real implementation for Android / iOS / macOS.
/// Uses named parameters — required since flutter_local_notifications v20+.
Future<void> scheduleNotification(
  FlutterLocalNotificationsPlugin plugin, {
  required int id,
  required String channelId,
  required String channelName,
  required String title,
  required String body,
  required tz.TZDateTime tzTime,
  DateTimeComponents matchComponents = DateTimeComponents.time,
  bool playSound = true, // FIX: Now respects the user's sound preference
}) async {
  // FIX: On Android 14+ (API 34), SCHEDULE_EXACT_ALARM is denied by default.
  // If exact alarms aren't available, fall back to inexact (slightly less
  // precise but still fires) instead of throwing a SecurityException.
  final android = plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  bool canExact = true;
  if (android != null) {
    canExact = await android.canScheduleExactNotifications() ?? false;
  }

  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('diyaa-dark-mode') ?? false;
  final largeIconName = isDarkMode ? 'launcher_icon_dark' : 'launcher_icon_light';

  // FIX: playSound/silent/presentSound now controlled by the playSound
  // parameter, which is threaded from the user's soundEnabled preference.
  // Previously these were always true/false, meaning sound played even when
  // the user had disabled it.
  await plugin.zonedSchedule(
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
        playSound: playSound,
        silent: !playSound,
        styleInformation: const BigTextStyleInformation(''),
        largeIcon: DrawableResourceAndroidBitmap(largeIconName),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: playSound,
      ),
    ),
    androidScheduleMode: canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle,
    matchDateTimeComponents: matchComponents,
  );
}

Future<void> cancelNotification(
  FlutterLocalNotificationsPlugin plugin,
  int id,
) async {
  await plugin.cancel(id: id);
}

Future<void> cancelAllNotifications(
  FlutterLocalNotificationsPlugin plugin,
) async {
  await plugin.cancelAll();
}

Future<void> showNotification(
  FlutterLocalNotificationsPlugin plugin, {
  required int id,
  required String title,
  required String body,
  required String channelId,
  required String channelName,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('diyaa-dark-mode') ?? false;
  final largeIconName = isDarkMode ? 'launcher_icon_dark' : 'launcher_icon_light';

  await plugin.show(
    id: id,
    title: title,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: false,
        largeIcon: DrawableResourceAndroidBitmap(largeIconName),
      ),
      iOS: const DarwinNotificationDetails(),
    ),
  );
}