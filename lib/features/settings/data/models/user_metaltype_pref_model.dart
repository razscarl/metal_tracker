class UserMetaltypePref {
  final String id;
  final String userId;
  final String metalTypeId;
  final String metalTypeName;

  const UserMetaltypePref({
    required this.id,
    required this.userId,
    required this.metalTypeId,
    required this.metalTypeName,
  });

  factory UserMetaltypePref.fromJson(Map<String, dynamic> json) {
    final metalType = json['metal_types'] as Map<String, dynamic>?;
    return UserMetaltypePref(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      metalTypeId: json['metal_type_id'] as String,
      metalTypeName: metalType?['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'metal_type_id': metalTypeId,
      };
}
