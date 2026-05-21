/// Immutable data model for a single achievement badge.
class BadgeModel {
  final String id;
  final String nameEn;
  final String nameAr;
  final String descriptionEn;
  final String descriptionAr;
  final String icon;
  final int requiredSessions;
  final String color;
  final bool isUnlocked;

  const BadgeModel({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.icon,
    required this.requiredSessions,
    required this.color,
    this.isUnlocked = false,
  });

  BadgeModel copyWith({bool? isUnlocked}) => BadgeModel(
        id: id,
        nameEn: nameEn,
        nameAr: nameAr,
        descriptionEn: descriptionEn,
        descriptionAr: descriptionAr,
        icon: icon,
        requiredSessions: requiredSessions,
        color: color,
        isUnlocked: isUnlocked ?? this.isUnlocked,
      );

  /// All badges defined in the app.
  static const List<BadgeModel> all = [
    BadgeModel(
      id: 'first_step',
      nameEn: 'First Step',
      nameAr: 'الخطوة الأولى',
      descriptionEn: 'Complete your first azkar session',
      descriptionAr: 'أكمل جلسة أذكار أولى',
      icon: '🌱',
      requiredSessions: 1,
      color: 'teal',
    ),
    BadgeModel(
      id: 'devoted',
      nameEn: 'Devoted',
      nameAr: 'المداوم',
      descriptionEn: 'Complete 10 sessions',
      descriptionAr: 'أكمل ١٠ جلسات',
      icon: '⭐',
      requiredSessions: 10,
      color: 'gold',
    ),
    BadgeModel(
      id: 'consistent',
      nameEn: 'Consistent',
      nameAr: 'المثابر',
      descriptionEn: 'Complete 30 sessions',
      descriptionAr: 'أكمل ٣٠ جلسة',
      icon: '🌟',
      requiredSessions: 30,
      color: 'gold',
    ),
    BadgeModel(
      id: 'faithful',
      nameEn: 'Faithful',
      nameAr: 'الثابت',
      descriptionEn: 'Complete 100 sessions',
      descriptionAr: 'أكمل ١٠٠ جلسة',
      icon: '💎',
      requiredSessions: 100,
      color: 'teal',
    ),
    BadgeModel(
      id: 'golden_heart',
      nameEn: 'Golden Heart',
      nameAr: 'القلب الذهبي',
      descriptionEn: 'Complete 365 sessions',
      descriptionAr: 'أكمل ٣٦٥ جلسة',
      icon: '👑',
      requiredSessions: 365,
      color: 'gold',
    ),
  ];
}
