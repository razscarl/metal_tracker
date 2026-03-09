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
  /// Finds the #price div, splits by line, locates the line containing
  /// setting.searchString, and extracts the price via regex.
  Future<Map<String, double>> scrape(
      List<RetailerScraperSetting> settings) async {
    // Group by URL so we only fetch each page once
    final byUrl = <String, List<RetailerScraperSetting>>{};
    for (final s in settings) {
      final fetchUrl = s.searchUrl ?? url;
      byUrl.putIfAbsent(fetchUrl, () => []).add(s);
    }

    final priceRegex = RegExp(r'\$(\d+(?:\.\d+)?)');
    final result = <String, double>{};

    for (final entry in byUrl.entries) {
      debugPrint('🟡 IMP Local Spot: fetching ${entry.key}');
      final html = await fetchHtml(entry.key);
      debugPrint('🟡 IMP Local Spot: received ${html.length} chars');
      final doc = parse(html);
      final priceDiv = doc.querySelector('#price');
      if (priceDiv == null) {
        debugPrint('🟡 IMP Local Spot: #price div not found on page');
        continue;
      }

      final lines = priceDiv.text.split('\n');
      debugPrint('🟡 IMP Local Spot: #price div has ${lines.length} lines');

      for (final s in entry.value) {
        if (s.metalType == null) continue;
        final line = lines.firstWhere(
          (l) => l.contains(s.searchString),
          orElse: () => '',
        );
        if (line.isEmpty) {
          debugPrint('🟡 IMP Local Spot: no line containing "${s.searchString}" found');
          continue;
        }
        final match = priceRegex.firstMatch(line);
        if (match == null) {
          debugPrint('🟡 IMP Local Spot: line found but no price pattern: "$line"');
          continue;
        }
        final price = double.tryParse(match.group(1)!);
        debugPrint('🟡 IMP Local Spot: ${s.metalType} → "$line" → $price');
        if (price != null && price > 0) result[s.metalType!] = price;
      }
    }
    return result;
  }
}
