// lib/core/widgets/card_heading.dart

import 'package:flutter/material.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';

/// Standard card heading: icon on the left, title next to it, optional
/// trailing widget aligned to the right (e.g. a range or metal selector).
///
/// Used on any card across the app — not analytics-specific.
class CardHeading extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final Color? iconColor;

  const CardHeading({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: iconColor ?? AppColors.primaryGold, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
