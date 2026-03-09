// lib/core/data/services/base_scraper_service.dart
import 'package:http/http.dart' as http;

/// Base class for all scraper services
abstract class BaseScraperService {
  /// Retailer name for this scraper
  String get retailerName;

  /// URL to scrape
  String get url;

  /// HTTP headers for requests
  Map<String, String> get headers => {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      };

  /// Fetch HTML from URL with error handling
  Future<String> fetchHtml(String targetUrl) async {
    try {
      final response = await http
          .get(Uri.parse(targetUrl), headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception(
            '$retailerName returned status ${response.statusCode} for $targetUrl');
      }
    } catch (e) {
      throw Exception('Failed to fetch $retailerName page: $e');
    }
  }

  /// Fetch HTML via POST request (for AJAX endpoints)
  Future<String> fetchHtmlPost(
      String targetUrl, Map<String, String> payload) async {
    try {
      final response = await http
          .post(
            Uri.parse(targetUrl),
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
            '$retailerName returned status ${response.statusCode} for $targetUrl');
      }
    } catch (e) {
      throw Exception('Failed to POST to $retailerName: $e');
    }
  }

  /// Helper to safely parse double from text
  double parsePrice(String text) {
    try {
      final cleaned = text.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  /// Helper to normalize weight to troy ounces
  double normalizeToOunces(double value, String unit) {
    switch (unit.toLowerCase()) {
      case 'kg':
      case 'kilogram':
        return value / 32.1507;
      case 'g':
      case 'gram':
        return value * 0.0321507466;
      case 'oz':
      case 'ounce':
      default:
        return value;
    }
  }
}
