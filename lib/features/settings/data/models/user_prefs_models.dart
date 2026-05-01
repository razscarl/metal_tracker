import 'package:metal_tracker/core/utils/time_service.dart';

class UserGlobalSpotPref {
  final String? id;
  final String userId;
  final String providerKey;
  final String apiKey;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserGlobalSpotPref({
    this.id,
    required this.userId,
    required this.providerKey,
    required this.apiKey,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory UserGlobalSpotPref.fromJson(Map<String, dynamic> json) {
    return UserGlobalSpotPref(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      providerKey: json['provider_key'] as String,
      apiKey: json['api_key'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? TimeService.parseTimestamp(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? TimeService.parseTimestamp(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'provider_key': providerKey,
      'api_key': apiKey,
      'is_active': isActive,
    };
  }
}
