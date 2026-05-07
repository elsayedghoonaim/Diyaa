import 'package:adhan_dart/adhan_dart.dart';
import 'package:geolocator/geolocator.dart';

/// The session that should be highlighted/suggested right now based on local time.
enum SuggestedSession { morning, evening, sleep, wakeup, postPrayer, none }

class PrayerInfo {
  final DateTime fajr;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final String cityLabel; // e.g. "21.3891°N, 39.8579°E"

  const PrayerInfo({
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.cityLabel,
  });
}

class PrayerTimesService {
  /// Requests location permission if useLocation is true, then computes today's prayer times.
  /// If useLocation is false or permission is denied, it defaults to Riyadh.
  static Future<PrayerInfo?> loadTodaysPrayers({bool useLocation = false}) async {
    try {
      Position? pos;
      
      if (useLocation) {
        // 1. Check & request permission
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm != LocationPermission.denied && perm != LocationPermission.deniedForever) {
          // 2. Get current position
          pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 10),
            ),
          );
        }
      }

      // Fallback to Riyadh
      final lat = pos?.latitude ?? 24.7136;
      final lng = pos?.longitude ?? 46.6753;
      final label = pos != null 
          ? '${lat.toStringAsFixed(2)}°N, ${lng.toStringAsFixed(2)}°E' 
          : 'Riyadh';

      // 3. Calculate prayer times using Adhan
      final coordinates = Coordinates(lat, lng);
      final params = CalculationMethodParameters.muslimWorldLeague();
      params.madhab = Madhab.shafi;

      final now = DateTime.now();
      final times = PrayerTimes(
        coordinates: coordinates,
        date: now,
        calculationParameters: params,
        precision: true,
      );

      return PrayerInfo(
        fajr: times.fajr.toLocal(),
        dhuhr: times.dhuhr.toLocal(),
        asr: times.asr.toLocal(),
        maghrib: times.maghrib.toLocal(),
        isha: times.isha.toLocal(),
        cityLabel: label,
      );
    } catch (_) {
      return null;
    }
  }

  /// Determines which session to suggest based on current time vs prayer times.
  ///
  /// Logic:
  ///  • Fajr → Fajr+1h    : Morning Azkar (morning)
  ///  • After each prayer ±30 min : Post-Prayer Dhikr (postPrayer)
  ///  • Asr → Maghrib-30min: Evening Azkar (evening)
  ///  • Isha → Midnight    : Sleep Azkar (sleep)
  ///  • Midnight → Fajr    : Waking Up / Night (wakeup)
  static SuggestedSession suggest(PrayerInfo prayers) {
    final now = DateTime.now();

    // Window helpers
    bool inWindow(DateTime start, int afterMinutes) {
      final end = start.add(Duration(minutes: afterMinutes));
      return now.isAfter(start) && now.isBefore(end);
    }

    // Post-prayer window: 30 min after each prayer
    if (inWindow(prayers.fajr, 30)) return SuggestedSession.morning;
    if (inWindow(prayers.dhuhr, 30)) return SuggestedSession.postPrayer;
    if (inWindow(prayers.asr, 30)) return SuggestedSession.postPrayer;

    // Evening: from Asr+30min to Maghrib
    final eveningStart = prayers.asr.add(const Duration(minutes: 30));
    if (now.isAfter(eveningStart) && now.isBefore(prayers.maghrib)) {
      return SuggestedSession.evening;
    }

    if (inWindow(prayers.maghrib, 30)) return SuggestedSession.postPrayer;

    // Sleep: from Isha to midnight
    final midnight = DateTime(now.year, now.month, now.day + 1);
    if (now.isAfter(prayers.isha) && now.isBefore(midnight)) {
      return SuggestedSession.sleep;
    }

    // Early morning: midnight to Fajr
    final earlyMorningStart = DateTime(now.year, now.month, now.day);
    if (now.isAfter(earlyMorningStart) && now.isBefore(prayers.fajr)) {
      return SuggestedSession.wakeup;
    }

    // Morning window: Fajr+30min to Dhuhr
    final morningStart = prayers.fajr.add(const Duration(minutes: 30));
    if (now.isAfter(morningStart) && now.isBefore(prayers.dhuhr)) {
      return SuggestedSession.morning;
    }

    return SuggestedSession.none;
  }

  /// Maps SuggestedSession to the azkar.json session id string.
  static String sessionId(SuggestedSession s) {
    switch (s) {
      case SuggestedSession.morning:
        return 'morning';
      case SuggestedSession.evening:
        return 'morning'; // same JSON session, user sees context from time
      case SuggestedSession.sleep:
        return 'sleep';
      case SuggestedSession.wakeup:
        return 'wakeup';
      case SuggestedSession.postPrayer:
        return 'cat_7'; // Post-wudu / post-prayer dhikr
      case SuggestedSession.none:
        return 'morning';
    }
  }
}
