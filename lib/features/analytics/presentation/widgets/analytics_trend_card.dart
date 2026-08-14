// lib/features/analytics/presentation/widgets/analytics_trend_card.dart

import 'package:flutter/material.dart';
import 'package:metal_tracker/core/widgets/card_heading.dart';
import 'package:metal_tracker/core/widgets/date_range_selector.dart';
import 'package:metal_tracker/core/widgets/metal_type_selector.dart';

/// Standard trend chart card for analytics detail screens.
///
/// Layout:
///   [icon + title ···············] [Range selector]
///                                  [Metal selector]  ← only when [onMetalChanged] is provided
///   [chart]  ← owns its own legend and empty state
class AnalyticsTrendCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String range;
  final ValueChanged<String> onRangeChanged;

  /// Currently selected metal. Required when [onMetalChanged] is provided.
  final String? selectedMetal;

  /// When non-null a Metal selector row is rendered below the Range selector.
  final ValueChanged<String?>? onMetalChanged;

  /// The chart widget — handles its own legend, empty state, and height.
  final Widget chart;

  const AnalyticsTrendCard({
    super.key,
    required this.icon,
    required this.title,
    required this.range,
    required this.onRangeChanged,
    this.selectedMetal,
    this.onMetalChanged,
    required this.chart,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardHeading(
              icon: icon,
              title: title,
              trailing: DateRangeSelector(
                selected: range,
                onChanged: onRangeChanged,
              ),
            ),
            if (onMetalChanged != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Metal:',
                    style: TextStyle(
                        color: cs.onSurfaceVariant, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  MetalTypeSelector(
                    selected: selectedMetal,
                    onChanged: onMetalChanged!,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            chart,
          ],
        ),
      ),
    );
  }
}
