import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repo/azkar_repository.dart';
import '../../domain/entities/zikr.dart';
import '../../../../core/constants/preference_keys.dart';
import '../../../../core/utils/arabic_utils.dart';
import '../../../prayer_times/domain/entities/prayer_info.dart';
import 'azkar_state.dart';

/// Manages per-session Zikr progress.
/// Handles tapping, index advancing, persistence, and completion detection.
class ZikrCubit extends Cubit<ZikrState> {
  final AzkarRepository _repository;

  ZikrCubit({required AzkarRepository repository})
      : _repository = repository,
        super(const ZikrInitial());

  /// Loads a session and restores previously saved progress.
  Future<void> loadSession(String sessionId, {PrayerInfo? prayerInfo}) async {
    emit(const ZikrLoading());
    try {
      var session = await _repository.loadSession(sessionId);
      if (session == null) {
        emit(const ZikrError('Session not found'));
        return;
      }
      if ((sessionId == 'cat_7' || sessionId == '27') && prayerInfo != null) {
        final now = DateTime.now();
        String completedPrayer;
        if (now.isAfter(prayerInfo.fajr) && now.isBefore(prayerInfo.dhuhr)) {
          completedPrayer = 'fajr';
        } else if (now.isAfter(prayerInfo.dhuhr) && now.isBefore(prayerInfo.asr)) {
          completedPrayer = 'dhuhr';
        } else if (now.isAfter(prayerInfo.asr) && now.isBefore(prayerInfo.maghrib)) {
          completedPrayer = 'asr';
        } else if (now.isAfter(prayerInfo.maghrib) && now.isBefore(prayerInfo.isha)) {
          completedPrayer = 'maghrib';
        } else {
          completedPrayer = 'isha';
        }
        final filteredZikrs = session.zikrs.where((z) {
          if (z.arabic.contains('أَسْأَلُـكَ عِلْمـاً') || z.arabic.contains('أَسْأَلُكَ عِلْماً') || normalizeArabic(z.arabic).contains('اسالك علما')) {
            return completedPrayer == 'fajr';
          }
          if (z.arabic.contains('لا إلهَ إلاّ اللّهُ وحْـدَهُ') || z.arabic.contains('لاَ إِلَهَ إِلاَّ اللَّهُ وَحْدَهُ') || normalizeArabic(z.arabic).contains('لا اله الا الله وحده') ||
              z.arabic.contains('أَجِرْنِي') || normalizeArabic(z.arabic).contains('اجرني')) {
            return completedPrayer == 'fajr' || completedPrayer == 'maghrib';
          }
          return true;
        }).toList();
        session = AzkarSession(
          id: session.id,
          nameAr: session.nameAr,
          nameEn: session.nameEn,
          zikrs: filteredZikrs,
        );
      }
      final savedIndex = await _loadSavedIndex(sessionId);
      final savedCounts = await _loadSavedCounts(sessionId);
      final totalZikrs = session.zikrs.length;
      final index = (savedIndex < totalZikrs) ? savedIndex : 0;
      final counts = (savedCounts != null && savedCounts.length == totalZikrs)
          ? savedCounts
          : List.filled(totalZikrs, 0);
      emit(ZikrActive(session: session, currentIndex: index, counts: counts));
    } catch (e) {
      emit(ZikrError('Failed to load session: $e'));
    }
  }

  /// Increments the tap count for the current zikr.
  Future<void> tap() async {
    final current = state;
    if (current is! ZikrActive) return;

    final zikr = current.session.zikrs[current.currentIndex];
    if (current.counts[current.currentIndex] >= zikr.repeat) return;

    final newCounts = List<int>.from(current.counts);
    newCounts[current.currentIndex]++;
    final updated = current.copyWith(counts: newCounts);
    emit(updated);
    await _saveProgress(current.session.id, updated.currentIndex, newCounts);

    if (newCounts[current.currentIndex] >= zikr.repeat) {
      await _advanceOrComplete(updated);
    }
  }

  Future<void> _advanceOrComplete(ZikrActive current) async {
    final nextIndex = current.currentIndex + 1;
    if (nextIndex < current.session.zikrs.length) {
      final advanced = current.copyWith(currentIndex: nextIndex);
      emit(advanced);
      await _saveProgress(current.session.id, nextIndex, current.counts);
    } else {
      await _clearProgress(current.session.id);
      emit(ZikrCompleted(current.session));
    }
  }

  void goToPrevious() {
    final current = state;
    if (current is! ZikrActive || current.currentIndex <= 0) return;
    emit(current.copyWith(currentIndex: current.currentIndex - 1));
    _saveProgress(
      current.session.id,
      current.currentIndex - 1,
      current.counts,
    );
  }

  void goToNext() {
    final current = state;
    if (current is! ZikrActive) return;
    if (current.currentIndex >= current.session.zikrs.length - 1) return;
    emit(current.copyWith(currentIndex: current.currentIndex + 1));
    _saveProgress(
      current.session.id,
      current.currentIndex + 1,
      current.counts,
    );
  }

  void goToIndex(int index) {
    final current = state;
    if (current is! ZikrActive) return;
    if (index < 0 || index >= current.session.zikrs.length) return;
    emit(current.copyWith(currentIndex: index));
    _saveProgress(current.session.id, index, current.counts);
  }

  // ── Persistence ───────────────────────────────────────────────────────────

  Future<void> _saveProgress(
    String sessionId,
    int index,
    List<int> counts,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${kSessionProgressIndexKey}_$sessionId', index);
    await prefs.setString(
      '${kSessionProgressCountsKey}_$sessionId',
      counts.join(','),
    );
  }

  Future<int> _loadSavedIndex(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('${kSessionProgressIndexKey}_$sessionId') ?? 0;
  }

  Future<List<int>?> _loadSavedCounts(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('${kSessionProgressCountsKey}_$sessionId');
    if (raw == null || raw.isEmpty) return null;
    try {
      return raw.split(',').map(int.parse).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearProgress(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${kSessionProgressIndexKey}_$sessionId');
    await prefs.remove('${kSessionProgressCountsKey}_$sessionId');
  }
}
