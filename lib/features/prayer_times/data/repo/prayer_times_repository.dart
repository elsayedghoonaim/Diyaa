import 'package:flutter/foundation.dart';
import '../data_sources/prayer_times_local_data_source.dart';
import '../../domain/entities/prayer_info.dart';
import '../../../../features/settings/data/data_sources/settings_local_data_source.dart';
import '../../../../core/services/notification_service.dart';

/// Repository for prayer times data.
/// Coordinates GPS loading, caching of coordinates, and notification scheduling.
class PrayerTimesRepository {
  final PrayerTimesLocalDataSource _dataSource;
  final SettingsLocalDataSource _settingsDataSource;

  const PrayerTimesRepository({
    required PrayerTimesLocalDataSource dataSource,
    required SettingsLocalDataSource settingsDataSource,
  })  : _dataSource = dataSource,
        _settingsDataSource = settingsDataSource;

  /// Loads today's prayer times, attempting GPS first then falling back to cache.
  Future<PrayerInfo?> loadTodaysPrayers() async {
    final settings = await _settingsDataSource.loadSettings();

    PrayerInfo? info;

    if (!settings.useGps &&
        settings.latitude != null &&
        settings.longitude != null) {
      // Manual city — skip GPS
      info = _dataSource.computeFromCoords(
        settings.latitude!,
        settings.longitude!,
        label: settings.manualCityName.isNotEmpty ? settings.manualCityName : null,
      );
    } else {
      // GPS mode with timeout fallback
      try {
        info = await _dataSource
            .loadTodaysPrayers(
              lastLat: settings.latitude,
              lastLng: settings.longitude,
            )
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () => null,
            );
      } catch (e) {
        debugPrint('[PrayerTimesRepo] GPS error: $e');
      }

      // Fall back to cached coordinates
      if (info == null &&
          settings.latitude != null &&
          settings.longitude != null) {
        info = _dataSource.computeFromCoords(
          settings.latitude!,
          settings.longitude!,
        );
      }
    }

    // Absolute fallback — Makkah
    info ??= _dataSource.computeFromCoords(
      21.3891,
      39.8579,
      label: 'Makkah Al-Mukarramah (default)',
    );

    if (info != null) {
      await _settingsDataSource.saveCoordinates(info.latitude, info.longitude);
      await _scheduleNotifications(info, settings);
    }

    return info;
  }

  SuggestedSession? suggest(PrayerInfo? prayers) {
    if (prayers == null) return null;
    return _dataSource.suggest(prayers);
  }

  Future<void> _scheduleNotifications(
    PrayerInfo info,
    dynamic settings,
  ) async {
    try {
      await NotificationService.requestPermissions();
      await NotificationService.scheduleAll(
        _dataSource.toService(info),
        isArabic:    settings.arabicMode,
        notifPrayer: settings.notifPrayer,
        notifAzkar:  settings.notifAzkar,
        notifStreak: settings.notifStreak,
        soundEnabled: settings.soundEnabled,
        currentStreak: 0,
      );
    } catch (e) {
      debugPrint('[PrayerTimesRepo] scheduleNotifications error: $e');
    }
  }
}
