// lib/features/spot_prices/data/services/gs_local_spot_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:metal_tracker/core/data/services/base_scraper_service.dart';
import 'package:metal_tracker/features/retailers/data/models/retailer_scraper_setting_model.dart';

class GsLocalSpotService extends BaseScraperService {
  static const String _ajaxUrl =
      'https://goldsecure.com.au/wp-admin/admin-ajax.php';

  @override
  String get retailerName => 'Gold Secure';

  @override
  String get url => _ajaxUrl;

  @override
  Map<String, String> get headers => {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36',
        'X-Requested-With': 'XMLHttpRequest',
        'Origin': 'https://goldsecure.com.au',
        'Referer': 'https://goldsecure.com.au/live-price/',
        'Accept': 'application/json, text/javascript, */*; q=0.01',
        'Accept-Language': 'en-US,en;q=0.9',
      };

  /// Returns {metalType: price} for each active setting.
  /// Uses the GS update_prices AJAX action which returns all metals in one call.
  /// setting.searchUrl overrides the default AJAX URL.
  /// setting.searchString is used as the JSON key (e.g. "gold", "silver", "platinum").
  Future<Map<String, double>> scrape(
      List<RetailerScraperSetting> settings) async {
    // GS always uses the same AJAX endpoint regardless of searchUrl in settings.
    debugPrint('🟢 GS Local Spot: POSTing to $_ajaxUrl');

    final body = await fetchHtmlPost(_ajaxUrl, {
      'action': 'update_prices',
      'currency_name': 'aud',
    });

    debugPrint('🟢 GS Local Spot: response ${body.length} chars');
    debugPrint('🟢 GS Local Spot: body preview: ${body.substring(0, body.length.clamp(0, 300))}');

    final json = jsonDecode(body) as Map<String, dynamic>;
    if (json['success'] != true) {
      throw Exception('GS update_prices returned success=false: $body');
    }

    final data = json['data'] as Map<String, dynamic>;
    debugPrint('🟢 GS Local Spot: data keys = ${data.keys.toList()}');

    final result = <String, double>{};
    for (final s in settings) {
      if (s.metalType == null) continue;
      // searchString is the JSON key (e.g. "gold"); fall back to metalType.
      final key = s.searchString.isNotEmpty
          ? s.searchString.toLowerCase()
          : s.metalType!.toLowerCase();
      final raw = data[key]?.toString();
      if (raw == null) {
        debugPrint('🟢 GS Local Spot: no key "$key" in response data');
        continue;
      }
      final price = double.tryParse(raw.replaceAll(',', ''));
      debugPrint('🟢 GS Local Spot: ${s.metalType} key="$key" → "$raw" → $price');
      if (price != null && price > 0) result[s.metalType!] = price;
    }
    return result;
  }
}
