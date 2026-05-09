import 'package:flutter_timezone/flutter_timezone.dart';

Future<String> getDeviceTimezone() async {
  final result = await FlutterTimezone.getLocalTimezone();
  // flutter_timezone v3+ returns TimezoneInfo; v2 returns String.
  // .toString() safely handles both.
  return result.toString();
}