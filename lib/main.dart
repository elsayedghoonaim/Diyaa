import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'services/notification_service.dart';
import 'theme/app_colors.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait — must be called before runApp
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // FIX #1: Initialize the notification service at startup AND request
  // permissions immediately. Previously requestPermissions() was only called
  // inside _loadPrayerTimes(), meaning a failed initialize() left the app
  // with no permissions and no way to recover without a full restart.
  try {
    await NotificationService.initialize();
    await NotificationService.requestPermissions();
  } catch (e) {
    // Non-fatal: the app still launches without notifications.
    debugPrint('[main] NotificationService startup failed: $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const DiyaaApp(),
    ),
  );
}

// FIX #2: DiyaaApp is now a StatefulWidget with WidgetsBindingObserver so it
// can detect when the app resumes from background. This is required to handle
// the case where the user revoked exact-alarm permission in device settings
// and then returns to the app — we re-request permissions and reschedule.
class DiyaaApp extends StatefulWidget {
  const DiyaaApp({super.key});

  @override
  State<DiyaaApp> createState() => _DiyaaAppState();
}

class _DiyaaAppState extends State<DiyaaApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Called whenever the app moves between foreground and background.
  /// On resume: re-request permissions (handles revocation) and trigger
  /// a reschedule via the provider so fresh prayer times are applied.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('[DiyaaApp] App resumed — refreshing permissions & prayer times.');
      // Re-request permissions in case they were revoked in device settings
      NotificationService.requestPermissions().catchError((e) {
        debugPrint('[DiyaaApp] requestPermissions on resume failed: $e');
      });
      // Refresh prayer times + reschedule notifications
      // Using context.mounted check before reading provider
      if (mounted) {
        context.read<AppProvider>().refreshPrayerTimes();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return MaterialApp(
      title: 'Diyaa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.bgLight,
        colorScheme: const ColorScheme.light(
          primary: AppColors.accentTealLight,
          secondary: AppColors.accentGoldLight,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bgDark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accentTealDark,
          secondary: AppColors.accentGoldDark,
        ),
        useMaterial3: true,
      ),
      themeMode: provider.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: provider.onboardingComplete
          ? MainScreen(key: MainScreen.mainKey)
          : const OnboardingScreen(),
    );
  }
}