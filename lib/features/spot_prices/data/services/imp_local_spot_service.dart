// lib/features/spot_prices/data/services/imp_local_spot_service.dart
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' show parse;
import 'package:metal_tracker/core/data/services/base_scraper_service.dart';
import 'package:metal_tracker/features/retailers/data/models/retailer_scraper_setting_model.dart';

class ImpLocalSpotService extends BaseScraperService {
  @override
  String get retailerName => 'Imperial Bullion';

  @override
  String get url => 'https://www.imperialbullion.com.au';

  /// Returns {metalType: price} for each active setting.
  /// Uses setting.searchUrl if set, otherwise falls back to [url].
  /// setting.searchString is a CSS class word (e.g. "brxe-jrlurv") that
  /// uniquely identifies the price element in the Bricks Builder markup.
  Future<Map<String, double>> scrape(
      List<RetailerScraperSetting> settings) async {
    // Group by URL so we only fetch each page once
    final byUrl = <String, List<RetailerScraperSetting>>{};
    for (final s in settings) {
      final fetchUrl = s.searchUrl ?? url;
      byUrl.putIfAbsent(fetchUrl, () => []).add(s);
    }

    final result = <String, double>{};

    for (final entry in byUrl.entries) {
      debugPrint('🟡 IMP Local Spot: fetching ${entry.key}');
      final html = await fetchHtml(entry.key);
      debugPrint('🟡 IMP Local Spot: received ${html.length} chars');
      final doc = parse(html);

      for (final s in entry.value) {
        if (s.metalType == null) continue;
        // Use [class~="word"] to match a single class word within the class list
        final el = doc.querySelector('[class~="${s.searchString}"]');
        if (el == null) {
          debugPrint('🟡 IMP Local Spot: no element with class "${s.searchString}"');
          continue;
        }
        final price = parsePrice(el.text);
        debugPrint('🟡 IMP Local Spot: ${s.metalType} → "${el.text.trim()}" → $price');
        if (price > 0) result[s.metalType!] = price;
      }
    }
    return result;
  }
}
