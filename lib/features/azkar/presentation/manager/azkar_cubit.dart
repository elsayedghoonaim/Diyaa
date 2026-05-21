import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repo/azkar_repository.dart';
import 'azkar_state.dart';

/// Manages the daily session list shown on the Home screen.
class AzkarCubit extends Cubit<AzkarState> {
  final AzkarRepository _repository;

  AzkarCubit({required AzkarRepository repository})
      : _repository = repository,
        super(const AzkarInitial());

  Future<void> loadDailySessions() async {
    emit(const AzkarLoading());
    try {
      final sessions = await _repository.loadDailySessions();
      emit(AzkarLoaded(sessions));
    } catch (e) {
      emit(AzkarError('Failed to load sessions: $e'));
    }
  }

  Future<void> loadLibrarySessions() async {
    emit(const AzkarLoading());
    try {
      final sessions = await _repository.loadLibrarySessions();
      emit(AzkarLoaded(sessions));
    } catch (e) {
      emit(AzkarError('Failed to load library: $e'));
    }
  }
}
