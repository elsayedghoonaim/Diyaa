/// Stub for platforms that don't support flutter_timezone
/// (Windows, Linux, Web). Returns Cairo as a safe default for Egypt.
Future<String> getDeviceTimezone() async {
  return 'Africa/Cairo';
}