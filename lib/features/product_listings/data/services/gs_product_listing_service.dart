// lib/features/product_listings/data/services/gs_product_listing_service.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:metal_tracker/core/data/services/base_scraper_service.dart';
import 'package:metal_tracker/features/product_listings/data/models/product_listing_scrape_result.dart';
import 'package:metal_tracker/features/retailers/data/models/retailer_scraper_setting_model.dart';

/// Scrapes product listings from Gold Secure via the public WooCommerce
/// Store API — no Cloudflare issues, clean JSON, all metals in one request.
class GsProductListingService extends BaseScraperService {
  static const _apiBase =
      'https://goldsecure.com.au/wp-json/wc/store/v1/products';
  static const _perPage = 100;

  @override
  String get retailerName => 'Gold Secure';

  @override
  String get url => 'https://goldsecure.com.au/';

  @override
  Map<String, String> get headers => {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36',
        'Accept': 'application/json, */*',
        'Accept-Language': 'en-AU,en;q=0.9',
        'X-Requested-With': 'XMLHttpRequest',
        'Referer': 'https://goldsecure.com.au/buy-gold/',
      };

  /// Fetches all products, handling pagination automatically.
  Future<List<dynamic>> _fetchAllProducts() async {
    final all = <dynamic>[];
    int page = 1;

    while (true) {
      final uri =
          Uri.parse('$_apiBase?per_page=$_perPage&page=$page');
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 30));

      debugPrint(
          '🟢 GS Listings: API page $page → ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception(
            'Gold Secure API returned status ${response.statusCode}');
      }

      final List<dynamic> page_products = json.decode(response.body);
      if (page_products.isEmpty) break;

      all.addAll(page_products);
      if (page_products.length < _perPage) break;
      page++;
    }

    return all;
  }

  Future<ProductListingScrapeResult> scrape(
      String retailerId, List<RetailerScraperSetting> settings) async {
    final listings = <ScrapedListing>[];
    final errors = <String>[];

    try {
      final products = await _fetchAllProducts();
      debugPrint('🟢 GS Listings: Total fetched: ${products.length}');

      for (final product in products) {
        final name = (product['name'] as String?)?.trim() ?? '';
        // Price is in cents as a string e.g. "20361" = $203.61
        final priceStr =
            (product['prices']?['price'] as String?) ?? '0';
        final price = (double.tryParse(priceStr) ?? 0) / 100;

        if (name.isEmpty || price <= 0) continue;

        final stockClass =
            product['stock_availability']?['class'] as String?;
        final isInStock = product['is_in_stock'] as bool? ?? false;
        final capturedStatus =
            stockClass ?? (isInStock ? 'in-stock' : 'out-of-stock');

        listings.add(ScrapedListing(
          listingName: name,
          sellPrice: price,
          metalType: _inferMetalType(name),
          capturedStatus: capturedStatus,
        ));
      }
      debugPrint('🟢 GS Listings: Added ${listings.length} listings');
    } catch (e) {
      errors.add('$e');
      debugPrint('🔴 GS Listings: Error: $e');
    }

    return ProductListingScrapeResult(
      retailerId: retailerId,
      listings: listings,
      status: listings.isEmpty
          ? 'failed'
          : errors.isNotEmpty
              ? 'partial'
              : 'success',
      errors: errors,
    );
  }

  String? _inferMetalType(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('gold')) return 'gold';
    if (lower.contains('silver')) return 'silver';
    if (lower.contains('platinum')) return 'platinum';
    return null;
  }
}
