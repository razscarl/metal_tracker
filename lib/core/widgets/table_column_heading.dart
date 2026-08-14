// lib/core/widgets/table_column_heading.dart

import 'package:flutter/material.dart';

/// A single column heading in a card-based data table.
///
/// Tappable when [onTap] is provided. Displays a sort indicator when
/// [sortActive] is true — active column uses [cs.onSurface], not a metal
/// colour. The sort arrow and optional "2" badge sit tightly inline with
/// the label.
///
/// Sort state is owned by the screen; this widget only displays what it
/// is told. When the sort UX is redesigned (C058), update the callers —
/// this widget stays the same.
class TableColumnHeading extends StatelessWidget {
  final String label;
  final int flex;
  final TextAlign align;
  final VoidCallback? onTap;
  final bool sortActive;
  final bool sortAscending;
  final bool sortSecondary;

  const TableColumnHeading({
    super.key,
    required this.label,
    required this.flex,
    this.align = TextAlign.start,
    this.onTap,
    this.sortActive = false,
    this.sortAscending = true,
    this.sortSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = sortActive ? cs.onSurface : cs.onSurfaceVariant;

    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: align == TextAlign.right
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (sortActive) ...[
                const SizedBox(width: 2),
                Icon(
                  sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: sortSecondary ? 9 : 11,
                  color: color,
                ),
                if (sortSecondary)
                  Text(
                    '2',
                    style: TextStyle(
                      color: color,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
