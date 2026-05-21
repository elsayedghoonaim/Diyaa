/// Domain entity for a single zikr (dhikr) item.
/// Pure Dart — no Flutter or platform dependencies.
class Zikr {
  final String arabic;
  final String transliteration;
  final String translation;
  final String source;
  final String sourceAr;
  final int repeat;
  final String repeatAr;
  final String description;

  const Zikr({
    required this.arabic,
    this.transliteration = '',
    this.translation = '',
    this.source = '',
    this.sourceAr = '',
    required this.repeat,
    this.repeatAr = '',
    this.description = '',
  });
}

/// A named collection of [Zikr] items forming a session.
class AzkarSession {
  final String id;
  final String nameAr;
  final String nameEn;
  final List<Zikr> zikrs;

  const AzkarSession({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.zikrs,
  });
}
