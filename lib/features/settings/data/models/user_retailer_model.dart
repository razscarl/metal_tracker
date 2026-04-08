class UserRetailer {
  final String? id;
  final String userId;
  final String retailerId;
  final String? retailerName;

  const UserRetailer({
    this.id,
    required this.userId,
    required this.retailerId,
    this.retailerName,
  });

  factory UserRetailer.fromJson(Map<String, dynamic> json) {
    final retailer = json['retailers'] as Map<String, dynamic>?;
    return UserRetailer(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      retailerId: json['retailer_id'] as String,
      retailerName: retailer?['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'retailer_id': retailerId,
      };
}
