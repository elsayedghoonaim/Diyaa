import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:diyaa_app/core/services/notification_service.dart';
import 'package:diyaa_app/features/settings/data/data_sources/settings_local_data_source.dart';
import 'package:diyaa_app/features/settings/data/repo/settings_repository.dart';
import 'package:diyaa_app/features/settings/presentation/manager/settings_cubit.dart';
import 'package:diyaa_app/features/prayer_times/data/data_sources/prayer_times_local_data_source.dart';
import 'package:diyaa_app/features/prayer_times/data/repo/prayer_times_repository.dart';
import 'package:diyaa_app/features/prayer_times/presentation/manager/prayer_times_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel iconChannel = MethodChannel('diyaa_icon_channel');
  const MethodChannel alarmChannel = MethodChannel('diyaa_alarm_channel');
  const MethodChannel geolocatorChannel = MethodChannel('flutter.baseflow.com/geolocator');
  const MethodChannel localNotificationsChannel = MethodChannel('dexterous.com/flutter/local_notifications');
  const MethodChannel audioplayersChannel = MethodChannel('xyz.luan/audioplayers');

  final List<MethodCall> mockCalls = [];

  setUp(() async {
    mockCalls.clear();
    SharedPreferences.setMockInitialValues({
      'diyaa-sound-enabled': true,
      'diyaa-lat': 30.0444,
      'diyaa-lng': 31.2357,
      'diyaa-manual-city': 'Cairo',
      'diyaa-use-gps': true,
      'diyaa-location-prefs-ver': 2,
    });

    // Mock Icon channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(iconChannel, (MethodCall call) async {
      mockCalls.add(call);
      return true;
    });

    // Mock Alarm channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(alarmChannel, (MethodCall call) async {
      mockCalls.add(call);
      return true;
    });

    // Mock Geolocator channel to throw error to simulate GPS failure/timeout
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(geolocatorChannel, (MethodCall call) async {
      mockCalls.add(call);
      if (call.method == 'checkPermission' || call.method == 'requestPermission') {
        return 0; // LocationPermission.denied
      }
      throw PlatformException(code: 'GPS_ERROR', message: 'Simulated GPS error/timeout');
    });

    // Mock Local Notifications channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(localNotificationsChannel, (MethodCall call) async {
      mockCalls.add(call);
      if (call.method == 'initialize') {
        return true;
      }
      if (call.method == 'canScheduleExactNotifications') {
        return true;
      }
      return null;
    });

    // Mock Audioplayers channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioplayersChannel, (MethodCall call) async {
      mockCalls.add(call);
      return null;
    });

    // Initialize the platform-specific plugin instance for tests
    FlutterLocalNotificationsPlatform.instance = AndroidFlutterLocalNotificationsPlugin();

    // Initialize notification service timezone fallbacks
    await NotificationService.initialize();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(iconChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(alarmChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(geolocatorChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(localNotificationsChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioplayersChannel, null);
  });

  test('Cubit initialization schedules notifications even when GPS fails/timeouts', () async {
    final settingsDs = const SettingsLocalDataSource();
    final prayerTimesDs = const PrayerTimesLocalDataSource();

    final settingsRepo = SettingsRepository(
      dataSource: settingsDs,
      prayerTimesDataSource: prayerTimesDs,
    );
    final prayerTimesRepo = PrayerTimesRepository(
      dataSource: prayerTimesDs,
      settingsDataSource: settingsDs,
    );

    final settingsCubit = SettingsCubit(repository: settingsRepo);
    final prayerTimesCubit = PrayerTimesCubit(repository: prayerTimesRepo);

    // Load settings first (which will load the cached coordinates)
    await settingsCubit.loadSettings();

    // Load prayer times (attempts GPS, fails, then falls back to cached coords)
    await prayerTimesCubit.loadPrayerTimes();

    // Verify coordinates fallback to cached ones (Cairo lat: 30.0444, lng: 31.2357)
    final info = prayerTimesCubit.currentPrayerInfo;
    expect(info, isNotNull);
    expect(info!.latitude, closeTo(30.0444, 0.0001));
    expect(info.longitude, closeTo(31.2357, 0.0001));

    // Verify that notifications were scheduled on local notifications channel
    final zonedScheduleCalls = mockCalls
        .where((c) => c.method == 'zonedSchedule')
        .toList();

    // Total scheduled: 5 prayers + 9 azkar + 1 weekly Jumuah = 15 notifications scheduled!
    expect(zonedScheduleCalls.isNotEmpty, true);
    expect(zonedScheduleCalls.length, 15);
  });

  test('setSoundEnabled toggles dynamic channels deletion and rescheduling', () async {
    final settingsDs = const SettingsLocalDataSource();
    final prayerTimesDs = const PrayerTimesLocalDataSource();

    final settingsRepo = SettingsRepository(
      dataSource: settingsDs,
      prayerTimesDataSource: prayerTimesDs,
    );
    final prayerTimesRepo = PrayerTimesRepository(
      dataSource: prayerTimesDs,
      settingsDataSource: settingsDs,
    );

    final settingsCubit = SettingsCubit(repository: settingsRepo);
    final prayerTimesCubit = PrayerTimesCubit(repository: prayerTimesRepo);

    await settingsCubit.loadSettings();
    await prayerTimesCubit.loadPrayerTimes();

    mockCalls.clear();

    // Toggle sound preference to false
    await settingsCubit.setSoundEnabled(false);

    // Verify Settings state updated
    expect(settingsCubit.currentSettings!.soundEnabled, false);

    // Verify deletion of the standard notification channels
    final deleteChannelCalls = mockCalls
        .where((c) => c.method == 'deleteNotificationChannel')
        .map((c) {
          if (c.arguments is String) return c.arguments as String;
          if (c.arguments is Map) return c.arguments['channelId'] as String;
          return c.arguments.toString();
        })
        .toList();

    // In app_v2, these channels should be cleaned up (deleted and recreated with new sound preference):
    expect(deleteChannelCalls.contains('diyaa_prayer'), true);
    expect(deleteChannelCalls.contains('diyaa_azkar'), true);

    // Streak/milestone channels do not need sound preference updates, so they shouldn't be deleted:
    expect(deleteChannelCalls.contains('diyaa_streak'), false);

    // Verify that notifications were rescheduled
    final reschedCalls = mockCalls
        .where((c) => c.method == 'zonedSchedule')
        .toList();
    expect(reschedCalls.length, 15);
  });
}
