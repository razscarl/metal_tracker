// lib/core/utils/weight_converter.dart
import '../constants/app_constants.dart';

extension WeightUnitConversion on WeightUnit {
  double get _toOzFactor {
    switch (this) {
      case WeightUnit.oz:
        return 1.0;
      case WeightUnit.g:
        return 0.0321507466;
      case WeightUnit.kg:
        return 32.15074657;
    }
  }

  double get _fromOzFactor {
    switch (this) {
      case WeightUnit.oz:
        return 1.0;
      case WeightUnit.g:
        return 31.1034768;
      case WeightUnit.kg:
        return 0.0311034768;
    }
  }

  double convertTo(double value, WeightUnit targetUnit) {
    if (this == targetUnit) return value;
    double ozValue = value * _toOzFactor;
    return ozValue * targetUnit._fromOzFactor;
  }
}

class WeightCalculations {
  /// Returns the pure metal content in Troy Ounces.
  static double pureMetalContent({
    required double weight,
    required WeightUnit unit,
    required double purity,
  }) {
    double weightInOz = weight * unit._toOzFactor;
    return weightInOz * (purity / 100.0);
  }

  /// Normalizes a price to $/oz of pure metal.
  static double pricePerPureOunce({
    required double totalPrice,
    required double weight,
    required WeightUnit unit,
    required double purity,
  }) {
    final pureOz = pureMetalContent(
      weight: weight,
      unit: unit,
      purity: purity,
    );
    return totalPrice / pureOz;
  }

  /// Calculates the value of a specific quantity of metal based on market oz price.
  static double holdingValue({
    required double weight,
    required WeightUnit unit,
    required double purity,
    required double currentPricePerPureOz,
  }) {
    final pureOz = pureMetalContent(weight: weight, unit: unit, purity: purity);
    return pureOz * currentPricePerPureOz;
  }
}
