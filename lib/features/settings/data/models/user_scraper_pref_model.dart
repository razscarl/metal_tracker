class UserScraperPref {
  final String id;
  final String userId;
  final String retailerScraperSettingsId;
  // Joined from retailer_scraper_settings + retailers:
  final String? scraperType;
  final String? metalType;
  final String? retailerId;
  final String? retailerName;

  const UserScraperPref({
    required this.id,
    required this.userId,
    required this.retailerScraperSettingsId,
    this.scraperType,
    this.metalType,
    this.retailerId,
    this.retailerName,
  });

  factory UserScraperPref.fromJson(Map<String, dynamic> json) {
    final settings = json['retailer_scraper_settings'] as Map<String, dynamic>?;
    final retailer = settings?['retailers'] as Map<String, dynamic>?;
    return UserScraperPref(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      retailerScraperSettingsId:
          json['retailer_scraper_settings_id'] as String,
      scraperType: settings?['scraper_type'] as String?,
      metalType: settings?['metal_type'] as String?,
      retailerId: settings?['retailer_id'] as String?,
      retailerName: retailer?['name'] as String?,
    );
  }

  String get displayLabel {
    final name = retailerName ?? 'Unknown';
    final metal = metalType ?? '';
    if (metal.isEmpty) return name;
    return '$name — ${metal[0].toUpperCase()}${metal.substring(1)}';
  }
}
