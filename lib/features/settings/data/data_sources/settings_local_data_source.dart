import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/preference_keys.dart';
import '../models/settings_model.dart';

/// Reads and writes all user settings via SharedPreferences.
/// Responsible only for persistence — no business logic here.
class SettingsLocalDataSource {
  const SettingsLocalDataSource();

  Future<SettingsModel> loadSettings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int locVer = _readInt(prefs, kLocationPrefsVerKey, 0);
    if (locVer < kLocationPrefsVersion) {
      debugPrint('[SettingsDS] Location prefs v$locVer → v$kLocationPrefsVersion: resetting to GPS mode');
      await prefs.setBool(kUseGpsKey, true);
      await prefs.remove(kManualCityKey);
      await prefs.remove(kLatitudeKey);
      await prefs.remove(kLongitudeKey);
      await prefs.setInt(kLocationPrefsVerKey, kLocationPrefsVersion);
    }
    String salahSound = _readString(prefs, kSalahSoundKey, 'salah_enhanced_v4');
    if (salahSound == 'salah_enhanced') {
      salahSound = 'salah_enhanced_v4';
      await prefs.setString(kSalahSoundKey, 'salah_enhanced_v4');
    }
    return SettingsModel(
      darkMode:            _readBool(prefs, kDarkModeKey, false),
      arabicMode:          _readBool(prefs, kArabicModeKey, false),
      hijriDates:          _readBool(prefs, kHijriDatesKey, true),
      zikrFontSize:        _readString(prefs, kZikrFontSizeKey, 'medium'),
      appTextScale:        _readDouble(prefs, kAppTextScaleKey, 0.88),
      useGps:              _readBool(prefs, kUseGpsKey, true),
      manualCityName:      _readString(prefs, kManualCityKey, ''),
      latitude:            _readNullableDouble(prefs, kLatitudeKey),
      longitude:           _readNullableDouble(prefs, kLongitudeKey),
      notifPrayer:         _readBool(prefs, kNotifPrayerKey, true),
      notifAzkar:          _readBool(prefs, kNotifAzkarKey, true),
      notifStreak:         _readBool(prefs, kNotifStreakKey, true),
      notifMilestone:      _readBool(prefs, kNotifMilestoneKey, true),
      soundEnabled:        _readBool(prefs, kSoundEnabledKey, true),
      salahNotif:          _readBool(prefs, kSalahNotifKey, false),
      salahSound:          salahSound,
      salahInterval:       _readInt(prefs, kSalahIntervalKey, 60),
      salahOverrideSilent: _readBool(prefs, kSalahOverrideSilentKey, false),
      onboardingComplete:  _readBool(prefs, kOnboardingCompleteKey, false),
    );
  }

  bool _readBool(SharedPreferences prefs, String key, bool defaultValue) {
    try {
      final Object? value = prefs.get(key);
      if (value is bool) {
        return value;
      }
      if (value is String) {
        return value.toLowerCase() == 'true';
      }
      if (value is int) {
        return value != 0;
      }
      return defaultValue;
    } catch (e) {
      debugPrint('[SettingsLocalDataSource] Error reading boolean for key $key: $e');
      return defaultValue;
    }
  }

  double _readDouble(SharedPreferences prefs, String key, double defaultValue) {
    try {
      final Object? value = prefs.get(key);
      if (value is double) {
        return value;
      }
      if (value is int) {
        return value.toDouble();
      }
      if (value is String) {
        return double.tryParse(value) ?? defaultValue;
      }
      return defaultValue;
    } catch (e) {
      debugPrint('[SettingsLocalDataSource] Error reading double for key $key: $e');
      return defaultValue;
    }
  }

  double? _readNullableDouble(SharedPreferences prefs, String key) {
    try {
      final Object? value = prefs.get(key);
      if (value is double) {
        return value;
      }
      if (value is int) {
        return value.toDouble();
      }
      if (value is String) {
        return double.tryParse(value);
      }
      return null;
    } catch (e) {
      debugPrint('[SettingsLocalDataSource] Error reading nullable double for key $key: $e');
      return null;
    }
  }

  int _readInt(SharedPreferences prefs, String key, int defaultValue) {
    try {
      final Object? value = prefs.get(key);
      if (value is int) {
        return value;
      }
      if (value is double) {
        return value.toInt();
      }
      if (value is String) {
        return int.tryParse(value) ?? defaultValue;
      }
      return defaultValue;
    } catch (e) {
      debugPrint('[SettingsLocalDataSource] Error reading int for key $key: $e');
      return defaultValue;
    }
  }

  String _readString(SharedPreferences prefs, String key, String defaultValue) {
    try {
      final Object? value = prefs.get(key);
      if (value is String) {
        return value;
      }
      if (value != null) {
        return value.toString();
      }
      return defaultValue;
    } catch (e) {
      debugPrint('[SettingsLocalDataSource] Error reading string for key $key: $e');
      return defaultValue;
    }
  }

  Future<void> saveDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kDarkModeKey, value);
  }

  Future<void> saveArabicMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kArabicModeKey, value);
  }

  Future<void> saveHijriDates(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kHijriDatesKey, value);
  }

  Future<void> saveZikrFontSize(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kZikrFontSizeKey, value);
  }

  Future<void> saveAppTextScale(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(kAppTextScaleKey, value);
  }

  Future<void> saveGpsMode(bool useGps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kUseGpsKey, useGps);
  }

  Future<void> saveManualCity({
    required String cityName,
    required double lat,
    required double lng,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kUseGpsKey, false);
    await prefs.setString(kManualCityKey, cityName);
    await prefs.setDouble(kLatitudeKey, lat);
    await prefs.setDouble(kLongitudeKey, lng);
  }

  Future<void> saveCoordinates(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(kLatitudeKey, lat);
    await prefs.setDouble(kLongitudeKey, lng);
  }

  Future<void> saveNotifPrayer(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kNotifPrayerKey, value);
  }

  Future<void> saveNotifAzkar(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kNotifAzkarKey, value);
  }

  Future<void> saveNotifStreak(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kNotifStreakKey, value);
  }

  Future<void> saveNotifMilestone(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kNotifMilestoneKey, value);
  }

  Future<void> saveSoundEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kSoundEnabledKey, value);
  }

  Future<void> saveSalahNotif(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kSalahNotifKey, value);
  }

  Future<void> saveSalahSound(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kSalahSoundKey, value);
  }

  Future<void> saveSalahInterval(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(kSalahIntervalKey, minutes);
  }

  Future<void> saveSalahOverrideSilent(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kSalahOverrideSilentKey, value);
  }

  Future<void> saveOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kOnboardingCompleteKey, true);
  }
}
