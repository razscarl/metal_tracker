class AutomationConfig {
  final String id;
  final String timezone;
  final bool enabled;
  final DateTime? updatedAt;

  const AutomationConfig({
    required this.id,
    required this.timezone,
    required this.enabled,
    this.updatedAt,
  });

  factory AutomationConfig.fromJson(Map<String, dynamic> json) {
    return AutomationConfig(
      id: json['id'] as String,
      timezone: json['timezone'] as String? ?? 'Australia/Brisbane',
      enabled: json['enabled'] as bool? ?? true,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'timezone': timezone,
        'enabled': enabled,
        'updated_at': DateTime.now().toIso8601String(),
      };

  AutomationConfig copyWith({String? timezone, bool? enabled}) {
    return AutomationConfig(
      id: id,
      timezone: timezone ?? this.timezone,
      enabled: enabled ?? this.enabled,
      updatedAt: DateTime.now(),
    );
  }
}
