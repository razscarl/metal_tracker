// lib/features/scrapers/models/scrape_result_models.dart:Scrape Result Models

/// Result from live price scraper
class LivePriceScrapeResult {
  final String retailerId;
  final Map<String, Map<String, double>> prices; // metalType -> {sell, buyback}
  final String scrapeStatus;
  final List<String> scrapeErrors;

  LivePriceScrapeResult({
    required this.retailerId,
    required this.prices,
    required this.scrapeStatus,
    required this.scrapeErrors,
  });

  bool get hasErrors => scrapeErrors.isNotEmpty;
  bool get isSuccess => scrapeStatus == 'success';
  bool get isPartial => scrapeStatus == 'partial';
  bool get isFailed => scrapeStatus == 'failed';
}

/// Single product from product listing scraper
class ScrapedProduct {
  final String listingName;
  final double listingSellPrice;

  ScrapedProduct({
    required this.listingName,
    required this.listingSellPrice,
  });
}

/// Result from product listing scraper
class ProductListingScrapeResult {
  final String retailerId;
  final List<ScrapedProduct> products;
  final String scrapeStatus;
  final List<String> scrapeErrors;

  ProductListingScrapeResult({
    required this.retailerId,
    required this.products,
    required this.scrapeStatus,
    required this.scrapeErrors,
  });

  bool get hasErrors => scrapeErrors.isNotEmpty;
  bool get isSuccess => scrapeStatus == 'success';
  bool get isPartial => scrapeStatus == 'partial';
  bool get isFailed => scrapeStatus == 'failed';
}

/// Result from local spot scraper
class LocalSpotScrapeResult {
  final String retailerId;
  final Map<String, double> spotPrices; // metalType -> localSpotPrice
  final String scrapeStatus;
  final List<String> scrapeErrors;

  LocalSpotScrapeResult({
    required this.retailerId,
    required this.spotPrices,
    required this.scrapeStatus,
    required this.scrapeErrors,
  });

  bool get hasErrors => scrapeErrors.isNotEmpty;
  bool get isSuccess => scrapeStatus == 'success';
  bool get isPartial => scrapeStatus == 'partial';
  bool get isFailed => scrapeStatus == 'failed';
}
