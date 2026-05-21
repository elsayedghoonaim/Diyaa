import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/settings_model.dart';
import '../../data/repo/settings_repository.dart';
import 'settings_state.dart';

/// Cubit responsible for all settings-related state transitions.
/// Screens dispatch setter calls; the cubit delegates to [SettingsRepository].
class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repository;

  SettingsCubit({required SettingsRepository repository})
      : _repository = repository,
        super(const SettingsInitial());

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadSettings() async {
    emit(const SettingsLoading());
    try {
      final settings = await _repository.loadSettings();
      emit(SettingsLoaded(settings));
    } catch (e) {
      debugPrint('[SettingsCubit] Error loading settings: $e');
      emit(SettingsError('Failed to load settings: $e'));
    }
  }

  // ── Convenience getter ────────────────────────────────────────────────────

  SettingsModel? get currentSettings =>
      state is SettingsLoaded ? (state as SettingsLoaded).settings : null;

  // ── Setters ───────────────────────────────────────────────────────────────

  Future<void> setDarkMode(bool value) => _update(
        (s) => _repository.setDarkMode(s, value),
      );

  Future<void> setArabicMode(bool value) => _update(
        (s) => _repository.setArabicMode(s, value),
      );

  Future<void> setHijriDates(bool value) => _update(
        (s) => _repository.setHijriDates(s, value),
      );

  Future<void> setZikrFontSize(String value) => _update(
        (s) => _repository.setZikrFontSize(s, value),
      );

  Future<void> setAppTextScale(double value) => _update(
        (s) => _repository.setAppTextScale(s, value),
      );

  Future<void> setUseGps(bool value) => _update(
        (s) => _repository.setUseGps(s, value),
      );

  Future<void> setManualCity({
    required String cityName,
    required double lat,
    required double lng,
  }) =>
      _update(
        (s) => _repository.setManualCity(s, cityName: cityName, lat: lat, lng: lng),
      );

  Future<void> setNotifPrayer(bool value) => _update(
        (s) => _repository.setNotifPrayer(s, value),
      );

  Future<void> setNotifAzkar(bool value) => _update(
        (s) => _repository.setNotifAzkar(s, value),
      );

  Future<void> setNotifStreak(bool value, {required int currentStreak}) => _update(
        (s) => _repository.setNotifStreak(s, value, currentStreak: currentStreak),
      );

  Future<void> setNotifMilestone(bool value) => _update(
        (s) => _repository.setNotifMilestone(s, value),
      );

  Future<void> setSoundEnabled(bool value) => _update(
        (s) => _repository.setSoundEnabled(s, value),
      );

  Future<void> setSalahNotif(bool value) => _update(
        (s) => _repository.setSalahNotif(s, value),
      );

  Future<void> setSalahSound(String value) => _update(
        (s) => _repository.setSalahSound(s, value),
      );

  Future<void> setSalahInterval(int minutes) => _update(
        (s) => _repository.setSalahInterval(s, minutes),
      );

  Future<void> setSalahOverrideSilent(bool value) => _update(
        (s) => _repository.setSalahOverrideSilent(s, value),
      );

  Future<void> completeOnboarding() => _update(
        (s) => _repository.completeOnboarding(s),
      );

  Future<void> syncLauncherIcon() async {
    final settings = currentSettings;
    if (settings == null) return;
    await _repository.syncLauncherIcon(settings.darkMode);
  }

  // ── Private helper ────────────────────────────────────────────────────────

  Future<void> _update(
    Future<SettingsModel> Function(SettingsModel current) updater,
  ) async {
    final current = currentSettings;
    if (current == null) return;
    try {
      final updated = await updater(current);
      emit(SettingsLoaded(updated));
    } catch (e) {
      emit(SettingsError('Settings update failed: $e'));
    }
  }
}
