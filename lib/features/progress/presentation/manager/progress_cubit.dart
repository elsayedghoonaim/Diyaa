import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/progress_model.dart';
import '../../data/repo/progress_repository.dart';
import 'progress_state.dart';

/// Manages gamification state: points, streaks, badges, completed sessions.
class ProgressCubit extends Cubit<ProgressState> {
  final ProgressRepository _repository;

  ProgressCubit({required ProgressRepository repository})
      : _repository = repository,
        super(const ProgressInitial());

  Future<void> loadProgress() async {
    emit(const ProgressLoading());
    try {
      final progress = await _repository.loadProgress();
      emit(ProgressLoaded(progress));
    } catch (e) {
      debugPrint('[ProgressCubit] Error loading progress: $e');
      emit(ProgressError('Failed to load progress: $e'));
    }
  }

  Future<void> completeSession(String sessionId) async {
    final ProgressState current = state;
    if (current is! ProgressLoaded) return;
    try {
      final ProgressModel updated = await _repository.completeSession(
        current.progress,
        sessionId,
      );
      emit(ProgressLoaded(updated));
    } catch (e) {
      emit(ProgressError('Failed to save session: $e'));
    }
  }

  Future<void> deductPoints(int amount) async {
    final ProgressState current = state;
    if (current is! ProgressLoaded) return;
    try {
      final ProgressModel updated = await _repository.deductPoints(
        current.progress,
        amount,
      );
      emit(ProgressLoaded(updated));
    } catch (e) {
      emit(ProgressError('Failed to deduct points: $e'));
    }
  }
}
