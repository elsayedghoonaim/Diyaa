import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait — must be called before runApp.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialize notifications at startup and request permissions immediately.
  // Non-fatal: the app still launches without notifications.
  try {
    await NotificationService.initialize();
    await NotificationService.requestPermissions();
  } catch (e) {
    debugPrint('[main] NotificationService startup failed: $e');
  }

  runApp(const DiyaaApp());
}