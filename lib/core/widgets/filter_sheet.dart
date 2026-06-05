// lib/core/widgets/filter_sheet.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FilterSheet — standard bottom-sheet scaffold for all filter UIs
// ─────────────────────────────────────────────────────────────────────────────

class FilterSheet {
  FilterSheet._();

  static Future<void> show({
    required BuildContext context,
    required String title,
    required List<Widget> Function(StateSetter setSheetState) builder,
    required VoidCallback onReset,
    double initialSize = 0.65,
    double maxSize     = 0.9,
  }) {
    return showModalBottomSheet(
      context:             context,
      isScrollControlled:  true,
      backgroundColor:     Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: initialSize,
          minChildSize:     0.35,
          maxChildSize:     maxSize,
          builder: (_, scrollController) {
            final cs = Theme.of(ctx).colorScheme;
            final tt = Theme.of(ctx).textTheme;
            return Container(
              decoration: BoxDecoration(
                color:        cs.surfaceContainerLow,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width:  40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color:        cs.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                    child: Row(
                      children: [
                        Text(title, style: tt.titleMedium),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            onReset();
                            setSheetState(() {});
                          },
                          child: const Text('Reset'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      children: builder(setSheetState),
                    ),
                  ),
                ],
              ),
            );
          },
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: tt.labelSmall?.copyWith(
              color:         cs.onSurfaceVariant,
              fontWeight:    FontWeight.w600,
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
  final T      value;
  final String label;
  final Color? color;

  const FilterChipOption({
    required this.value,
    required this.label,
    this.color,
  });
}

class FilterChipGroup<T> extends StatelessWidget {
  final List<FilterChipOption<T>> options;
  final T?                        selected;
  final ValueChanged<T?>          onChanged;

  const FilterChipGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing:    8,
      runSpacing: 8,
      children: [
        _FilterChip(
          label:      'All',
          isSelected: selected == null,
          color:      cs.primary,
          onTap:      () => onChanged(null),
        ),
        for (final opt in options)
          _FilterChip(
            label:      opt.label,
            isSelected: selected == opt.value,
            color:      opt.color ?? cs.primary,
            onTap: () {
              if (selected == opt.value) {
                onChanged(null);
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
  final String             label;
  final Color              color;
  final bool               checked;
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
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap:        () => onChanged(!checked),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width:  22,
              height: 22,
              decoration: BoxDecoration(
                color: checked
                    ? color.withValues(alpha: 0.15)
                    : Colors.transparent,
                border: Border.all(
                  color: checked ? color : cs.outline,
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
                color:      checked ? color : cs.onSurface,
                fontSize:   14,
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
    FilterChipOption(value: 'week',  label: 'Week'),
    FilterChipOption(value: 'month', label: 'Month'),
    FilterChipOption(value: 'year',  label: 'Year'),
  ];

  final String?           selected;
  final ValueChanged<String?> onChanged;

  const FilterDatePreset({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChipGroup<String>(
      options:   presets,
      selected:  selected,
      onChanged: onChanged,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FilterRangeSlider — labelled double range slider
// ─────────────────────────────────────────────────────────────────────────────

class FilterRangeSlider extends StatelessWidget {
  final double                   min;
  final double                   max;
  final double                   currentMin;
  final double                   currentMax;
  final ValueChanged<RangeValues> onChanged;
  final String Function(double)  format;

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
    final tt = Theme.of(context).textTheme;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(format(currentMin),
                style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
            Text(format(currentMax),
                style: tt.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        RangeSlider(
          values:    RangeValues(currentMin, currentMax),
          min:       min,
          max:       max,
          divisions: max > min
              ? ((max - min) / math.max(1, (max - min) / 100))
                  .round()
                  .clamp(1, 200)
              : null,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FilterSearchField — single-line text search
// ─────────────────────────────────────────────────────────────────────────────

class FilterSearchField extends StatefulWidget {
  final String             hint;
  final String             value;
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
      onChanged:  widget.onChanged,
      decoration: InputDecoration(
        hintText:    widget.hint,
        prefixIcon:  const Icon(Icons.search, size: 18),
        suffixIcon:  _controller.text.isNotEmpty
            ? IconButton(
                icon:     const Icon(Icons.close, size: 16),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                },
              )
            : null,
        isDense:        true,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal chip widget
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String      label;
  final bool        isSelected;
  final Color       color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : cs.surfaceContainerHighest,
          border: Border.all(
            color: isSelected ? color : cs.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:      isSelected ? color : cs.onSurfaceVariant,
            fontSize:   13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
