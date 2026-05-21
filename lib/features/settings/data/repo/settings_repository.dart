import 'package:flutter/foundation.dart';
import '../data_sources/settings_local_data_source.dart';
import '../models/settings_model.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../features/prayer_times/data/data_sources/prayer_times_local_data_source.dart';

/// Repository that orchestrates settings persistence and side-effects such as
/// rescheduling notifications after relevant preference changes.
class SettingsRepository {
  final SettingsLocalDataSource _dataSource;
  final PrayerTimesLocalDataSource _prayerTimesDataSource;

  const SettingsRepository({
    required SettingsLocalDataSource dataSource,
    required PrayerTimesLocalDataSource prayerTimesDataSource,
  })  : _dataSource = dataSource,
        _prayerTimesDataSource = prayerTimesDataSource;

  Future<SettingsModel> loadSettings() => _dataSource.loadSettings();

  Future<SettingsModel> setDarkMode(SettingsModel current, bool value) async {
    await _dataSource.saveDarkMode(value);
    try {
      await appIconChannel.invokeMethod('changeIcon', {'darkMode': value});
    } catch (e) {
      debugPrint('[SettingsRepo] Launcher icon sync failed: $e');
    }
    return current.copyWith(darkMode: value);
  }

  Future<SettingsModel> setArabicMode(SettingsModel current, bool value) async {
    await _dataSource.saveArabicMode(value);
    final updated = current.copyWith(arabicMode: value);
    await _rescheduleNotifications(updated);
    return updated;
  }

  Future<SettingsModel> setHijriDates(SettingsModel current, bool value) async {
    await _dataSource.saveHijriDates(value);
    return current.copyWith(hijriDates: value);
  }

  Future<SettingsModel> setZikrFontSize(SettingsModel current, String value) async {
    await _dataSource.saveZikrFontSize(value);
    return current.copyWith(zikrFontSize: value);
  }

  Future<SettingsModel> setAppTextScale(SettingsModel current, double value) async {
    await _dataSource.saveAppTextScale(value);
    return current.copyWith(appTextScale: value);
  }

  Future<SettingsModel> setUseGps(SettingsModel current, bool value) async {
    await _dataSource.saveGpsMode(value);
    return current.copyWith(useGps: value);
  }

  Future<SettingsModel> setManualCity(
    SettingsModel current, {
    required String cityName,
    required double lat,
    required double lng,
  }) async {
    await _dataSource.saveManualCity(cityName: cityName, lat: lat, lng: lng);
    return current.copyWith(
      useGps: false,
      manualCityName: cityName,
      latitude: lat,
      longitude: lng,
    );
  }

  Future<SettingsModel> setNotifPrayer(SettingsModel current, bool value) async {
    await _dataSource.saveNotifPrayer(value);
    final updated = current.copyWith(notifPrayer: value);
    await _rescheduleNotifications(updated);
    return updated;
  }

  Future<SettingsModel> setNotifAzkar(SettingsModel current, bool value) async {
    await _dataSource.saveNotifAzkar(value);
    final updated = current.copyWith(notifAzkar: value);
    await _rescheduleNotifications(updated);
    return updated;
  }

  Future<SettingsModel> setNotifStreak(
    SettingsModel current,
    bool value, {
    required int currentStreak,
  }) async {
    await _dataSource.saveNotifStreak(value);
    final updated = current.copyWith(notifStreak: value);
    try {
      await NotificationService.scheduleStreakWarning(
        enabled: value,
        isArabic: updated.arabicMode,
        currentStreak: currentStreak,
        soundEnabled: updated.soundEnabled,
      );
    } catch (_) {}
    return updated;
  }

  Future<SettingsModel> setNotifMilestone(SettingsModel current, bool value) async {
    await _dataSource.saveNotifMilestone(value);
    return current.copyWith(notifMilestone: value);
  }

  Future<SettingsModel> setSoundEnabled(SettingsModel current, bool value) async {
    await _dataSource.saveSoundEnabled(value);
    final updated = current.copyWith(soundEnabled: value);
    await _rescheduleSalahNabi(updated);
    await _rescheduleNotifications(updated);
    return updated;
  }

  Future<SettingsModel> setSalahNotif(SettingsModel current, bool value) async {
    await _dataSource.saveSalahNotif(value);
    final updated = current.copyWith(salahNotif: value);
    await _rescheduleSalahNabi(updated);
    return updated;
  }

  Future<SettingsModel> setSalahSound(SettingsModel current, String value) async {
    await _dataSource.saveSalahSound(value);
    final updated = current.copyWith(salahSound: value);
    if (updated.salahNotif) await _rescheduleSalahNabi(updated);
    return updated;
  }

  Future<SettingsModel> setSalahInterval(SettingsModel current, int minutes) async {
    await _dataSource.saveSalahInterval(minutes);
    final updated = current.copyWith(salahInterval: minutes);
    if (updated.salahNotif) await _rescheduleSalahNabi(updated);
    return updated;
  }

  Future<SettingsModel> setSalahOverrideSilent(SettingsModel current, bool value) async {
    await _dataSource.saveSalahOverrideSilent(value);
    final updated = current.copyWith(salahOverrideSilent: value);
    if (updated.salahNotif) await _rescheduleSalahNabi(updated);
    return updated;
  }

  Future<SettingsModel> completeOnboarding(SettingsModel current) async {
    await _dataSource.saveOnboardingComplete();
    return current.copyWith(onboardingComplete: true);
  }

  Future<void> syncLauncherIcon(bool darkMode) async {
    try {
      await appIconChannel.invokeMethod('changeIcon', {'darkMode': darkMode});
    } catch (e) {
      debugPrint('[SettingsRepo] Launcher icon sync failed: $e');
    }
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  Future<void> _rescheduleNotifications(SettingsModel settings) async {
    final prayerInfo = _prayerTimesDataSource.loadCachedPrayerTimes(
      latitude: settings.latitude,
      longitude: settings.longitude,
    );
    if (prayerInfo == null) return;
    try {
      await NotificationService.requestPermissions();
      await NotificationService.scheduleAll(
        _prayerTimesDataSource.toService(prayerInfo),
        isArabic:    settings.arabicMode,
        notifPrayer: settings.notifPrayer,
        notifAzkar:  settings.notifAzkar,
        notifStreak: settings.notifStreak,
        soundEnabled: settings.soundEnabled,
      );
      await _rescheduleSalahNabi(settings);
    } catch (e) {
      debugPrint('[SettingsRepo] _rescheduleNotifications failed: $e');
    }
  }

  Future<void> _rescheduleSalahNabi(SettingsModel settings) async {
    try {
      await NotificationService.scheduleSalahNabiReminders(
        enabled:         settings.salahNotif,
        soundAsset:      settings.salahSound,
        intervalMinutes: settings.salahInterval,
        overrideSilent:  settings.salahOverrideSilent,
        soundEnabled:    settings.soundEnabled,
      );
    } catch (e) {
      debugPrint('[SettingsRepo] _rescheduleSalahNabi failed: $e');
    }
  }
}
