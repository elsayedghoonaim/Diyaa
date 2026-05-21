class ShopModel {
  final Set<String> unlockedThemes;
  final Set<String> unlockedAudios;
  final String activeTheme;
  final String activeAudio;

  const ShopModel({
    required this.unlockedThemes,
    required this.unlockedAudios,
    required this.activeTheme,
    required this.activeAudio,
  });

  ShopModel copyWith({
    Set<String>? unlockedThemes,
    Set<String>? unlockedAudios,
    String? activeTheme,
    String? activeAudio,
  }) {
    return ShopModel(
      unlockedThemes: unlockedThemes ?? this.unlockedThemes,
      unlockedAudios: unlockedAudios ?? this.unlockedAudios,
      activeTheme: activeTheme ?? this.activeTheme,
      activeAudio: activeAudio ?? this.activeAudio,
    );
  }
}
