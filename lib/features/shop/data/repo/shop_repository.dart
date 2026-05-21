import '../data_sources/shop_local_data_source.dart';
import '../models/shop_model.dart';

class ShopRepository {
  final ShopLocalDataSource _dataSource;

  const ShopRepository({required ShopLocalDataSource dataSource})
      : _dataSource = dataSource;

  Future<ShopModel> loadShop() => _dataSource.loadShop();

  Future<ShopModel> purchaseTheme(ShopModel current, String themeId) async {
    await _dataSource.unlockTheme(themeId);
    final Set<String> updatedThemes = Set<String>.from(current.unlockedThemes)..add(themeId);
    return current.copyWith(unlockedThemes: updatedThemes);
  }

  Future<ShopModel> applyTheme(ShopModel current, String themeId) async {
    await _dataSource.saveActiveTheme(themeId);
    return current.copyWith(activeTheme: themeId);
  }

  Future<ShopModel> purchaseAudio(ShopModel current, String audioId) async {
    await _dataSource.unlockAudio(audioId);
    final Set<String> updatedAudios = Set<String>.from(current.unlockedAudios)..add(audioId);
    return current.copyWith(unlockedAudios: updatedAudios);
  }

  Future<ShopModel> applyAudio(ShopModel current, String audioId) async {
    await _dataSource.saveActiveAudio(audioId);
    return current.copyWith(activeAudio: audioId);
  }
}
