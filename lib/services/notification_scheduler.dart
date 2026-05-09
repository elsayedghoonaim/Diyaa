/// Conditional export:
/// On Android / iOS / macOS → real scheduling implementation.
/// On Windows / Linux / Web → no-op stubs (never compiled with real API).
export 'notification_scheduler_stub.dart'
    if (dart.library.io) 'notification_scheduler_mobile.dart';