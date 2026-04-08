// lib/features/scrapers/data/services/gba_live_price_service.dart:GBA Live Price Scraper Service
import 'package:html/parser.dart' show parse;
import 'package:metal_tracker/core/data/services/base_scraper_service.dart';
import 'package:metal_tracker/features/live_prices/data/models/live_price_scrape_result.dart';
import '../../../retailers/data/models/retailer_scraper_setting_model.dart';

class GbaLivePriceService extends BaseScraperService {
  @override
  String get retailerName => 'Gold Bullion Australia';

  @override
  String get url =>
      'https://www.goldbullionaustralia.com.au/live-charts-prices/';

  Future<LivePriceScrapeResult> scrape(
    String retailerId,
    List<RetailerScraperSetting> settings,
  ) async {
    final errors = <String>[];
    final prices = <String, Map<String, double>>{};

    try {
      final html = await fetchHtml(url);
      final document = parse(html);

      for (final setting in settings) {
        if (!setting.isActive || setting.metalType == null) continue;

        final metalType = setting.metalType!;
        final searchString = setting.searchString;

        try {
          final metalPrices = _extractFromTable(document, searchString);

          if (metalPrices['sell']! > 0 && metalPrices['buyback']! > 0) {
            prices[metalType] = metalPrices;
          } else {
            errors.add('$metalType: Prices are zero');
          }
        } catch (e) {
          errors.add('$metalType: Failed - $e');
        }
      }

      String scrapeStatus;
      if (prices.isEmpty) {
        scrapeStatus = 'failed';
      } else if (errors.isNotEmpty) {
        scrapeStatus = 'partial';
      } else {
        scrapeStatus = 'success';
      }

      return LivePriceScrapeResult(
        retailerId: retailerId,
        prices: prices,
        scrapeStatus: scrapeStatus,
        scrapeErrors: errors,
      );
    } catch (e) {
      return LivePriceScrapeResult(
        retailerId: retailerId,
        prices: {},
        scrapeStatus: 'failed',
        scrapeErrors: ['Fatal error: $e'],
      );
    }
  }

  Map<String, double> _extractFromTable(dynamic document, String searchString) {
    final rows = document.querySelectorAll('tr');

    for (var row in rows) {
      final text = row.text.toLowerCase();

      if (text.contains(searchString.toLowerCase())) {
        final cells = row.querySelectorAll('td');

        if (cells.length >= 3) {
          double sell = parsePrice(cells[1].text);
          double buy = parsePrice(cells[2].text);

          if (sell > 0 && buy > 0) {
            return {'sell': sell, 'buyback': buy};
          }
        }

        throw Exception('Row found but invalid prices');
      }
    }

    throw Exception('Not found: "$searchString"');
  }
}
