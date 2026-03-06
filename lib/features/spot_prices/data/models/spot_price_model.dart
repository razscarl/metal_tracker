// lib/features/spot_prices/data/models/spot_price_model.dart

class SpotPrice {
  final String id;
  final String userId;
  final String metalType;
  final double price;
  final String sourceType; // 'global_api' | 'local_scraper'
  final String source; // e.g. 'Metal Price API', 'GBA', 'GS', 'IMP'
  final String? retailerId;
  final DateTime fetchDate;
  final DateTime fetchTimestamp;
  final String status;
  final String? error;

  const SpotPrice({
    required this.id,
    required this.userId,
    required this.metalType,
    required this.price,
    required this.sourceType,
    required this.source,
    this.retailerId,
    required this.fetchDate,
    required this.fetchTimestamp,
    required this.status,
    this.error,
  });

  factory SpotPrice.fromJson(Map<String, dynamic> json) {
    return SpotPrice(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      metalType: json['metal_type'] as String,
      price: (json['price'] as num).toDouble(),
      sourceType: json['source_type'] as String,
      source: json['source'] as String,
      retailerId: json['retailer_id'] as String?,
      fetchDate: DateTime.parse(json['fetch_date'] as String),
      fetchTimestamp: DateTime.parse(json['fetch_timestamp'] as String),
      status: json['status'] as String,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'metal_type': metalType,
      'price': price,
      'source_type': sourceType,
      'source': source,
      'retailer_id': retailerId,
      'fetch_date': fetchDate.toIso8601String().split('T')[0],
      'fetch_timestamp': fetchTimestamp.toIso8601String(),
      'status': status,
      'error': error,
    };
  }

  SpotPrice copyWith({
    String? id,
    String? userId,
    String? metalType,
    double? price,
    String? sourceType,
    String? source,
    String? retailerId,
    DateTime? fetchDate,
    DateTime? fetchTimestamp,
    String? status,
    String? error,
  }) {
    return SpotPrice(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      metalType: metalType ?? this.metalType,
      price: price ?? this.price,
      sourceType: sourceType ?? this.sourceType,
      source: source ?? this.source,
      retailerId: retailerId ?? this.retailerId,
      fetchDate: fetchDate ?? this.fetchDate,
      fetchTimestamp: fetchTimestamp ?? this.fetchTimestamp,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }

  /// Human-readable label for sourceType.
  String get sourceTypeLabel =>
      sourceType == 'global_api' ? 'Global' : 'Local';
}
