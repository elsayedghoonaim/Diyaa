import '../data_sources/azkar_local_data_source.dart';
import '../../domain/entities/zikr.dart';

/// Repository for azkar data.
/// Cubits call only this class — never the data source directly.
class AzkarRepository {
  final AzkarLocalDataSource _dataSource;

  const AzkarRepository({required AzkarLocalDataSource dataSource})
      : _dataSource = dataSource;

  Future<List<AzkarSession>> loadDailySessions() =>
      _dataSource.loadDailySessions();

  Future<AzkarSession?> loadSession(String sessionId) =>
      _dataSource.loadSession(sessionId);

  Future<List<AzkarSession>> loadLibrarySessions() =>
      _dataSource.loadLibrarySessions();
}
