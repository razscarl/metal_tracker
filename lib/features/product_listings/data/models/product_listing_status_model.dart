// lib/features/product_listings/data/models/product_listing_status_model.dart

/// A row from the `product_listing_statuses` lookup table.
///
/// Maps a raw [capturedStatus] string returned by a scraper to a canonical
/// [storedStatus] value that is written to `product_listings.availability`.
class ProductListingStatus {
  final String id;
  final String capturedStatus;
  final String storedStatus;
  final String displayLabel;
  final bool isActive;

  const ProductListingStatus({
    required this.id,
    required this.capturedStatus,
    required this.storedStatus,
    required this.displayLabel,
    required this.isActive,
  });

  factory ProductListingStatus.fromJson(Map<String, dynamic> json) {
    return ProductListingStatus(
      id: json['id'] as String,
      capturedStatus: json['captured_status'] as String,
      storedStatus: json['stored_status'] as String,
      displayLabel: json['display_label'] as String,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'captured_status': capturedStatus,
        'stored_status': storedStatus,
        'display_label': displayLabel,
        'is_active': isActive,
      };

  ProductListingStatus copyWith({
    String? capturedStatus,
    String? storedStatus,
    String? displayLabel,
    bool? isActive,
  }) {
    return ProductListingStatus(
      id: id,
      capturedStatus: capturedStatus ?? this.capturedStatus,
      storedStatus: storedStatus ?? this.storedStatus,
      displayLabel: displayLabel ?? this.displayLabel,
      isActive: isActive ?? this.isActive,
    );
  }
}
