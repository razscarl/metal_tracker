// lib/features/scrapers/models/local_spot_price_model.dart:Local Spot Price Model
class LocalSpotPrice {
  final String id;
  final String retailerId;
  final String metalType;
  final double localSpotPrice;
  final DateTime scrapeDate;
  final DateTime scrapeTimestamp;
  final String scrapeStatus;
  final String? scrapeError;

  LocalSpotPrice({
    required this.id,
    required this.retailerId,
    required this.metalType,
    required this.localSpotPrice,
    required this.scrapeDate,
    required this.scrapeTimestamp,
    required this.scrapeStatus,
    this.scrapeError,
  });

  factory LocalSpotPrice.fromJson(Map<String, dynamic> json) {
    return LocalSpotPrice(
      id: json['id'] as String,
      retailerId: json['retailer_id'] as String,
      metalType: json['metal_type'] as String,
      localSpotPrice: (json['local_spot_price'] as num).toDouble(),
      scrapeDate: DateTime.parse(json['scrape_date'] as String),
      scrapeTimestamp: DateTime.parse(json['scrape_timestamp'] as String),
      scrapeStatus: json['scrape_status'] as String,
      scrapeError: json['scrape_error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'retailer_id': retailerId,
      'metal_type': metalType,
      'local_spot_price': localSpotPrice,
      'scrape_date': scrapeDate.toIso8601String().split('T')[0],
      'scrape_timestamp': scrapeTimestamp.toIso8601String(),
      'scrape_status': scrapeStatus,
      'scrape_error': scrapeError,
    };
  }
}
