class UserMetalType {
  final String? id;
  final String userId;
  final String metalType; // 'gold' | 'silver' | 'platinum'

  const UserMetalType({this.id, required this.userId, required this.metalType});

  factory UserMetalType.fromJson(Map<String, dynamic> json) => UserMetalType(
        id: json['id'] as String?,
        userId: json['user_id'] as String,
        metalType: json['metal_type'] as String,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'metal_type': metalType,
      };
}
