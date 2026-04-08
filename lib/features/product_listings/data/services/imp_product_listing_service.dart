// lib/features/product_listings/data/services/imp_product_listing_service.dart
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:metal_tracker/core/data/services/base_scraper_service.dart';
import 'package:metal_tracker/features/product_listings/data/models/product_listing_scrape_result.dart';
import 'package:metal_tracker/features/retailers/data/models/retailer_scraper_setting_model.dart';

/// Scrapes product listings from Imperial Bullion's shop page.
///
/// IMP uses WP Grid Builder (WPGB). Page 1 is fetched as static HTML.
/// Pages 2+ are fetched via the WPGB REST API:
///   GET /wp-json/wpgb/v2/filter/?action=action&paged=N
/// which returns JSON with an `html` field containing rendered card HTML.
///
/// - Name:      first `<a>` inside any `<h3>` in the card
/// - Price:     `div.wpgb-block-5` text, e.g. `$7,195.25`
/// - MetalType: inferred from the product URL slug
class ImpProductListingService extends BaseScraperService {
  @override
  String get retailerName => 'Imperial Bullion';

  @override
  String get url => 'https://imperialbullion.com.au/shop/';

  Future<ProductListingScrapeResult> scrape(
      String retailerId, List<RetailerScraperSetting> settings) async {
    final errors = <String>[];

    final allMetalSetting =
        settings.where((s) => s.metalType == null).firstOrNull;
    if (allMetalSetting == null) {
      return ProductListingScrapeResult(
        retailerId: retailerId,
        listings: [],
        status: 'failed',
        errors: [
          'No "all metals" setting found. Add a product_listing setting with Metal Type = None.'
        ],
      );
    }
    final shopUrl = allMetalSetting.searchUrl ?? '';
    if (shopUrl.isEmpty) {
      return ProductListingScrapeResult(
        retailerId: retailerId,
        listings: [],
        status: 'failed',
        errors: ['Product listing setting has no URL configured.'],
      );
    }

    final allRaw = <_RawListing>[];

    try {
      final base = shopUrl.endsWith('/') ? shopUrl : '$shopUrl/';
      final seenNames = <String>{};
      String? wpgbRestUrl;

      // ── Page 1: static HTML ────────────────────────────────────────────────
      debugPrint('🟣 IMP Listings: Fetching page 1 (static HTML)');
      final page1Html = await fetchHtml(base);
      final page1Doc = parse(page1Html);

      // Extract WPGB REST URL and total pages from embedded JS config
      for (final script in page1Doc.querySelectorAll('script')) {
        final src = script.text;
        if (!src.contains('wpgb_settings')) continue;
        final restMatch =
            RegExp(r'"restUrl"\s*:\s*"([^"]+)"').firstMatch(src);
        if (restMatch != null) {
          wpgbRestUrl = restMatch.group(1)?.replaceAll(r'\/', '/');
        }
        // max_num_pages may not be in the initial config — will read from API response
      }
      debugPrint('🟣 IMP Listings: WPGB restUrl=$wpgbRestUrl');

      _extractCards(page1Doc.querySelectorAll('article.wpgb-card'),
          seenNames, allRaw);
      debugPrint('🟣 IMP Listings: Page 1: ${allRaw.length} listings');

      // ── Pages 2+: WooCommerce Store API (public, no auth) ─────────────────
      // IMP's WPGB AJAX/REST requires session state; WC Store API is simpler.
      final baseHost = Uri.parse(base).origin;
      final wcStoreBase = '$baseHost/wp-json/wc/store/v1/products';
      debugPrint('🟣 IMP Listings: Trying WC Store API: $wcStoreBase');

      int wcPage = 1;
      bool wcWorked = false;
      final wcRaw = <_RawListing>[];
      final wcSeen = <String>{};

      while (true) {
        try {
          final uri = Uri.parse('$wcStoreBase?per_page=100&page=$wcPage&status=publish');
          final response = await http
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 30));

          debugPrint('🟣 IMP Listings: WC Store API page $wcPage: status=${response.statusCode}');
          if (response.statusCode != 200) break;

          final items = jsonDecode(response.body);
          if (items is! List || items.isEmpty) break;
          wcWorked = true;

          for (final item in items) {
            final rawName = item['name'] as String? ?? '';
            final name = _decodeHtmlEntities(rawName);
            if (name.isEmpty || !wcSeen.add(name)) continue;

            // WC Store API prices are in smallest currency unit (cents)
            final priceStr = item['prices']?['price'] as String? ?? '0';
            final decimals =
                (item['prices']?['currency_minor_unit'] as num?)?.toInt() ?? 2;
            final price = (int.tryParse(priceStr) ?? 0) / _pow10(decimals);
            if (price <= 0) continue;

            final permalink = item['permalink'] as String? ?? '';
            final metalType = _metalFromUrl(permalink);
            if (metalType == null) {
              debugPrint('🟣 IMP Listings: "$name" — metal unknown, saving anyway');
            }
            wcRaw.add(_RawListing(name: name, price: price, metalType: metalType));
          }

          debugPrint('🟣 IMP Listings: WC Store API page $wcPage: ${items.length} products');
          if (items.length < 100) break; // last page
          wcPage++;
        } catch (e) {
          debugPrint('🟣 IMP Listings: WC Store API error: $e');
          break;
        }
      }

      if (wcWorked) {
        // Replace page-1 HTML results with the complete WC Store API results
        allRaw.clear();
        allRaw.addAll(wcRaw);
        debugPrint('🟣 IMP Listings: Using WC Store API — ${allRaw.length} total products');
      } else {
        debugPrint('🟣 IMP Listings: WC Store API unavailable — using ${allRaw.length} from static HTML');
      }

      debugPrint('🟣 IMP Listings: Total extracted: ${allRaw.length}');
      for (final metal in ['gold', 'silver', 'platinum']) {
        final count = allRaw.where((r) => r.metalType == metal).length;
        debugPrint('🟣 IMP Listings: $metal: $count listings');
      }
    } catch (e) {
      debugPrint('🔴 IMP Listings: Fatal error: $e');
      return ProductListingScrapeResult(
        retailerId: retailerId,
        listings: [],
        status: 'failed',
        errors: [e.toString()],
      );
    }

    final listings = allRaw
        .map((r) => ScrapedListing(
              listingName: r.name,
              sellPrice: r.price,
              metalType: r.metalType,
              capturedStatus: null,
            ))
        .toList();

    return ProductListingScrapeResult(
      retailerId: retailerId,
      listings: listings,
      status: listings.isEmpty ? 'failed' : 'success',
      errors: errors,
    );
  }

  void _extractCards(dynamic cards, Set<String> seenNames,
      List<_RawListing> allRaw) {
    for (final card in cards) {
      final nameAnchor = card.querySelector('h3 a');
      final name = nameAnchor?.text.trim() ?? '';
      if (name.isEmpty) continue;
      if (!seenNames.add(name)) continue;

      final priceEl = card.querySelector('div.wpgb-block-5');
      final price = priceEl != null ? parsePrice(priceEl.text) : 0.0;
      if (price <= 0) continue;

      final href = nameAnchor?.attributes['href'] ?? '';
      final metalType = _metalFromUrl(href);
      if (metalType == null) {
        debugPrint('🟣 IMP Listings: "$name" — metal unknown from URL, saving anyway');
      }

      allRaw.add(_RawListing(name: name, price: price, metalType: metalType));
    }
  }

  String? _metalFromUrl(String href) {
    final lower = href.toLowerCase();
    if (lower.contains('platinum')) return 'platinum';
    if (lower.contains('silver')) return 'silver';
    if (lower.contains('gold')) return 'gold';
    return null;
  }
}

double _pow10(int n) => math.pow(10, n).toDouble();

String _decodeHtmlEntities(String s) => s
    .replaceAll('&#8211;', '–')
    .replaceAll('&#8212;', '—')
    .replaceAll('&#8216;', '\u2018')
    .replaceAll('&#8217;', '\u2019')
    .replaceAll('&#8220;', '\u201C')
    .replaceAll('&#8221;', '\u201D')
    .replaceAll('&amp;', '&')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#039;', "'")
    .replaceAll('&nbsp;', ' ');

class _RawListing {
  final String name;
  final double price;
  final String? metalType;

  const _RawListing({
    required this.name,
    required this.price,
    this.metalType,
  });
}
