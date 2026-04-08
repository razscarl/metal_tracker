// lib/features/product_listings/data/models/product_listing_scrape_result.dart

/// A single product scraped from a retailer's listing page.
class ScrapedListing {
  final String listingName;
  final double sellPrice;
  final String? metalType; // 'gold' | 'silver' | 'platinum' — null if unknown

  /// Raw status string captured from the page (e.g. 'out of stock', 'in store only').
  /// null means nothing was found — assumed available.
  final String? capturedStatus;

  const ScrapedListing({
    required this.listingName,
    required this.sellPrice,
    this.metalType,
    this.capturedStatus,
  });
}

/// Result from a product listing scrape for one retailer.
class ProductListingScrapeResult {
  final String retailerId;
  final List<ScrapedListing> listings;

  /// 'success' | 'partial' | 'failed'
  final String status;
  final List<String> errors;

  const ProductListingScrapeResult({
    required this.retailerId,
    required this.listings,
    required this.status,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccess => status == 'success';
  bool get isPartial => status == 'partial';
  bool get isFailed => status == 'failed';
}
