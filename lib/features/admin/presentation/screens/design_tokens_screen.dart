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
            child: SelectableText('Error: $e',
                style: const TextStyle(color: AppColors.lossRed))),
        data: (themes) {
          if (themes.isEmpty) {
            return const Center(
                child: Text('No themes found.',
                    style: TextStyle(color: AppColors.textSecondary)));
          }
          final activeThemeId =
              _selectedThemeId ?? themes.first['id'] as String;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ThemeSelector(
                themes: themes,
                selectedId: activeThemeId,
                onChanged: (id) => setState(() => _selectedThemeId = id),
              ),
              const Divider(color: Colors.white12, height: 1),
              Expanded(child: _TokenList(themeId: activeThemeId)),
            ],
          );
        },
      ),
    );
  }
}

// ── Theme selector ────────────────────────────────────────────────────────────

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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: themes.map((t) {
          final id = t['id'] as String;
          final selected = id == selectedId;
          final available = t['is_available'] as bool? ?? false;
          final isDefault = t['is_default'] as bool? ?? false;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(id),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primaryGold.withValues(alpha: 0.15)
                      : AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: selected ? AppColors.primaryGold : Colors.white12),
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
                      const Text('hidden',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 10)),
                    ],
                    if (isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('default',
                            style: TextStyle(
                                color: AppColors.primaryGold, fontSize: 9)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Token list grouped by group_name ──────────────────────────────────────────

class _TokenList extends ConsumerWidget {
  final String themeId;

  const _TokenList({required this.themeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokensAsync = ref.watch(designTokensAdminProvider(themeId));

    return tokensAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGold)),
      error: (e, _) => Center(
          child: SelectableText('Error: $e',
              style: const TextStyle(color: AppColors.lossRed))),
      data: (tokens) {
        final groups = <String, List<Map<String, dynamic>>>{};
        for (final token in tokens) {
          final group = token['group_name'] as String;
          groups.putIfAbsent(group, () => []).add(token);
        }
        final groupNames = groups.keys.toList();
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 32),
          itemCount: groupNames.length,
          itemBuilder: (context, i) {
            final group = groupNames[i];
            return _GroupSection(
              groupName: group,
              tokens: groups[group]!,
              themeId: themeId,
            );
          },
        );
      },
    );
  }
}

// ── Group section ─────────────────────────────────────────────────────────────

class _GroupSection extends StatelessWidget {
  final String groupName;
  final List<Map<String, dynamic>> tokens;
  final String themeId;

  const _GroupSection({
    required this.groupName,
    required this.tokens,
    required this.themeId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
          child: Text(
            groupName.toUpperCase(),
            style: const TextStyle(
              color: AppColors.primaryGold,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ),
        ...tokens.map((t) => _TokenRow(token: t, themeId: themeId)),
      ],
    );
  }
}

// ── Token row ─────────────────────────────────────────────────────────────────

class _TokenRow extends StatelessWidget {
  final Map<String, dynamic> token;
  final String themeId;

  const _TokenRow({required this.token, required this.themeId});

  String get _rawValue {
    final values = token['design_token_values'] as List?;
    if (values == null || values.isEmpty) return '—';
    return (values.first as Map<String, dynamic>)['value'] as String? ?? '';
  }

  String get _valueId {
    final values = token['design_token_values'] as List?;
    if (values == null || values.isEmpty) return '';
    return (values.first as Map<String, dynamic>)['id'] as String? ?? '';
  }

  String get _refTokenId {
    final values = token['design_token_values'] as List?;
    if (values == null || values.isEmpty) return '';
    return (values.first as Map<String, dynamic>)['references_token_id']
            as String? ??
        '';
  }

  bool get _isColor => token['token_type'] == 'color';
  bool get _isPrimitive => token['tier'] == 'primitive';

  Color? _parseColor(String hex) {
    try {
      return Color(int.parse('0xFF${hex.replaceAll('#', '')}'));
    } catch (_) {
      return null;
    }
  }

  // Returns value with human-readable unit context.
  String _formatValue(String raw, String type) {
    if (raw.isEmpty || raw == '—') return '—';
    switch (type) {
      case 'color':
        return raw;
      case 'spacing':
      case 'radius':
        return '$raw px';
      case 'font_size':
        return '$raw pt';
      case 'font_weight':
        final w = int.tryParse(raw) ?? 0;
        final label = switch (w) {
          100 => 'Thin',
          200 => 'ExtraLight',
          300 => 'Light',
          400 => 'Regular',
          500 => 'Medium',
          600 => 'Semibold',
          700 => 'Bold',
          800 => 'ExtraBold',
          900 => 'Black',
          _ => '',
        };
        return label.isEmpty ? raw : '$raw — $label';
      case 'font_family':
        return raw;
      case 'opacity':
        final pct = ((double.tryParse(raw) ?? 0) * 100).toInt();
        return '$pct%';
      case 'duration_ms':
        return '$raw ms';
      default:
        return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final raw = _rawValue;
    final type = token['token_type'] as String;
    final color = _isColor ? _parseColor(raw) : null;
    final displayValue = _isPrimitive
        ? _formatValue(raw, type)
        : '→ ${token['tier'] == 'semantic' ? 'ref' : raw}';

    return InkWell(
      onTap: () => _showEditSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white10)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Swatch / type icon ──────────────────────────────────────────
            if (_isColor && color != null)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
              )
            else
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: Icon(
                  _iconForType(type),
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            const SizedBox(width: 12),

            // ── Primary label + secondary token name ────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    token['reserved_for'] as String,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        token['token_name'] as String,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: _isPrimitive
                              ? Colors.white10
                              : AppColors.primaryGold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          _isPrimitive ? 'primitive' : 'semantic',
                          style: TextStyle(
                            color: _isPrimitive
                                ? AppColors.textSecondary
                                : AppColors.primaryGold,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // ── Value + chevron ─────────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  displayValue,
                  style: TextStyle(
                    color: _isColor && color != null
                        ? color
                        : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: _isColor ? 'monospace' : null,
                  ),
                ),
                const SizedBox(height: 2),
                const Icon(Icons.chevron_right,
                    size: 14, color: AppColors.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    return switch (type) {
      'font_size' => Icons.format_size,
      'font_weight' => Icons.format_bold,
      'font_family' => Icons.font_download_outlined,
      'spacing' => Icons.space_bar,
      'radius' => Icons.rounded_corner,
      'opacity' => Icons.opacity,
      'duration_ms' => Icons.timer_outlined,
      _ => Icons.data_object,
    };
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _isPrimitive
          ? _EditPrimitiveSheet(
              token: token,
              valueId: _valueId,
              currentValue: _rawValue,
              themeId: themeId,
            )
          : _EditSemanticSheet(
              token: token,
              valueId: _valueId,
              currentRefTokenId: _refTokenId,
              themeId: themeId,
            ),
    );
  }
}

// ── Edit primitive sheet ──────────────────────────────────────────────────────

class _EditPrimitiveSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> token;
  final String valueId;
  final String currentValue;
  final String themeId;

  const _EditPrimitiveSheet({
    required this.token,
    required this.valueId,
    required this.currentValue,
    required this.themeId,
  });

  @override
  ConsumerState<_EditPrimitiveSheet> createState() =>
      _EditPrimitiveSheetState();
}

class _EditPrimitiveSheetState extends ConsumerState<_EditPrimitiveSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.currentValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _isColor => widget.token['token_type'] == 'color';

  Color? get _previewColor {
    if (!_isColor) return null;
    try {
      return Color(int.parse('0xFF${_ctrl.text.replaceAll('#', '')}'));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(tokenValueEditorProvider).isLoading;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_isColor)
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) => Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: _previewColor ?? Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.token['reserved_for'] as String,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.token['token_name'] as String,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _ctrl,
            autofocus: true,
            style: const TextStyle(
                color: AppColors.textPrimary, fontFamily: 'monospace'),
            decoration: InputDecoration(
              labelText: _isColor ? 'Hex value (e.g. #D4AF37)' : 'Value',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.backgroundDark,
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.primaryGold),
              ),
              onPressed: saving
                  ? null
                  : () async {
                      await ref
                          .read(tokenValueEditorProvider.notifier)
                          .updatePrimitive(
                            tokenValueId: widget.valueId,
                            value: _ctrl.text.trim(),
                            themeId: widget.themeId,
                          );
                      if (context.mounted) Navigator.pop(context);
                    },
              child: saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primaryGold))
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Edit semantic sheet ───────────────────────────────────────────────────────

class _EditSemanticSheet extends ConsumerWidget {
  final Map<String, dynamic> token;
  final String valueId;
  final String currentRefTokenId;
  final String themeId;

  const _EditSemanticSheet({
    required this.token,
    required this.valueId,
    required this.currentRefTokenId,
    required this.themeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenType = token['token_type'] as String;
    final primitivesAsync =
        ref.watch(primitiveTokensByTypeProvider(tokenType));
    final saving = ref.watch(tokenValueEditorProvider).isLoading;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            token['reserved_for'] as String,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            token['token_name'] as String,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontFamily: 'monospace'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select the primitive value this token uses:',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          primitivesAsync.when(
            loading: () => const Center(
                child:
                    CircularProgressIndicator(color: AppColors.primaryGold)),
            error: (e, _) => SelectableText('Error: $e',
                style: const TextStyle(color: AppColors.lossRed)),
            data: (primitives) => Column(
              children: primitives.map((p) {
                final id = p['id'] as String;
                final selected = id == currentRefTokenId;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selected
                        ? AppColors.primaryGold
                        : AppColors.textSecondary,
                    size: 18,
                  ),
                  title: Text(
                    p['reserved_for'] as String,
                    style: TextStyle(
                      color: selected
                          ? AppColors.primaryGold
                          : AppColors.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                  subtitle: Text(
                    p['token_name'] as String,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontFamily: 'monospace'),
                  ),
                  onTap: saving
                      ? null
                      : () async {
                          await ref
                              .read(tokenValueEditorProvider.notifier)
                              .updateReference(
                                tokenValueId: valueId,
                                referencesTokenId: id,
                                themeId: themeId,
                              );
                          if (context.mounted) Navigator.pop(context);
                        },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
