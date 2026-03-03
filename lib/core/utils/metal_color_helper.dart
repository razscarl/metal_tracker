// lib/features/auth/presentation/screens/auth_wrapper.dart:Auth Wrapper
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
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

  static IconData getIconForMetal(MetalType metalType) {
    // You can customize icons per metal type if desired
    return Icons.circle;
  }
}
