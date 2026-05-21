import '../../domain/entities/prayer_info.dart';

/// States emitted by [PrayerTimesCubit].
sealed class PrayerTimesState {
  const PrayerTimesState();
}

final class PrayerTimesInitial extends PrayerTimesState {
  const PrayerTimesInitial();
}

final class PrayerTimesLoading extends PrayerTimesState {
  const PrayerTimesLoading();
}

final class PrayerTimesLoaded extends PrayerTimesState {
  final PrayerInfo prayerInfo;
  final SuggestedSession suggestedSession;
  const PrayerTimesLoaded({
    required this.prayerInfo,
    required this.suggestedSession,
  });
}

final class PrayerTimesError extends PrayerTimesState {
  final String message;
  const PrayerTimesError(this.message);
}
