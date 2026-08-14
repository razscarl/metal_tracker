// lib/core/widgets/date_range_selector.dart

import 'package:flutter/material.dart';

/// Horizontal date-range chip selector for chart views.
///
/// Options: 7D, 30D, 90D, All. Selected chip uses the theme's primary container
/// colour (Royal Indigo) — not a metal colour.
class DateRangeSelector extends StatelessWidget {
  final String selected; // '7d', '30d', '90d', 'all'
  final ValueChanged<String> onChanged;

  const DateRangeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text('Range:',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
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
                      ? cs.primaryContainer
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  r == 'all' ? 'All' : r.toUpperCase(),
                  style: TextStyle(
                    color: selected == r
                        ? cs.onPrimaryContainer
                        : cs.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: selected == r
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
