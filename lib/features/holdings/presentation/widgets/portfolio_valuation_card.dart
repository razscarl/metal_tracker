// lib/features/holdings/presentation/widgets/portfolio_valuation_card.dart:Portfolio Valuation Card
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/metal_color_helper.dart';
import '../../../live_prices/data/models/live_price_model.dart';
import '../providers/holdings_providers.dart';

class PortfolioValuationCard extends ConsumerWidget {
  const PortfolioValuationCard({super.key});

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : dateTime.hour == 0
            ? 12
            : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} $hour:$minute $period';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// For each metal type, find the most recent live price timestamp
  Map<MetalType, DateTime?> _getLatestDatePerMetal(
    List<LivePrice> livePrices,
    Map<String, dynamic> profileMap,
  ) {
    final result = <MetalType, DateTime?>{};

    // Initialise all metals to null
    for (final metal in MetalType.values) {
      result[metal] = null;
    }

    for (final price in livePrices) {
      final profile = profileMap[price.productProfileId];
      if (profile == null) continue;

      final metalType = profile.metalTypeEnum as MetalType;
      final current = result[metalType];

      if (current == null || price.captureTimestamp.isAfter(current)) {
        result[metalType] = price.captureTimestamp;
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final valuationAsync = ref.watch(portfolioValuationProvider);
    final livePricesAsync = ref.watch(livePricesProvider);
    final profilesAsync = ref.watch(productProfilesProvider);

    return valuationAsync.when(
      data: (valuation) {
        // If no holdings, don't show anything
        if (valuation.metalBreakdown.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Portfolio Valuation',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),

                // Missing prices warning
                if (!valuation.hasAllPrices) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppConstants.cardBorderRadius),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber,
                            color: AppColors.warning),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Add live prices for ${valuation.missingPrices.map((m) => m.displayName).join(', ')} to see full portfolio value',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Total Summary
                _SummaryRow(
                  label: 'Current Value',
                  value: '\$${valuation.totalCurrentValue.toStringAsFixed(2)}',
                  valueStyle:
                      Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'Total Cost',
                  value: '\$${valuation.totalPurchaseCost.toStringAsFixed(2)}',
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
                ),
                const SizedBox(height: 16),

                // Last Updated Section
                livePricesAsync.when(
                  data: (livePrices) => profilesAsync.when(
                    data: (profiles) {
                      // Build profile lookup map
                      final profileMap = {for (var p in profiles) p.id: p};

                      // Get latest date per metal
                      final latestByMetal = _getLatestDatePerMetal(
                        livePrices,
                        profileMap,
                      );

                      return _LastUpdatedSection(
                        latestByMetal: latestByMetal,
                        formatDateTime: _formatDateTime,
                        isToday: _isToday,
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // Divider
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Metal Breakdown
                ...valuation.metalBreakdown.entries.map((entry) {
                  final metal = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _MetalBreakdown(metalValuation: metal),
                  );
                }),
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
}

class _LastUpdatedSection extends StatelessWidget {
  final Map<MetalType, DateTime?> latestByMetal;
  final String Function(DateTime) formatDateTime;
  final bool Function(DateTime) isToday;

  const _LastUpdatedSection({
    required this.latestByMetal,
    required this.formatDateTime,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              const Icon(
                Icons.schedule,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Live Prices were last updated:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // One row per metal type
          ...MetalType.values.map((metalType) {
            final lastUpdated = latestByMetal[metalType];
            final hasPrice = lastUpdated != null;
            final isOutdated = hasPrice && !isToday(lastUpdated);
            final metalColor = MetalColorHelper.getColorForMetal(metalType);
            final metalIcon = MetalColorHelper.getIconForMetal(metalType);

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  // Metal icon and name
                  Icon(metalIcon, size: 14, color: metalColor),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 70,
                    child: Text(
                      '${metalType.displayName}:',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: metalColor),
                    ),
                  ),

                  // Date/time or No prices entered
                  Expanded(
                    child: Text(
                      hasPrice
                          ? formatDateTime(lastUpdated)
                          : 'No prices entered',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: !hasPrice
                                ? AppColors.textSecondary
                                : isOutdated
                                    ? AppColors.warning
                                    : AppColors.success,
                            fontWeight: isOutdated
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                    ),
                  ),

                  // Warning icon if outdated
                  if (isOutdated)
                    const Icon(
                      Icons.warning_amber,
                      size: 14,
                      color: AppColors.warning,
                    ),
                ],
              ),
            );
          }),
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

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueStyle,
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
        Text(
          value,
          style: valueStyle?.copyWith(color: valueColor) ??
              Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
        ),
      ],
    );
  }
}

class _MetalBreakdown extends StatelessWidget {
  final MetalValuation metalValuation;

  const _MetalBreakdown({required this.metalValuation});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metal header with icon
        Row(
          children: [
            Icon(
              MetalColorHelper.getIconForMetal(metalValuation.metalType),
              color:
                  MetalColorHelper.getColorForMetal(metalValuation.metalType),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              metalValuation.metalType.displayName,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            Text(
              '${metalValuation.holdingsCount} ${metalValuation.holdingsCount == 1 ? 'holding' : 'holdings'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Values
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Value',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '\$${metalValuation.currentValue.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cost',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '\$${metalValuation.purchaseCost.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Gain/Loss',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${metalValuation.gainLoss >= 0 ? '+' : ''}\$${metalValuation.gainLoss.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: metalValuation.gainLoss >= 0
                              ? AppColors.gainGreen
                              : AppColors.lossRed,
                        ),
                  ),
                  Text(
                    '${metalValuation.gainLossPercent >= 0 ? '+' : ''}${metalValuation.gainLossPercent.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: metalValuation.gainLoss >= 0
                              ? AppColors.gainGreen
                              : AppColors.lossRed,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Best price info
        if (metalValuation.bestPricePerOz != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MetalColorHelper.getColorForMetal(metalValuation.metalType)
                  .withValues(alpha: 0.1),
              borderRadius:
                  BorderRadius.circular(AppConstants.cardBorderRadius),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.star,
                  size: 14,
                  color: MetalColorHelper.getColorForMetal(
                      metalValuation.metalType),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Best Price: \$${metalValuation.bestPricePerOz!.toStringAsFixed(2)}/oz (${metalValuation.bestRetailerName})',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
