// lib/features/product_listings/data/services/gba_product_listing_service.dart
import 'package:flutter/foundation.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;
import 'package:metal_tracker/core/data/services/base_scraper_service.dart';
import 'package:metal_tracker/features/product_listings/data/models/product_listing_scrape_result.dart';
import 'package:metal_tracker/features/retailers/data/models/retailer_scraper_setting_model.dart';

/// Scrapes product listings from Gold Bullion Australia's category pages.
///
/// GBA uses WooCommerce with Elementor layout. Products are paginated via
/// `/buy/gold/paged/2/` etc.
///
/// Each [settings] entry with a non-null metalType and a searchUrl is scraped
/// independently — e.g. one setting per gold/silver/platinum category URL.
class GbaProductListingService extends BaseScraperService {
  @override
  String get retailerName => 'Gold Bullion Australia';

  @override
  String get url => 'https://www.goldbullionaustralia.com.au/buy/';

  Future<ProductListingScrapeResult> scrape(
      String retailerId, List<RetailerScraperSetting> settings) async {
    final listings = <ScrapedListing>[];
    final errors = <String>[];

    for (final setting in settings) {
      final metalType = setting.metalType;
      if (metalType == null) continue;

      final startUrl = setting.searchUrl;
      if (startUrl == null || startUrl.isEmpty) {
        errors.add('$metalType: no URL configured for this setting');
        continue;
      }

      try {
        String? currentUrl = startUrl;
        int pageNum = 1;
        final metalListings = <ScrapedListing>[];

        while (currentUrl != null) {
          debugPrint(
              '🔵 GBA Listings: Fetching $metalType page $pageNum: $currentUrl');
          final html = await fetchHtml(currentUrl);
          final doc = parse(html);

          final pageListings = _extractListings(doc, metalType);
          metalListings.addAll(pageListings);
          debugPrint(
              '🔵 GBA Listings: Page $pageNum: ${pageListings.length} listings');

          final nextLink = doc.querySelector('a[rel="next"]');
          currentUrl = nextLink?.attributes['href'];
          pageNum++;
          if (pageNum > 50) break;
        }

        listings.addAll(metalListings);
        debugPrint(
            '🔵 GBA Listings: Total for $metalType: ${metalListings.length}');
      } catch (e) {
        errors.add('$metalType: $e');
        debugPrint('🔴 GBA Listings: Error for $metalType: $e');
      }
    } // end settings loop

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

  List<ScrapedListing> _extractListings(dynamic doc, String metalType) {
    final result = <ScrapedListing>[];

    final cards = doc.querySelectorAll('article.card');
    debugPrint('🔵 GBA: article.card count: ${cards.length}');

    if (cards.isEmpty) return result;

    for (final card in cards) {
      // Name: try heading with link first, then any heading text
      String name = card.querySelector('h2 a, h3 a, h4 a')?.text.trim() ?? '';
      if (name.isEmpty) {
        name = card.querySelector('h2, h3, h4')?.text.trim() ?? '';
      }
      if (name.isEmpty) continue;

      // Price: try bdi (WooCommerce), then spans containing '$'
      double price = 0;
      final bdi = card.querySelector('bdi');
      if (bdi != null) price = parsePrice(bdi.text);
      if (price <= 0) {
        for (final span in card.querySelectorAll('span')) {
          final t = span.text.trim();
          if (t.startsWith(r'$') && t.length > 1) {
            price = parsePrice(t);
            if (price > 0) break;
          }
        }
      }
      if (price <= 0) continue;

      result.add(ScrapedListing(
        listingName: name,
        sellPrice: price,
        metalType: metalType,
        capturedStatus: _captureStatus(card),
      ));
    }
    return result;
  }

  String? _captureStatus(Element card) {
    final classes = card.attributes['class'] ?? '';
    if (classes.contains('outofstock')) return 'outofstock';
    return null;
  }
}
