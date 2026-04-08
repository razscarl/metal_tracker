// lib/core/utils/time_service.dart

/// Centralised DateTime parsing helper.
/// All ISO 8601 strings from Supabase are UTC — always call `.toLocal()`.
class TimeService {
  TimeService._();

  /// Parses a UTC ISO 8601 string and converts to local time.
  static DateTime parseUtc(String iso) => DateTime.parse(iso).toLocal();
}
