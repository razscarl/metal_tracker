// lib/features/retailers/data/models/retailers_model.dart:Retailers Model
class Retailer {
  final String id;
  final String? userId;
  final String name;
  final String? retailerAbbr;
  final String? baseUrl;
  final bool isActive;

  Retailer({
    required this.id,
    this.userId,
    required this.name,
    this.retailerAbbr,
    this.baseUrl,
    required this.isActive,
  });

  factory Retailer.fromJson(Map<String, dynamic> json) {
    return Retailer(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      retailerAbbr: json['retailer_abbr'] as String?,
      baseUrl: json['base_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'retailer_abbr': retailerAbbr,
      'base_url': baseUrl,
      'is_active': isActive,
    };
  }
}
