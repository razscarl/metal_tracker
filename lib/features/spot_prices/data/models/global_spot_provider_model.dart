import 'package:metal_tracker/core/utils/time_service.dart';

class GlobalSpotProvider {
  final String id;
  final String name;
  final String providerKey;
  final String? baseUrl;
  final String? description;
  final bool isActive;
  final DateTime createdAt;

  const GlobalSpotProvider({
    required this.id,
    required this.name,
    required this.providerKey,
    this.baseUrl,
    this.description,
    required this.isActive,
    required this.createdAt,
  });

  factory GlobalSpotProvider.fromJson(Map<String, dynamic> json) {
    return GlobalSpotProvider(
      id: json['id'] as String,
      name: json['name'] as String,
      providerKey: json['provider_key'] as String,
      baseUrl: json['base_url'] as String?,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: TimeService.parseTimestamp(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'provider_key': providerKey,
      'base_url': baseUrl,
      'description': description,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
