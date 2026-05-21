import '../../domain/entities/prayer_info.dart';
import '../../../../core/services/prayer_times_service.dart' as service;

/// Data source that wraps the static PrayerTimesService methods.
/// Returns domain entities — no raw maps or primitives exposed.
class PrayerTimesLocalDataSource {
  const PrayerTimesLocalDataSource();

  /// Loads today's prayer times using GPS (or falls back to cached coords).
  Future<PrayerInfo?> loadTodaysPrayers({
    double? lastLat,
    double? lastLng,
  }) async {
    final result = await service.PrayerTimesService.loadTodaysPrayers(
      lastLat: lastLat,
      lastLng: lastLng,
    );
    return result == null ? null : fromService(result);
  }

  /// Computes prayer times immediately from known coordinates (no GPS call).
  PrayerInfo? computeFromCoords(
    double lat,
    double lng, {
    String? label,
  }) {
    final result = service.PrayerTimesService.computeFromCoords(lat, lng, label: label);
    return result == null ? null : fromService(result);
  }

  /// Suggests the session to highlight right now.
  SuggestedSession suggest(PrayerInfo prayers) {
    final suggested = service.PrayerTimesService.suggest(toService(prayers));
    switch (suggested) {
      case service.SuggestedSession.morning:
        return SuggestedSession.morning;
      case service.SuggestedSession.evening:
        return SuggestedSession.evening;
      case service.SuggestedSession.sleep:
        return SuggestedSession.sleep;
      case service.SuggestedSession.wakeup:
        return SuggestedSession.wakeup;
      case service.SuggestedSession.postPrayer:
        return SuggestedSession.postPrayer;
      case service.SuggestedSession.none:
        return SuggestedSession.none;
    }
  }

  /// Returns cached prayer times from coordinates without making a GPS call.
  /// Used by SettingsRepository when rescheduling notifications.
  PrayerInfo? loadCachedPrayerTimes({
    required double? latitude,
    required double? longitude,
  }) {
    if (latitude == null || longitude == null) return null;
    return computeFromCoords(latitude, longitude);
  }

  // ── Adapters ──────────────────────────────────────────────────────────────

  PrayerInfo fromService(service.PrayerInfo s) => PrayerInfo(
        fajr:      s.fajr,
        dhuhr:     s.dhuhr,
        asr:       s.asr,
        maghrib:   s.maghrib,
        isha:      s.isha,
        cityLabel: s.cityLabel,
        latitude:  s.latitude,
        longitude: s.longitude,
        methodName: s.methodName,
      );

  service.PrayerInfo toService(PrayerInfo p) => service.PrayerInfo(
        fajr:      p.fajr,
        dhuhr:     p.dhuhr,
        asr:       p.asr,
        maghrib:   p.maghrib,
        isha:      p.isha,
        cityLabel: p.cityLabel,
        latitude:  p.latitude,
        longitude: p.longitude,
        methodName: p.methodName,
      );
}
