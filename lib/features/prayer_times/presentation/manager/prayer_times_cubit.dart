import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repo/prayer_times_repository.dart';
import '../../domain/entities/prayer_info.dart';
import 'prayer_times_state.dart';

/// Cubit responsible for loading and refreshing today's prayer times.
class PrayerTimesCubit extends Cubit<PrayerTimesState> {
  final PrayerTimesRepository _repository;

  PrayerTimesCubit({required PrayerTimesRepository repository})
      : _repository = repository,
        super(const PrayerTimesInitial());

  Future<void> loadPrayerTimes() async {
    if (state is PrayerTimesLoading) return;
    emit(const PrayerTimesLoading());
    try {
      final info = await _repository.loadTodaysPrayers();
      if (info != null) {
        final suggested =
            _repository.suggest(info) ?? SuggestedSession.none;
        emit(PrayerTimesLoaded(prayerInfo: info, suggestedSession: suggested));
      } else {
        emit(const PrayerTimesError('Could not determine prayer times.'));
      }
    } catch (e) {
      emit(PrayerTimesError('Prayer times error: $e'));
    }
  }

  Future<void> refreshPrayerTimes() => loadPrayerTimes();

  PrayerInfo? get currentPrayerInfo =>
      state is PrayerTimesLoaded
          ? (state as PrayerTimesLoaded).prayerInfo
          : null;
}
