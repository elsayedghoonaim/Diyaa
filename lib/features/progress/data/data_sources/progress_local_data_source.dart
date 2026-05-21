import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/preference_keys.dart';
import '../../../../core/utils/date_utils.dart' as du;
import '../models/badge_model.dart';
import '../models/progress_model.dart';

/// Reads and writes all progress-related data via SharedPreferences.
class ProgressLocalDataSource {
  const ProgressLocalDataSource();

  Future<ProgressModel> loadProgress() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      await _resetIfNewDay(prefs);
    } catch (e) {
      debugPrint('[ProgressLocalDataSource] Error resetting daily progress: $e');
    }
    List<String> completedRaw = <String>[];
    try {
      completedRaw = prefs.getStringList(kCompletedSessionsKey) ?? <String>[];
    } catch (e) {
      debugPrint('[ProgressLocalDataSource] Error reading completed sessions: $e');
      try {
        final String? jsonStr = prefs.getString(kCompletedSessionsKey);
        if (jsonStr != null) {
          final List<dynamic> list = json.decode(jsonStr) as List<dynamic>;
          completedRaw = list.map((dynamic e) => e.toString()).toList();
        }
      } catch (_) {}
    }
    List<int> weeklyCompletion = <int>[0, 0, 0, 0, 0, 0, 0];
    try {
      final String? weeklyRaw = prefs.getString(kWeeklyCompletionKey);
      if (weeklyRaw != null) {
        final List<dynamic> decoded = json.decode(weeklyRaw) as List<dynamic>;
        weeklyCompletion = decoded.map((dynamic e) => (e as num).toInt()).toList();
      }
    } catch (e) {
      debugPrint('[ProgressLocalDataSource] Error reading weekly completion: $e');
      try {
        final List<String>? list = prefs.getStringList(kWeeklyCompletionKey);
        if (list != null) {
          weeklyCompletion = list.map((String e) => int.tryParse(e) ?? 0).toList();
        }
      } catch (_) {}
    }
    Set<String> unlockedIds = <String>{};
    try {
      unlockedIds = (prefs.getStringList(kUnlockedBadgesKey) ?? <String>[]).toSet();
    } catch (e) {
      debugPrint('[ProgressLocalDataSource] Error reading unlocked badges: $e');
    }
    final List<BadgeModel> badges = BadgeModel.all
        .map((BadgeModel b) => b.copyWith(isUnlocked: unlockedIds.contains(b.id)))
        .toList();
    int totalPoints = 0;
    try {
      totalPoints = prefs.getInt(kTotalPointsKey) ?? 0;
    } catch (e) {
      debugPrint('[ProgressLocalDataSource] Error reading total points: $e');
      final String? str = prefs.getString(kTotalPointsKey);
      if (str != null) {
        totalPoints = int.tryParse(str) ?? 0;
      }
    }
    int totalSessions = 0;
    try {
      totalSessions = prefs.getInt(kTotalSessionsKey) ?? 0;
    } catch (e) {
      debugPrint('[ProgressLocalDataSource] Error reading total sessions: $e');
      final String? str = prefs.getString(kTotalSessionsKey);
      if (str != null) {
        totalSessions = int.tryParse(str) ?? 0;
      }
    }
    int streak = 0;
    try {
      streak = prefs.getInt(kStreakKey) ?? 0;
    } catch (e) {
      debugPrint('[ProgressLocalDataSource] Error reading streak: $e');
      final String? str = prefs.getString(kStreakKey);
      if (str != null) {
        streak = int.tryParse(str) ?? 0;
      }
    }
    int morningStreak = 0;
    try {
      morningStreak = prefs.getInt(kMorningStreakKey) ?? 0;
    } catch (e) {
      debugPrint('[ProgressLocalDataSource] Error reading morning streak: $e');
      final String? str = prefs.getString(kMorningStreakKey);
      if (str != null) {
        morningStreak = int.tryParse(str) ?? 0;
      }
    }
    return ProgressModel(
      totalPoints:            totalPoints,
      totalSessions:          totalSessions,
      streak:                 streak,
      morningStreak:          morningStreak,
      completedSessionsToday: completedRaw,
      weeklyCompletion:       weeklyCompletion,
      badges:                 badges,
    );
  }

  Future<ProgressModel> completeSession(
    ProgressModel current,
    String sessionId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay(prefs);

    if (current.hasCompletedSession(sessionId)) return current;

    final completed = List<String>.from(current.completedSessionsToday)
      ..add(sessionId);

    final points     = current.totalPoints + _pointsForSession(sessionId);
    final sessions   = current.totalSessions + 1;
    final streak     = await _updateStreak(prefs, current.streak);
    final morning    = await _updateMorningStreak(prefs, current.morningStreak, sessionId);
    final weekly     = _updateWeekly(current.weeklyCompletion);
    final badges     = _evaluateBadges(current.badges, sessions);

    await prefs.setStringList(kCompletedSessionsKey, completed);
    await prefs.setInt(kTotalPointsKey,    points);
    await prefs.setInt(kTotalSessionsKey,  sessions);
    await prefs.setInt(kStreakKey,         streak);
    await prefs.setInt(kMorningStreakKey,  morning);
    await prefs.setString(kWeeklyCompletionKey, json.encode(weekly));
    await prefs.setStringList(
      kUnlockedBadgesKey,
      badges.where((b) => b.isUnlocked).map((b) => b.id).toList(),
    );

    return current.copyWith(
      totalPoints:            points,
      totalSessions:          sessions,
      streak:                 streak,
      morningStreak:          morning,
      completedSessionsToday: completed,
      weeklyCompletion:       weekly,
      badges:                 badges,
    );
  }

  Future<ProgressModel> deductPoints(
    ProgressModel current,
    int amount,
  ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int points = current.totalPoints - amount;
    await prefs.setInt(kTotalPointsKey, points);
    return current.copyWith(totalPoints: points);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _resetIfNewDay(SharedPreferences prefs) async {
    final lastReset = prefs.getString(kLastResetKey) ?? '';
    final today     = du.todayString();
    if (lastReset == today) return;
    await prefs.setStringList(kCompletedSessionsKey, []);
    await prefs.setString(kLastResetKey, today);

    // Update streak: if yesterday completed a session, streak survives
    final lastStreakDate = prefs.getString(kLastStreakDateKey) ?? '';
    final yesterday      = du.yesterdayString();
    if (lastStreakDate != yesterday && lastStreakDate != today) {
      await prefs.setInt(kStreakKey, 0);
    }
  }

  int _pointsForSession(String sessionId) {
    if (sessionId == 'morning' || sessionId == '1') return 50;
    if (sessionId == 'evening') return 50;
    if (sessionId == 'sleep' || sessionId == '2') return 30;
    if (sessionId == 'wakeup' || sessionId == '3') return 30;
    if (sessionId == 'cat_7' || sessionId == '27') return 40;
    return 25;
  }

  Future<int> _updateStreak(SharedPreferences prefs, int currentStreak) async {
    final today          = du.todayString();
    final lastStreakDate  = prefs.getString(kLastStreakDateKey) ?? '';
    final yesterday      = du.yesterdayString();

    int newStreak = currentStreak;
    if (lastStreakDate == today) {
      newStreak = currentStreak;
    } else if (lastStreakDate == yesterday) {
      newStreak = currentStreak + 1;
    } else {
      newStreak = 1;
    }

    await prefs.setInt(kStreakKey, newStreak);
    await prefs.setString(kLastStreakDateKey, today);
    return newStreak;
  }

  Future<int> _updateMorningStreak(
    SharedPreferences prefs,
    int currentMorning,
    String sessionId,
  ) async {
    if (sessionId != 'morning' && sessionId != '1') return currentMorning;

    final today         = du.todayString();
    final lastMorning   = prefs.getString(kLastMorningDateKey) ?? '';
    final yesterday     = du.yesterdayString();

    int newMorning;
    if (lastMorning == today) {
      newMorning = currentMorning;
    } else if (lastMorning == yesterday) {
      newMorning = currentMorning + 1;
    } else {
      newMorning = 1;
    }

    await prefs.setInt(kMorningStreakKey, newMorning);
    await prefs.setString(kLastMorningDateKey, today);
    return newMorning;
  }

  List<int> _updateWeekly(List<int> current) {
    final dayIndex = DateTime.now().weekday - 1; // 0=Mon, 6=Sun
    final updated  = List<int>.from(current);
    if (dayIndex >= 0 && dayIndex < 7) {
      updated[dayIndex] = (updated[dayIndex]) + 1;
    }
    return updated;
  }

  List<BadgeModel> _evaluateBadges(
    List<BadgeModel> current,
    int totalSessions,
  ) {
    return current
        .map((b) => b.copyWith(
              isUnlocked: b.isUnlocked || totalSessions >= b.requiredSessions,
            ))
        .toList();
  }
}
