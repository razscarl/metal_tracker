// lib/features/metadata/data/models/metadata_models.dart

class MetalTypeRecord {
  final String id;
  final String name;
  final bool isActive;
  final DateTime createdAt;

  const MetalTypeRecord({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdAt,
  });

  factory MetalTypeRecord.fromJson(Map<String, dynamic> json) => MetalTypeRecord(
        id: json['id'] as String,
        name: json['name'] as String,
        isActive: json['is_active'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );
}

class MetalFormRecord {
  final String id;
  final String name;
  final bool isActive;
  final DateTime createdAt;

  const MetalFormRecord({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdAt,
  });

  factory MetalFormRecord.fromJson(Map<String, dynamic> json) => MetalFormRecord(
        id: json['id'] as String,
        name: json['name'] as String,
        isActive: json['is_active'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );
}
