// lib/features/scrapers/models/product_listing_model.dart:Product Listing Model
class ProductListing {
  final String id;
  final String listingName;
  final double listingSellPrice;
  final String retailerId;
  final String? productProfileId;
  final String scrapeStatus;
  final String? scrapeError;
  final DateTime scrapeDate;
  final DateTime scrapeTimestamp;

  ProductListing({
    required this.id,
    required this.listingName,
    required this.listingSellPrice,
    required this.retailerId,
    this.productProfileId,
    required this.scrapeStatus,
    this.scrapeError,
    required this.scrapeDate,
    required this.scrapeTimestamp,
  });

  factory ProductListing.fromJson(Map<String, dynamic> json) {
    return ProductListing(
      id: json['id'] as String,
      listingName: json['listing_name'] as String,
      listingSellPrice: (json['listing_sell_price'] as num).toDouble(),
      retailerId: json['retailer_id'] as String,
      productProfileId: json['product_profile_id'] as String?,
      scrapeStatus: json['scrape_status'] as String,
      scrapeError: json['scrape_error'] as String?,
      scrapeDate: DateTime.parse(json['scrape_date'] as String),
      scrapeTimestamp: DateTime.parse(json['scrape_timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listing_name': listingName,
      'listing_sell_price': listingSellPrice,
      'retailer_id': retailerId,
      'product_profile_id': productProfileId,
      'scrape_status': scrapeStatus,
      'scrape_error': scrapeError,
      'scrape_date': scrapeDate.toIso8601String().split('T')[0],
      'scrape_timestamp': scrapeTimestamp.toIso8601String(),
    };
  }
}
