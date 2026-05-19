import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/prayer_times_service.dart';
import '../services/notification_service.dart';

// ── Preference Keys ──────────────────────────────────────────────────────────
const String _kDarkModeKey              = 'diyaa-dark-mode';
const String _kArabicModeKey            = 'diyaa-arabic-mode';
const String _kHijriDatesKey            = 'diyaa-hijri-dates';
const String _kCompletedSessionsKey     = 'diyaa-completed-sessions';
const String _kLastResetKey             = 'diyaa-last-reset';
const String _kTotalPointsKey           = 'diyaa-total-points';
const String _kTotalSessionsKey         = 'diyaa-total-sessions';
const String _kStreakKey                = 'diyaa-streak';
const String _kLastStreakDateKey        = 'diyaa-last-streak-date';
const String _kWeeklyCompletionKey      = 'diyaa-weekly-completion';
const String _kUnlockedBadgesKey        = 'diyaa-unlocked-badges';
const String _kMorningStreakKey         = 'diyaa-morning-streak';
const String _kUnlockedThemesKey        = 'diyaa-unlocked-themes';
const String _kUnlockedAudiosKey        = 'diyaa-unlocked-audios';
const String _kActiveThemeKey           = 'diyaa-active-theme';
const String _kActiveAudioKey           = 'diyaa-active-audio';
const String _kOnboardingCompleteKey    = 'diyaa-onboarding-complete';
const String _kSessionProgressIndexKey  = 'diyaa-session-progress-index';
const String _kSessionProgressCountsKey = 'diyaa-session-progress-counts';

// Notification keys
const String _kNotifPrayerKey        = 'diyaa-notif-prayer';
const String _kNotifAzkarKey         = 'diyaa-notif-azkar';   // FIX: was missing entirely
const String _kNotifStreakKey        = 'diyaa-notif-streak';
const String _kNotifMilestoneKey     = 'diyaa-notif-milestone';
const String _kSoundEnabledKey       = 'diyaa-sound-enabled';

// Al-Salah 'ala Al-Nabi notification keys
const String _kSalahNotifKey         = 'diyaa-salah-notif';
const String _kSalahSoundKey         = 'diyaa-salah-sound';        // 'salah_enhanced' | 'salah_nabi'
const String _kSalahIntervalKey      = 'diyaa-salah-interval';     // minutes: 30/60/90/120
const String _kSalahOverrideSilentKey = 'diyaa-salah-override-silent';

// Location prefs version — bump to force a reset when location logic changes.
// v1 = original (no GPS toggle)
// v2 = added GPS toggle + manual city
const int    _kLocationPrefsVersion = 2;
const String _kLocationPrefsVerKey  = 'diyaa-location-prefs-ver';

// ── Badge model ──────────────────────────────────────────────────────────────
class AzkarBadge {
  final String id;
  final String nameEn;
  final String nameAr;
  final String descEn;
  final String descAr;
  final String icon;
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

// ════════════════════════════════════════════════════════════════════════════
// AppProvider
// ════════════════════════════════════════════════════════════════════════════
class AppProvider extends ChangeNotifier {
  // ── UI preferences ──────────────────────────────────────────────────────
  bool _darkMode   = false;
  bool _arabicMode = false;
  bool _hijriDates = true;

  // ── Location ─────────────────────────────────────────────────────────────
  bool    _useGps         = true;
  double? _latitude;
  double? _longitude;
  String  _manualCityName = '';

  // ── Notification preferences ─────────────────────────────────────────────
  // FIX: _notifAzkar now exists as a fully independent preference.
  // Previously notifAzkar was always passed as _notifPrayer, meaning toggling
  // prayer notifications silently toggled azkar too, with no user-visible control.
  bool _notifPrayer    = true;
  bool _notifAzkar     = true;
  bool _notifStreak    = true;
  bool _notifMilestone = true;
  bool _soundEnabled   = true;

  // Al-Salah 'ala Al-Nabi
  bool   _salahNotif         = false;
  String _salahSound         = 'salah_enhanced';
  int    _salahInterval      = 60;
  bool   _salahOverrideSilent = false;

  // ── Onboarding ────────────────────────────────────────────────────────────
  bool _onboardingComplete = false;

  // ── Session progress ──────────────────────────────────────────────────────
  Map<String, int>       _sessionProgressIndex  = {};
  Map<String, List<int>> _sessionProgressCounts = {};

  // ── Progress tracking ─────────────────────────────────────────────────────
  Set<String> _completedSessionsToday = {};
  int         _totalPoints   = 0;
  int         _totalSessions = 0;
  int         _streak        = 0;
  List<bool>  _weeklyCompletion = List.filled(7, false);
  int         _morningStreak = 0;

  // ── Prayer times ──────────────────────────────────────────────────────────
  PrayerInfo?      _prayerInfo;
  SuggestedSession _suggested    = SuggestedSession.none;
  bool             _prayerLoading = false;

  // ── Badges & Shop ─────────────────────────────────────────────────────────
  late List<AzkarBadge> _badges;
  Set<String> _unlockedThemes = {'desert_dunes'};
  Set<String> _unlockedAudios = {'prayer_bell'};
  String      _activeTheme    = 'desert_dunes';
  String      _activeAudio    = 'prayer_bell';

  // ════════════════════════════════════════════════════════════════════════════
  // GETTERS
  // ════════════════════════════════════════════════════════════════════════════
  bool   get darkMode           => _darkMode;
  bool   get arabicMode         => _arabicMode;
  bool   get hijriDates         => _hijriDates;
  bool   get useGps             => _useGps;
  bool   get useLocation        => _useGps; // compat alias
  String get manualCityName     => _manualCityName;

  bool   get notifPrayer         => _notifPrayer;
  bool   get notifAzkar          => _notifAzkar;
  bool   get notifStreak         => _notifStreak;
  bool   get notifMilestone      => _notifMilestone;
  bool   get soundEnabled        => _soundEnabled;

  // Al-Salah 'ala Al-Nabi getters
  bool   get salahNotif          => _salahNotif;
  String get salahSound          => _salahSound;
  int    get salahInterval       => _salahInterval;
  bool   get salahOverrideSilent => _salahOverrideSilent;
  bool   get onboardingComplete => _onboardingComplete;

  Set<String>      get completedSessionsToday => _completedSessionsToday;
  int              get totalPoints            => _totalPoints;
  int              get totalSessions          => _totalSessions;
  int              get streak                 => _streak;
  List<bool>       get weeklyCompletion       => _weeklyCompletion;
  int              get morningStreak          => _morningStreak;
  PrayerInfo?      get prayerInfo             => _prayerInfo;
  SuggestedSession get suggestedSession       => _suggested;
  bool             get prayerLoading          => _prayerLoading;

  List<AzkarBadge> get badges         => _badges;
  List<AzkarBadge> get unlockedBadges => _badges.where((b) => b.unlocked).toList();
  List<AzkarBadge> get lockedBadges   => _badges.where((b) => !b.unlocked).toList();

  Set<String> get unlockedThemes => _unlockedThemes;
  Set<String> get unlockedAudios => _unlockedAudios;
  String      get activeTheme    => _activeTheme;
  String      get activeAudio    => _activeAudio;

  // ════════════════════════════════════════════════════════════════════════════
  // CONSTRUCTOR
  // ════════════════════════════════════════════════════════════════════════════
  AppProvider() {
    _initBadges();
    _init();
  }

  Future<void> _init() async {
    await _loadPreferences();
    await _loadPrayerTimes();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BADGES
  // ════════════════════════════════════════════════════════════════════════════
  void _initBadges() {
    _badges = [
      AzkarBadge(
        id: 'early_riser',
        nameEn: 'Early Riser', nameAr: 'المبكّر',
        descEn: 'Complete Morning Azkar 7 days in a row',
        descAr: 'أكمل أذكار الصباح 7 أيام متتالية',
        icon: '🌅', color: 'teal',
      ),
      AzkarBadge(
        id: 'morning_light',
        nameEn: 'Morning Light', nameAr: 'نور الصباح',
        descEn: 'Never missed Morning Azkar this month',
        descAr: 'لم تفوّت أذكار الصباح هذا الشهر',
        icon: '☀️', color: 'gold',
      ),
      AzkarBadge(
        id: 'devoted',
        nameEn: 'Devoted', nameAr: 'المواظب',
        descEn: 'Reach a 7-day streak',
        descAr: 'حافظ على سلسلة 7 أيام',
        icon: '🔥', color: 'gold',
      ),
      AzkarBadge(
        id: 'century',
        nameEn: 'Century', nameAr: 'المئوي',
        descEn: 'Complete 100 sessions total',
        descAr: 'أكمل 100 جلسة',
        icon: '💯', color: 'teal',
      ),
      AzkarBadge(
        id: 'gem_collector',
        nameEn: 'Gem Collector', nameAr: 'جامع الجواهر',
        descEn: 'Earn 1,000 PTS',
        descAr: 'اكسب 1000 نقطة',
        icon: '💎', color: 'teal',
      ),
      AzkarBadge(
        id: 'fortress',
        nameEn: 'The Fortress', nameAr: 'الحصن',
        descEn: 'Complete all 5 daily sessions in one day',
        descAr: 'أكمل الجلسات الخمس في يوم واحد',
        icon: '🏰', color: 'gold',
      ),
    ];
  }

  // ════════════════════════════════════════════════════════════════════════════
  // LOAD PREFERENCES
  // ════════════════════════════════════════════════════════════════════════════
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    _darkMode   = prefs.getBool(_kDarkModeKey)   ?? false;
    _arabicMode = prefs.getBool(_kArabicModeKey) ?? false;
    _hijriDates = prefs.getBool(_kHijriDatesKey) ?? true;

    // ── Location migration ──
    final locVer = prefs.getInt(_kLocationPrefsVerKey) ?? 0;
    if (locVer < _kLocationPrefsVersion) {
      debugPrint('[AppProvider] Location prefs v$locVer → v$_kLocationPrefsVersion: resetting to GPS mode');
      await prefs.setBool('diyaa-use-gps', true);
      await prefs.remove('diyaa-manual-city');
      await prefs.remove('diyaa-lat');
      await prefs.remove('diyaa-lng');
      await prefs.setInt(_kLocationPrefsVerKey, _kLocationPrefsVersion);
    }

    _useGps         = prefs.getBool('diyaa-use-gps')       ?? true;
    _manualCityName = prefs.getString('diyaa-manual-city') ?? '';
    _latitude       = prefs.getDouble('diyaa-lat');
    _longitude      = prefs.getDouble('diyaa-lng');

    // Fast startup: render cached prayer times instantly before GPS resolves
    if (_latitude != null && _longitude != null) {
      final info = PrayerTimesService.computeFromCoords(_latitude!, _longitude!);
      if (info != null) {
        _prayerInfo = info;
        _suggested  = PrayerTimesService.suggest(info);
      }
    }

    _onboardingComplete = prefs.getBool(_kOnboardingCompleteKey) ?? false;

    // ── Notification prefs ──
    _notifPrayer    = prefs.getBool(_kNotifPrayerKey)     ?? true;
    _notifAzkar     = prefs.getBool(_kNotifAzkarKey)      ?? true;
    _notifStreak    = prefs.getBool(_kNotifStreakKey)      ?? true;
    _notifMilestone = prefs.getBool(_kNotifMilestoneKey)  ?? true;
    _soundEnabled   = prefs.getBool(_kSoundEnabledKey)    ?? true;

    // ── Al-Salah 'ala Al-Nabi prefs ──
    _salahNotif          = prefs.getBool(_kSalahNotifKey)           ?? false;
    _salahSound          = prefs.getString(_kSalahSoundKey)         ?? 'salah_enhanced';
    _salahInterval       = prefs.getInt(_kSalahIntervalKey)         ?? 60;
    _salahOverrideSilent = prefs.getBool(_kSalahOverrideSilentKey)  ?? false;

    // ── Progress ──
    _totalPoints   = prefs.getInt(_kTotalPointsKey)   ?? 0;
    _totalSessions = prefs.getInt(_kTotalSessionsKey) ?? 0;
    _streak        = prefs.getInt(_kStreakKey)         ?? 0;
    _morningStreak = prefs.getInt(_kMorningStreakKey)  ?? 0;

    final weekStr = prefs.getString(_kWeeklyCompletionKey) ?? '';
    if (weekStr.isNotEmpty) {
      final parts = weekStr.split(',');
      _weeklyCompletion = List.generate(
          7, (i) => i < parts.length ? parts[i] == 'true' : false);
    } else {
      _weeklyCompletion = List.filled(7, false);
    }

    // ── Badges ──
    final unlockedIds = prefs.getStringList(_kUnlockedBadgesKey) ?? [];
    for (final badge in _badges) {
      badge.unlocked = unlockedIds.contains(badge.id);
    }

    // ── Shop ──
    _unlockedThemes = (prefs.getStringList(_kUnlockedThemesKey) ?? ['desert_dunes']).toSet();
    _unlockedAudios = (prefs.getStringList(_kUnlockedAudiosKey) ?? ['prayer_bell']).toSet();
    _activeTheme    = prefs.getString(_kActiveThemeKey) ?? 'desert_dunes';
    _activeAudio    = prefs.getString(_kActiveAudioKey) ?? 'prayer_bell';

    // ── Daily reset ──
    final lastReset = prefs.getString(_kLastResetKey) ?? '';
    final today     = _todayString();

    if (lastReset != today) {
      _handleDayRollover(prefs, lastReset, today);
      _completedSessionsToday = {};

      // Clear all session progress on a new day
      final staleKeys = prefs.getKeys().where((k) =>
          k.startsWith('$_kSessionProgressIndexKey-') ||
          k.startsWith('$_kSessionProgressCountsKey-'));
      for (final key in staleKeys) {
        await prefs.remove(key);
      }
      _sessionProgressIndex  = {};
      _sessionProgressCounts = {};

      await prefs.setStringList(_kCompletedSessionsKey, []);
      await prefs.setString(_kLastResetKey, today);
    } else {
      _completedSessionsToday =
          (prefs.getStringList(_kCompletedSessionsKey) ?? []).toSet();
    }

    // ── Restore in-progress session state (only if not just reset) ──
    final progressKeys = prefs.getKeys()
        .where((k) => k.startsWith('$_kSessionProgressIndexKey-'));
    for (final key in progressKeys) {
      final sessionId = key.replaceFirst('$_kSessionProgressIndexKey-', '');
      _sessionProgressIndex[sessionId] = prefs.getInt(key) ?? 0;
      final countsList = prefs.getStringList(
          '$_kSessionProgressCountsKey-$sessionId');
      if (countsList != null) {
        _sessionProgressCounts[sessionId] =
            countsList.map(int.parse).toList();
      }
    }

    notifyListeners();
  }

  void _handleDayRollover(
      SharedPreferences prefs, String lastReset, String today) {
    final lastStreakDate = prefs.getString(_kLastStreakDateKey) ?? '';
    final yesterday     = _yesterdayString();

    if (lastStreakDate == yesterday) {
      _streak++;
    } else if (lastStreakDate != today) {
      _streak = 0;
    }

    // Rotate weekly tracker — mark today's slot as false (not yet done)
    final todayWeekday = DateTime.now().weekday; // 1=Mon … 7=Sun
    _weeklyCompletion[todayWeekday - 1] = false;

    prefs.setInt(_kStreakKey, _streak);
    prefs.setString(_kWeeklyCompletionKey, _weeklyCompletion.join(','));
  }

  // ════════════════════════════════════════════════════════════════════════════
  // PRAYER TIMES
  // ════════════════════════════════════════════════════════════════════════════
  Future<void> _loadPrayerTimes() async {
    _prayerLoading = true;
    notifyListeners();

    try {
      PrayerInfo? info;

      if (!_useGps && _latitude != null && _longitude != null) {
        // Manual city — use saved coords, skip GPS entirely
        debugPrint('[AppProvider] Manual mode: using ($_latitude, $_longitude)');
        info = PrayerTimesService.computeFromCoords(
          _latitude!, _longitude!,
          label: _manualCityName.isNotEmpty ? _manualCityName : null,
        );
      } else {
        // GPS mode
        info = await PrayerTimesService.loadTodaysPrayers(
          lastLat: _latitude,
          lastLng: _longitude,
        ).timeout(const Duration(seconds: 15), onTimeout: () {
          debugPrint('[AppProvider] GPS timed out — falling back to cache');
          return null;
        });
        // GPS failed → use cached coords
        if (info == null && _latitude != null && _longitude != null) {
          info = PrayerTimesService.computeFromCoords(_latitude!, _longitude!);
        }
      }

      // Absolute fallback — Makkah
      info ??= PrayerTimesService.computeFromCoords(
          21.3891, 39.8579, label: 'Makkah Al-Mukarramah (default)');

      if (info != null) {
        _prayerInfo = info;
        _suggested  = PrayerTimesService.suggest(info);

        // Persist fresh coordinates for next cold startup
        _latitude  = info.latitude;
        _longitude = info.longitude;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('diyaa-lat', info.latitude);
        await prefs.setDouble('diyaa-lng', info.longitude);

        debugPrint('[AppProvider] Prayer times loaded — '
            'Fajr=${info.fajr.toLocal()}, '
            'method=${info.methodName}, '
            'location=${info.cityLabel}');

        await _rescheduleNotifications();
      }
    } catch (e) {
      debugPrint('[AppProvider] _loadPrayerTimes error: $e');
      _suggested = SuggestedSession.morning;
      // Last-resort fallback using cached coords
      if (_latitude != null && _longitude != null && _prayerInfo == null) {
        _prayerInfo =
            PrayerTimesService.computeFromCoords(_latitude!, _longitude!);
      }
    } finally {
      _prayerLoading = false;
      notifyListeners();
    }
  }

  /// Re-requests permissions then re-schedules all notifications using the
  /// current prayer info and all three independent notification flags.
  ///
  /// FIX: notifAzkar is now passed as _notifAzkar (its own independent value)
  /// instead of incorrectly passing _notifPrayer for both.
  Future<void> _rescheduleNotifications() async {
    if (_prayerInfo == null) return;
    try {
      // FIX: scheduleAll() now uses selective cancellation (only IDs 10-40),
      // so Salah Nabi (IDs 60-400) is no longer destroyed by scheduleAll().
      // soundEnabled is now passed through to scheduleAll() and Salah Nabi.
      await NotificationService.requestPermissions();
      await NotificationService.scheduleAll(
        _prayerInfo!,
        isArabic:    _arabicMode,
        notifPrayer: _notifPrayer,
        notifAzkar:  _notifAzkar,
        notifStreak: _notifStreak,
        soundEnabled: _soundEnabled, // FIX: now passed through
        currentStreak: _streak,
      );
      // Also reschedule Al-Salah 'ala Al-Nabi reminders
      await _rescheduleSalahNabi();
    } catch (e) {
      debugPrint('[AppProvider] _rescheduleNotifications failed: $e');
    }
  }

  Future<void> refreshPrayerTimes() => _loadPrayerTimes();

  // ════════════════════════════════════════════════════════════════════════════
  // SESSION COMPLETION
  // ════════════════════════════════════════════════════════════════════════════
  Future<void> completeSession(String sessionId, {int pts = 100}) async {
    if (_completedSessionsToday.contains(sessionId)) return;

    _completedSessionsToday.add(sessionId);
    _totalPoints   += pts;
    _totalSessions += 1;

    final prefs     = await SharedPreferences.getInstance();
    final today     = _todayString();
    final yesterday = _yesterdayString();
    final todayWeekday = DateTime.now().weekday;

    // ── Streak update ──
    final lastStreakDate = prefs.getString(_kLastStreakDateKey) ?? '';
    if (lastStreakDate != today) {
      if (lastStreakDate == yesterday) {
        _streak++;
      } else {
        _streak = 1; // broken or first ever — restart at 1
      }
      await prefs.setString(_kLastStreakDateKey, today);
    }

    // ── Morning streak ──
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

    // ── Weekly tracker ──
    _weeklyCompletion[todayWeekday - 1] = true;

    // ── Persist ──
    await prefs.setStringList(_kCompletedSessionsKey, _completedSessionsToday.toList());
    await prefs.setInt(_kTotalPointsKey,   _totalPoints);
    await prefs.setInt(_kTotalSessionsKey, _totalSessions);
    await prefs.setInt(_kStreakKey,        _streak);
    await prefs.setString(_kWeeklyCompletionKey, _weeklyCompletion.join(','));

    _checkBadges(prefs);
    notifyListeners();
  }

  bool isSessionCompleted(String sessionId) =>
      _completedSessionsToday.contains(sessionId);

  // ════════════════════════════════════════════════════════════════════════════
  // BADGE EVALUATION
  // ════════════════════════════════════════════════════════════════════════════
  void _checkBadges(SharedPreferences prefs) {
    bool changed = false;

    void unlock(String id) {
      final b = _badges.firstWhere((b) => b.id == id, orElse: () => _badges[0]);
      if (!b.unlocked) {
        b.unlocked = true;
        changed    = true;
      }
    }

    if (_morningStreak >= 7)   unlock('early_riser');
    if (_morningStreak >= 30)  unlock('morning_light');
    if (_streak >= 7)          unlock('devoted');
    if (_totalSessions >= 100) unlock('century');
    if (_totalPoints >= 1000)  unlock('gem_collector');

    const allSessions = {'morning', 'evening', 'sleep', 'wakeup', 'cat_7'};
    if (_completedSessionsToday.containsAll(allSessions)) unlock('fortress');

    if (changed) {
      final ids = _badges.where((b) => b.unlocked).map((b) => b.id).toList();
      prefs.setStringList(_kUnlockedBadgesKey, ids);
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SETTINGS SETTERS
  // ════════════════════════════════════════════════════════════════════════════
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
    // Reschedule so notification text language updates immediately
    await _rescheduleNotifications();
  }

  Future<void> setHijriDates(bool value) async {
    _hijriDates = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHijriDatesKey, value);
  }

  Future<void> setUseGps(bool value) async {
    _useGps = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('diyaa-use-gps', value);
    await refreshPrayerTimes();
  }

  Future<void> setManualCity({
    required String cityName,
    required double lat,
    required double lng,
  }) async {
    _useGps         = false;
    _manualCityName = cityName;
    _latitude       = lat;
    _longitude      = lng;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('diyaa-use-gps', false);
    await prefs.setString('diyaa-manual-city', cityName);
    await prefs.setDouble('diyaa-lat', lat);
    await prefs.setDouble('diyaa-lng', lng);
    await refreshPrayerTimes();
  }

  Future<void> setUseLocation(bool value) => setUseGps(value);

  // ── Notification setters ──────────────────────────────────────────────────

  Future<void> setNotifPrayer(bool value) async {
    _notifPrayer = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifPrayerKey, value);
    await _rescheduleNotifications();
  }

  /// FIX: This setter now exists and is properly independent.
  /// Previously there was no way for the user to control azkar notifications
  /// without also toggling prayer notifications.
  Future<void> setNotifAzkar(bool value) async {
    _notifAzkar = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifAzkarKey, value);
    await _rescheduleNotifications();
  }

  Future<void> setNotifStreak(bool value) async {
    _notifStreak = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifStreakKey, value);
    if (!value) {
      try {
        await NotificationService.scheduleStreakWarning(
            enabled: false, isArabic: _arabicMode, currentStreak: _streak,
            soundEnabled: _soundEnabled); // FIX: pass sound preference
      } catch (_) {}
    } else if (_streak > 0) {
      try {
        await NotificationService.scheduleStreakWarning(
            enabled: true, isArabic: _arabicMode, currentStreak: _streak,
            soundEnabled: _soundEnabled); // FIX: pass sound preference
      } catch (_) {}
    }
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
    _rescheduleSalahNabi();
  }

  // ── Al-Salah 'ala Al-Nabi setters ────────────────────────────────────────

  Future<void> setSalahNotif(bool value) async {
    _salahNotif = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSalahNotifKey, value);
    _rescheduleSalahNabi();
  }

  Future<void> setSalahSound(String value) async {
    _salahSound = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSalahSoundKey, value);
    if (_salahNotif) _rescheduleSalahNabi();
  }

  Future<void> setSalahInterval(int minutes) async {
    _salahInterval = minutes;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kSalahIntervalKey, minutes);
    if (_salahNotif) _rescheduleSalahNabi();
  }

  Future<void> setSalahOverrideSilent(bool value) async {
    _salahOverrideSilent = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSalahOverrideSilentKey, value);
    if (_salahNotif) _rescheduleSalahNabi();
  }

  Future<void> _rescheduleSalahNabi() async {
    try {
      await NotificationService.scheduleSalahNabiReminders(
        enabled:       _salahNotif,
        soundAsset:    _salahSound,
        intervalMinutes: _salahInterval,
        overrideSilent: _salahOverrideSilent,
        soundEnabled:  _soundEnabled, // FIX: now passed through
      );
    } catch (e) {
      debugPrint('[AppProvider] _rescheduleSalahNabi failed: $e');
    }
  }

  Future<void> completeOnboarding() async {
    _onboardingComplete = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingCompleteKey, true);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SESSION PROGRESS PERSISTENCE
  // ════════════════════════════════════════════════════════════════════════════
  void saveZikrProgress(String sessionId, int index, List<int> counts) async {
    _sessionProgressIndex[sessionId]  = index;
    _sessionProgressCounts[sessionId] = counts;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_kSessionProgressIndexKey-$sessionId', index);
    await prefs.setStringList(
        '$_kSessionProgressCountsKey-$sessionId',
        counts.map((e) => e.toString()).toList());
  }

  int       getSavedZikrIndex(String sessionId)  => _sessionProgressIndex[sessionId]  ?? 0;
  List<int>? getSavedZikrCounts(String sessionId) => _sessionProgressCounts[sessionId];

  void clearSessionProgress(String sessionId) async {
    _sessionProgressIndex.remove(sessionId);
    _sessionProgressCounts.remove(sessionId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_kSessionProgressIndexKey-$sessionId');
    await prefs.remove('$_kSessionProgressCountsKey-$sessionId');
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SHOP
  // ════════════════════════════════════════════════════════════════════════════
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

  // ════════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════════════════════════════════════════
  String _todayString() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  String _yesterdayString() {
    final n = DateTime.now().subtract(const Duration(days: 1));
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  /// Bilingual text helper
  String t(String en, String ar) => _arabicMode ? ar : en;

  /// Converts Western digits to Arabic-Indic digits when in Arabic mode
  String toArabicDigits(String input) {
    if (!_arabicMode) return input;
    const en = ['0','1','2','3','4','5','6','7','8','9'];
    const ar = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
    String res = input;
    for (int i = 0; i < en.length; i++) {
      res = res.replaceAll(en[i], ar[i]);
    }
    return res;
  }
}