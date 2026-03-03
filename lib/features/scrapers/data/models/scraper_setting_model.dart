// lib/features/scrapers/data/models/scraper_setting_model.dart:Scraper Setting Model
class ScraperSetting {
  final String id;
  final String retailerId;
  final String scraperType;
  final String? metalType;
  final String searchString;
  final bool isActive;
  final String? notes;

  ScraperSetting({
    required this.id,
    required this.retailerId,
    required this.scraperType,
    this.metalType,
    required this.searchString,
    required this.isActive,
    this.notes,
  });

  factory ScraperSetting.fromJson(Map<String, dynamic> json) {
    return ScraperSetting(
      id: json['id'] as String,
      retailerId: json['retailer_id'] as String,
      scraperType: json['scraper_type'] as String,
      metalType: json['metal_type'] as String?,
      searchString: json['search_string'] as String,
      isActive: json['is_active'] as bool? ?? true,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'retailer_id': retailerId,
      'scraper_type': scraperType,
      'metal_type': metalType,
      'search_string': searchString,
      'is_active': isActive,
      'notes': notes,
    };
  }

  ScraperSetting copyWith({
    String? id,
    String? retailerId,
    String? scraperType,
    String? metalType,
    String? searchString,
    bool? isActive,
    String? notes,
  }) {
    return ScraperSetting(
      id: id ?? this.id,
      retailerId: retailerId ?? this.retailerId,
      scraperType: scraperType ?? this.scraperType,
      metalType: metalType ?? this.metalType,
      searchString: searchString ?? this.searchString,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
    );
  }
}
