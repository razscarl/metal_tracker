class AutomationSchedule {
  final String id;
  final String scrapeType;
  final List<String> runTimes;
  final bool enabled;

  const AutomationSchedule({
    required this.id,
    required this.scrapeType,
    required this.runTimes,
    required this.enabled,
  });

  factory AutomationSchedule.fromJson(Map<String, dynamic> json) {
    return AutomationSchedule(
      id: json['id'] as String,
      scrapeType: json['scrape_type'] as String,
      runTimes: List<String>.from(json['run_times'] as List? ?? []),
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'scrape_type': scrapeType,
        'run_times': runTimes,
        'enabled': enabled,
      };

  AutomationSchedule copyWith({List<String>? runTimes, bool? enabled}) {
    return AutomationSchedule(
      id: id,
      scrapeType: scrapeType,
      runTimes: runTimes ?? this.runTimes,
      enabled: enabled ?? this.enabled,
    );
  }

  String get displayName => switch (scrapeType) {
        'live_prices' => 'Live Prices',
        'local_spot' => 'Local Spot',
        'global_spot' => 'Global Spot',
        'product_listings' => 'Product Listings',
        _ => scrapeType,
      };
}

// Strongly-typed scrape type constants
abstract class ScrapeType {
  static const livePrices = 'live_prices';
  static const localSpot = 'local_spot';
  static const globalSpot = 'global_spot';
  static const productListings = 'product_listings';

  static String displayName(String type) => switch (type) {
        livePrices => 'Live Prices',
        localSpot => 'Local Spot',
        globalSpot => 'Global Spot',
        productListings => 'Product Listings',
        _ => type,
      };
}
