// lib/features/spot_prices/data/services/gba_local_spot_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' show parse;
import 'package:metal_tracker/core/data/services/base_scraper_service.dart';
import 'package:metal_tracker/features/retailers/data/models/retailer_scraper_setting_model.dart';

class GbaLocalSpotService extends BaseScraperService {
  static const String _ajaxUrl =
      'https://www.goldbullionaustralia.com.au/wp-admin/admin-ajax.php'
      '?action=get_live_price_update';
  static const String _baseUrl = 'https://www.goldbullionaustralia.com.au';

  @override
  String get retailerName => 'Gold Bullion Australia';

  @override
  String get url => _baseUrl;

  /// Returns {metalType: price} for each active setting.
  /// Gold + Silver come from the AJAX JSON endpoint.
  /// Platinum comes from static HTML (CSS class selector).
  Future<Map<String, double>> scrape(
      List<RetailerScraperSetting> settings) async {
    final result = <String, double>{};

    final goldSetting =
        settings.where((s) => s.metalType == 'gold').firstOrNull;
    final silverSetting =
        settings.where((s) => s.metalType == 'silver').firstOrNull;
    final platSetting =
        settings.where((s) => s.metalType == 'platinum').firstOrNull;

    // ── Gold + Silver via AJAX ──────────────────────────────────────────────
    if (goldSetting != null || silverSetting != null) {
      debugPrint('🟡 GBA Local Spot: GET $_ajaxUrl');
      try {
        final body = await fetchHtml(_ajaxUrl);
        debugPrint('🟡 GBA Local Spot: AJAX response: $body');
        final json = jsonDecode(body) as Map<String, dynamic>;

        if (goldSetting != null) {
          final raw = json['gold']?.toString();
          debugPrint('🟡 GBA Local Spot: gold raw = "$raw"');
          if (raw != null) {
            final price = double.tryParse(raw.replaceAll(',', ''));
            if (price != null && price > 0) result['gold'] = price;
          }
        }
        if (silverSetting != null) {
          final raw = json['silver']?.toString();
          debugPrint('🟡 GBA Local Spot: silver raw = "$raw"');
          if (raw != null) {
            final price = double.tryParse(raw.replaceAll(',', ''));
            if (price != null && price > 0) result['silver'] = price;
          }
        }
      } catch (e) {
        debugPrint('🟡 GBA Local Spot: AJAX error: $e');
        rethrow;
      }
    }

    // ── Platinum via HTML ───────────────────────────────────────────────────
    if (platSetting != null) {
      final fetchUrl = platSetting.searchUrl ?? _baseUrl;
      debugPrint('🟡 GBA Local Spot: fetching HTML for platinum: $fetchUrl');
      try {
        final html = await fetchHtml(fetchUrl);
        final doc = parse(html);
        // searchString is the class word to match — e.g. "platinum"
        // matches <div class="price-status platinum">
        final el = doc.querySelector('[class~="${platSetting.searchString}"]');
        if (el == null) {
          debugPrint(
              '🟡 GBA Local Spot: no element with class containing "${platSetting.searchString}"');
        } else {
          final price = parsePrice(el.text);
          debugPrint(
              '🟡 GBA Local Spot: platinum → "${el.text.trim()}" → $price');
          if (price > 0) result['platinum'] = price;
        }
      } catch (e) {
        debugPrint('🟡 GBA Local Spot: HTML fetch error for platinum: $e');
        rethrow;
      }
    }

    return result;
  }
}
