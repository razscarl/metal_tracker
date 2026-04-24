import 'package:metal_tracker/core/utils/time_service.dart';

class UserLivePricePref {
  final String? id;
  final String userId;
  final String retailerId;
  final String? metalType;
  final bool isActive;

  const UserLivePricePref({
    this.id,
    required this.userId,
    required this.retailerId,
    this.metalType,
    this.isActive = true,
  });

  factory UserLivePricePref.fromJson(Map<String, dynamic> json) {
    return UserLivePricePref(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      retailerId: json['retailer_id'] as String,
      metalType: json['metal_type'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'retailer_id': retailerId,
      'metal_type': metalType,
      'is_active': isActive,
    };
  }
}

class UserLocalSpotPref {
  final String? id;
  final String userId;
  final String retailerId;
  final String? metalType;
  final bool isActive;

  const UserLocalSpotPref({
    this.id,
    required this.userId,
    required this.retailerId,
    this.metalType,
    this.isActive = true,
  });

  factory UserLocalSpotPref.fromJson(Map<String, dynamic> json) {
    return UserLocalSpotPref(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      retailerId: json['retailer_id'] as String,
      metalType: json['metal_type'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'retailer_id': retailerId,
      'metal_type': metalType,
      'is_active': isActive,
    };
  }
}

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
