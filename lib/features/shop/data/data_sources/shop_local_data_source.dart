import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/preference_keys.dart';
import '../models/shop_model.dart';

class ShopLocalDataSource {
  const ShopLocalDataSource();

  Future<ShopModel> loadShop() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final List<String> themesList = preferences.getStringList(kUnlockedThemesKey) ?? <String>['desert_dunes'];
    final List<String> audiosList = preferences.getStringList(kUnlockedAudiosKey) ?? <String>['prayer_bell'];
    final String activeTheme = preferences.getString(kActiveThemeKey) ?? 'desert_dunes';
    final String activeAudio = preferences.getString(kActiveAudioKey) ?? 'prayer_bell';
    return ShopModel(
      unlockedThemes: themesList.toSet(),
      unlockedAudios: audiosList.toSet(),
      activeTheme: activeTheme,
      activeAudio: activeAudio,
    );
  }

  Future<void> unlockTheme(String themeId) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final List<String> themesList = preferences.getStringList(kUnlockedThemesKey) ?? <String>['desert_dunes'];
    final Set<String> themesSet = themesList.toSet();
    themesSet.add(themeId);
    await preferences.setStringList(kUnlockedThemesKey, themesSet.toList());
  }

  Future<void> saveActiveTheme(String themeId) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(kActiveThemeKey, themeId);
  }

  Future<void> unlockAudio(String audioId) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final List<String> audiosList = preferences.getStringList(kUnlockedAudiosKey) ?? <String>['prayer_bell'];
    final Set<String> audiosSet = audiosList.toSet();
    audiosSet.add(audioId);
    await preferences.setStringList(kUnlockedAudiosKey, audiosSet.toList());
  }

  Future<void> saveActiveAudio(String audioId) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(kActiveAudioKey, audioId);
  }
}
