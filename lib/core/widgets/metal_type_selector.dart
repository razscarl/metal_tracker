// lib/core/widgets/metal_type_selector.dart

import 'package:flutter/material.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';

/// Single-select metal type chip row.
///
/// [selected]: currently selected metal ('gold', 'silver', 'platinum').
///   Null is only valid when [showAll] is true and means "All" is selected.
/// [showAll]: prepend an "All" chip (null value). Default false.
class MetalTypeSelector extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;
  final bool showAll;

  const MetalTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.showAll = false,
  });

  Widget _chip(
    BuildContext context,
    String? value,
    String label,
    Color chipColor, {
    Color? selectedTextColor,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = selected == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? chipColor : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? (selectedTextColor ?? AppColors.textDark)
                  : cs.onSurfaceVariant,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        if (showAll)
          _chip(context, null, 'All', cs.primaryContainer,
              selectedTextColor: cs.onPrimaryContainer),
        _chip(context, 'gold', 'Gold', AppColors.primaryGold),
        _chip(context, 'silver', 'Silver', AppColors.secondarySilver),
        _chip(context, 'platinum', 'Platinum', AppColors.accentPlatinum),
      ],
    );
  }
}
