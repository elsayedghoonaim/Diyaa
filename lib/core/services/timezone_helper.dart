// Conditional export:
// - On Android / iOS / macOS  → uses flutter_timezone (real device timezone)
// - On Windows / Linux / Web  → uses stub (returns 'Africa/Cairo')
//
// The condition `dart.library.io` is true on all native platforms, but
// flutter_timezone only has a native implementation for Android/iOS/macOS.
// We therefore check the platform at runtime inside the mobile file.
export 'timezone_helper_stub.dart'
    if (dart.library.io) 'timezone_helper_mobile.dart';