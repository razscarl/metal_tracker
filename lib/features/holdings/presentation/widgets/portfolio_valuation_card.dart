// lib/features/holdings/presentation/widgets/portfolio_valuation_card.dart:Portfolio Valuation Card
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/constants/app_constants.dart';
import 'package:metal_tracker/features/holdings/presentation/providers/holdings_providers.dart';
import 'package:metal_tracker/features/holdings/presentation/screens/holdings_screen.dart';

class PortfolioValuationCard extends ConsumerWidget {
  /// When set, shows valuation for that metal only. Null = full portfolio.
  final MetalType? metalFilter;

  const PortfolioValuationCard({super.key, this.metalFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final valuationAsync = ref.watch(portfolioValuationProvider);
    final movement = ref.watch(portfolioMovementProvider).valueOrNull;

    return valuationAsync.when(
      data: (valuation) {
        if (valuation.metalBreakdown.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      size: 40, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  const Text(
                    'You have no holdings to value.',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Add your first holding on the Holdings page.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Go to Holdings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: AppColors.textDark,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const HoldingsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // ── Filtered: single metal ──────────────────────────────────────────
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
                  Text(
                    '${metalFilter!.displayName} Valuation',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  if (missingPrice) ...[
                    _warningBanner(
                      context,
                      'No live prices for ${metalFilter!.displayName} — showing cost only',
                    ),
                    const SizedBox(height: 16),
                  ],
                  _SummaryRow(
                    label: 'Current Value',
                    value: '\$${metalVal.currentValue.toStringAsFixed(2)}',
                    valueStyle: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Total Cost',
                    value: '\$${metalVal.purchaseCost.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Gain/Loss',
                    value:
                        '${metalVal.gainLoss >= 0 ? '+' : ''}\$${metalVal.gainLoss.toStringAsFixed(2)} '
                        '(${metalVal.gainLossPercent >= 0 ? '+' : ''}${metalVal.gainLossPercent.toStringAsFixed(1)}%)',
                    valueColor: metalVal.gainLoss >= 0
                        ? AppColors.gainGreen
                        : AppColors.lossRed,
                    valueStyle:
                        Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                    trailing: movement?.byMetal[metalFilter!] != null
                        ? _MovementChip(
                            delta: movement!.byMetal[metalFilter!]!.delta,
                            pct: movement.byMetal[metalFilter!]!.pct,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          );
        }

        // ── Full portfolio ──────────────────────────────────────────────────
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Portfolio Valuation',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                if (!valuation.hasAllPrices) ...[
                  _warningBanner(
                    context,
                    'Add live prices for ${valuation.missingPrices.map((m) => m.displayName).join(', ')} to see full portfolio value',
                  ),
                  const SizedBox(height: 16),
                ],
                _SummaryRow(
                  label: 'Current Value',
                  value:
                      '\$${valuation.totalCurrentValue.toStringAsFixed(2)}',
                  valueStyle:
                      Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'Total Cost',
                  value:
                      '\$${valuation.totalPurchaseCost.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'Gain/Loss',
                  value:
                      '${valuation.totalGainLoss >= 0 ? '+' : ''}\$${valuation.totalGainLoss.toStringAsFixed(2)} '
                      '(${valuation.totalGainLossPercent >= 0 ? '+' : ''}${valuation.totalGainLossPercent.toStringAsFixed(1)}%)',
                  valueColor: valuation.totalGainLoss >= 0
                      ? AppColors.gainGreen
                      : AppColors.lossRed,
                  valueStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  trailing: movement != null
                      ? _MovementChip(
                          delta: movement.totalDelta,
                          pct: movement.totalPct,
                        )
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
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Error loading portfolio: $error',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }

  Widget _warningBanner(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
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
  final String label;
  final String value;
  final Color? valueColor;
  final TextStyle? valueStyle;
  final Widget? trailing;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueStyle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: valueStyle?.copyWith(color: valueColor) ??
                  Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: valueColor,
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
    final isUp = delta >= 0;
    final color = isUp ? AppColors.gainGreen : AppColors.lossRed;
    final sign = isUp ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.arrow_upward : Icons.arrow_downward,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '$sign${pct.toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
