import '../../../settings/data/models/settings_model.dart';

/// States emitted by [SettingsCubit].
sealed class SettingsState {
  const SettingsState();
}

/// Initial state before any settings are loaded.
final class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

/// Settings are being loaded from persistent storage.
final class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

/// Settings were loaded successfully.
final class SettingsLoaded extends SettingsState {
  final SettingsModel settings;
  const SettingsLoaded(this.settings);
}

/// An error occurred while loading or saving settings.
final class SettingsError extends SettingsState {
  final String message;
  const SettingsError(this.message);
}
