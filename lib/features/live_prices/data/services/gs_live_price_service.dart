// lib/features/scrapers/data/services/gs_live_price_service.dart:Gold Secure Live Price Scraper Service
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'base_scraper_service.dart';
import '../../../scrapers/data/models/scrape_result_models.dart';
import '../../../retailers/data/models/retailer_scraper_setting_model.dart';

class GsLivePriceService extends BaseScraperService {
  static const String ajaxUrl =
      'https://goldsecure.com.au/wp-admin/admin-ajax.php';
  static const String ajaxAction = 'get_posts_ajax_live_price';

  @override
  String get retailerName => 'Gold Secure';

  @override
  String get url => ajaxUrl;

  /// Override headers for Gold Secure to include AJAX-specific headers
  @override
  Map<String, String> get headers => {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36',
        'X-Requested-With': 'XMLHttpRequest',
        'Referer': 'https://goldsecure.com.au/live-price/',
        'Accept': '*/*',
        'Accept-Language': 'en-US,en;q=0.9',
        'Cookie': 'PHPSESSID=03aab98d5f424688be08af1d3f9495d3',
      };

  /// Custom POST method for Gold Secure that uses GS-specific headers
  Future<String> _fetchGsAjax(Map<String, String> payload) async {
    try {
      final response = await http
          .post(
            Uri.parse(ajaxUrl),
            headers: {
              ...headers,
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: payload,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception(
            '$retailerName returned status ${response.statusCode} for $ajaxUrl');
      }
    } catch (e) {
      throw Exception('Failed to POST to $retailerName: $e');
    }
  }

  Future<LivePriceScrapeResult> scrape(
    String retailerId,
    List<RetailerScraperSetting> settings,
  ) async {
    final errors = <String>[];
    final prices = <String, Map<String, double>>{};

    print('🟢 GS: Starting scrape with ${settings.length} settings');

    try {
      for (final setting in settings) {
        print(
            '🟢 GS: Processing setting - Metal: ${setting.metalType}, Active: ${setting.isActive}');

        if (!setting.isActive || setting.metalType == null) {
          print('🟠 GS: Skipping inactive or null metal type');
          continue;
        }

        final metalType = setting.metalType!;
        final searchString = setting.searchString;
        print('🟢 GS: Searching for: "$searchString"');

        try {
          // Make AJAX POST request for this metal
          final payload = {
            'action': ajaxAction,
            'metal_tab': metalType.toLowerCase(),
            'brand_weight': 'weight',
            'end_tab': 'all',
          };

          print('🟢 GS: Making POST request with payload: $payload');
          final html = await _fetchGsAjax(payload);
          print('🟢 GS: Received HTML response (${html.length} chars)');

          final metalPrices = _extractFromTable(html, searchString);
          print(
              '🟢 GS: Extracted prices - Sell: ${metalPrices['sell']}, Buy: ${metalPrices['buyback']}');

          if (metalPrices['sell']! > 0 && metalPrices['buyback']! > 0) {
            prices[metalType] = metalPrices;
            print('✅ GS: $metalType prices added successfully');
          } else {
            errors.add('$metalType: Prices are zero');
            print('🔴 GS: $metalType prices are zero');
          }
        } catch (e) {
          errors.add('$metalType: Failed - $e');
          print('🔴 GS: $metalType exception: $e');
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

      print(
          '🟢 GS: Final status: $scrapeStatus, Prices: ${prices.length}, Errors: ${errors.length}');
      if (errors.isNotEmpty) {
        print('🔴 GS: Error details: ${errors.join(", ")}');
      }

      return LivePriceScrapeResult(
        retailerId: retailerId,
        prices: prices,
        scrapeStatus: scrapeStatus,
        scrapeErrors: errors,
      );
    } catch (e) {
      print('🔴 GS: Fatal error in scrape: $e');
      return LivePriceScrapeResult(
        retailerId: retailerId,
        prices: {},
        scrapeStatus: 'failed',
        scrapeErrors: ['Fatal error: $e'],
      );
    }
  }

  Map<String, double> _extractFromTable(String htmlBody, String searchString) {
    final document = parse(htmlBody);
    final rows = document.querySelectorAll('tr');

    print('🟢 GS: Parsing ${rows.length} table rows');

    for (var row in rows) {
      final cells = row.querySelectorAll('td');
      if (cells.length < 3) continue;

      final productName = cells[0].text.toLowerCase();
      print('🟢 GS: Checking row: "$productName"');

      if (productName.contains(searchString.toLowerCase())) {
        print('✅ GS: Match found!');
        final sell = parsePrice(cells[1].text);
        final buy = parsePrice(cells[2].text);

        if (sell > 0 && buy > 0) {
          return {'sell': sell, 'buyback': buy};
        }
      }
    }

    print('🔴 GS: No matching row found for "$searchString"');
    throw Exception('Not found: "$searchString"');
  }
}
