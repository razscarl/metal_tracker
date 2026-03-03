// lib/features/holdings/data/models/product_profile_model.dart:Product Profile Model
import '../../../../../../core/constants/app_constants.dart';
import '../../../../../../core/utils/weight_converter.dart';

class ProductProfile {
  final String id;
  final String userId;
  final String profileName;
  final String profileCode;
  final String metalType;
  final String metalForm;
  final String? metalFormCustom;
  final double weight;
  final String weightDisplay;
  final String weightUnit;
  final double purity;

  ProductProfile({
    required this.id,
    required this.userId,
    required this.profileName,
    required this.profileCode,
    required this.metalType,
    required this.metalForm,
    this.metalFormCustom,
    required this.weight,
    required this.weightDisplay,
    required this.weightUnit,
    required this.purity,
  });

  // Getter: Convert string metalType to MetalType enum
  MetalType get metalTypeEnum => MetalType.fromString(metalType);

  // Getter: Convert string weightUnit to WeightUnit enum
  WeightUnit get weightUnitEnum => WeightUnit.fromString(weightUnit);

  // Getter: Calculate pure metal content in troy ounces
  double get pureMetalContent => WeightCalculations.pureMetalContent(
        weight: weight,
        unit: weightUnitEnum,
        purity: purity,
      );

  factory ProductProfile.fromJson(Map<String, dynamic> json) {
    return ProductProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      profileName: json['profile_name'] as String,
      profileCode: json['profile_code'] as String,
      metalType: json['metal_type'] as String,
      metalForm: json['metal_form'] as String,
      metalFormCustom: json['metal_form_custom'] as String?,
      weight: (json['weight'] as num).toDouble(),
      weightDisplay: json['weight_display'] as String,
      weightUnit: json['weight_unit'] as String,
      purity: (json['purity'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'profile_name': profileName,
      'profile_code': profileCode,
      'metal_type': metalType,
      'metal_form': metalForm,
      'metal_form_custom': metalFormCustom,
      'weight': weight,
      'weight_display': weightDisplay,
      'weight_unit': weightUnit,
      'purity': purity,
    };
  }
}
