class ChangeRequest {
  final String? id;
  final String userId;
  final String requestType;
  final String subject;
  final String? description;
  final String status; // pending | in_progress | completed | rejected
  final String? adminNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ChangeRequest({
    this.id,
    required this.userId,
    required this.requestType,
    required this.subject,
    this.description,
    this.status = 'pending',
    this.adminNotes,
    this.createdAt,
    this.updatedAt,
  });

  factory ChangeRequest.fromJson(Map<String, dynamic> json) {
    return ChangeRequest(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      requestType: json['request_type'] as String,
      subject: json['subject'] as String,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'pending',
      adminNotes: json['admin_notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'request_type': requestType,
      'subject': subject,
      'description': description,
      'status': status,
      'admin_notes': adminNotes,
    };
  }

  ChangeRequest copyWith({
    String? status,
    String? adminNotes,
  }) {
    return ChangeRequest(
      id: id,
      userId: userId,
      requestType: requestType,
      subject: subject,
      description: description,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

// Strongly-typed request type constants
abstract class ChangeRequestType {
  static const newRetailer = 'new_retailer';
  static const changeRetailer = 'change_retailer';
  static const newLivePriceRetailer = 'new_live_price_retailer';
  static const changeLivePriceRetailer = 'change_live_price_retailer';
  static const newLocalSpotRetailer = 'new_local_spot_retailer';
  static const changeLocalSpotRetailer = 'change_local_spot_retailer';
  static const newGlobalSpotProvider = 'new_global_spot_provider';
  static const changeGlobalSpotProvider = 'change_global_spot_provider';
  static const newProductListingRetailer = 'new_product_listing_retailer';
  static const changeProductListingRetailer = 'change_product_listing_retailer';
  static const changeProductProfile = 'change_product_profile';
  static const newAnalytics = 'new_analytics';
  static const changeAnalytics = 'change_analytics';
  static const adminAccess = 'admin_access';
  static const removeAdminAccess = 'remove_admin_access';
  static const other = 'other';

  static String displayName(String type) {
    switch (type) {
      case newRetailer:            return 'New Retailer';
      case changeRetailer:         return 'Change Retailer';
      case newLivePriceRetailer:   return 'New Live Price Retailer';
      case changeLivePriceRetailer:return 'Change Live Price Retailer';
      case newLocalSpotRetailer:   return 'New Local Spot Retailer';
      case changeLocalSpotRetailer:return 'Change Local Spot Retailer';
      case newGlobalSpotProvider:  return 'New Global Spot Provider';
      case changeGlobalSpotProvider:return 'Change Global Spot Provider';
      case newProductListingRetailer: return 'New Product Listing Retailer';
      case changeProductListingRetailer: return 'Change Product Listing Retailer';
      case changeProductProfile:   return 'Change Product Profile';
      case newAnalytics:           return 'New Analytics';
      case changeAnalytics:        return 'Change Analytics';
      case adminAccess:            return 'Admin Access Request';
      case removeAdminAccess:      return 'Remove Admin Access';
      default:                     return 'Other';
    }
  }
}
