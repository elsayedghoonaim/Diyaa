import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme/app_colors.dart';
import '../core/services/notification_service.dart';

// Features — cubits
import '../features/settings/data/data_sources/settings_local_data_source.dart';
import '../features/settings/data/repo/settings_repository.dart';
import '../features/settings/presentation/manager/settings_cubit.dart';
import '../features/settings/presentation/manager/settings_state.dart';

import '../features/prayer_times/data/data_sources/prayer_times_local_data_source.dart';
import '../features/prayer_times/data/repo/prayer_times_repository.dart';
import '../features/prayer_times/presentation/manager/prayer_times_cubit.dart';

import '../features/azkar/data/data_sources/azkar_local_data_source.dart';
import '../features/azkar/data/repo/azkar_repository.dart';
import '../features/azkar/presentation/manager/azkar_cubit.dart';

import '../features/progress/data/data_sources/progress_local_data_source.dart';
import '../features/progress/data/repo/progress_repository.dart';
import '../features/progress/presentation/manager/progress_cubit.dart';

// Screens
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import 'main_screen.dart';

/// Root application widget.
/// Provides all Cubits to the widget tree and handles app lifecycle events.
class DiyaaApp extends StatefulWidget {
  const DiyaaApp({super.key});

  @override
  State<DiyaaApp> createState() => _DiyaaAppState();
}

class _DiyaaAppState extends State<DiyaaApp> with WidgetsBindingObserver {
  // ── Dependency graph ──────────────────────────────────────────────────────

  final SettingsLocalDataSource _settingsDs = const SettingsLocalDataSource();
  final PrayerTimesLocalDataSource _prayerTimesDs =
      const PrayerTimesLocalDataSource();
  final AzkarLocalDataSource _azkarDs = const AzkarLocalDataSource();
  final ProgressLocalDataSource _progressDs = const ProgressLocalDataSource();

  late final SettingsRepository _settingsRepo;
  late final PrayerTimesRepository _prayerTimesRepo;
  late final AzkarRepository _azkarRepo;
  late final ProgressRepository _progressRepo;

  late final SettingsCubit _settingsCubit;
  late final PrayerTimesCubit _prayerTimesCubit;
  late final AzkarCubit _azkarCubit;
  late final ProgressCubit _progressCubit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _settingsRepo = SettingsRepository(
      dataSource: _settingsDs,
      prayerTimesDataSource: _prayerTimesDs,
    );
    _prayerTimesRepo = PrayerTimesRepository(
      dataSource: _prayerTimesDs,
      settingsDataSource: _settingsDs,
    );
    _azkarRepo     = AzkarRepository(dataSource: _azkarDs);
    _progressRepo  = ProgressRepository(dataSource: _progressDs);

    _settingsCubit    = SettingsCubit(repository: _settingsRepo);
    _prayerTimesCubit = PrayerTimesCubit(repository: _prayerTimesRepo);
    _azkarCubit       = AzkarCubit(repository: _azkarRepo);
    _progressCubit    = ProgressCubit(repository: _progressRepo);

    // Bootstrap: load settings first, then kick off prayer times in parallel.
    _settingsCubit.loadSettings();
    _prayerTimesCubit.loadPrayerTimes();
    _progressCubit.loadProgress();
    _azkarCubit.loadDailySessions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settingsCubit.close();
    _prayerTimesCubit.close();
    _azkarCubit.close();
    _progressCubit.close();
    super.dispose();
  }

  /// Re-request permissions and refresh prayer times when the app resumes.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('[DiyaaApp] App resumed — refreshing permissions & prayer times.');
      NotificationService.requestPermissions().catchError((e) {
        debugPrint('[DiyaaApp] requestPermissions on resume failed: $e');
      });
      _prayerTimesCubit.refreshPrayerTimes();
    } else if (state == AppLifecycleState.paused) {
      debugPrint('[DiyaaApp] App paused — syncing launcher icon.');
      _settingsCubit.syncLauncherIcon();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsCubit>.value(value: _settingsCubit),
        BlocProvider<PrayerTimesCubit>.value(value: _prayerTimesCubit),
        BlocProvider<AzkarCubit>.value(value: _azkarCubit),
        BlocProvider<ProgressCubit>.value(value: _progressCubit),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          final isDark = settingsState is SettingsLoaded
              ? settingsState.settings.darkMode
              : false;
          final textScale = settingsState is SettingsLoaded
              ? settingsState.settings.appTextScale
              : 0.88;
          final onboardingComplete = settingsState is SettingsLoaded
              ? settingsState.settings.onboardingComplete
              : false;

          return MaterialApp(
            title: 'Diyaa',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            builder: (context, child) {
              final data = MediaQuery.of(context);
              return MediaQuery(
                data: data.copyWith(
                  textScaler: TextScaler.linear(textScale),
                ),
                child: child!,
              );
            },
            home: settingsState is SettingsInitial ||
                    settingsState is SettingsLoading
                ? const _SplashScreen()
                : onboardingComplete
                    ? MainScreen(key: MainScreen.mainKey)
                    : const OnboardingScreen(),
          );
        },
      ),
    );
  }
}

/// Minimal loading splash while settings are being read from disk.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
