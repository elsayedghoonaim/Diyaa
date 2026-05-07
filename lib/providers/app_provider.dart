import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/prayer_times_service.dart';
import '../services/notification_service.dart';

const String _kDarkModeKey            = 'diyaa-dark-mode';
const String _kArabicModeKey          = 'diyaa-arabic-mode';
const String _kHijriDatesKey          = 'diyaa-hijri-dates';
const String _kCompletedSessionsKey   = 'diyaa-completed-sessions';
const String _kLastResetKey           = 'diyaa-last-reset';
const String _kTotalPointsKey         = 'diyaa-total-points';
const String _kTotalSessionsKey       = 'diyaa-total-sessions';
const String _kStreakKey              = 'diyaa-streak';
const String _kLastStreakDateKey      = 'diyaa-last-streak-date';
const String _kWeeklyCompletionKey    = 'diyaa-weekly-completion'; // comma-sep 7 booleans
const String _kUnlockedBadgesKey      = 'diyaa-unlocked-badges';
const String _kMorningStreakKey       = 'diyaa-morning-streak';
const String _kUnlockedThemesKey      = 'diyaa-unlocked-themes';
const String _kUnlockedAudiosKey      = 'diyaa-unlocked-audios';
const String _kActiveThemeKey         = 'diyaa-active-theme';
const String _kActiveAudioKey         = 'diyaa-active-audio';
const String _kOnboardingCompleteKey  = 'diyaa-onboarding-complete';
const String _kSessionProgressIndexKey = 'diyaa-session-progress-index';
const String _kSessionProgressCountsKey = 'diyaa-session-progress-counts';

// Settings Keys
const String _kNotifPrayerKey         = 'diyaa-notif-prayer';
const String _kNotifStreakKey         = 'diyaa-notif-streak';
const String _kNotifMilestoneKey      = 'diyaa-notif-milestone';
const String _kSoundEnabledKey        = 'diyaa-sound-enabled';

/// A badge definition
class AzkarBadge {
  final String id;
  final String nameEn;
  final String nameAr;
  final String descEn;
  final String descAr;
  final String icon; // emoji
  final String color; // 'teal' | 'gold'
  bool unlocked;

  AzkarBadge({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.descEn,
    required this.descAr,
    required this.icon,
    required this.color,
    this.unlocked = false,
  });
}

class AppProvider extends ChangeNotifier {
  bool _darkMode   = false;
  bool _arabicMode = false;
  bool _hijriDates = true;
  bool _useLocation = false;

  // Settings
  bool _notifPrayer = true;
  bool _notifStreak = true;
  bool _notifMilestone = true;
  bool _soundEnabled = true;
  bool _onboardingComplete = false;

  // Session progress persistence
  Map<String, int> _sessionProgressIndex = {};
  Map<String, List<int>> _sessionProgressCounts = {};

  // Progress tracking
  Set<String> _completedSessionsToday = {};
  int _totalPoints   = 0;   // PTS (gems)
  int _totalSessions = 0;   // cumulative sessions completed
  int _streak        = 0;   // consecutive days with at least 1 session
  List<bool> _weeklyCompletion = List.filled(7, false); // Mon–Sun
  int _morningStreak = 0;   // days in a row with morning azkar done

  // Prayer times state
  PrayerInfo? _prayerInfo;
  SuggestedSession _suggested = SuggestedSession.none;
  bool _prayerLoading = false;

  // Badges
  late List<AzkarBadge> _badges;

  // Shop state
  Set<String> _unlockedThemes = {'desert_dunes'};
  Set<String> _unlockedAudios = {'prayer_bell'};
  String _activeTheme = 'desert_dunes';
  String _activeAudio = 'prayer_bell';

  // ── Getters ──────────────────────────────────
  bool get darkMode               => _darkMode;
  bool get arabicMode             => _arabicMode;
  bool get hijriDates             => _hijriDates;
  bool get useLocation            => _useLocation;
  
  bool get notifPrayer            => _notifPrayer;
  bool get notifStreak            => _notifStreak;
  bool get notifMilestone         => _notifMilestone;
  bool get soundEnabled           => _soundEnabled;
  bool get onboardingComplete     => _onboardingComplete;

  Set<String> get completedSessionsToday => _completedSessionsToday;
  int get totalPoints             => _totalPoints;
  int get totalSessions           => _totalSessions;
  int get streak                  => _streak;
  List<bool> get weeklyCompletion => _weeklyCompletion;
  int get morningStreak           => _morningStreak;
  PrayerInfo? get prayerInfo      => _prayerInfo;
  SuggestedSession get suggestedSession => _suggested;
  bool get prayerLoading          => _prayerLoading;
  List<AzkarBadge> get badges          => _badges;
  List<AzkarBadge> get unlockedBadges  => _badges.where((b) => b.unlocked).toList();
  List<AzkarBadge> get lockedBadges    => _badges.where((b) => !b.unlocked).toList();
  
  Set<String> get unlockedThemes => _unlockedThemes;
  Set<String> get unlockedAudios => _unlockedAudios;
  String get activeTheme => _activeTheme;
  String get activeAudio => _activeAudio;

  AppProvider() {
    _initBadges();
    _init();
  }

  Future<void> _init() async {
    await _loadPreferences();
    await _loadPrayerTimes();
  }

  void _initBadges() {
    _badges = [
      AzkarBadge(
        id: 'early_riser',
        nameEn: 'Early Riser',
        nameAr: 'المبكّر',
        descEn: 'Complete Morning Azkar 7 days in a row',
        descAr: 'أكمل أذكار الصباح 7 أيام متتالية',
        icon: '🌅',
        color: 'teal',
      ),
      AzkarBadge(
        id: 'morning_light',
        nameEn: 'Morning Light',
        nameAr: 'نور الصباح',
        descEn: 'Never missed Morning Azkar this month',
        descAr: 'لم تفوّت أذكار الصباح هذا الشهر',
        icon: '☀️',
        color: 'gold',
      ),
      AzkarBadge(
        id: 'devoted',
        nameEn: 'Devoted',
        nameAr: 'المواظب',
        descEn: 'Reach a 7-day streak',
        descAr: 'حافظ على سلسلة 7 أيام',
        icon: '🔥',
        color: 'gold',
      ),
      AzkarBadge(
        id: 'century',
        nameEn: 'Century',
        nameAr: 'المئوي',
        descEn: 'Complete 100 sessions total',
        descAr: 'أكمل 100 جلسة',
        icon: '💯',
        color: 'teal',
      ),
      AzkarBadge(
        id: 'gem_collector',
        nameEn: 'Gem Collector',
        nameAr: 'جامع الجواهر',
        descEn: 'Earn 1,000 PTS',
        descAr: 'اكسب 1000 نقطة',
        icon: '💎',
        color: 'teal',
      ),
      AzkarBadge(
        id: 'fortress',
        nameEn: 'The Fortress',
        nameAr: 'الحصن',
        descEn: 'Complete all 5 daily sessions in one day',
        descAr: 'أكمل الجلسات الخمس في يوم واحد',
        icon: '🏰',
        color: 'gold',
      ),
    ];
  }

  // ── Load from storage ─────────────────────────
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode   = prefs.getBool(_kDarkModeKey)   ?? false;
    _arabicMode = prefs.getBool(_kArabicModeKey) ?? false;
    _hijriDates = prefs.getBool(_kHijriDatesKey) ?? true;
    _useLocation = prefs.getBool('diyaa-use-location') ?? true;
    _onboardingComplete = prefs.getBool(_kOnboardingCompleteKey) ?? false;

    _notifPrayer = prefs.getBool(_kNotifPrayerKey) ?? true;
    _notifStreak = prefs.getBool(_kNotifStreakKey) ?? true;
    _notifMilestone = prefs.getBool(_kNotifMilestoneKey) ?? true;
    _soundEnabled = prefs.getBool(_kSoundEnabledKey) ?? true;

    _totalPoints   = prefs.getInt(_kTotalPointsKey)   ?? 0;
    _totalSessions = prefs.getInt(_kTotalSessionsKey) ?? 0;
    _streak        = prefs.getInt(_kStreakKey)         ?? 0;
    _morningStreak = prefs.getInt(_kMorningStreakKey)  ?? 0;

    // Load weekly completion (7 booleans, stored as "true,false,...")
    final weekStr = prefs.getString(_kWeeklyCompletionKey) ?? '';
    if (weekStr.isNotEmpty) {
      final parts = weekStr.split(',');
      _weeklyCompletion = List.generate(7, (i) => i < parts.length ? parts[i] == 'true' : false);
    } else {
      _weeklyCompletion = List.filled(7, false);
    }

    // Load unlocked badges
    final unlockedIds = prefs.getStringList(_kUnlockedBadgesKey) ?? [];
    for (final badge in _badges) {
      badge.unlocked = unlockedIds.contains(badge.id);
    }

    // Load shop state
    _unlockedThemes = (prefs.getStringList(_kUnlockedThemesKey) ?? ['desert_dunes']).toSet();
    _unlockedAudios = (prefs.getStringList(_kUnlockedAudiosKey) ?? ['prayer_bell']).toSet();
    _activeTheme    = prefs.getString(_kActiveThemeKey) ?? 'desert_dunes';
    _activeAudio    = prefs.getString(_kActiveAudioKey) ?? 'prayer_bell';

    // Daily reset
    final lastReset = prefs.getString(_kLastResetKey) ?? '';
    final today = _todayString();

    if (lastReset != today) {
      // New day — check streak
      _handleDayRollover(prefs, lastReset, today);
      _completedSessionsToday = {};
      await prefs.setStringList(_kCompletedSessionsKey, []);
      await prefs.setString(_kLastResetKey, today);
    } else {
      _completedSessionsToday = (prefs.getStringList(_kCompletedSessionsKey) ?? []).toSet();
    }

    // Load session progress
    _sessionProgressIndex = {};
    _sessionProgressCounts = {};
    final progressKeys = prefs.getKeys().where((k) => k.startsWith('$_kSessionProgressIndexKey-'));
    for (final key in progressKeys) {
      final sessionId = key.replaceFirst('$_kSessionProgressIndexKey-', '');
      _sessionProgressIndex[sessionId] = prefs.getInt(key) ?? 0;
      final countsList = prefs.getStringList('$_kSessionProgressCountsKey-$sessionId');
      if (countsList != null) {
        _sessionProgressCounts[sessionId] = countsList.map((e) => int.parse(e)).toList();
      }
    }

    notifyListeners();
  }

  /// Called on new day: updates streak and weekly tracker
  void _handleDayRollover(SharedPreferences prefs, String lastReset, String today) {
    final lastStreakDate = prefs.getString(_kLastStreakDateKey) ?? '';
    final yesterday = _yesterdayString();

    // Had at least 1 session yesterday?
    final hadSessionYesterday = lastStreakDate == yesterday;

    if (hadSessionYesterday) {
      _streak++;
    } else if (lastStreakDate != today) {
      _streak = 0;
    }

    // Rotate weekly completion — shift left, new day = false
    final todayWeekday = DateTime.now().weekday; // 1=Mon … 7=Sun
    _weeklyCompletion[todayWeekday - 1] = false;

    prefs.setInt(_kStreakKey, _streak);
    prefs.setString(_kWeeklyCompletionKey, _weeklyCompletion.join(','));
  }

  String _todayString() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }

  String _yesterdayString() {
    final n = DateTime.now().subtract(const Duration(days: 1));
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }

  // ── Session completion ────────────────────────
  /// Call this when a user fully completes a session.
  /// [sessionId]  — e.g. 'morning', 'evening', 'post_prayer'
  /// [pts]        — points to award (default: 100 per session)
  Future<void> completeSession(String sessionId, {int pts = 100}) async {
    if (_completedSessionsToday.contains(sessionId)) return;

    _completedSessionsToday.add(sessionId);
    _totalPoints   += pts;
    _totalSessions += 1;

    // Mark today as active for streak
    final prefs = await SharedPreferences.getInstance();
    final today  = _todayString();
    final todayWeekday = DateTime.now().weekday;

    // Update streak: if last-streak-date is yesterday, increment; else start fresh
    final lastStreakDate = prefs.getString(_kLastStreakDateKey) ?? '';
    final yesterday = _yesterdayString();

    if (lastStreakDate != today) {
      if (lastStreakDate == yesterday) {
        _streak++;
      } else if (lastStreakDate.isEmpty) {
        _streak = 1;
      } else {
        _streak = 1; // broken — restart
      }
      await prefs.setString(_kLastStreakDateKey, today);
    }

    // Morning streak
    if (sessionId == 'morning') {
      final lastMorningDate = prefs.getString('diyaa-last-morning-date') ?? '';
      if (lastMorningDate == yesterday) {
        _morningStreak++;
      } else if (lastMorningDate != today) {
        _morningStreak = 1;
      }
      await prefs.setString('diyaa-last-morning-date', today);
      await prefs.setInt(_kMorningStreakKey, _morningStreak);
    }

    // Mark this weekday as completed
    _weeklyCompletion[todayWeekday - 1] = true;

    // Persist
    await prefs.setStringList(_kCompletedSessionsKey, _completedSessionsToday.toList());
    await prefs.setInt(_kTotalPointsKey,   _totalPoints);
    await prefs.setInt(_kTotalSessionsKey, _totalSessions);
    await prefs.setInt(_kStreakKey,        _streak);
    await prefs.setString(_kWeeklyCompletionKey, _weeklyCompletion.join(','));

    // Evaluate badges
    _checkBadges(prefs);

    notifyListeners();
  }

  bool isSessionCompleted(String sessionId) => _completedSessionsToday.contains(sessionId);

  // ── Badge evaluation ──────────────────────────
  void _checkBadges(SharedPreferences prefs) {
    bool changed = false;

    void unlock(String id) {
      final b = _badges.firstWhere((b) => b.id == id, orElse: () => _badges[0]);
      if (!b.unlocked) {
        b.unlocked = true;
        changed = true;
      }
    }

    if (_morningStreak >= 7)  unlock('early_riser');
    if (_streak >= 7)         unlock('devoted');
    if (_totalSessions >= 100) unlock('century');
    if (_totalPoints >= 1000) unlock('gem_collector');

    // All 5 sessions today
    const allSessions = {'morning', 'wake_up', 'post_prayer', 'evening', 'sleep'};
    if (_completedSessionsToday.containsAll(allSessions)) unlock('fortress');

    if (changed) {
      final ids = _badges.where((b) => b.unlocked).map((b) => b.id).toList();
      prefs.setStringList(_kUnlockedBadgesKey, ids);
    }
  }

  // ── Prayer times ──────────────────────────────
  Future<void> _loadPrayerTimes() async {
    _prayerLoading = true;
    notifyListeners();

    try {
      final info = await PrayerTimesService.loadTodaysPrayers(useLocation: _useLocation)
          .timeout(const Duration(seconds: 15), onTimeout: () => null);
      _prayerInfo = info;
      _suggested  = info != null ? PrayerTimesService.suggest(info) : SuggestedSession.morning;

      if (info != null) {
        try {
          await NotificationService.requestPermissions();
          await NotificationService.scheduleAzkarNotifications(info, isArabic: _arabicMode);
        } catch (_) {
          // Notification scheduling failed — non-fatal
        }
      }
    } catch (_) {
      _suggested = SuggestedSession.morning;
    } finally {
      _prayerLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshPrayerTimes() => _loadPrayerTimes();

  // ── Settings ──────────────────────────────────
  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkModeKey, value);
  }

  Future<void> setArabicMode(bool value) async {
    _arabicMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kArabicModeKey, value);
  }

  Future<void> setHijriDates(bool value) async {
    _hijriDates = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHijriDatesKey, value);
  }

  Future<void> setUseLocation(bool value) async {
    _useLocation = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('diyaa-use-location', value);
    await refreshPrayerTimes();
  }

  Future<void> setNotifPrayer(bool value) async {
    _notifPrayer = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifPrayerKey, value);
  }

  Future<void> setNotifStreak(bool value) async {
    _notifStreak = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifStreakKey, value);
  }

  Future<void> setNotifMilestone(bool value) async {
    _notifMilestone = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifMilestoneKey, value);
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSoundEnabledKey, value);
  }

  Future<void> completeOnboarding() async {
    _onboardingComplete = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingCompleteKey, true);
  }

  // ── Session Progress ──────────────────────────
  void saveZikrProgress(String sessionId, int index, List<int> counts) async {
    _sessionProgressIndex[sessionId] = index;
    _sessionProgressCounts[sessionId] = counts;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_kSessionProgressIndexKey-$sessionId', index);
    await prefs.setStringList('$_kSessionProgressCountsKey-$sessionId', counts.map((e) => e.toString()).toList());
  }

  int getSavedZikrIndex(String sessionId) => _sessionProgressIndex[sessionId] ?? 0;
  List<int>? getSavedZikrCounts(String sessionId) => _sessionProgressCounts[sessionId];

  void clearSessionProgress(String sessionId) async {
    _sessionProgressIndex.remove(sessionId);
    _sessionProgressCounts.remove(sessionId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_kSessionProgressIndexKey-$sessionId');
    await prefs.remove('$_kSessionProgressCountsKey-$sessionId');
  }

  /// Bilingual helper
  String t(String en, String ar) => _arabicMode ? ar : en;

  /// Arabic numbers helper
  String toArabicDigits(String input) {
    if (!_arabicMode) return input;
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String res = input;
    for (int i = 0; i < english.length; i++) {
      res = res.replaceAll(english[i], arabic[i]);
    }
    return res;
  }

  // ── Shop Methods ────────────────────────────────
  Future<bool> purchaseTheme(String themeId, int cost) async {
    if (_totalPoints >= cost && !_unlockedThemes.contains(themeId)) {
      _totalPoints -= cost;
      _unlockedThemes.add(themeId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kTotalPointsKey, _totalPoints);
      await prefs.setStringList(_kUnlockedThemesKey, _unlockedThemes.toList());
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> applyTheme(String themeId) async {
    if (_unlockedThemes.contains(themeId)) {
      _activeTheme = themeId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kActiveThemeKey, themeId);
      notifyListeners();
    }
  }

  Future<bool> purchaseAudio(String audioId, int cost) async {
    if (_totalPoints >= cost && !_unlockedAudios.contains(audioId)) {
      _totalPoints -= cost;
      _unlockedAudios.add(audioId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kTotalPointsKey, _totalPoints);
      await prefs.setStringList(_kUnlockedAudiosKey, _unlockedAudios.toList());
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> applyAudio(String audioId) async {
    if (_unlockedAudios.contains(audioId)) {
      _activeAudio = audioId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kActiveAudioKey, audioId);
      notifyListeners();
    }
  }
}
