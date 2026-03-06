// lib/features/spot_prices/data/services/metal_price_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:metal_tracker/features/spot_prices/data/services/base_global_spot_price_service.dart';

class MetalPriceApiService extends BaseGlobalSpotPriceService {
  static const _baseUrl = 'https://api.metalpriceapi.com/v1';

  static const _errorMessages = {
    '101': 'No API key was supplied.',
    '102': 'Account is inactive. Please activate your account.',
    '103': 'The requested API endpoint does not exist.',
    '104': 'Monthly API request limit has been reached.',
    '105': 'The current subscription plan does not support this endpoint.',
    '106': 'The current subscription plan does not support this base currency.',
    '201': 'An invalid base currency has been specified.',
    '202': 'One or more invalid currency codes were specified.',
    '301': 'An invalid date was specified.',
    '302': 'Date is out of allowed range (before 1st Jan 1999).',
    '304': 'Date cannot be in the future.',
    '401': 'No or an invalid amount has been specified.',
    '402': 'The requested conversion is not supported.',
    '501': 'No fluctuation data is available for the given date range.',
    '502':
        'The requested time frame exceeds the maximum allowed (365 days for paid, 7 days for free).',
    '601': 'No or an invalid OHLC interval was specified.',
    '602':
        'The requested OHLC date range exceeds the maximum allowed (31 days).',
    '701': 'Too many requests. Please implement exponential back-off.',
    '800': 'Internal API error. Please try again later.',
    '900': 'The service is temporarily unavailable. Please try again later.',
  };

  @override
  String get serviceType => 'metalpriceapi';

  @override
  String get displayName => 'Metal Price API';

  @override
  String get infoBannerText =>
      'API keys are from metalpriceapi.com. '
      'Base currency is typically AUD and '
      'currencies are XAU (Gold), XAG (Silver), XPT (Platinum).';

  @override
  List<ServiceConfigField> get configSchema => const [
        ServiceConfigField(
          key: 'baseCurrency',
          label: 'Base Currency',
          hint: 'AUD',
          defaultValue: 'AUD',
        ),
        ServiceConfigField(
          key: 'currencies',
          label: 'Metal Codes',
          hint: 'XAU,XAG,XPT',
          defaultValue: 'XAU,XAG,XPT',
        ),
      ];

  @override
  Future<SpotPriceUsageResult?> checkUsage(
    String apiKey,
    Map<String, String> config,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/usage').replace(
        queryParameters: {'api_key': apiKey},
      );

      final response = await http.get(uri);
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (body['success'] != true) {
        final code = body['error']?['code']?.toString() ?? '';
        final message = _errorMessages[code] ??
            body['error']?['info'] as String? ??
            'Unknown error (code $code)';
        return SpotPriceUsageResult(
          used: 0,
          total: 0,
          remaining: 0,
          errorMessage: message,
        );
      }

      final result = body['result'] as Map<String, dynamic>? ?? {};
      final used = (result['used'] as num?)?.toInt() ?? 0;
      final total = (result['total'] as num?)?.toInt() ?? 0;
      final remaining =
          (result['remaining'] as num?)?.toInt() ?? (total - used);

      return SpotPriceUsageResult(
        plan: result['plan'] as String?,
        used: used,
        total: total,
        remaining: remaining,
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
    final base = config['baseCurrency'] ?? 'AUD';
    final currencies = config['currencies'] ?? 'XAU,XAG,XPT';

    try {
      final uri = Uri.parse('$_baseUrl/latest').replace(
        queryParameters: {
          'api_key': apiKey,
          'base': base,
          'currencies': currencies,
        },
      );

      final response = await http.get(uri);
      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (body['success'] != true) {
        final code = body['error']?['code']?.toString() ?? '';
        final message = _errorMessages[code] ??
            body['error']?['info'] as String? ??
            'Unknown error (code $code)';
        return SpotPriceRatesResult(
          base: base,
          rates: {},
          errorMessage: message,
        );
      }

      final rawRates = body['rates'] as Map<String, dynamic>? ?? {};
      final rates = rawRates.map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      );

      final tsSeconds = (body['timestamp'] as num?)?.toInt();
      final timestamp = tsSeconds != null
          ? DateTime.fromMillisecondsSinceEpoch(tsSeconds * 1000)
          : DateTime.now();

      return SpotPriceRatesResult(
        base: base,
        timestamp: timestamp,
        rates: rates,
      );
    } catch (e) {
      return SpotPriceRatesResult(
        base: base,
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
    final base = config['baseCurrency'] ?? 'AUD';
    return {
      'gold': rates['${base}XAU'] ?? rates['XAU'],
      'silver': rates['${base}XAG'] ?? rates['XAG'],
      'platinum': rates['${base}XPT'] ?? rates['XPT'],
    };
  }
}
