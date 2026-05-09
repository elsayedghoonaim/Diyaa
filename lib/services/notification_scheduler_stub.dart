import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// No-op stub for Windows / Linux / Web.
/// None of these methods are ever called on those platforms.
Future<void> scheduleNotification(
  FlutterLocalNotificationsPlugin plugin, {
  required int id,
  required String channelId,
  required String channelName,
  required String title,
  required String body,
  required tz.TZDateTime tzTime,
}) async {}

Future<void> cancelNotification(
  FlutterLocalNotificationsPlugin plugin,
  int id,
) async {}

Future<void> cancelAllNotifications(
  FlutterLocalNotificationsPlugin plugin,
) async {}

Future<void> showNotification(
  FlutterLocalNotificationsPlugin plugin, {
  required int id,
  required String title,
  required String body,
  required String channelId,
  required String channelName,
}) async {}