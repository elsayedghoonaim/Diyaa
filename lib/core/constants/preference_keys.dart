// Preference keys for SharedPreferences — single source of truth.
// All features read and write using these constants.

const String kDarkModeKey              = 'diyaa-dark-mode';
const String kArabicModeKey            = 'diyaa-arabic-mode';
const String kHijriDatesKey            = 'diyaa-hijri-dates';
const String kZikrFontSizeKey          = 'diyaa-zikr-font-size';
const String kAppTextScaleKey          = 'diyaa-app-text-scale';

// Location
const String kUseGpsKey                = 'diyaa-use-gps';
const String kManualCityKey            = 'diyaa-manual-city';
const String kLatitudeKey              = 'diyaa-lat';
const String kLongitudeKey             = 'diyaa-lng';
const int    kLocationPrefsVersion     = 2;
const String kLocationPrefsVerKey      = 'diyaa-location-prefs-ver';

// Notifications
const String kNotifPrayerKey           = 'diyaa-notif-prayer';
const String kNotifAzkarKey            = 'diyaa-notif-azkar';
const String kNotifStreakKey           = 'diyaa-notif-streak';
const String kNotifMilestoneKey        = 'diyaa-notif-milestone';
const String kSoundEnabledKey          = 'diyaa-sound-enabled';

// Al-Salah 'ala Al-Nabi
const String kSalahNotifKey            = 'diyaa-salah-notif';
const String kSalahSoundKey            = 'diyaa-salah-sound';
const String kSalahIntervalKey         = 'diyaa-salah-interval';
const String kSalahOverrideSilentKey   = 'diyaa-salah-override-silent';

// Progress
const String kCompletedSessionsKey     = 'diyaa-completed-sessions';
const String kLastResetKey             = 'diyaa-last-reset';
const String kTotalPointsKey           = 'diyaa-total-points';
const String kTotalSessionsKey         = 'diyaa-total-sessions';
const String kStreakKey                = 'diyaa-streak';
const String kLastStreakDateKey        = 'diyaa-last-streak-date';
const String kWeeklyCompletionKey      = 'diyaa-weekly-completion';
const String kUnlockedBadgesKey        = 'diyaa-unlocked-badges';
const String kMorningStreakKey         = 'diyaa-morning-streak';
const String kLastMorningDateKey       = 'diyaa-last-morning-date';

// Shop
const String kUnlockedThemesKey        = 'diyaa-unlocked-themes';
const String kUnlockedAudiosKey        = 'diyaa-unlocked-audios';
const String kActiveThemeKey           = 'diyaa-active-theme';
const String kActiveAudioKey           = 'diyaa-active-audio';

// Onboarding
const String kOnboardingCompleteKey    = 'diyaa-onboarding-complete';

// Session progress
const String kSessionProgressIndexKey  = 'diyaa-session-progress-index';
const String kSessionProgressCountsKey = 'diyaa-session-progress-counts';
