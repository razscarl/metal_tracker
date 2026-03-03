// lib/core/constants/scraper_constants.dart:Scraper Constants

/// Scraper type identifiers
class ScraperType {
  static const String livePrice = 'live_price';
  static const String productListing = 'product_listing';
  static const String localSpot = 'local_spot';
}

/// Scraper names for UI display
class ScraperNames {
  static const String gbaLivePrice = 'GBA Live Price';
  static const String gbaProductListing = 'GBA Product Listing';
  static const String gbaLocalSpot = 'GBA Local Spot';
}

/// Scrape status values
class ScrapeStatus {
  static const String success = 'success';
  static const String partial = 'partial';
  static const String failed = 'failed';
}
