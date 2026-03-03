// lib/features/scrapers/data/models/retailer_scraper_setting_model.dart:Retailer Scraper Setting Model
class RetailerScraperSetting {
  final String id;
  final String retailerId;
  final String scraperType;
  final String? metalType;
  final bool isActive;
  final String? searchUrl;
  final String searchString;

  RetailerScraperSetting({
    required this.id,
    required this.retailerId,
    required this.scraperType,
    this.metalType,
    required this.isActive,
    this.searchUrl,
    required this.searchString,
  });

  factory RetailerScraperSetting.fromJson(Map<String, dynamic> json) {
    return RetailerScraperSetting(
      id: json['id'] as String,
      retailerId: json['retailer_id'] as String,
      scraperType: json['scraper_type'] as String,
      metalType: json['metal_type'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      searchUrl: json['search_url'] as String?,
      searchString: json['search_string'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'retailer_id': retailerId,
      'scraper_type': scraperType,
      'metal_type': metalType,
      'is_active': isActive,
      'search_url': searchUrl,
      'search_string': searchString,
    };
  }
}
