// lib/features/analytics/presentation/widgets/analytics_widgets.dart

import 'package:flutter/material.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/features/settings/data/models/user_analytics_settings_model.dart';

/// Consistent pill-style range selector used across all analytics detail screens.
class AnalyticsRangeChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const AnalyticsRangeChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Range:',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(width: 8),
        for (final r in ['7d', '30d', '90d', 'all'])
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onChanged(r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: selected == r
                      ? AppColors.primaryGold
                      : AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  r == 'all' ? 'All' : r.toUpperCase(),
                  style: TextStyle(
                    color: selected == r
                        ? AppColors.textDark
                        : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight:
                        selected == r ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Guide colour for GSR — gold / silver / neutral (not green/red, valid exception).
Color gsrGuideColor(String guide, UserAnalyticsSettings settings) {
  if (guide == settings.gsrHighText) return AppColors.secondarySilver;
  if (guide == settings.gsrLowText) return AppColors.primaryGold;
  return AppColors.textSecondary;
}

/// Guide colour for Local Premium and Local Spread — green / red / neutral.
Color standardGuideColor(String guide, String lowLabel, String highLabel) {
  if (guide == lowLabel) return AppColors.gainGreen;
  if (guide == highLabel) return AppColors.lossRed;
  return AppColors.textSecondary;
}
