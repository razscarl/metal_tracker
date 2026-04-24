// lib/features/holdings/data/models/holding_model.dart:Holding Model
import 'package:metal_tracker/core/utils/time_service.dart';
import '../../../product_profiles/data/models/product_profile_model.dart';

class Holding {
  final String id;
  final String userId;
  final String productName;
  final String productProfileId;
  final String? retailerId;
  final DateTime purchaseDate;
  final double purchasePrice;
  final bool isSold;
  final DateTime? soldDate;
  final double? soldPrice;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional: Include the full product profile object
  final ProductProfile? productProfile;

  Holding({
    required this.id,
    required this.userId,
    required this.productName,
    required this.productProfileId,
    this.retailerId,
    required this.purchaseDate,
    required this.purchasePrice,
    this.isSold = false,
    this.soldDate,
    this.soldPrice,
    required this.createdAt,
    required this.updatedAt,
    this.productProfile,
  });

  factory Holding.fromJson(Map<String, dynamic> json) {
    return Holding(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      productName: json['product_name'] as String,
      productProfileId: json['product_profile_id'] as String,
      retailerId: json['retailer_id'] as String?,
      purchaseDate: DateTime.parse(json['purchase_date'] as String),
      purchasePrice: (json['purchase_price'] as num).toDouble(),
      isSold: json['is_sold'] as bool? ?? false,
      soldDate: json['sold_date'] != null
          ? DateTime.parse(json['sold_date'] as String)
          : null,
      soldPrice: json['sold_price'] != null
          ? (json['sold_price'] as num).toDouble()
          : null,
      createdAt: TimeService.parseTimestamp(json['created_at'] as String),
      updatedAt: TimeService.parseTimestamp(json['updated_at'] as String),
      productProfile: json['product_profiles'] != null
          ? ProductProfile.fromJson(
              json['product_profiles'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_name': productName,
      'product_profile_id': productProfileId,
      'retailer_id': retailerId,
      'purchase_date': purchaseDate.toIso8601String().split('T')[0],
      'purchase_price': purchasePrice,
      'is_sold': isSold,
      'sold_date': soldDate?.toIso8601String().split('T')[0],
      'sold_price': soldPrice,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper: Calculate gain/loss
  double calculateGain(double currentValue) {
    return currentValue - purchasePrice;
  }

  double calculateGainPercent(double currentValue) {
    if (purchasePrice == 0) return 0;
    return (calculateGain(currentValue) / purchasePrice) * 100;
  }
}
