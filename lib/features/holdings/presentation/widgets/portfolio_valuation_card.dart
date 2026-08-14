// lib/features/holdings/presentation/widgets/portfolio_valuation_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/constants/app_constants.dart';
import 'package:metal_tracker/core/widgets/movement_arrow.dart';
import 'package:metal_tracker/features/holdings/presentation/providers/holdings_providers.dart';
import 'package:metal_tracker/features/holdings/presentation/screens/holdings_screen.dart';

class PortfolioValuationCard extends ConsumerWidget {
  final MetalType? metalFilter;
  const PortfolioValuationCard({super.key, this.metalFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs             = Theme.of(context).colorScheme;
    final tt             = Theme.of(context).textTheme;
    final valuationAsync = ref.watch(portfolioValuationProvider);
    final movement       = ref.watch(portfolioMovementProvider).valueOrNull;

    return valuationAsync.when(
      data: (valuation) {
        // ── Empty state ───────────────────────────────────────────────────
        if (valuation.metalBreakdown.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 40, color: cs.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text(
                    'You have no holdings to value.',
                    style: tt.titleSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Add your first holding on the Holdings page.',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon:  const Icon(Icons.add, size: 16),
                    label: const Text('Go to Holdings'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HoldingsScreen()),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // ── Single metal ──────────────────────────────────────────────────
        if (metalFilter != null) {
          final metalVal = valuation.metalBreakdown[metalFilter];
          if (metalVal == null) return const SizedBox.shrink();
          final missingPrice = metalVal.bestPricePerOz == null;

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${metalFilter!.displayName} Valuation',
                      style: tt.headlineSmall),
                  const SizedBox(height: 16),
                  if (missingPrice) ...[
                    _warningBanner(context,
                        'No live prices for ${metalFilter!.displayName} — showing cost only'),
                    const SizedBox(height: 16),
                  ],
                  _SummaryRow(
                    label:      'Current Value',
                    value:      '\$${metalVal.currentValue.toStringAsFixed(2)}',
                    valueStyle: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Total Cost',
                    value: '\$${metalVal.purchaseCost.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Gain/Loss',
                    value: '${metalVal.gainLoss >= 0 ? '+' : ''}\$${metalVal.gainLoss.toStringAsFixed(2)} '
                        '(${metalVal.gainLossPercent >= 0 ? '+' : ''}${metalVal.gainLossPercent.toStringAsFixed(1)}%)',
                    valueColor: metalVal.gainLoss >= 0
                        ? AppColors.gainGreen
                        : AppColors.lossRed,
                    valueStyle: tt.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    trailing: movement?.byMetal[metalFilter!] != null
                        ? _MovementChip(
                            delta: movement!.byMetal[metalFilter!]!.delta,
                            pct:   movement.byMetal[metalFilter!]!.pct,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          );
        }

        // ── Full portfolio ────────────────────────────────────────────────
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Portfolio Valuation', style: tt.headlineSmall),
                const SizedBox(height: 16),
                if (!valuation.hasAllPrices) ...[
                  _warningBanner(
                    context,
                    'Add live prices for ${valuation.missingPrices.map((m) => m.displayName).join(', ')} to see full portfolio value',
                  ),
                  const SizedBox(height: 16),
                ],
                _SummaryRow(
                  label:      'Current Value',
                  value:      '\$${valuation.totalCurrentValue.toStringAsFixed(2)}',
                  valueStyle: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'Total Cost',
                  value: '\$${valuation.totalPurchaseCost.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'Gain/Loss',
                  value: '${valuation.totalGainLoss >= 0 ? '+' : ''}\$${valuation.totalGainLoss.toStringAsFixed(2)} '
                      '(${valuation.totalGainLossPercent >= 0 ? '+' : ''}${valuation.totalGainLossPercent.toStringAsFixed(1)}%)',
                  valueColor: valuation.totalGainLoss >= 0
                      ? AppColors.gainGreen
                      : AppColors.lossRed,
                  valueStyle: tt.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  trailing: movement != null
                      ? _MovementChip(delta: movement.totalDelta, pct: movement.totalPct)
                      : null,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            'Error loading portfolio: $error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }

  Widget _warningBanner(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String     label;
  final String     value;
  final Color?     valueColor;
  final TextStyle? valueStyle;
  final Widget?    trailing;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueStyle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: tt.bodyMedium),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: valueStyle?.copyWith(color: valueColor) ??
                  tt.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color:      valueColor,
                  ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 6),
              trailing!,
            ],
          ],
        ),
      ],
    );
  }
}

class _MovementChip extends StatelessWidget {
  final double delta;
  final double pct;
  const _MovementChip({required this.delta, required this.pct});

  @override
  Widget build(BuildContext context) {
    final isUp  = delta >= 0;
    final color = isUp ? AppColors.gainGreen : AppColors.lossRed;
    final sign  = isUp ? '+' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MovementArrow(movementUp: isUp, color: color, size: 10),
          const SizedBox(width: 2),
          Text(
            '$sign${pct.toStringAsFixed(1)}%',
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
