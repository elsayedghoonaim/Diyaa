import 'package:flutter/services.dart';

/// Immutable snapshot of all user-configurable settings.
/// [copyWith] produces a modified clone without mutating the original.
class SettingsModel {
  final bool darkMode;
  final bool arabicMode;
  final bool hijriDates;
  final String zikrFontSize;
  final double appTextScale;

  // Location
  final bool useGps;
  final String manualCityName;
  final double? latitude;
  final double? longitude;

  // Notifications
  final bool notifPrayer;
  final bool notifAzkar;
  final bool notifStreak;
  final bool notifMilestone;
  final bool soundEnabled;

  // Al-Salah 'ala Al-Nabi
  final bool salahNotif;
  final String salahSound;
  final int salahInterval;
  final bool salahOverrideSilent;

  // Onboarding
  final bool onboardingComplete;

  const SettingsModel({
    this.darkMode = false,
    this.arabicMode = false,
    this.hijriDates = true,
    this.zikrFontSize = 'medium',
    this.appTextScale = 0.88,
    this.useGps = true,
    this.manualCityName = '',
    this.latitude,
    this.longitude,
    this.notifPrayer = true,
    this.notifAzkar = true,
    this.notifStreak = true,
    this.notifMilestone = true,
    this.soundEnabled = true,
    this.salahNotif = false,
    this.salahSound = 'salah_enhanced',
    this.salahInterval = 60,
    this.salahOverrideSilent = false,
    this.onboardingComplete = false,
  });

  SettingsModel copyWith({
    bool? darkMode,
    bool? arabicMode,
    bool? hijriDates,
    String? zikrFontSize,
    double? appTextScale,
    bool? useGps,
    String? manualCityName,
    double? latitude,
    double? longitude,
    bool? notifPrayer,
    bool? notifAzkar,
    bool? notifStreak,
    bool? notifMilestone,
    bool? soundEnabled,
    bool? salahNotif,
    String? salahSound,
    int? salahInterval,
    bool? salahOverrideSilent,
    bool? onboardingComplete,
  }) {
    return SettingsModel(
      darkMode: darkMode ?? this.darkMode,
      arabicMode: arabicMode ?? this.arabicMode,
      hijriDates: hijriDates ?? this.hijriDates,
      zikrFontSize: zikrFontSize ?? this.zikrFontSize,
      appTextScale: appTextScale ?? this.appTextScale,
      useGps: useGps ?? this.useGps,
      manualCityName: manualCityName ?? this.manualCityName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      notifPrayer: notifPrayer ?? this.notifPrayer,
      notifAzkar: notifAzkar ?? this.notifAzkar,
      notifStreak: notifStreak ?? this.notifStreak,
      notifMilestone: notifMilestone ?? this.notifMilestone,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      salahNotif: salahNotif ?? this.salahNotif,
      salahSound: salahSound ?? this.salahSound,
      salahInterval: salahInterval ?? this.salahInterval,
      salahOverrideSilent: salahOverrideSilent ?? this.salahOverrideSilent,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }
}

/// Native MethodChannel for the adaptive launcher icon feature.
const MethodChannel appIconChannel = MethodChannel('diyaa_icon_channel');
