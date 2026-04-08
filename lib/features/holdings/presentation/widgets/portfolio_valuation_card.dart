// lib/features/holdings/presentation/widgets/portfolio_valuation_card.dart:Portfolio Valuation Card
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/constants/app_constants.dart';
import 'package:metal_tracker/features/holdings/presentation/providers/holdings_providers.dart';

class PortfolioValuationCard extends ConsumerWidget {
  /// When set, shows valuation for that metal only. Null = full portfolio.
  final MetalType? metalFilter;

  const PortfolioValuationCard({super.key, this.metalFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final valuationAsync = ref.watch(portfolioValuationProvider);
    final movementAsync = ref.watch(portfolioMovementProvider);

    return valuationAsync.when(
      data: (valuation) {
        if (valuation.metalBreakdown.isEmpty) return const SizedBox.shrink();

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
                  trailing: movementAsync.valueOrNull != null
                      ? _MovementChip(movementAsync.valueOrNull!)
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
  final PortfolioMovement movement;
  const _MovementChip(this.movement);

  @override
  Widget build(BuildContext context) {
    final color = movement.isUp ? AppColors.gainGreen : AppColors.lossRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            movement.isUp
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '${movement.isUp ? '+' : ''}${movement.changePct.toStringAsFixed(1)}%',
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
