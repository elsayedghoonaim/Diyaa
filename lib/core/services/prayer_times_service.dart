import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// The session that should be highlighted/suggested right now based on local time.
enum SuggestedSession { morning, evening, sleep, wakeup, postPrayer, none }

class PrayerInfo {
  final DateTime fajr;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final String cityLabel;
  final double latitude;
  final double longitude;
  final String methodName; // For display in settings

  const PrayerInfo({
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.cityLabel,
    required this.latitude,
    required this.longitude,
    this.methodName = '',
  });
}

class PrayerTimesService {
  // ── Regional method selector ──────────────────────────────────────────────
  //
  // Picks the most appropriate calculation method based on coordinates.
  // No manual selection needed — fully automatic.
  //
  //  • Arabian Peninsula / Gulf   → Umm Al-Qura (Makkah)
  //  • North Africa / Egypt       → Egyptian General Authority
  //  • South/Southeast Asia       → Karachi (UISA)
  //  • Rest of the world          → Muslim World League (default)
  static CalculationParameters _methodForCoords(double lat, double lng) {
    // Saudi Arabia, UAE, Kuwait, Qatar, Bahrain, Oman, Yemen
    if (lat >= 12 && lat <= 32 && lng >= 34 && lng <= 60) {
      final params = CalculationMethodParameters.ummAlQura();
      params.madhab = Madhab.shafi;
      return params;
    }
    // Egypt, Libya, Sudan, Algeria, Morocco, Tunisia
    if (lat >= 15 && lat <= 38 && lng >= -14 && lng <= 36) {
      final params = CalculationMethodParameters.egyptian();
      params.madhab = Madhab.shafi;
      return params;
    }
    // Pakistan, Bangladesh, India
    if (lat >= 6 && lat <= 38 && lng >= 60 && lng <= 96) {
      final params = CalculationMethodParameters.karachi();
      params.madhab = Madhab.hanafi;
      return params;
    }
    // Default: Muslim World League
    final params = CalculationMethodParameters.muslimWorldLeague();
    params.madhab = Madhab.shafi;
    return params;
  }

  static String methodNameForCoords(double lat, double lng) {
    if (lat >= 12 && lat <= 32 && lng >= 34 && lng <= 60) {
      return 'Umm Al-Qura (Makkah)';
    }
    if (lat >= 15 && lat <= 38 && lng >= -14 && lng <= 36) {
      return 'Egyptian General Authority';
    }
    if (lat >= 6 && lat <= 38 && lng >= 60 && lng <= 96) {
      return 'Karachi (UISA)';
    }
    return 'Muslim World League';
  }

  // ── Compute times from raw coordinates (no GPS call) ─────────────────────
  /// Calculates prayer times for the given lat/lng immediately without
  /// touching GPS. Used for startup cache and offline/unsupported platforms.
  ///
  /// DST note: always passes the UTC date to adhan_dart so astronomical
  /// calculations are stable. The library returns UTC DateTimes which we
  /// convert to local (DST-aware) using [_toLocal].
  static PrayerInfo? computeFromCoords(double lat, double lng, {String? label}) {
    try {
      final params = _methodForCoords(lat, lng);
      final methodName = methodNameForCoords(lat, lng);
      final coordinates = Coordinates(lat, lng);

      // Use local DateTime — the library extracts year/month/day from it
      // to anchor the solar calculation to the correct calendar date.
      final now = DateTime.now();

      debugPrint('[PrayerTimes] Computing for $lat,$lng | '
          'local=$now | tz=${now.timeZoneName} offset=${now.timeZoneOffset}');

      final times = PrayerTimes(
        coordinates: coordinates,
        date: now,
        calculationParameters: params,
        precision: true,
      );

      // adhan_dart returns DateTime.utc(...) — convert to local (DST-aware)
      DateTime toLocal(DateTime dt) => dt.isUtc ? dt.toLocal() : dt;

      final fajr    = toLocal(times.fajr);
      final dhuhr   = toLocal(times.dhuhr);
      final asr     = toLocal(times.asr);
      final maghrib = toLocal(times.maghrib);
      final isha    = toLocal(times.isha);

      debugPrint('[PrayerTimes] Fajr=$fajr  Dhuhr=$dhuhr  Maghrib=$maghrib  Isha=$isha');

      return PrayerInfo(
        fajr:    fajr,
        dhuhr:   dhuhr,
        asr:     asr,
        maghrib: maghrib,
        isha:    isha,
        cityLabel: label ?? '${lat.toStringAsFixed(2)}°N, ${lng.toStringAsFixed(2)}°E',
        latitude: lat,
        longitude: lng,
        methodName: methodName,
      );
    } catch (e) {
      debugPrint('[PrayerTimes] computeFromCoords error: $e');
      return null;
    }
  }

  // ── GPS fetch + compute ───────────────────────────────────────────────────
  /// Fetches the device GPS position and computes today's prayer times.
  ///
  /// Falls back gracefully through:
  ///   1. Live GPS position
  ///   2. Last known GPS position
  ///   3. Provided cached [lastLat]/[lastLng]
  ///   4. Makkah default (21.39°N, 39.86°E)
  ///
  /// GPS is skipped entirely on unsupported platforms (Linux/Web desktop).
  static Future<PrayerInfo?> loadTodaysPrayers({
    double? lastLat,
    double? lastLng,
  }) async {
    // ── A: Try GPS (Android / iOS / Windows only) ──
    double? gpsLat;
    double? gpsLng;

    final isGpsSupported = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.windows;

    if (isGpsSupported) {
      try {
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }

        if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
          // Try last known first (instant)
          Position? pos = await Geolocator.getLastKnownPosition();

          // If not available, fetch fresh with a short timeout
          if (pos == null) {
            try {
              pos = await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.low,
                  timeLimit: Duration(seconds: 6),
                ),
              );
            } catch (_) {
              // Timeout or unsupported — fall through to cache
            }
          }

          if (pos != null) {
            gpsLat = pos.latitude;
            gpsLng = pos.longitude;
            debugPrint('[PrayerTimes] GPS success: $gpsLat, $gpsLng');
          }
        } else {
          debugPrint('[PrayerTimes] Location permission denied: $perm');
        }
      } catch (e) {
        debugPrint('[PrayerTimes] GPS error (ignored): $e');
      }
    } else {
      debugPrint('[PrayerTimes] GPS not supported on ${defaultTargetPlatform.name} — using cache/fallback');
    }

    // ── B: Choose best available coordinates ──
    final double lat;
    final double lng;
    final String label;

    if (gpsLat != null && gpsLng != null) {
      lat = gpsLat;
      lng = gpsLng;
      label = '${lat.toStringAsFixed(2)}°N, ${lng.toStringAsFixed(2)}°E';
    } else if (lastLat != null && lastLng != null) {
      lat = lastLat;
      lng = lastLng;
      label = '${lat.toStringAsFixed(2)}°N, ${lng.toStringAsFixed(2)}°E (cached)';
      debugPrint('[PrayerTimes] Using cached coordinates: $lat, $lng');
    } else {
      // Makkah fallback — at least shows correct times for most users
      lat = 21.3891;
      lng = 39.8579;
      label = 'Makkah Al-Mukarramah (default)';
      debugPrint('[PrayerTimes] Using Makkah default coordinates');
    }

    // ── C: Compute prayer times ──
    return computeFromCoords(lat, lng, label: label);
  }

  // ── Session suggestion ────────────────────────────────────────────────────
  static SuggestedSession suggest(PrayerInfo prayers) {
    final now = DateTime.now();

    bool inWindow(DateTime start, int afterMinutes) {
      final end = start.add(Duration(minutes: afterMinutes));
      return now.isAfter(start) && now.isBefore(end);
    }

    if (inWindow(prayers.fajr, 30)) return SuggestedSession.morning;
    if (inWindow(prayers.dhuhr, 30)) return SuggestedSession.postPrayer;
    if (inWindow(prayers.asr, 30)) return SuggestedSession.postPrayer;

    final eveningStart = prayers.asr.add(const Duration(minutes: 30));
    if (now.isAfter(eveningStart) && now.isBefore(prayers.maghrib)) {
      return SuggestedSession.evening;
    }

    if (inWindow(prayers.maghrib, 30)) return SuggestedSession.postPrayer;

    final midnight = DateTime(now.year, now.month, now.day + 1);
    if (now.isAfter(prayers.isha) && now.isBefore(midnight)) {
      return SuggestedSession.sleep;
    }

    final earlyMorningStart = DateTime(now.year, now.month, now.day);
    if (now.isAfter(earlyMorningStart) && now.isBefore(prayers.fajr)) {
      return SuggestedSession.wakeup;
    }

    final morningStart = prayers.fajr.add(const Duration(minutes: 30));
    if (now.isAfter(morningStart) && now.isBefore(prayers.dhuhr)) {
      return SuggestedSession.morning;
    }

    return SuggestedSession.none;
  }

  static String sessionId(SuggestedSession s) {
    switch (s) {
      case SuggestedSession.morning:     return 'morning';
      case SuggestedSession.evening:     return 'morning';
      case SuggestedSession.sleep:       return 'sleep';
      case SuggestedSession.wakeup:      return 'wakeup';
      case SuggestedSession.postPrayer:  return 'cat_7';
      case SuggestedSession.none:        return 'morning';
    }
  }
}
