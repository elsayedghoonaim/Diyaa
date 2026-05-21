/// The session that should be highlighted/suggested right now based on local time.
enum SuggestedSession { morning, evening, sleep, wakeup, postPrayer, none }

/// Pure domain entity for today's prayer times.
/// No Flutter or platform dependencies — safe for unit testing.
class PrayerInfo {
  final DateTime fajr;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final String cityLabel;
  final double latitude;
  final double longitude;
  final String methodName;

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
