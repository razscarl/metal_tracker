// lib/core/widgets/filter_sheet.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FilterSheet — standard bottom-sheet scaffold for all filter UIs
// ─────────────────────────────────────────────────────────────────────────────

class FilterSheet {
  FilterSheet._();

  /// Opens a filter bottom sheet.
  ///
  /// [builder] receives a [StateSetter] that refreshes only the sheet UI;
  /// to also refresh the screen, call the screen's `setState` inside the
  /// same closure (capture it in the calling method).
  ///
  /// [onReset] is called when the Reset button is tapped (sheet state is
  /// refreshed automatically after the callback returns).
  static Future<void> show({
    required BuildContext context,
    required String title,
    required List<Widget> Function(StateSetter setSheetState) builder,
    required VoidCallback onReset,
    double initialSize = 0.65,
    double maxSize = 0.9,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: initialSize,
          minChildSize: 0.35,
          maxChildSize: maxSize,
          builder: (_, scrollController) => Container(
            decoration: const BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          onReset();
                          setSheetState(() {});
                        },
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            size: 20, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.white12),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: builder(setSheetState),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FilterSection — labelled section wrapper
// ─────────────────────────────────────────────────────────────────────────────

class FilterSection extends StatelessWidget {
  final String label;
  final Widget child;

  const FilterSection({
    super.key,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FilterChipGroup<T> — single-select radio chips  (null value = "All")
// ─────────────────────────────────────────────────────────────────────────────

class FilterChipOption<T> {
  final T value;
  final String label;
  final Color? color;

  const FilterChipOption({
    required this.value,
    required this.label,
    this.color,
  });
}

/// Single-select chip group. [selected] is `null` when "All" is active.
class FilterChipGroup<T> extends StatelessWidget {
  final List<FilterChipOption<T>> options;
  final T? selected;
  final ValueChanged<T?> onChanged;

  const FilterChipGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // "All" chip
        _FilterChip(
          label: 'All',
          isSelected: selected == null,
          color: AppColors.primaryGold,
          onTap: () => onChanged(null),
        ),
        for (final opt in options)
          _FilterChip(
            label: opt.label,
            isSelected: selected == opt.value,
            color: opt.color ?? AppColors.primaryGold,
            onTap: () {
              if (selected == opt.value) {
                onChanged(null); // deselect → All
              } else {
                onChanged(opt.value);
              }
            },
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FilterCheckRow — colored checkbox row for multi-select lists
// ─────────────────────────────────────────────────────────────────────────────

class FilterCheckRow extends StatelessWidget {
  final String label;
  final Color color;
  final bool checked;
  final ValueChanged<bool> onChanged;

  const FilterCheckRow({
    super.key,
    required this.label,
    required this.color,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!checked),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: checked
                    ? color.withValues(alpha: 0.15)
                    : Colors.transparent,
                border: Border.all(
                  color: checked ? color : Colors.white24,
                  width: checked ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: checked
                  ? Icon(Icons.check, size: 14, color: color)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: checked ? color : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: checked ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FilterDatePreset — standard All / Today / Week / Month / Year chip group
// ─────────────────────────────────────────────────────────────────────────────

class FilterDatePreset extends StatelessWidget {
  static const List<FilterChipOption<String>> presets = [
    FilterChipOption(value: 'today', label: 'Today'),
    FilterChipOption(value: 'week', label: 'Week'),
    FilterChipOption(value: 'month', label: 'Month'),
    FilterChipOption(value: 'year', label: 'Year'),
  ];

  final String? selected;
  final ValueChanged<String?> onChanged;

  const FilterDatePreset({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChipGroup<String>(
      options: presets,
      selected: selected,
      onChanged: onChanged,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FilterRangeSlider — labelled double range slider
// ─────────────────────────────────────────────────────────────────────────────

class FilterRangeSlider extends StatelessWidget {
  final double min;
  final double max;
  final double currentMin;
  final double currentMax;
  final ValueChanged<RangeValues> onChanged;
  final String Function(double) format;

  const FilterRangeSlider({
    super.key,
    required this.min,
    required this.max,
    required this.currentMin,
    required this.currentMax,
    required this.onChanged,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    if (min >= max) return const SizedBox.shrink();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              format(currentMin),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              format(currentMax),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primaryGold,
            inactiveTrackColor: Colors.white12,
            thumbColor: AppColors.primaryGold,
            overlayColor: AppColors.primaryGold.withValues(alpha: 0.12),
            rangeThumbShape:
                const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: RangeSlider(
            values: RangeValues(currentMin, currentMax),
            min: min,
            max: max,
            divisions: max > min
                ? ((max - min) / math.max(1, (max - min) / 100))
                    .round()
                    .clamp(1, 200)
                : null,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FilterSearchField — single-line text search
// ─────────────────────────────────────────────────────────────────────────────

class FilterSearchField extends StatefulWidget {
  final String hint;
  final String value;
  final ValueChanged<String> onChanged;

  const FilterSearchField({
    super.key,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  @override
  State<FilterSearchField> createState() => _FilterSearchFieldState();
}

class _FilterSearchFieldState extends State<FilterSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(FilterSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(
            color: AppColors.textSecondary, fontSize: 14),
        prefixIcon: const Icon(Icons.search,
            size: 18, color: AppColors.textSecondary),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close,
                    size: 16, color: AppColors.textSecondary),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                },
              )
            : null,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal chip widget (shared by FilterChipGroup)
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : AppColors.backgroundDark,
          border: Border.all(
            color: isSelected ? color : Colors.white12,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
