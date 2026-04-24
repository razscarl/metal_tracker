// lib/core/utils/time_service.dart

/// Centralised date/time helpers. Convention:
///   • Timestamps stored in DB  → UTC   (use [toUtcString])
///   • Date-only fields in DB   → local date as YYYY-MM-DD (use [toLocalDateString])
///   • Parsing timestamps from DB → local DateTime (use [parseTimestamp])
///   • Parsing date-only from DB  → plain DateTime.parse (no timezone meaning)
///   • Display → DateFormat on local DateTime using [AppDateFormats] constants
class TimeService {
  TimeService._();

  /// Parses a UTC ISO 8601 timestamp from Supabase → local [DateTime].
  /// Use for all timestamp columns (created_at, updated_at, *_timestamp, etc.).
  static DateTime parseTimestamp(String s) => DateTime.parse(s).toLocal();

  /// Serialises a [DateTime] → UTC ISO 8601 string for DB timestamp columns.
  static String toUtcString(DateTime dt) => dt.toUtc().toIso8601String();

  /// Extracts the local calendar date as a YYYY-MM-DD string for DB date-only columns.
  /// Uses the device's local timezone so the date reflects the user's "today".
  static String toLocalDateString(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  /// Convenience: today's local date as YYYY-MM-DD.
  static String todayLocalString() => toLocalDateString(DateTime.now());

  /// Legacy alias — kept so any existing callers still compile.
  @Deprecated('Use parseTimestamp()')
  static DateTime parseUtc(String iso) => parseTimestamp(iso);
}

/// Canonical display format strings — use these instead of inline string literals.
/// All formats operate on local [DateTime] values.
abstract class AppDateFormats {
  /// Compact datetime: "24 Apr 10:30" — home, live prices, spot prices
  static const compact = 'd MMM HH:mm';

  /// Date only: "24 Apr 2026" — analytics, holdings detail
  static const date = 'd MMM y';

  /// Date + time: "24 Apr 2026 10:30" — admin screens
  static const dateTime = 'd MMM y HH:mm';

  /// Full datetime with seconds: "24 Apr 2026 10:30:45" — automation job details
  static const full = 'd MMM y HH:mm:ss';

  /// Short date: "24 Apr 26" — compact table rows
  static const dateShort = 'd MMM yy';
}
