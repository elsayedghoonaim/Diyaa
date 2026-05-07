import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'services/notification_service.dart';
import 'theme/app_colors.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  try {
    await NotificationService.initialize();
  } catch (_) {
    // Non-fatal: notifications won't work but app still launches
    debugPrint('Notification service init failed');
  }
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const DiyaaApp(),
    ),
  );
}

class DiyaaApp extends StatelessWidget {
  const DiyaaApp({super.key});

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
      home: MainScreen(key: MainScreen.mainKey),
    );
  }
}
