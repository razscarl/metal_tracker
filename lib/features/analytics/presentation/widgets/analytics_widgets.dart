// lib/features/analytics/presentation/widgets/analytics_widgets.dart

import 'package:flutter/material.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';

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
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          'Range:',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
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
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  r == 'all' ? 'All' : r.toUpperCase(),
                  style: TextStyle(
                    color: selected == r
                        ? AppColors.textDark
                        : cs.onSurfaceVariant,
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
