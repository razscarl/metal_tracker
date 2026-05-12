class UserMetalformPref {
  final String id;
  final String userId;
  final String metalFormId;
  final String metalFormName;

  const UserMetalformPref({
    required this.id,
    required this.userId,
    required this.metalFormId,
    required this.metalFormName,
  });

  factory UserMetalformPref.fromJson(Map<String, dynamic> json) {
    final metalForm = json['metal_forms'] as Map<String, dynamic>?;
    return UserMetalformPref(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      metalFormId: json['metal_form_id'] as String,
      metalFormName: metalForm?['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'metal_form_id': metalFormId,
      };
}
