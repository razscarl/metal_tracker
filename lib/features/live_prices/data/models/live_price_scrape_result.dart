// lib/features/live_prices/data/models/live_price_scrape_result.dart

/// Result from a live price scraper for one retailer.
class LivePriceScrapeResult {
  final String retailerId;
  final Map<String, Map<String, double>> prices; // metalType → {sell, buyback}
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
