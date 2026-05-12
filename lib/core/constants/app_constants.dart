// lib/core/constants/app_constants.dart:App Constants and Enums
// Metal Types
enum MetalType {
  gold('Gold'),
  silver('Silver'),
  platinum('Platinum');

  final String displayName;
  const MetalType(this.displayName);

  static MetalType fromString(String value) {
    return MetalType.values.firstWhere(
      (e) => e.displayName.toLowerCase() == value.toLowerCase(),
      orElse: () => MetalType.gold,
    );
  }
}

// Weight Units
enum WeightUnit {
  oz('oz'),
  g('g'),
  kg('kg');

  final String displayName;
  const WeightUnit(this.displayName);

  static WeightUnit fromString(String value) {
    return WeightUnit.values.firstWhere(
      (e) => e.displayName == value,
      orElse: () => WeightUnit.oz,
    );
  }

  static List<String> get displayNames =>
      WeightUnit.values.map((e) => e.displayName).toList();
}

// App-wide constants
class AppConstants {
  // Validation
  static const double minWeight = 0.001;
  static const double maxWeight = 10000;
  static const double minPrice = 0.01;
  static const double maxPrice = 10000000;

  // Date ranges
  static final DateTime minPurchaseDate = DateTime(2000);
  static DateTime get maxPurchaseDate => DateTime.now();

  // UI
  static const double cardBorderRadius = 12.0;
  static const double buttonHeight = 48.0;
}
