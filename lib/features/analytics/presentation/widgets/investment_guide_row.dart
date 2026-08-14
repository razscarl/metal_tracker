// lib/features/analytics/presentation/widgets/investment_guide_row.dart

import 'package:flutter/material.dart';

/// One investment-guide row: icon · coloured label · muted description.
///
/// Used inside analytics info cards (GSR, Local Premium).
/// Will be absorbed into AnalyticsInfoCard when that scaffold is built.
class InvestmentGuideRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String text;

  const InvestmentGuideRow({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
