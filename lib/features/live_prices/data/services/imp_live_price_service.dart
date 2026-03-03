// lib/features/scrapers/data/services/imp_live_price_service.dart:Imperial Bullion Live Price Scraper Service
import 'dart:convert';
import 'package:flutter/foundation.dart';
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

    debugPrint('🟣 IMP: Starting scrape with ${settings.length} settings');

    try {
      // Get API endpoint from first setting's search_url (they should all be the same)
      final apiEndpoint = settings.first.searchUrl ?? url;

      // Fetch JSON from API
      debugPrint('🟣 IMP: Fetching data from API: $apiEndpoint');

      final response = await http
          .get(Uri.parse(apiEndpoint), headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Imperial API returned status: ${response.statusCode}');
      }

      debugPrint('🟣 IMP: API response received (${response.body.length} chars)');

      // Parse JSON - data is at root level, no 'feed' wrapper
      final Map<String, dynamic> data = jsonDecode(response.body);

      debugPrint('🟣 IMP: JSON parsed, ${data.keys.length} product keys found');

      // Process each setting
      for (final setting in settings) {
        debugPrint(
            '🟣 IMP: Processing setting - Metal: ${setting.metalType}, Active: ${setting.isActive}');

        if (!setting.isActive || setting.metalType == null) {
          debugPrint('🟠 IMP: Skipping inactive or null metal type');
          continue;
        }

        final metalType = setting.metalType!;
        final apiKey = setting.searchString; // e.g., "IBAU1oz"

        debugPrint('🟣 IMP: Looking for API key: "$apiKey"');

        try {
          if (!data.containsKey(apiKey)) {
            throw Exception('API key "$apiKey" not found in response');
          }

          final metalData = data[apiKey] as Map<String, dynamic>;
          debugPrint('🟣 IMP: Found data for $apiKey: $metalData');

          final metalPrices = _extractMetalData(metalData);
          debugPrint(
              '🟣 IMP: Extracted prices - Sell: ${metalPrices['sell']}, Buy: ${metalPrices['buyback']}');

          if (metalPrices['sell']! > 0 && metalPrices['buyback']! > 0) {
            prices[metalType] = metalPrices;
            debugPrint('✅ IMP: $metalType prices added successfully');
          } else {
            errors.add('$metalType: Prices are zero');
            debugPrint('🔴 IMP: $metalType prices are zero');
          }
        } catch (e) {
          errors.add('$metalType: Failed - $e');
          debugPrint('🔴 IMP: $metalType exception: $e');
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

      debugPrint(
          '🟣 IMP: Final status: $scrapeStatus, Prices: ${prices.length}, Errors: ${errors.length}');
      if (errors.isNotEmpty) {
        debugPrint('🔴 IMP: Error details: ${errors.join(", ")}');
      }

      return LivePriceScrapeResult(
        retailerId: retailerId,
        prices: prices,
        scrapeStatus: scrapeStatus,
        scrapeErrors: errors,
      );
    } catch (e) {
      debugPrint('🔴 IMP: Fatal error in scrape: $e');
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
      debugPrint('🔴 IMP: Error extracting metal data: $e');
      return {'sell': 0.0, 'buyback': 0.0};
    }
  }
}
