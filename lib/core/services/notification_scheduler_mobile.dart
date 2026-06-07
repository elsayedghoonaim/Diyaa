import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
  bool playSound = true,
  bool isDarkMode = false,
}) async {
  // On Android 14+ (API 34), SCHEDULE_EXACT_ALARM is denied by default.
  // Fall back to inexact (slightly less precise but still fires).
  final android = plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  bool canExact = true;
  if (android != null) {
    try {
      canExact = await android.canScheduleExactNotifications() ?? false;
    } catch (e) {
      canExact = false;
    }
  }

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
        icon: isDarkMode ? '@mipmap/launcher_icon_dark' : '@mipmap/launcher_icon_light',
        color: isDarkMode ? const Color(0xFF05070C) : const Color(0xFF0B6E6E),
        styleInformation: const BigTextStyleInformation(''),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: playSound,
      ),
      windows: const WindowsNotificationDetails(),
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
  bool isDarkMode = false,
}) async {
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
        icon: isDarkMode ? '@mipmap/launcher_icon_dark' : '@mipmap/launcher_icon_light',
        color: isDarkMode ? const Color(0xFF05070C) : const Color(0xFF0B6E6E),
        styleInformation: const BigTextStyleInformation(''),
      ),
      iOS: const DarwinNotificationDetails(),
      windows: const WindowsNotificationDetails(),
    ),
  );
}