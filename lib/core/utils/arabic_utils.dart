// Bilingual text and Arabic digit utilities.
// These were previously methods on AppProvider — moved here so all features
// can access them as pure functions without a BuildContext or provider.

/// Returns [ar] when [isArabic] is true, otherwise returns [en].
String localise(String en, String ar, {required bool isArabic}) =>
    isArabic ? ar : en;

/// Converts Western (ASCII) digits in [input] to Arabic-Indic digits.
/// Returns [input] unchanged when [isArabic] is false.
String toArabicDigits(String input, {required bool isArabic}) {
  if (!isArabic) return input;
  const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const ar = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  String result = input;
  for (int i = 0; i < en.length; i++) {
    result = result.replaceAll(en[i], ar[i]);
  }
  return result;
}

/// Formats an integer with thousands comma separator.
String formatNumber(int n) {
  if (n < 1000) return n.toString();
  if (n < 1000000) {
    final s = n.toString();
    return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
  }
  return n.toString();
}

/// Normalizes Arabic text by removing diacritics and unifying characters.
String normalizeArabic(String text) {
  return text
      .replaceAll('\u064B', '')
      .replaceAll('\u064C', '')
      .replaceAll('\u064D', '')
      .replaceAll('\u064E', '')
      .replaceAll('\u064F', '')
      .replaceAll('\u0650', '')
      .replaceAll('\u0651', '')
      .replaceAll('\u0652', '')
      .replaceAll('\u0640', '')
      .replaceAll('أ', 'ا')
      .replaceAll('إ', 'ا')
      .replaceAll('آ', 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي');
}

