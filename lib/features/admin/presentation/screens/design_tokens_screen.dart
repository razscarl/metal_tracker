// lib/features/admin/presentation/screens/design_tokens_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/features/admin/presentation/providers/design_tokens_admin_providers.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────

class DesignTokensScreen extends ConsumerStatefulWidget {
  const DesignTokensScreen({super.key});

  @override
  ConsumerState<DesignTokensScreen> createState() => _DesignTokensScreenState();
}

class _DesignTokensScreenState extends ConsumerState<DesignTokensScreen> {
  String? _selectedThemeId;

  @override
  Widget build(BuildContext context) {
    final themesAsync = ref.watch(allDesignThemesProvider);

    return AppScaffold(
      title: 'Design Tokens',
      body: themesAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: SelectableText('Error loading themes: $e',
                style: TextStyle(color: Theme.of(context).colorScheme.error))),
        data: (themes) {
          if (themes.isEmpty) {
            return Center(
                child: Text('No themes configured.',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)));
          }
          final themeId =
              _selectedThemeId ?? themes.first['id'] as String;
          return Column(
            children: [
              _ThemeSelector(
                themes: themes,
                selectedId: themeId,
                onChanged: (id) => setState(() => _selectedThemeId = id),
              ),
              const Divider(height: 1),
              Expanded(child: _TokenContent(themeId: themeId)),
            ],
          );
        },
      ),
    );
  }
}

// ─── Theme selector ───────────────────────────────────────────────────────────

class _ThemeSelector extends StatelessWidget {
  final List<Map<String, dynamic>> themes;
  final String selectedId;
  final ValueChanged<String> onChanged;

  const _ThemeSelector({
    required this.themes,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: themes.map((t) {
          final id        = t['id'] as String;
          final selected  = id == selectedId;
          final available = t['is_available'] as bool? ?? false;
          final isDefault = t['is_default'] as bool? ?? false;
          return GestureDetector(
            onTap: () => onChanged(id),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: selected
                    ? cs.primaryContainer
                    : cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: selected ? cs.primary : cs.outlineVariant),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t['display_name'] as String,
                    style: TextStyle(
                      color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (!available) ...[
                    const SizedBox(width: 5),
                    Text('· hidden',
                        style: TextStyle(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                            fontSize: 10)),
                  ],
                  if (isDefault) ...[
                    const SizedBox(width: 5),
                    Text('· default',
                        style: TextStyle(
                            color: cs.primary.withValues(alpha: 0.7),
                            fontSize: 10)),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Content ──────────────────────────────────────────────────────────────────

class _TokenContent extends ConsumerWidget {
  final String themeId;
  const _TokenContent({required this.themeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokensAsync     = ref.watch(semanticTokensResolvedProvider(themeId));
    final textStylesAsync = ref.watch(textStylesAdminProvider(themeId));

    return tokensAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator()),
      error: (e, _) => Center(
          child: SelectableText('Error: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.error))),
      data: (tokens) {
        final colours  = tokens.where((t) => t['token_type'] == 'color').toList();
        final sizes    = tokens.where((t) => t['token_type'] == 'font_size').toList();
        final weights  = tokens.where((t) => t['token_type'] == 'font_weight').toList();
        final families = tokens.where((t) => t['token_type'] == 'font_family').toList();
        final spacing  = tokens.where((t) => t['token_type'] == 'spacing').toList();
        final radius   = tokens.where((t) => t['token_type'] == 'radius').toList();
        final opacity  = tokens.where((t) => t['token_type'] == 'opacity').toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            // ── Text Styles ─────────────────────────────────────────────────
            textStylesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (styles) => styles.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader('Text Styles', context),
                        _TextStylesSection(
                            styles: styles, themeId: themeId),
                        const SizedBox(height: 8),
                      ],
                    ),
            ),

            // ── Colours ─────────────────────────────────────────────────────
            if (colours.isNotEmpty) ...[
              _sectionHeader('Colours', context),
              _ColoursGrid(tokens: colours, themeId: themeId),
              const SizedBox(height: 8),
            ],

            // ── Typography ──────────────────────────────────────────────────
            if (sizes.isNotEmpty || weights.isNotEmpty || families.isNotEmpty) ...[
              _sectionHeader('Typography', context),
              _TypographyList(
                sizes: sizes,
                weights: weights,
                families: families,
                themeId: themeId,
              ),
              const SizedBox(height: 8),
            ],

            // ── Spacing ─────────────────────────────────────────────────────
            if (spacing.isNotEmpty) ...[
              _sectionHeader('Spacing', context),
              _SpacingList(tokens: spacing, themeId: themeId),
              const SizedBox(height: 8),
            ],

            // ── Radius ──────────────────────────────────────────────────────
            if (radius.isNotEmpty) ...[
              _sectionHeader('Radius', context),
              _RadiusList(tokens: radius, themeId: themeId),
              const SizedBox(height: 8),
            ],

            // ── Opacity ─────────────────────────────────────────────────────
            if (opacity.isNotEmpty) ...[
              _sectionHeader('Opacity', context),
              _OpacityList(tokens: opacity, themeId: themeId),
            ],
          ],
        );
      },
    );
  }

  Widget _sectionHeader(String title, BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      );
}

// ─── Text Styles section ──────────────────────────────────────────────────────

class _TextStylesSection extends StatelessWidget {
  final List<Map<String, dynamic>> styles;
  final String themeId;

  const _TextStylesSection({required this.styles, required this.themeId});

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      return Color(int.parse('0xFF${hex.replaceAll('#', '')}'));
    } catch (_) {
      return null;
    }
  }

  TextStyle _textStyle(Map<String, dynamic> style, BuildContext context) {
    final color  = _parseColor(style['color_value'] as String?) ?? Theme.of(context).colorScheme.onSurface;
    final size   = double.tryParse(style['font_size'] as String? ?? '') ?? 14;
    final weight = int.tryParse(style['font_weight'] as String? ?? '') ?? 400;
    return TextStyle(
      color: color,
      fontSize: size,
      fontWeight: FontWeight.values[(weight ~/ 100).clamp(1, 9) - 1],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Column(
        children: styles.asMap().entries.map((entry) {
          final i     = entry.key;
          final style = entry.value;
          return Column(
            children: [
              InkWell(
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (_) => _TextStyleEditorSheet(
                      style: style, themeId: themeId),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              style['display_name'] as String,
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('The quick brown fox',
                                style: _textStyle(style, context)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          size: 16, color: cs.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
              if (i < styles.length - 1)
                const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Text Style Editor sheet ──────────────────────────────────────────────────

class _TextStyleEditorSheet extends ConsumerWidget {
  final Map<String, dynamic> style;
  final String themeId;

  const _TextStyleEditorSheet({required this.style, required this.themeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorsAsync   = ref.watch(semanticColorTokensProvider(themeId));
    final sizesAsync    = ref.watch(semanticTokensByTypeProvider('font_size', themeId));
    final weightsAsync  = ref.watch(semanticTokensByTypeProvider('font_weight', themeId));
    final saving        = ref.watch(textStyleEditorProvider).isLoading;

    Color? _parse(String? hex) {
      if (hex == null) return null;
      try {
        return Color(int.parse('0xFF${hex.replaceAll('#', '')}'));
      } catch (_) {
        return null;
      }
    }

    TextStyle _previewStyle() {
      final color  = _parse(style['color_value'] as String?) ?? Theme.of(context).colorScheme.onSurface;
      final size   = double.tryParse(style['font_size'] as String? ?? '') ?? 14;
      final weight = int.tryParse(style['font_weight'] as String? ?? '') ?? 400;
      return TextStyle(
        color: color,
        fontSize: size.clamp(10, 32),
        fontWeight: FontWeight.values[(weight ~/ 100).clamp(1, 9) - 1],
      );
    }

    Future<void> save({
      String? colorTokenId,
      String? fontSizeTokenId,
      String? fontWeightTokenId,
    }) async {
      await ref.read(textStyleEditorProvider.notifier).updateToken(
            textStyleId:      style['id'] as String,
            themeId:          themeId,
            colorTokenId:      colorTokenId,
            fontSizeTokenId:   fontSizeTokenId,
            fontWeightTokenId: fontWeightTokenId,
          );
      if (context.mounted) Navigator.pop(context);
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, controller) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + preview
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(style['display_name'] as String,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: Text('The quick brown fox', style: _previewStyle()),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.all(16),
              children: [
                // ── Colour ──────────────────────────────────────────────────
                _propHeader('Colour'),
                colorsAsync.when(
                  loading: () => const CircularProgressIndicator(
                      color: AppColors.primaryGold),
                  error: (e, _) => SelectableText('$e',
                      style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  data: (colors) => _ColorRow(
                    tokens: colors,
                    selectedId: style['color_token_id'] as String?,
                    onSelect: (id) => save(colorTokenId: id),
                    saving: saving,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Size ────────────────────────────────────────────────────
                _propHeader('Size'),
                sizesAsync.when(
                  loading: () => const CircularProgressIndicator(
                      color: AppColors.primaryGold),
                  error: (e, _) => SelectableText('$e',
                      style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  data: (sizes) => _FontSizeRow(
                    tokens: sizes,
                    selectedId: style['font_size_token_id'] as String?,
                    onSelect: (id) => save(fontSizeTokenId: id),
                    saving: saving,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Weight ───────────────────────────────────────────────────
                _propHeader('Weight'),
                weightsAsync.when(
                  loading: () => const CircularProgressIndicator(
                      color: AppColors.primaryGold),
                  error: (e, _) => SelectableText('$e',
                      style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  data: (weights) => _FontWeightRow(
                    tokens: weights,
                    selectedId: style['font_weight_token_id'] as String?,
                    onSelect: (id) => save(fontWeightTokenId: id),
                    saving: saving,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _propHeader(String label) {
    // context is available via build — access theme inline
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// Helper: horizontal colour chip row
class _ColorRow extends StatelessWidget {
  final List<Map<String, dynamic>> tokens;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final bool saving;

  const _ColorRow({
    required this.tokens,
    required this.selectedId,
    required this.onSelect,
    required this.saving,
  });

  Color? _parse(String? hex) {
    if (hex == null) return null;
    try {
      return Color(int.parse('0xFF${hex.replaceAll('#', '')}'));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: tokens.map((t) {
        final id       = t['id'] as String;
        final selected = id == selectedId;
        final color    = _parse(t['resolved_value'] as String?);
        return GestureDetector(
          onTap: saving ? null : () => onSelect(id),
          child: Tooltip(
            message: t['reserved_for'] as String,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color ?? Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? cs.onSurface : cs.outlineVariant,
                      width: selected ? 3 : 1,
                    ),
                  ),
                ),
                if (selected)
                  Icon(Icons.check, color: cs.onSurface, size: 16),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// Helper: font size chips
class _FontSizeRow extends StatelessWidget {
  final List<Map<String, dynamic>> tokens;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final bool saving;

  const _FontSizeRow({
    required this.tokens,
    required this.selectedId,
    required this.onSelect,
    required this.saving,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tokens.map((t) {
        final id       = t['id'] as String;
        final selected = id == selectedId;
        final size     = double.tryParse(t['resolved_value'] as String? ?? '') ?? 14;
        return GestureDetector(
          onTap: saving ? null : () => onSelect(id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? cs.primaryContainer : cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: selected ? cs.primary : cs.outlineVariant),
            ),
            child: Text(
              'Aa',
              style: TextStyle(
                color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                fontSize: size.clamp(10, 22),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// Helper: font weight chips (MS Word style — shows sample in that weight)
class _FontWeightRow extends StatelessWidget {
  final List<Map<String, dynamic>> tokens;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final bool saving;

  const _FontWeightRow({
    required this.tokens,
    required this.selectedId,
    required this.onSelect,
    required this.saving,
  });

  String _weightName(int w) {
    const n = {
      100: 'Thin', 200: 'ExtraLight', 300: 'Light',
      400: 'Regular', 500: 'Medium',  600: 'Semibold',
      700: 'Bold',    800: 'ExtraBold', 900: 'Black'
    };
    return n[w] ?? '$w';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: tokens.map((t) {
        final id       = t['id'] as String;
        final selected = id == selectedId;
        final w        = int.tryParse(t['resolved_value'] as String? ?? '') ?? 400;
        final fw       = FontWeight.values[(w ~/ 100).clamp(1, 9) - 1];
        return GestureDetector(
          onTap: saving ? null : () => onSelect(id),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? cs.primaryContainer : cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: selected ? cs.primary : cs.outlineVariant),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'The quick brown fox',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 13,
                      fontWeight: fw,
                    ),
                  ),
                ),
                Text(
                  _weightName(w),
                  style: TextStyle(
                    color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.check, size: 14, color: cs.onPrimaryContainer),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Colours grid ─────────────────────────────────────────────────────────────

class _ColoursGrid extends StatelessWidget {
  final List<Map<String, dynamic>> tokens;
  final String themeId;

  const _ColoursGrid({required this.tokens, required this.themeId});

  Color? _parse(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      return Color(int.parse('0xFF${hex.replaceAll('#', '')}'));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemW = (MediaQuery.of(context).size.width - 52) / 3;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: tokens.map((t) {
        final hex   = t['resolved_value'] as String?;
        final color = _parse(hex);
        return GestureDetector(
          onTap: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (_) => _ColourPickerSheet(token: t, themeId: themeId),
          ),
          child: Builder(builder: (context) {
            final cs = Theme.of(context).colorScheme;
            return Container(
            width: itemW,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: color ?? Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: color == null
                      ? Center(
                          child: Icon(Icons.help_outline,
                              color: cs.onSurfaceVariant, size: 16))
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  t['reserved_for'] as String,
                  style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 11,
                      fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  hex ?? 'Not set',
                  style: TextStyle(
                      color: color ?? cs.onSurfaceVariant,
                      fontSize: 10,
                      fontFamily: 'monospace'),
                ),
              ],
            ),
          );}),
        );
      }).toList(),
    );
  }
}

// ─── Colour picker sheet — full HSV wheel + palette ───────────────────────────

class _ColourPickerSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> token;
  final String themeId;

  const _ColourPickerSheet({required this.token, required this.themeId});

  @override
  ConsumerState<_ColourPickerSheet> createState() => _ColourPickerSheetState();
}

class _ColourPickerSheetState extends ConsumerState<_ColourPickerSheet> {
  late Color _pickerColor;
  final _hexController = TextEditingController();

  Color? _parse(String? hex) {
    if (hex == null) return null;
    try {
      return Color(int.parse('0xFF${hex.replaceAll('#', '')}'));
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _pickerColor =
        _parse(widget.token['resolved_value'] as String?) ?? AppColors.primaryGold;
    _hexController.text =
        (widget.token['resolved_value'] as String? ?? '#000000')
            .replaceAll('#', '');
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _onPickerChanged(Color color) {
    setState(() {
      _pickerColor = color;
      _hexController.text =
          '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
    });
  }

  String get _currentHex =>
      '#${_pickerColor.value.toRadixString(16).substring(2).toUpperCase()}';

  Future<void> _applyToNearestPrimitive(
      List<Map<String, dynamic>> primitives) async {
    // Find exact match by hex
    String? matchId;
    for (final p in primitives) {
      final pHex = (p['value'] as String? ?? '').toUpperCase();
      if (pHex == _currentHex) {
        matchId = p['id'] as String;
        break;
      }
    }
    if (matchId != null) {
      await ref.read(tokenValueEditorProvider.notifier).updateReference(
            tokenValueId: widget.token['value_id'] as String,
            referencesTokenId: matchId,
            themeId: widget.themeId,
          );
      if (mounted) Navigator.pop(context);
    } else {
      // No exact match — show which palette colour is nearest
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'This colour is not in the palette. Pick from the swatches below or ask your developer to add it.'),
            
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primitivesAsync =
        ref.watch(primitiveTokensWithValuesProvider('color', widget.themeId));
    final saving = ref.watch(tokenValueEditorProvider).isLoading;

    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, controller) => Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _pickerColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.outlineVariant),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.token['reserved_for'] as String,
                    style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),

          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.all(16),
              children: [
                // ── HSV colour wheel ─────────────────────────────────────────
                ColorPicker(
                  pickerColor: _pickerColor,
                  onColorChanged: _onPickerChanged,
                  enableAlpha: false,
                  labelTypes: const [],
                  pickerAreaHeightPercent: 0.55,
                  displayThumbColor: true,
                  hexInputBar: false,
                ),

                // ── Hex input ────────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _pickerColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _hexController,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[#0-9a-fA-F]')),
                          LengthLimitingTextInputFormatter(7),
                        ],
                        style: TextStyle(
                            color: cs.onSurface,
                            fontFamily: 'monospace'),
                        decoration: InputDecoration(
                          labelText: 'Hex',
                          labelStyle:
                              TextStyle(color: cs.onSurfaceVariant),
                          prefixText: '#',
                          prefixStyle:
                              TextStyle(color: cs.onSurfaceVariant),
                        ),
                        onChanged: (val) {
                          final c = _parse('#$val');
                          if (c != null) setState(() => _pickerColor = c);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Palette swatches ─────────────────────────────────────────
                Text(
                  'PALETTE — tap to apply directly',
                  style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 10,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                primitivesAsync.when(
                  loading: () => const CircularProgressIndicator(
                      color: AppColors.primaryGold),
                  error: (e, _) => SelectableText('Error: $e',
                      style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  data: (primitives) {
                    final currentRefId =
                        widget.token['references_token_id'] as String? ?? '';
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: primitives.map((p) {
                        final id       = p['id'] as String;
                        final hex      = p['value'] as String?;
                        final color    = _parse(hex);
                        final selected = id == currentRefId;
                        return GestureDetector(
                          onTap: saving
                              ? null
                              : () async {
                                  await ref
                                      .read(tokenValueEditorProvider.notifier)
                                      .updateReference(
                                        tokenValueId: widget.token['value_id']
                                            as String,
                                        referencesTokenId: id,
                                        themeId: widget.themeId,
                                      );
                                  if (context.mounted) Navigator.pop(context);
                                },
                          child: Tooltip(
                            message: hex ?? '—',
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selected
                                          ? cs.onSurface
                                          : cs.outlineVariant,
                                      width: selected ? 3 : 1,
                                    ),
                                  ),
                                ),
                                if (selected)
                                  const Icon(Icons.check,
                                      color: Colors.white, size: 16),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // ── Apply button ─────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      side: BorderSide(color: cs.primary),
                    ),
                    onPressed: saving
                        ? null
                        : () async {
                            final pAsync = ref.read(
                                primitiveTokensWithValuesProvider(
                                    'color', widget.themeId));
                            final primitives =
                                pAsync.valueOrNull ?? [];
                            await _applyToNearestPrimitive(primitives);
                          },
                    child: saving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Apply colour'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Typography list ──────────────────────────────────────────────────────────

class _TypographyList extends ConsumerWidget {
  final List<Map<String, dynamic>> sizes;
  final List<Map<String, dynamic>> weights;
  final List<Map<String, dynamic>> families;
  final String themeId;

  const _TypographyList({
    required this.sizes,
    required this.weights,
    required this.families,
    required this.themeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = [...sizes, ...weights, ...families];
    return Card(
      child: Column(
        children: all.asMap().entries.map((entry) {
          final i = entry.key;
          final t = entry.value;
          return Column(
            children: [
              _TypographyRow(token: t, themeId: themeId),
              if (i < all.length - 1)
                const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _TypographyRow extends StatelessWidget {
  final Map<String, dynamic> token;
  final String themeId;

  const _TypographyRow({required this.token, required this.themeId});

  TextStyle _sampleStyle(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final type  = token['token_type'] as String;
    final value = token['resolved_value'] as String? ?? '';
    switch (type) {
      case 'font_size':
        return TextStyle(
            color: cs.onSurface,
            fontSize: (double.tryParse(value) ?? 14).clamp(10, 28));
      case 'font_weight':
        final w = int.tryParse(value) ?? 400;
        return TextStyle(
            color: cs.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.values[(w ~/ 100).clamp(1, 9) - 1]);
      case 'font_family':
        return TextStyle(color: cs.onSurface, fontSize: 14, fontFamily: value);
      default:
        return TextStyle(color: cs.onSurface, fontSize: 14);
    }
  }

  String _valueLabel() {
    final type  = token['token_type'] as String;
    final value = token['resolved_value'] as String? ?? '';
    switch (type) {
      case 'font_size':   return '$value pt';
      case 'font_weight':
        final w = int.tryParse(value) ?? 400;
        const n = {100:'Thin',200:'ExtraLight',300:'Light',400:'Regular',
          500:'Medium',600:'Semibold',700:'Bold',800:'ExtraBold',900:'Black'};
        return n[w] ?? value;
      case 'font_family': return value;
      default:            return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showPicker(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(token['reserved_for'] as String,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11)),
                  const SizedBox(height: 6),
                  Text('The quick brown fox', style: _sampleStyle(context)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(_valueLabel(),
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right,
                size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _TypographyPickerSheet(token: token, themeId: themeId),
    );
  }
}

// ─── Typography picker — MS Word / Google Docs style ─────────────────────────

class _TypographyPickerSheet extends ConsumerWidget {
  final Map<String, dynamic> token;
  final String themeId;

  const _TypographyPickerSheet({required this.token, required this.themeId});

  String _formatValue(String? raw, String type) {
    if (raw == null) return '—';
    switch (type) {
      case 'font_size':
        return '$raw pt';
      case 'font_weight':
        final w = int.tryParse(raw) ?? 400;
        const n = {100:'Thin',200:'ExtraLight',300:'Light',400:'Regular',
          500:'Medium',600:'Semibold',700:'Bold',800:'ExtraBold',900:'Black'};
        return n[w] ?? raw;
      case 'font_family':
        return raw;
      default:
        return raw;
    }
  }

  TextStyle _previewStyle(String? raw, String type, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (type) {
      case 'font_size':
        return TextStyle(
            color: cs.onSurface,
            fontSize: (double.tryParse(raw ?? '') ?? 14).clamp(10, 28));
      case 'font_weight':
        final w = int.tryParse(raw ?? '') ?? 400;
        return TextStyle(
            color: cs.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.values[(w ~/ 100).clamp(1, 9) - 1]);
      case 'font_family':
        return TextStyle(color: cs.onSurface, fontSize: 15, fontFamily: raw);
      default:
        return TextStyle(color: cs.onSurface, fontSize: 15);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs            = Theme.of(context).colorScheme;
    final tokenType    = token['token_type'] as String;
    final primitivesAsync =
        ref.watch(primitiveTokensWithValuesProvider(tokenType, themeId));
    final saving       = ref.watch(tokenValueEditorProvider).isLoading;
    final currentRefId = token['references_token_id'] as String? ?? '';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      maxChildSize: 0.9,
      builder: (_, controller) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  token['reserved_for'] as String,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text('Select a value:',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: primitivesAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primaryGold)),
              error: (e, _) => Center(
                  child: SelectableText('Error: $e',
                      style: TextStyle(color: Theme.of(context).colorScheme.error))),
              data: (primitives) => ListView.builder(
                controller: controller,
                itemCount: primitives.length,
                itemBuilder: (_, i) {
                  final p        = primitives[i];
                  final id       = p['id'] as String;
                  final value    = p['value'] as String?;
                  final selected = id == currentRefId;

                  return InkWell(
                    onTap: saving
                        ? null
                        : () async {
                            await ref
                                .read(tokenValueEditorProvider.notifier)
                                .updateReference(
                                  tokenValueId:
                                      token['value_id'] as String,
                                  referencesTokenId: id,
                                  themeId: themeId,
                                );
                            if (context.mounted) Navigator.pop(context);
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: selected
                            ? cs.primaryContainer.withValues(alpha: 0.4)
                            : Colors.transparent,
                        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'The quick brown fox',
                              style: _previewStyle(value, tokenType, context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _formatValue(value, tokenType),
                            style: TextStyle(
                              color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            selected
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: selected ? cs.primary : cs.onSurfaceVariant,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Spacing list ─────────────────────────────────────────────────────────────

class _SpacingList extends StatelessWidget {
  final List<Map<String, dynamic>> tokens;
  final String themeId;
  const _SpacingList({required this.tokens, required this.themeId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Column(
        children: tokens.asMap().entries.map((entry) {
          final i  = entry.key;
          final t  = entry.value;
          final px = double.tryParse(t['resolved_value'] as String? ?? '') ?? 0;
          return Column(
            children: [
              InkWell(
                onTap: () => _showPicker(context, t),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t['reserved_for'] as String,
                                style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 11)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  width: (px * 5).clamp(4.0, 200.0),
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: cs.primary.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('${px.toInt()} px',
                                    style: TextStyle(
                                        color: cs.onSurfaceVariant,
                                        fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          size: 16, color: cs.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
              if (i < tokens.length - 1)
                const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showPicker(BuildContext context, Map<String, dynamic> token) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _TypographyPickerSheet(token: token, themeId: themeId),
    );
  }
}

// ─── Radius list ──────────────────────────────────────────────────────────────

class _RadiusList extends StatelessWidget {
  final List<Map<String, dynamic>> tokens;
  final String themeId;
  const _RadiusList({required this.tokens, required this.themeId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Column(
        children: tokens.asMap().entries.map((entry) {
          final i  = entry.key;
          final t  = entry.value;
          final px = double.tryParse(t['resolved_value'] as String? ?? '') ?? 0;
          return Column(
            children: [
              InkWell(
                onTap: () => _showPicker(context, t),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t['reserved_for'] as String,
                                style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 11)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: cs.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(px),
                                    border: Border.all(
                                        color: cs.primary.withValues(alpha: 0.5)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text('${px.toInt()} px radius',
                                    style: TextStyle(
                                        color: cs.onSurfaceVariant,
                                        fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          size: 16, color: cs.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
              if (i < tokens.length - 1)
                const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showPicker(BuildContext context, Map<String, dynamic> token) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _TypographyPickerSheet(token: token, themeId: themeId),
    );
  }
}

// ─── Opacity list ─────────────────────────────────────────────────────────────

class _OpacityList extends StatelessWidget {
  final List<Map<String, dynamic>> tokens;
  final String themeId;
  const _OpacityList({required this.tokens, required this.themeId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Column(
        children: tokens.asMap().entries.map((entry) {
          final i   = entry.key;
          final t   = entry.value;
          final val = double.tryParse(t['resolved_value'] as String? ?? '') ?? 0;
          final pct = (val * 100).toInt();
          return Column(
            children: [
              InkWell(
                onTap: () => _showPicker(context, t),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t['reserved_for'] as String,
                                style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 11)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: cs.primary.withValues(alpha: val),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: cs.outlineVariant),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text('$pct%',
                                    style: TextStyle(
                                        color: cs.onSurfaceVariant,
                                        fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          size: 16, color: cs.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
              if (i < tokens.length - 1)
                const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showPicker(BuildContext context, Map<String, dynamic> token) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _TypographyPickerSheet(token: token, themeId: themeId),
    );
  }
}
