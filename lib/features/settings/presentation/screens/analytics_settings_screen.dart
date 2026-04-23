import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/features/settings/data/models/user_analytics_settings_model.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_prefs_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Analytics tolerance settings.
///
/// Set [embedded] = true when shown inside settings_screen (no AppScaffold).
/// Set [embedded] = false (default) when opened as a standalone screen.
class AnalyticsSettingsScreen extends ConsumerWidget {
  final bool embedded;

  const AnalyticsSettingsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(userAnalyticsSettingsNotifierProvider);

    final body = settingsAsync.when(
      data: (settings) => _buildContent(context, ref, settings),
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
            child: CircularProgressIndicator(color: AppColors.primaryGold)),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error: $e',
            style: const TextStyle(color: AppColors.error, fontSize: 13)),
      ),
    );

    if (embedded) return body;
    return AppScaffold(
        title: 'Analytics Settings', body: ListView(children: [body]));
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, UserAnalyticsSettings s) {
    Future<void> save(UserAnalyticsSettings updated) async {
      try {
        await ref
            .read(userAnalyticsSettingsNotifierProvider.notifier)
            .save(updated);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: AppColors.error,
          ));
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Gold-Silver Ratio ─────────────────────────────────────────────
          _AnalyticsCard(
            title: 'Gold-Silver Ratio',
            color: AppColors.primaryGold,
            children: [
              _NumberTile(
                label: 'Low Ratio',
                hint: 'GSR at or below → "${s.gsrLowText}"',
                value: s.gsrLowMark,
                suffix: ':1',
                onSave: (v) => save(s.copyWith(gsrLowMark: v)),
              ),
              _NumberTile(
                label: 'High Ratio',
                hint: 'GSR at or above → "${s.gsrHighText}"',
                value: s.gsrHighMark,
                suffix: ':1',
                onSave: (v) => save(s.copyWith(gsrHighMark: v)),
              ),
              _TextTile(
                label: 'Low Investment Guidance',
                value: s.gsrLowText,
                onSave: (v) => save(s.copyWith(gsrLowText: v)),
              ),
              _TextTile(
                label: 'Neutral Investment Guidance',
                value: s.gsrMidText,
                onSave: (v) => save(s.copyWith(gsrMidText: v)),
              ),
              _TextTile(
                label: 'High Investment Guidance',
                value: s.gsrHighText,
                onSave: (v) => save(s.copyWith(gsrHighText: v)),
              ),
            ],
          ),

          // ── Local Premium ─────────────────────────────────────────────────
          _AnalyticsCard(
            title: 'Local Premium',
            color: AppColors.secondarySilver,
            children: [
              _NumberTile(
                label: 'Low Premium',
                hint: 'Premium at or below → "${s.lpLowText}"',
                value: s.lpLowMark,
                suffix: '%',
                decimals: 1,
                onSave: (v) => save(s.copyWith(lpLowMark: v)),
              ),
              _NumberTile(
                label: 'High Premium',
                hint: 'Premium at or above → "${s.lpHighText}"',
                value: s.lpHighMark,
                suffix: '%',
                decimals: 1,
                onSave: (v) => save(s.copyWith(lpHighMark: v)),
              ),
              _TextTile(
                label: 'Low Investment Guidance',
                value: s.lpLowText,
                onSave: (v) => save(s.copyWith(lpLowText: v)),
              ),
              _TextTile(
                label: 'Neutral Investment Guidance',
                value: s.lpMidText,
                onSave: (v) => save(s.copyWith(lpMidText: v)),
              ),
              _TextTile(
                label: 'High Investment Guidance',
                value: s.lpHighText,
                onSave: (v) => save(s.copyWith(lpHighText: v)),
              ),
            ],
          ),

          // ── Investment Guide: Premium over Spot ───────────────────────────
          _AnalyticsCard(
            title: 'Premium over Spot — Gold',
            color: AppColors.primaryGold,
            children: [
              _NumberTile(
                label: 'Low Premium (100 pts)',
                hint: 'Premium at or below this scores 100',
                value: s.premiumGoldLowPct,
                suffix: '%',
                decimals: 1,
                onSave: (v) => save(s.copyWith(premiumGoldLowPct: v)),
              ),
              _NumberTile(
                label: 'High Premium (0 pts)',
                hint: 'Premium at or above this scores 0',
                value: s.premiumGoldHighPct,
                suffix: '%',
                decimals: 1,
                onSave: (v) => save(s.copyWith(premiumGoldHighPct: v)),
              ),
            ],
          ),
          _AnalyticsCard(
            title: 'Premium over Spot — Silver',
            color: AppColors.secondarySilver,
            children: [
              _NumberTile(
                label: 'Low Premium (100 pts)',
                hint: 'Premium at or below this scores 100',
                value: s.premiumSilverLowPct,
                suffix: '%',
                decimals: 1,
                onSave: (v) => save(s.copyWith(premiumSilverLowPct: v)),
              ),
              _NumberTile(
                label: 'High Premium (0 pts)',
                hint: 'Premium at or above this scores 0',
                value: s.premiumSilverHighPct,
                suffix: '%',
                decimals: 1,
                onSave: (v) => save(s.copyWith(premiumSilverHighPct: v)),
              ),
            ],
          ),
          _AnalyticsCard(
            title: 'Premium over Spot — Platinum',
            color: AppColors.accentPlatinum,
            children: [
              _NumberTile(
                label: 'Low Premium (100 pts)',
                hint: 'Premium at or below this scores 100',
                value: s.premiumPlatLowPct,
                suffix: '%',
                decimals: 1,
                onSave: (v) => save(s.copyWith(premiumPlatLowPct: v)),
              ),
              _NumberTile(
                label: 'High Premium (0 pts)',
                hint: 'Premium at or above this scores 0',
                value: s.premiumPlatHighPct,
                suffix: '%',
                decimals: 1,
                onSave: (v) => save(s.copyWith(premiumPlatHighPct: v)),
              ),
            ],
          ),

          // ── Local Spread ──────────────────────────────────────────────────
          _AnalyticsCard(
            title: 'Local Spread — Gold',
            color: AppColors.primaryGold,
            children: [
              _NumberTile(
                label: 'Low Spread',
                hint: 'Spread ≤ this → "Buy"',
                value: s.spreadGoldBuyPct,
                suffix: '%',
                decimals: 1,
                onSave: (v) => save(s.copyWith(spreadGoldBuyPct: v)),
              ),
              _NumberTile(
                label: 'High Spread',
                hint: 'Spread ≤ this → "Hold"',
                value: s.spreadGoldHoldPct,
                suffix: '%',
                decimals: 1,
                onSave: (v) => save(s.copyWith(spreadGoldHoldPct: v)),
              ),
            ],
          ),
          _AnalyticsCard(
            title: 'Local Spread — Silver',
            color: AppColors.secondarySilver,
            children: [
              _NumberTile(
                label: 'Low Spread',
                hint: 'Spread ≤ this → "Buy"',
                value: s.spreadSilverBuyPct,
                suffix: '%',
                decimals: 1,
                onSave: (v) => save(s.copyWith(spreadSilverBuyPct: v)),
              ),
              _NumberTile(
                label: 'High Spread',
                hint: 'Spread ≤ this → "Hold"',
                value: s.spreadSilverHoldPct,
                suffix: '%',
                decimals: 1,
                onSave: (v) => save(s.copyWith(spreadSilverHoldPct: v)),
              ),
            ],
          ),
          _AnalyticsCard(
            title: 'Local Spread — Platinum',
            color: AppColors.accentPlatinum,
            children: [
              _NumberTile(
                label: 'Low Spread',
                hint: 'Spread ≤ this → "Buy"',
                value: s.spreadPlatBuyPct,
                suffix: '%',
                decimals: 1,
                onSave: (v) => save(s.copyWith(spreadPlatBuyPct: v)),
              ),
              _NumberTile(
                label: 'High Spread',
                hint: 'Spread ≤ this → "Hold"',
                value: s.spreadPlatHoldPct,
                suffix: '%',
                decimals: 1,
                onSave: (v) => save(s.copyWith(spreadPlatHoldPct: v)),
              ),
            ],
          ),

          // ── Local Spread Investment Guidance ─────────────────────────────
          _AnalyticsCard(
            title: 'Local Spread Investment Guidance',
            color: AppColors.primaryGold,
            children: [
              _TextTile(
                label: 'Low Spread Investment Guidance',
                value: s.spreadLowLabel,
                onSave: (v) => save(s.copyWith(spreadLowLabel: v)),
              ),
              _TextTile(
                label: 'Neutral Spread Investment Guidance',
                value: s.spreadMidLabel,
                onSave: (v) => save(s.copyWith(spreadMidLabel: v)),
              ),
              _TextTile(
                label: 'High Spread Investment Guidance',
                value: s.spreadHighLabel,
                onSave: (v) => save(s.copyWith(spreadHighLabel: v)),
              ),
            ],
          ),

          // ── Reset ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: OutlinedButton(
              onPressed: () async {
                final userId =
                    Supabase.instance.client.auth.currentUser!.id;
                await ref
                    .read(userAnalyticsSettingsNotifierProvider.notifier)
                    .reset(userId);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                foregroundColor: AppColors.textSecondary,
              ),
              child: const Text('Reset to Defaults'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Analytics Card ─────────────────────────────────────────────────────────────

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final Color color;
  final List<Widget> children;

  const _AnalyticsCard({
    required this.title,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          ...children,
        ],
      ),
    );
  }
}

// ── Number Tile ────────────────────────────────────────────────────────────────

class _NumberTile extends StatelessWidget {
  final String label;
  final String hint;
  final double value;
  final String suffix;
  final int decimals;
  final ValueChanged<double> onSave;

  const _NumberTile({
    required this.label,
    required this.hint,
    required this.value,
    required this.suffix,
    this.decimals = 0,
    required this.onSave,
  });

  void _showDialog(BuildContext context) {
    final ctrl = TextEditingController(text: value.toStringAsFixed(decimals));
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(label,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hint,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
              ],
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 16),
              decoration: InputDecoration(
                suffixText: suffix,
                suffixStyle:
                    const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              if (v != null) {
                onSave(v);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showDialog(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(hint,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            Text(
              '${value.toStringAsFixed(decimals)}$suffix',
              style: const TextStyle(
                color: AppColors.primaryGold,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.edit_outlined,
                size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ── Text Tile ──────────────────────────────────────────────────────────────────

class _TextTile extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onSave;

  const _TextTile({
    required this.label,
    required this.value,
    required this.onSave,
  });

  void _showDialog(BuildContext context) {
    final ctrl = TextEditingController(text: value);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: Text(label,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
          decoration: const InputDecoration(
              hintText: 'Enter label',
              hintStyle: TextStyle(color: AppColors.textSecondary)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final t = ctrl.text.trim();
              if (t.isNotEmpty) {
                onSave(t);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showDialog(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13)),
            ),
            Text(
              '"$value"',
              style: const TextStyle(
                color: AppColors.primaryGold,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.edit_outlined,
                size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
