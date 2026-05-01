class UserRetailerPref {
  final String id;
  final String userId;
  final String retailerId;
  final String? retailerName;
  final String? retailerAbbr;

  const UserRetailerPref({
    required this.id,
    required this.userId,
    required this.retailerId,
    this.retailerName,
    this.retailerAbbr,
  });

  factory UserRetailerPref.fromJson(Map<String, dynamic> json) {
    final retailer = json['retailers'] as Map<String, dynamic>?;
    return UserRetailerPref(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      retailerId: json['retailer_id'] as String,
      retailerName: retailer?['name'] as String?,
      retailerAbbr: retailer?['retailer_abbr'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'retailer_id': retailerId,
      };
}
