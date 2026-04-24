// lib/features/spot_prices/data/models/global_spot_price_api_setting_model.dart
import 'package:metal_tracker/core/utils/time_service.dart';

class GlobalSpotPriceApiSetting {
  final String id;
  final String userId;
  final String apiKey;
  final String serviceType;
  final Map<String, String> config;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const GlobalSpotPriceApiSetting({
    required this.id,
    required this.userId,
    required this.apiKey,
    required this.serviceType,
    required this.config,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory GlobalSpotPriceApiSetting.fromJson(Map<String, dynamic> json) {
    return GlobalSpotPriceApiSetting(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      apiKey: json['api_key'] as String,
      serviceType: json['service_type'] as String? ?? 'metalpriceapi',
      config: (json['config'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v.toString())),
      isActive: json['is_active'] as bool,
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
      'id': id,
      'user_id': userId,
      'api_key': apiKey,
      'service_type': serviceType,
      'config': config,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  GlobalSpotPriceApiSetting copyWith({
    String? apiKey,
    String? serviceType,
    Map<String, String>? config,
    bool? isActive,
  }) {
    return GlobalSpotPriceApiSetting(
      id: id,
      userId: userId,
      apiKey: apiKey ?? this.apiKey,
      serviceType: serviceType ?? this.serviceType,
      config: config ?? this.config,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
