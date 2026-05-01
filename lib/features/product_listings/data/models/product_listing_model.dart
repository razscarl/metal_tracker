// lib/features/product_listings/data/models/product_listing_model.dart
import 'package:metal_tracker/core/utils/time_service.dart';

class ProductListing {
  final String id;
  final String listingName;
  final double listingSellPrice;
  final String retailerId;
  final String? productProfileId;
  final String? metalType;
  final String availability;
  final String scrapeStatus;
  final String? scrapeError;
  final DateTime scrapeDate;
  final DateTime scrapeTimestamp;

  // Joined from retailers table (populated when queried with join)
  final String? retailerName;
  final String? retailerAbbr;

  ProductListing({
    required this.id,
    required this.listingName,
    required this.listingSellPrice,
    required this.retailerId,
    this.productProfileId,
    this.metalType,
    this.availability = 'available',
    required this.scrapeStatus,
    this.scrapeError,
    required this.scrapeDate,
    required this.scrapeTimestamp,
    this.retailerName,
    this.retailerAbbr,
  });

  factory ProductListing.fromJson(Map<String, dynamic> json) {
    final retailerData = json['retailers'] as Map<String, dynamic>?;
    return ProductListing(
      id: json['id'] as String,
      listingName: json['listing_name'] as String,
      listingSellPrice: (json['listing_sell_price'] as num).toDouble(),
      retailerId: json['retailer_id'] as String,
      productProfileId: json['product_profile_id'] as String?,
      metalType: (json['metal_type'] as String?)?.toLowerCase(),
      availability: json['availability'] as String? ?? 'available',
      scrapeStatus: json['scrape_status'] as String,
      scrapeError: json['scrape_error'] as String?,
      scrapeDate: DateTime.parse(json['scrape_date'] as String),
      scrapeTimestamp: TimeService.parseTimestamp(json['scrape_timestamp'] as String),
      retailerName: retailerData?['name'] as String?,
      retailerAbbr: retailerData?['retailer_abbr'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listing_name': listingName,
      'listing_sell_price': listingSellPrice,
      'retailer_id': retailerId,
      'product_profile_id': productProfileId,
      'availability': availability,
      'scrape_status': scrapeStatus,
      'scrape_error': scrapeError,
      'scrape_date': scrapeDate.toIso8601String().split('T')[0],
      'scrape_timestamp': scrapeTimestamp.toIso8601String(),
    };
  }
}
