import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_color_extension.dart';
import '../constants/app_constants.dart';

class MetalColorHelper {
  static Color getColorForMetal(MetalType metalType) {
    switch (metalType) {
      case MetalType.gold:
        return AppColors.primaryGold;
      case MetalType.silver:
        return AppColors.secondarySilver;
      case MetalType.platinum:
        return AppColors.accentPlatinum;
    }
  }

  static Color getColorForMetalString(String metalType) {
    final type = MetalType.fromString(metalType);
    return getColorForMetal(type);
  }

  /// Returns a colour appropriate for text labels.
  /// Silver uses a darker shade in light mode so it remains readable
  /// on light surfaces. All other metals return their standard colour.
  static Color getTextColorForMetal(BuildContext context, MetalType metal) {
    if (metal == MetalType.silver &&
        Theme.of(context).brightness == Brightness.light) {
      return Theme.of(context)
              .extension<AppColorExtension>()
              ?.metalSilverText ??
          AppColors.secondarySilver;
    }
    return getColorForMetal(metal);
  }

  static Color getTextColorForMetalString(BuildContext context, String metalType) {
    return getTextColorForMetal(context, MetalType.fromString(metalType));
  }

  static IconData getIconForMetal(MetalType metalType) {
    return Icons.circle;
  }

  static String getAssetPathForMetal(MetalType metalType) {
    switch (metalType) {
      case MetalType.gold:
        return 'assets/gold_icon.png';
      case MetalType.silver:
        return 'assets/silver_icon.png';
      case MetalType.platinum:
        return 'assets/platinum_icon.png';
    }
  }

  static String getAssetPathForMetalString(String metalType) {
    return getAssetPathForMetal(MetalType.fromString(metalType));
  }

  /// Chemical symbols used as display identifiers (Au / Ag / Pt).
  static String getSymbolForMetal(MetalType metalType) {
    switch (metalType) {
      case MetalType.gold:
        return 'Au';
      case MetalType.silver:
        return 'Ag';
      case MetalType.platinum:
        return 'Pt';
    }
  }

  static String getSymbolForMetalString(String metalType) {
    return getSymbolForMetal(MetalType.fromString(metalType));
  }
}
