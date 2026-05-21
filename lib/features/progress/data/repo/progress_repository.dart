import '../data_sources/progress_local_data_source.dart';
import '../models/progress_model.dart';

/// Repository for progress/gamification data.
class ProgressRepository {
  final ProgressLocalDataSource _dataSource;

  const ProgressRepository({required ProgressLocalDataSource dataSource})
      : _dataSource = dataSource;

  Future<ProgressModel> loadProgress() => _dataSource.loadProgress();

  Future<ProgressModel> completeSession(
    ProgressModel current,
    String sessionId,
  ) =>
      _dataSource.completeSession(current, sessionId);

  Future<ProgressModel> deductPoints(
    ProgressModel current,
    int amount,
  ) =>
      _dataSource.deductPoints(current, amount);
}
