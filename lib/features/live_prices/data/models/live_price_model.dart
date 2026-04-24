// lib/features/live_prices/data/models/live_price_model.dart
import 'package:metal_tracker/core/utils/time_service.dart';

class LivePrice {
  final String id;
  final String userId;
  final String retailerId;
  final String? retailerName;
  final String? retailerAbbr;
  final String? metalType;
  final String? livePriceName;
  final String? productProfileId;
  final DateTime captureDate;
  final DateTime captureTimestamp;
  final double? sellPrice;
  final double? buybackPrice;
  final String? scrapeStatus;
  final String? errorMessage;

  LivePrice({
    required this.id,
    required this.userId,
    required this.retailerId,
    this.retailerName,
    this.retailerAbbr,
    this.metalType,
    this.livePriceName,
    this.productProfileId,
    required this.captureDate,
    required this.captureTimestamp,
    this.sellPrice,
    this.buybackPrice,
    this.scrapeStatus,
    this.errorMessage,
  });

  factory LivePrice.fromJson(Map<String, dynamic> json) {
    final retailer = json['retailers'] as Map<String, dynamic>?;
    return LivePrice(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      retailerId: json['retailer_id'] as String,
      retailerName: retailer?['name'] as String?,
      retailerAbbr: retailer?['retailer_abbr'] as String?,
      metalType: json['metal_type'] as String?,
      livePriceName: json['live_price_name'] as String?,
      productProfileId: json['product_profile_id'] as String?,
      captureDate: DateTime.parse(json['capture_date'] as String),
      captureTimestamp: TimeService.parseTimestamp(json['capture_timestamp'] as String),
      sellPrice: json['sell_price'] != null
          ? (json['sell_price'] as num).toDouble()
          : null,
      buybackPrice: json['buyback_price'] != null
          ? (json['buyback_price'] as num).toDouble()
          : null,
      scrapeStatus: json['scrape_status'] as String?,
      errorMessage: json['error_message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'retailer_id': retailerId,
      'metal_type': metalType,
      'live_price_name': livePriceName,
      'product_profile_id': productProfileId,
      'capture_date': captureDate.toIso8601String().split('T')[0],
      'capture_timestamp': captureTimestamp.toIso8601String(),
      'sell_price': sellPrice,
      'buyback_price': buybackPrice,
      'scrape_status': scrapeStatus,
      'error_message': errorMessage,
    };
  }
}
