class WorldCity {
  final String nameEn;
  final String nameAr;
  final String countryEn;
  final String countryAr;
  final double lat;
  final double lng;

  const WorldCity({
    required this.nameEn,
    required this.nameAr,
    required this.countryEn,
    required this.countryAr,
    required this.lat,
    required this.lng,
  });
}

const List<WorldCity> kWorldCities = [
  // ── Arabian Peninsula ──
  WorldCity(nameEn: 'Makkah', nameAr: 'مكة المكرمة', countryEn: 'Saudi Arabia', countryAr: 'السعودية', lat: 21.3891, lng: 39.8579),
  WorldCity(nameEn: 'Madinah', nameAr: 'المدينة المنورة', countryEn: 'Saudi Arabia', countryAr: 'السعودية', lat: 24.5247, lng: 39.5692),
  WorldCity(nameEn: 'Riyadh', nameAr: 'الرياض', countryEn: 'Saudi Arabia', countryAr: 'السعودية', lat: 24.7136, lng: 46.6753),
  WorldCity(nameEn: 'Jeddah', nameAr: 'جدة', countryEn: 'Saudi Arabia', countryAr: 'السعودية', lat: 21.4858, lng: 39.1925),
  WorldCity(nameEn: 'Dammam', nameAr: 'الدمام', countryEn: 'Saudi Arabia', countryAr: 'السعودية', lat: 26.4207, lng: 50.0888),
  WorldCity(nameEn: 'Dubai', nameAr: 'دبي', countryEn: 'UAE', countryAr: 'الإمارات', lat: 25.2048, lng: 55.2708),
  WorldCity(nameEn: 'Abu Dhabi', nameAr: 'أبو ظبي', countryEn: 'UAE', countryAr: 'الإمارات', lat: 24.4539, lng: 54.3773),
  WorldCity(nameEn: 'Kuwait City', nameAr: 'الكويت', countryEn: 'Kuwait', countryAr: 'الكويت', lat: 29.3759, lng: 47.9774),
  WorldCity(nameEn: 'Doha', nameAr: 'الدوحة', countryEn: 'Qatar', countryAr: 'قطر', lat: 25.2854, lng: 51.5310),
  WorldCity(nameEn: 'Manama', nameAr: 'المنامة', countryEn: 'Bahrain', countryAr: 'البحرين', lat: 26.2235, lng: 50.5876),
  WorldCity(nameEn: 'Muscat', nameAr: 'مسقط', countryEn: 'Oman', countryAr: 'عُمان', lat: 23.5880, lng: 58.3829),
  WorldCity(nameEn: "Sana'a", nameAr: 'صنعاء', countryEn: 'Yemen', countryAr: 'اليمن', lat: 15.3694, lng: 44.1910),
  // ── North Africa ──
  WorldCity(nameEn: 'Cairo', nameAr: 'القاهرة', countryEn: 'Egypt', countryAr: 'مصر', lat: 30.0444, lng: 31.2357),
  WorldCity(nameEn: 'Alexandria', nameAr: 'الإسكندرية', countryEn: 'Egypt', countryAr: 'مصر', lat: 31.2001, lng: 29.9187),
  WorldCity(nameEn: 'Casablanca', nameAr: 'الدار البيضاء', countryEn: 'Morocco', countryAr: 'المغرب', lat: 33.5731, lng: -7.5898),
  WorldCity(nameEn: 'Rabat', nameAr: 'الرباط', countryEn: 'Morocco', countryAr: 'المغرب', lat: 33.9716, lng: -6.8498),
  WorldCity(nameEn: 'Algiers', nameAr: 'الجزائر', countryEn: 'Algeria', countryAr: 'الجزائر', lat: 36.7372, lng: 3.0865),
  WorldCity(nameEn: 'Tunis', nameAr: 'تونس', countryEn: 'Tunisia', countryAr: 'تونس', lat: 36.8190, lng: 10.1658),
  WorldCity(nameEn: 'Tripoli', nameAr: 'طرابلس', countryEn: 'Libya', countryAr: 'ليبيا', lat: 32.8872, lng: 13.1913),
  WorldCity(nameEn: 'Khartoum', nameAr: 'الخرطوم', countryEn: 'Sudan', countryAr: 'السودان', lat: 15.5007, lng: 32.5599),
  // ── Levant & Iraq ──
  WorldCity(nameEn: 'Amman', nameAr: 'عمّان', countryEn: 'Jordan', countryAr: 'الأردن', lat: 31.9454, lng: 35.9284),
  WorldCity(nameEn: 'Baghdad', nameAr: 'بغداد', countryEn: 'Iraq', countryAr: 'العراق', lat: 33.3152, lng: 44.3661),
  WorldCity(nameEn: 'Beirut', nameAr: 'بيروت', countryEn: 'Lebanon', countryAr: 'لبنان', lat: 33.8938, lng: 35.5018),
  WorldCity(nameEn: 'Damascus', nameAr: 'دمشق', countryEn: 'Syria', countryAr: 'سوريا', lat: 33.5138, lng: 36.2765),
  WorldCity(nameEn: 'Gaza', nameAr: 'غزة', countryEn: 'Palestine', countryAr: 'فلسطين', lat: 31.5017, lng: 34.4668),
  // ── Turkey & Central Asia ──
  WorldCity(nameEn: 'Istanbul', nameAr: 'إسطنبول', countryEn: 'Turkey', countryAr: 'تركيا', lat: 41.0082, lng: 28.9784),
  WorldCity(nameEn: 'Ankara', nameAr: 'أنقرة', countryEn: 'Turkey', countryAr: 'تركيا', lat: 39.9334, lng: 32.8597),
  WorldCity(nameEn: 'Tehran', nameAr: 'طهران', countryEn: 'Iran', countryAr: 'إيران', lat: 35.6892, lng: 51.3890),
  WorldCity(nameEn: 'Tashkent', nameAr: 'طشقند', countryEn: 'Uzbekistan', countryAr: 'أوزبكستان', lat: 41.2995, lng: 69.2401),
  // ── South & Southeast Asia ──
  WorldCity(nameEn: 'Karachi', nameAr: 'كراتشي', countryEn: 'Pakistan', countryAr: 'باكستان', lat: 24.8607, lng: 67.0011),
  WorldCity(nameEn: 'Lahore', nameAr: 'لاهور', countryEn: 'Pakistan', countryAr: 'باكستان', lat: 31.5204, lng: 74.3587),
  WorldCity(nameEn: 'Islamabad', nameAr: 'إسلام آباد', countryEn: 'Pakistan', countryAr: 'باكستان', lat: 33.7294, lng: 73.0931),
  WorldCity(nameEn: 'Dhaka', nameAr: 'دكا', countryEn: 'Bangladesh', countryAr: 'بنغلاديش', lat: 23.8103, lng: 90.4125),
  WorldCity(nameEn: 'Mumbai', nameAr: 'مومباي', countryEn: 'India', countryAr: 'الهند', lat: 19.0760, lng: 72.8777),
  WorldCity(nameEn: 'Delhi', nameAr: 'دلهي', countryEn: 'India', countryAr: 'الهند', lat: 28.7041, lng: 77.1025),
  WorldCity(nameEn: 'Kuala Lumpur', nameAr: 'كوالالمبور', countryEn: 'Malaysia', countryAr: 'ماليزيا', lat: 3.1390, lng: 101.6869),
  WorldCity(nameEn: 'Jakarta', nameAr: 'جاكرتا', countryEn: 'Indonesia', countryAr: 'إندونيسيا', lat: -6.2088, lng: 106.8456),
  // ── Africa (Sub-Saharan) ──
  WorldCity(nameEn: 'Lagos', nameAr: 'لاغوس', countryEn: 'Nigeria', countryAr: 'نيجيريا', lat: 6.5244, lng: 3.3792),
  WorldCity(nameEn: 'Accra', nameAr: 'أكرا', countryEn: 'Ghana', countryAr: 'غانا', lat: 5.6037, lng: -0.1870),
  WorldCity(nameEn: 'Nairobi', nameAr: 'نيروبي', countryEn: 'Kenya', countryAr: 'كينيا', lat: -1.2921, lng: 36.8219),
  WorldCity(nameEn: 'Dakar', nameAr: 'داكار', countryEn: 'Senegal', countryAr: 'السنغال', lat: 14.7167, lng: -17.4677),
  // ── Europe ──
  WorldCity(nameEn: 'London', nameAr: 'لندن', countryEn: 'UK', countryAr: 'المملكة المتحدة', lat: 51.5074, lng: -0.1278),
  WorldCity(nameEn: 'Paris', nameAr: 'باريس', countryEn: 'France', countryAr: 'فرنسا', lat: 48.8566, lng: 2.3522),
  WorldCity(nameEn: 'Berlin', nameAr: 'برلين', countryEn: 'Germany', countryAr: 'ألمانيا', lat: 52.5200, lng: 13.4050),
  WorldCity(nameEn: 'Amsterdam', nameAr: 'أمستردام', countryEn: 'Netherlands', countryAr: 'هولندا', lat: 52.3676, lng: 4.9041),
  WorldCity(nameEn: 'Brussels', nameAr: 'بروكسل', countryEn: 'Belgium', countryAr: 'بلجيكا', lat: 50.8503, lng: 4.3517),
  WorldCity(nameEn: 'Madrid', nameAr: 'مدريد', countryEn: 'Spain', countryAr: 'إسبانيا', lat: 40.4168, lng: -3.7038),
  WorldCity(nameEn: 'Rome', nameAr: 'روما', countryEn: 'Italy', countryAr: 'إيطاليا', lat: 41.9028, lng: 12.4964),
  WorldCity(nameEn: 'Stockholm', nameAr: 'ستوكهولم', countryEn: 'Sweden', countryAr: 'السويد', lat: 59.3293, lng: 18.0686),
  WorldCity(nameEn: 'Copenhagen', nameAr: 'كوبنهاغن', countryEn: 'Denmark', countryAr: 'الدنمارك', lat: 55.6761, lng: 12.5683),
  WorldCity(nameEn: 'Oslo', nameAr: 'أوسلو', countryEn: 'Norway', countryAr: 'النرويج', lat: 59.9139, lng: 10.7522),
  WorldCity(nameEn: 'Helsinki', nameAr: 'هلسنكي', countryEn: 'Finland', countryAr: 'فنلندا', lat: 60.1699, lng: 24.9384),
  WorldCity(nameEn: 'Vienna', nameAr: 'فيينا', countryEn: 'Austria', countryAr: 'النمسا', lat: 48.2082, lng: 16.3738),
  WorldCity(nameEn: 'Zurich', nameAr: 'زيورخ', countryEn: 'Switzerland', countryAr: 'سويسرا', lat: 47.3769, lng: 8.5417),
  // ── Americas ──
  WorldCity(nameEn: 'New York', nameAr: 'نيويورك', countryEn: 'USA', countryAr: 'الولايات المتحدة', lat: 40.7128, lng: -74.0060),
  WorldCity(nameEn: 'Los Angeles', nameAr: 'لوس أنجلوس', countryEn: 'USA', countryAr: 'الولايات المتحدة', lat: 34.0522, lng: -118.2437),
  WorldCity(nameEn: 'Chicago', nameAr: 'شيكاغو', countryEn: 'USA', countryAr: 'الولايات المتحدة', lat: 41.8781, lng: -87.6298),
  WorldCity(nameEn: 'Houston', nameAr: 'هيوستن', countryEn: 'USA', countryAr: 'الولايات المتحدة', lat: 29.7604, lng: -95.3698),
  WorldCity(nameEn: 'Toronto', nameAr: 'تورونتو', countryEn: 'Canada', countryAr: 'كندا', lat: 43.6532, lng: -79.3832),
  WorldCity(nameEn: 'Montreal', nameAr: 'مونتريال', countryEn: 'Canada', countryAr: 'كندا', lat: 45.5017, lng: -73.5673),
  WorldCity(nameEn: 'São Paulo', nameAr: 'ساو باولو', countryEn: 'Brazil', countryAr: 'البرازيل', lat: -23.5505, lng: -46.6333),
  // ── Oceania ──
  WorldCity(nameEn: 'Sydney', nameAr: 'سيدني', countryEn: 'Australia', countryAr: 'أستراليا', lat: -33.8688, lng: 151.2093),
  WorldCity(nameEn: 'Melbourne', nameAr: 'ملبورن', countryEn: 'Australia', countryAr: 'أستراليا', lat: -37.8136, lng: 144.9631),
];
