// lib/features/scrapers/models/global_spot_price_model.dart:Global Spot Price Model
class GlobalSpotPrice {
  final String id;
  final String metalType;
  final double globalSpotPrice;
  final String source;
  final DateTime fetchDate;
  final DateTime fetchTimestamp;
  final String fetchStatus;
  final String? fetchError;

  GlobalSpotPrice({
    required this.id,
    required this.metalType,
    required this.globalSpotPrice,
    required this.source,
    required this.fetchDate,
    required this.fetchTimestamp,
    required this.fetchStatus,
    this.fetchError,
  });

  factory GlobalSpotPrice.fromJson(Map<String, dynamic> json) {
    return GlobalSpotPrice(
      id: json['id'] as String,
      metalType: json['metal_type'] as String,
      globalSpotPrice: (json['global_spot_price'] as num).toDouble(),
      source: json['source'] as String,
      fetchDate: DateTime.parse(json['fetch_date'] as String),
      fetchTimestamp: DateTime.parse(json['fetch_timestamp'] as String),
      fetchStatus: json['fetch_status'] as String,
      fetchError: json['fetch_error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'metal_type': metalType,
      'global_spot_price': globalSpotPrice,
      'source': source,
      'fetch_date': fetchDate.toIso8601String().split('T')[0],
      'fetch_timestamp': fetchTimestamp.toIso8601String(),
      'fetch_status': fetchStatus,
      'fetch_error': fetchError,
    };
  }
}
