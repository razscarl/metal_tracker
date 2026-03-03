// lib/features/scrapers/data/services/imp_live_price_service.dart:Imperial Bullion Live Price Scraper Service
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'base_scraper_service.dart';
import '../../../scrapers/data/models/scrape_result_models.dart';
import '../../../retailers/data/models/retailer_scraper_setting_model.dart';

class ImpLivePriceService extends BaseScraperService {
  @override
  String get retailerName => 'Imperial Bullion';

  @override
  String get url => 'https://pricing.imperialbullion.com.au/pricing-feed.json';

  /// Override headers for Imperial Bullion API
  @override
  Map<String, String> get headers => {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'application/json',
        'Origin': 'https://imperialbullion.com.au',
      };

  Future<LivePriceScrapeResult> scrape(
    String retailerId,
    List<RetailerScraperSetting> settings,
  ) async {
    final errors = <String>[];
    final prices = <String, Map<String, double>>{};

    print('🟣 IMP: Starting scrape with ${settings.length} settings');

    try {
      // Get API endpoint from first setting's search_url (they should all be the same)
      final apiEndpoint = settings.first.searchUrl ?? url;

      // Fetch JSON from API
      print('🟣 IMP: Fetching data from API: $apiEndpoint');

      final response = await http
          .get(Uri.parse(apiEndpoint), headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Imperial API returned status: ${response.statusCode}');
      }

      print('🟣 IMP: API response received (${response.body.length} chars)');

      // Parse JSON - data is at root level, no 'feed' wrapper
      final Map<String, dynamic> data = jsonDecode(response.body);

      print('🟣 IMP: JSON parsed, ${data.keys.length} product keys found');

      // Process each setting
      for (final setting in settings) {
        print(
            '🟣 IMP: Processing setting - Metal: ${setting.metalType}, Active: ${setting.isActive}');

        if (!setting.isActive || setting.metalType == null) {
          print('🟠 IMP: Skipping inactive or null metal type');
          continue;
        }

        final metalType = setting.metalType!;
        final apiKey = setting.searchString; // e.g., "IBAU1oz"

        print('🟣 IMP: Looking for API key: "$apiKey"');

        try {
          if (!data.containsKey(apiKey)) {
            throw Exception('API key "$apiKey" not found in response');
          }

          final metalData = data[apiKey] as Map<String, dynamic>;
          print('🟣 IMP: Found data for $apiKey: $metalData');

          final metalPrices = _extractMetalData(metalData);
          print(
              '🟣 IMP: Extracted prices - Sell: ${metalPrices['sell']}, Buy: ${metalPrices['buyback']}');

          if (metalPrices['sell']! > 0 && metalPrices['buyback']! > 0) {
            prices[metalType] = metalPrices;
            print('✅ IMP: $metalType prices added successfully');
          } else {
            errors.add('$metalType: Prices are zero');
            print('🔴 IMP: $metalType prices are zero');
          }
        } catch (e) {
          errors.add('$metalType: Failed - $e');
          print('🔴 IMP: $metalType exception: $e');
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
          '🟣 IMP: Final status: $scrapeStatus, Prices: ${prices.length}, Errors: ${errors.length}');
      if (errors.isNotEmpty) {
        print('🔴 IMP: Error details: ${errors.join(", ")}');
      }

      return LivePriceScrapeResult(
        retailerId: retailerId,
        prices: prices,
        scrapeStatus: scrapeStatus,
        scrapeErrors: errors,
      );
    } catch (e) {
      print('🔴 IMP: Fatal error in scrape: $e');
      return LivePriceScrapeResult(
        retailerId: retailerId,
        prices: {},
        scrapeStatus: 'failed',
        scrapeErrors: ['Fatal error: $e'],
      );
    }
  }

  Map<String, double> _extractMetalData(Map<String, dynamic> metalObj) {
    try {
      return {
        'sell': (metalObj['SellPrice'] as num).toDouble(),
        'buyback': (metalObj['BuyPrice'] as num).toDouble(),
      };
    } catch (e) {
      print('🔴 IMP: Error extracting metal data: $e');
      return {'sell': 0.0, 'buyback': 0.0};
    }
  }
}
