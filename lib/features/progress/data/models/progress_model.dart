import 'badge_model.dart';

/// Immutable snapshot of a user's progress at a point in time.
class ProgressModel {
  final int totalPoints;
  final int totalSessions;
  final int streak;
  final int morningStreak;
  final List<String> completedSessionsToday;
  final List<int> weeklyCompletion;
  final List<BadgeModel> badges;

  const ProgressModel({
    this.totalPoints = 0,
    this.totalSessions = 0,
    this.streak = 0,
    this.morningStreak = 0,
    this.completedSessionsToday = const [],
    this.weeklyCompletion = const [0, 0, 0, 0, 0, 0, 0],
    this.badges = const [],
  });

  bool hasCompletedSession(String sessionId) =>
      completedSessionsToday.contains(sessionId);

  ProgressModel copyWith({
    int? totalPoints,
    int? totalSessions,
    int? streak,
    int? morningStreak,
    List<String>? completedSessionsToday,
    List<int>? weeklyCompletion,
    List<BadgeModel>? badges,
  }) {
    return ProgressModel(
      totalPoints:            totalPoints            ?? this.totalPoints,
      totalSessions:          totalSessions          ?? this.totalSessions,
      streak:                 streak                 ?? this.streak,
      morningStreak:          morningStreak          ?? this.morningStreak,
      completedSessionsToday: completedSessionsToday ?? this.completedSessionsToday,
      weeklyCompletion:       weeklyCompletion       ?? this.weeklyCompletion,
      badges:                 badges                 ?? this.badges,
    );
  }
}
