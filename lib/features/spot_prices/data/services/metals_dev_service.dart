// lib/features/spot_prices/data/services/metals_dev_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:metal_tracker/features/spot_prices/data/services/base_global_spot_price_service.dart';

class MetalsDevService extends BaseGlobalSpotPriceService {
  static const _errorMessages = {
    '1101': 'The API key provided is invalid.',
    '1201': 'The plan is not active due to failed payments.',
    '1202': 'The account is not active or disabled.',
    '1203': 'Monthly quota (including grace usage) exceeded.',
    '2101': 'Unsupported input parameter (metal code, authority code or unit code).',
    '2102': 'Mandatory input parameters missing from the request.',
    '2103': 'Unsupported currency code.',
    '2104': 'Invalid date format. Valid format is YYYY-MM-DD.',
    '2105': 'Invalid or out-of-range start/end date.',
  };

  @override
  String get serviceType => 'metalsdev';

  @override
  String get displayName => 'Metals.dev';

  @override
  String get infoBannerText =>
      'API keys are from metals.dev. Currency is typically AUD and unit toz '
      '(troy ounce). Gold, silver and platinum prices are returned directly.';

  @override
  List<ServiceConfigField> get configSchema => const [
        ServiceConfigField(
          key: 'baseUrl',
          label: 'Base URL',
          hint: 'https://api.metals.dev',
          defaultValue: 'https://api.metals.dev',
        ),
        ServiceConfigField(
          key: 'version',
          label: 'API Version',
          hint: 'v1',
          defaultValue: 'v1',
        ),
        ServiceConfigField(
          key: 'currency',
          label: 'Currency',
          hint: 'AUD',
          defaultValue: 'AUD',
        ),
        ServiceConfigField(
          key: 'unit',
          label: 'Unit',
          hint: 'toz',
          defaultValue: 'toz',
        ),
      ];

  String _stripTrailingSlash(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  String _latestUrl(Map<String, String> config) {
    final base = _stripTrailingSlash(
        config['baseUrl'] ?? 'https://api.metals.dev');
    final version = config['version'] ?? 'v1';
    return '$base/$version/latest';
  }

  String _usageUrl(Map<String, String> config) {
    final base = _stripTrailingSlash(
        config['baseUrl'] ?? 'https://api.metals.dev');
    return '$base/usage';
  }

  String _errorFrom(Map<String, dynamic> body) {
    final code = body['error_code']?.toString() ?? '';
    return _errorMessages[code] ??
        body['error_message'] as String? ??
        'Unknown error (code $code)';
  }

  @override
  Future<SpotPriceUsageResult?> checkUsage(
    String apiKey,
    Map<String, String> config,
  ) async {
    try {
      final uri = Uri.parse(_usageUrl(config)).replace(
        queryParameters: {'api_key': apiKey},
      );

      final response = await http.get(uri);
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (body['status'] != 'success') {
        return SpotPriceUsageResult(
          used: 0,
          total: 0,
          remaining: 0,
          errorMessage: _errorFrom(body),
        );
      }

      return SpotPriceUsageResult(
        plan: body['plan'] as String?,
        used: (body['used'] as num?)?.toInt() ?? 0,
        total: (body['total'] as num?)?.toInt() ?? 0,
        remaining: (body['remaining'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      return SpotPriceUsageResult(
        used: 0,
        total: 0,
        remaining: 0,
        errorMessage: 'Network error: $e',
      );
    }
  }

  @override
  Future<SpotPriceRatesResult> fetchLatestRates(
    String apiKey,
    Map<String, String> config,
  ) async {
    final currency = config['currency'] ?? 'AUD';
    final unit = config['unit'] ?? 'toz';

    try {
      final uri = Uri.parse(_latestUrl(config)).replace(
        queryParameters: {
          'api_key': apiKey,
          'currency': currency,
          'unit': unit,
        },
      );

      final response = await http.get(uri);
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (body['status'] != 'success') {
        return SpotPriceRatesResult(
          base: currency,
          rates: {},
          errorMessage: _errorFrom(body),
        );
      }

      final metals = body['metals'] as Map<String, dynamic>? ?? {};
      final rates = metals.map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      );

      final tsString = (body['timestamps'] as Map<String, dynamic>?)?['metal']
          as String?;
      final timestamp = tsString != null
          ? (DateTime.tryParse(tsString)?.toUtc())
          : DateTime.now().toUtc();

      return SpotPriceRatesResult(
        base: currency,
        timestamp: timestamp,
        rates: rates,
      );
    } catch (e) {
      return SpotPriceRatesResult(
        base: config['currency'] ?? 'AUD',
        rates: {},
        errorMessage: 'Network error: $e',
      );
    }
  }

  @override
  Map<String, double?> resolveMetals(
    Map<String, double> rates,
    Map<String, String> config,
  ) {
    return {
      'gold': rates['gold'],
      'silver': rates['silver'],
      'platinum': rates['platinum'],
    };
  }
}
