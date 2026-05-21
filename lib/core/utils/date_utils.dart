// Date utility functions extracted from AppProvider.
// Pure Dart — no Flutter or platform dependencies.

/// Returns today's date as an ISO-8601 date string (YYYY-MM-DD).
String todayString() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}

/// Returns yesterday's date as an ISO-8601 date string (YYYY-MM-DD).
String yesterdayString() {
  final n = DateTime.now().subtract(const Duration(days: 1));
  return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}
