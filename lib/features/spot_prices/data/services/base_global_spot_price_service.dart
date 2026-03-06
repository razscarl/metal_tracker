// lib/features/spot_prices/data/services/base_global_spot_price_service.dart

class SpotPriceUsageResult {
  final String? plan;
  final int used;
  final int total;
  final int remaining;
  final String? errorMessage;

  const SpotPriceUsageResult({
    this.plan,
    required this.used,
    required this.total,
    required this.remaining,
    this.errorMessage,
  });

  bool get isSuccess => errorMessage == null;
}

class SpotPriceRatesResult {
  final String base;
  final DateTime? timestamp;
  final Map<String, double> rates;
  final String? errorMessage;

  const SpotPriceRatesResult({
    required this.base,
    this.timestamp,
    required this.rates,
    this.errorMessage,
  });

  bool get isSuccess => errorMessage == null;
}

class ServiceConfigField {
  final String key;
  final String label;
  final String? hint;
  final String? defaultValue;
  final bool isRequired;

  const ServiceConfigField({
    required this.key,
    required this.label,
    this.hint,
    this.defaultValue,
    this.isRequired = true,
  });
}

abstract class BaseGlobalSpotPriceService {
  /// Registry key stored in DB (e.g. 'metalpriceapi').
  String get serviceType;

  /// Shown in the service dropdown.
  String get displayName;

  /// Shown on add/edit screen below the service dropdown.
  String get infoBannerText;

  /// Form fields rendered after the API key field. Empty = no extra fields.
  List<ServiceConfigField> get configSchema;

  /// Returns null if this service has no usage/quota endpoint.
  /// The UI skips the usage confirmation dialog when null is returned.
  Future<SpotPriceUsageResult?> checkUsage(
    String apiKey,
    Map<String, String> config,
  ) async =>
      null;

  /// Fetch latest spot rates. [config] holds service-specific key/value pairs.
  Future<SpotPriceRatesResult> fetchLatestRates(
    String apiKey,
    Map<String, String> config,
  );

  /// Maps raw rate keys → {metalName: price}. Each service knows its own format.
  /// Returns a map of e.g. {'gold': 2500.0, 'silver': 30.0, 'platinum': 900.0}.
  Map<String, double?> resolveMetals(
    Map<String, double> rates,
    Map<String, String> config,
  );
}
