// lib/features/admin/presentation/screens/design_tokens_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/features/admin/presentation/providers/design_tokens_admin_providers.dart';

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
            child: CircularProgressIndicator(color: AppColors.primaryGold)),
        error: (e, _) => Center(
            child: SelectableText('Error loading themes: $e',
                style: const TextStyle(color: AppColors.lossRed))),
        data: (themes) {
          if (themes.isEmpty) {
            return const Center(
                child: Text('No themes configured.',
                    style: TextStyle(color: AppColors.textSecondary)));
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
              const Divider(color: Colors.white12, height: 1),
              Expanded(child: _TokenContent(themeId: themeId)),
            ],
          );
        },
      ),
    );
  }
}

// ── Theme selector — wraps on small screens ───────────────────────────────────

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: themes.map((t) {
          final id       = t['id'] as String;
          final selected = id == selectedId;
          final available = t['is_available'] as bool? ?? false;
          final isDefault = t['is_default'] as bool? ?? false;
          return GestureDetector(
            onTap: () => onChanged(id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primaryGold.withValues(alpha: 0.15)
                    : AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: selected ? AppColors.primaryGold : Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t['display_name'] as String,
                    style: TextStyle(
                      color: selected
                          ? AppColors.primaryGold
                          : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (!available) ...[
                    const SizedBox(width: 6),
                    Text('· hidden',
                        style: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.6),
                            fontSize: 10)),
                  ],
                  if (isDefault) ...[
                    const SizedBox(width: 6),
                    Text('· default',
                        style: TextStyle(
                            color: AppColors.primaryGold.withValues(alpha: 0.7),
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

// ── Token content — loads semantic tokens and renders by type ─────────────────

class _TokenContent extends ConsumerWidget {
  final String themeId;

  const _TokenContent({required this.themeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokensAsync = ref.watch(semanticTokensResolvedProvider(themeId));

    return tokensAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGold)),
      error: (e, _) => Center(
          child: SelectableText('Error: $e',
              style: const TextStyle(color: AppColors.lossRed))),
      data: (tokens) {
        final colours    = tokens.where((t) => t['token_type'] == 'color').toList();
        final typography = tokens.where((t) => ['font_size', 'font_weight', 'font_family'].contains(t['token_type'])).toList();
        final spacing    = tokens.where((t) => t['token_type'] == 'spacing').toList();
        final radius     = tokens.where((t) => t['token_type'] == 'radius').toList();
        final opacity    = tokens.where((t) => t['token_type'] == 'opacity').toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (colours.isNotEmpty) ...[
              _sectionHeader('Colours'),
              _ColoursGrid(tokens: colours, themeId: themeId),
              const SizedBox(height: 8),
            ],
            if (typography.isNotEmpty) ...[
              _sectionHeader('Typography'),
              _TypographyList(tokens: typography, themeId: themeId),
              const SizedBox(height: 8),
            ],
            if (spacing.isNotEmpty) ...[
              _sectionHeader('Spacing'),
              _SpacingList(tokens: spacing, themeId: themeId),
              const SizedBox(height: 8),
            ],
            if (radius.isNotEmpty) ...[
              _sectionHeader('Radius'),
              _RadiusList(tokens: radius, themeId: themeId),
              const SizedBox(height: 8),
            ],
            if (opacity.isNotEmpty) ...[
              _sectionHeader('Opacity'),
              _OpacityList(tokens: opacity, themeId: themeId),
            ],
          ],
        );
      },
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppColors.primaryGold,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      );
}

// ── Colours grid ──────────────────────────────────────────────────────────────

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
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: tokens.map((t) {
        final hex   = t['resolved_value'] as String?;
        final color = _parse(hex);
        return GestureDetector(
          onTap: () => _showColourPicker(context, t),
          child: Container(
            width: (MediaQuery.of(context).size.width - 52) / 3,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Large colour swatch
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: color ?? Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: color == null
                      ? const Center(
                          child: Icon(Icons.help_outline,
                              color: AppColors.textSecondary, size: 16))
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  t['reserved_for'] as String,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  hex ?? 'Not set',
                  style: TextStyle(
                    color: color ?? AppColors.textSecondary,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showColourPicker(BuildContext context, Map<String, dynamic> token) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ColourPickerSheet(token: token, themeId: themeId),
    );
  }
}

// ── Typography list ───────────────────────────────────────────────────────────

class _TypographyList extends StatelessWidget {
  final List<Map<String, dynamic>> tokens;
  final String themeId;

  const _TypographyList({required this.tokens, required this.themeId});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: tokens.asMap().entries.map((entry) {
          final i = entry.key;
          final t = entry.value;
          return Column(
            children: [
              _TypographyRow(token: t, themeId: themeId),
              if (i < tokens.length - 1)
                const Divider(height: 1, color: Colors.white10),
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

  TextStyle _sampleStyle() {
    final type  = token['token_type'] as String;
    final value = token['resolved_value'] as String? ?? '';
    switch (type) {
      case 'font_size':
        return TextStyle(
          color: AppColors.textPrimary,
          fontSize: double.tryParse(value) ?? 14,
        );
      case 'font_weight':
        final w = int.tryParse(value) ?? 400;
        return TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.values[(w ~/ 100) - 1],
        );
      case 'font_family':
        return TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontFamily: value,
        );
      default:
        return const TextStyle(color: AppColors.textPrimary, fontSize: 14);
    }
  }

  String _valueLabel() {
    final type  = token['token_type'] as String;
    final value = token['resolved_value'] as String? ?? '';
    switch (type) {
      case 'font_size':   return '$value pt';
      case 'font_weight':
        final w = int.tryParse(value) ?? 400;
        final names = {100:'Thin',200:'ExtraLight',300:'Light',400:'Regular',
          500:'Medium',600:'Semibold',700:'Bold',800:'ExtraBold',900:'Black'};
        return names[w] ?? value;
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
                  Text(
                    token['reserved_for'] as String,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Text('The quick brown fox', style: _sampleStyle()),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _valueLabel(),
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _GenericPickerSheet(token: token, themeId: themeId),
    );
  }
}

// ── Spacing list ──────────────────────────────────────────────────────────────

class _SpacingList extends StatelessWidget {
  final List<Map<String, dynamic>> tokens;
  final String themeId;

  const _SpacingList({required this.tokens, required this.themeId});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: tokens.asMap().entries.map((entry) {
          final i = entry.key;
          final t = entry.value;
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
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  width: (px * 5).clamp(4, 200),
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGold
                                        .withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('${px.toInt()} px',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              if (i < tokens.length - 1)
                const Divider(height: 1, color: Colors.white10),
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
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _GenericPickerSheet(token: token, themeId: themeId),
    );
  }
}

// ── Radius list ───────────────────────────────────────────────────────────────

class _RadiusList extends StatelessWidget {
  final List<Map<String, dynamic>> tokens;
  final String themeId;

  const _RadiusList({required this.tokens, required this.themeId});

  @override
  Widget build(BuildContext context) {
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
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGold
                                        .withValues(alpha: 0.15),
                                    borderRadius:
                                        BorderRadius.circular(px),
                                    border: Border.all(
                                        color: AppColors.primaryGold
                                            .withValues(alpha: 0.5)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text('${px.toInt()} px radius',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              if (i < tokens.length - 1)
                const Divider(height: 1, color: Colors.white10),
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
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _GenericPickerSheet(token: token, themeId: themeId),
    );
  }
}

// ── Opacity list ──────────────────────────────────────────────────────────────

class _OpacityList extends StatelessWidget {
  final List<Map<String, dynamic>> tokens;
  final String themeId;

  const _OpacityList({required this.tokens, required this.themeId});

  @override
  Widget build(BuildContext context) {
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
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGold
                                        .withValues(alpha: val),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                        color: Colors.white24),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text('$pct%',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              if (i < tokens.length - 1)
                const Divider(height: 1, color: Colors.white10),
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
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _GenericPickerSheet(token: token, themeId: themeId),
    );
  }
}

// ── Colour picker sheet ───────────────────────────────────────────────────────

class _ColourPickerSheet extends ConsumerWidget {
  final Map<String, dynamic> token;
  final String themeId;

  const _ColourPickerSheet({required this.token, required this.themeId});

  Color? _parse(String? hex) {
    if (hex == null) return null;
    try {
      return Color(int.parse('0xFF${hex.replaceAll('#', '')}'));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primitivesAsync =
        ref.watch(primitiveTokensWithValuesProvider('color', themeId));
    final saving = ref.watch(tokenValueEditorProvider).isLoading;
    final currentRefId = token['references_token_id'] as String? ?? '';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
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
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tap a colour to assign it:',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: primitivesAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primaryGold)),
              error: (e, _) => Center(
                  child: SelectableText('Error: $e',
                      style:
                          const TextStyle(color: AppColors.lossRed))),
              data: (primitives) => GridView.builder(
                controller: controller,
                padding: const EdgeInsets.all(16),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
                itemCount: primitives.length,
                itemBuilder: (_, i) {
                  final p       = primitives[i];
                  final hex     = p['value'] as String?;
                  final color   = _parse(hex);
                  final id      = p['id'] as String;
                  final selected = id == currentRefId;
                  return GestureDetector(
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
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: color ?? Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? AppColors.textPrimary
                                      : Colors.white24,
                                  width: selected ? 3 : 1,
                                ),
                              ),
                            ),
                            if (selected)
                              const Icon(Icons.check,
                                  color: Colors.white, size: 20),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hex ?? '—',
                          style: TextStyle(
                            color: color ?? AppColors.textSecondary,
                            fontSize: 9,
                            fontFamily: 'monospace',
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

// ── Generic picker sheet (typography, spacing, radius, opacity) ───────────────

class _GenericPickerSheet extends ConsumerWidget {
  final Map<String, dynamic> token;
  final String themeId;

  const _GenericPickerSheet({required this.token, required this.themeId});

  String _formatValue(String? raw, String type) {
    if (raw == null || raw.isEmpty) return '—';
    switch (type) {
      case 'font_size':   return '$raw pt';
      case 'font_weight':
        final w = int.tryParse(raw) ?? 400;
        const names = {100:'Thin',200:'ExtraLight',300:'Light',400:'Regular',
          500:'Medium',600:'Semibold',700:'Bold',800:'ExtraBold',900:'Black'};
        return names[w] ?? raw;
      case 'font_family': return raw;
      case 'spacing':
      case 'radius':      return '$raw px';
      case 'opacity':
        final pct = ((double.tryParse(raw) ?? 0) * 100).toInt();
        return '$pct%';
      default:            return raw;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenType     = token['token_type'] as String;
    final primitivesAsync =
        ref.watch(primitiveTokensWithValuesProvider(tokenType, themeId));
    final saving        = ref.watch(tokenValueEditorProvider).isLoading;
    final currentRefId  = token['references_token_id'] as String? ?? '';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
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
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Select a value:',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: primitivesAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primaryGold)),
              error: (e, _) => Center(
                  child: SelectableText('Error: $e',
                      style:
                          const TextStyle(color: AppColors.lossRed))),
              data: (primitives) => ListView.builder(
                controller: controller,
                itemCount: primitives.length,
                itemBuilder: (_, i) {
                  final p        = primitives[i];
                  final id       = p['id'] as String;
                  final value    = p['value'] as String?;
                  final selected = id == currentRefId;
                  final label    = _formatValue(value, tokenType);

                  return ListTile(
                    leading: Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: selected
                          ? AppColors.primaryGold
                          : AppColors.textSecondary,
                      size: 20,
                    ),
                    title: Text(
                      label,
                      style: TextStyle(
                        color: selected
                            ? AppColors.primaryGold
                            : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
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
