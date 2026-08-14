// lib/core/utils/signal_color_helper.dart
//
// App-wide colour rules for investment signals and directional metric movement.
// Lives alongside MetalColorHelper in core/utils — available to the entire app.

import 'package:flutter/material.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/features/settings/data/models/user_analytics_settings_model.dart';

class SignalColorHelper {
  SignalColorHelper._();

  /// Colour for a directional movement indicator.
  ///
  /// Standard metrics (higher is better): up → gainGreen, down → lossRed.
  /// Lower-is-better metrics (spread, premium): direction is inverted —
  /// a falling value is good (gainGreen), a rising value is bad (lossRed).
  /// Null (no data yet) → textSecondary.
  static Color movementColor(bool? movementUp, {bool lowerIsBetter = false}) {
    if (movementUp == null) return AppColors.textSecondary;
    final isPositive = lowerIsBetter ? !movementUp : movementUp;
    return isPositive ? AppColors.gainGreen : AppColors.lossRed;
  }

  /// Colour for a GSR investment guide label.
  /// Maps to the corresponding metal colour: gold for "buy gold",
  /// silver for "buy silver", null for neutral ("hold").
  /// Callers use `?? cs.onSurface` for the neutral fallback.
  static Color? gsrGuideColor(String guide, UserAnalyticsSettings settings) {
    if (guide == settings.gsrLowText) return AppColors.primaryGold;
    if (guide == settings.gsrHighText) return AppColors.secondarySilver;
    return null; // neutral — caller uses cs.onSurface
  }

  /// Colour for a standard two-label guide (low = gain, high = loss, mid = neutral).
  /// Used by Local Premium and Local Spread guide columns.
  /// Returns null for neutral; callers use `?? cs.onSurface`.
  static Color? standardGuideColor(
      String guide, String lowLabel, String highLabel) {
    if (guide == lowLabel) return AppColors.gainGreen;
    if (guide == highLabel) return AppColors.lossRed;
    return null; // neutral — caller uses cs.onSurface
  }
}
