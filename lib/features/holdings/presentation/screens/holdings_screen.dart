// lib/features/holdings/presentation/screens/holdings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:metal_tracker/core/constants/app_constants.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/core/utils/weight_converter.dart';
import 'package:metal_tracker/core/widgets/app_logo_title.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/features/holdings/data/models/holding_model.dart';
import 'package:metal_tracker/features/holdings/presentation/providers/holdings_providers.dart';
import 'package:metal_tracker/features/holdings/presentation/screens/add_holding_screen.dart';
import 'package:metal_tracker/features/holdings/presentation/screens/holding_detail_screen.dart';
import 'package:metal_tracker/core/widgets/app_drawer.dart';
import 'package:metal_tracker/features/holdings/presentation/widgets/portfolio_valuation_card.dart';

final _dateFmt = DateFormat('d MMM yyyy');

enum _SortBy {
  dateDesc,
  dateAsc,
  gainDesc,
  gainAsc,
  priceDesc,
  priceAsc,
}

extension _SortByLabel on _SortBy {
  String get label => switch (this) {
        _SortBy.dateDesc => 'Newest first',
        _SortBy.dateAsc => 'Oldest first',
        _SortBy.gainDesc => 'Best gain',
        _SortBy.gainAsc => 'Worst gain',
        _SortBy.priceDesc => 'Price (high)',
        _SortBy.priceAsc => 'Price (low)',
      };
}

class HoldingsScreen extends ConsumerWidget {
  const HoldingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: const AppLogoTitle('My Holdings'),
          backgroundColor: AppColors.backgroundDark,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.add_chart),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddHoldingScreen(),
                  ),
                );
                ref.invalidate(holdingsProvider);
                ref.invalidate(portfolioValuationProvider);
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Sold'),
            ],
            indicatorColor: AppColors.primaryGold,
            labelColor: AppColors.primaryGold,
            unselectedLabelColor: AppColors.textSecondary,
          ),
        ),
        body: const TabBarView(
          children: [
            _ActiveTab(),
            _SoldTab(),
          ],
        ),
      ),
    );
  }
}

// ── Active Tab ────────────────────────────────────────────────────────────────

class _ActiveTab extends ConsumerStatefulWidget {
  const _ActiveTab();

  @override
  ConsumerState<_ActiveTab> createState() => _ActiveTabState();
}

class _ActiveTabState extends ConsumerState<_ActiveTab> {
  MetalType? _metalFilter;
  _SortBy _sortBy = _SortBy.dateDesc;

  @override
  Widget build(BuildContext context) {
    final holdingsAsync = ref.watch(holdingsProvider);
    final valuationAsync = ref.watch(portfolioValuationProvider);

    return RefreshIndicator(
      color: AppColors.primaryGold,
      onRefresh: () async {
        ref.invalidate(holdingsProvider);
        ref.invalidate(portfolioValuationProvider);
      },
      child: holdingsAsync.when(
        data: (holdings) {
          final valuation = valuationAsync.valueOrNull;

          // Filter
          var filtered = _metalFilter == null
              ? holdings
              : holdings
                  .where((h) =>
                      h.productProfile?.metalTypeEnum == _metalFilter)
                  .toList();

          // Annotate with gain/loss for sorting
          final annotated = filtered.map((h) {
            double? gainLoss;
            double? gainLossPercent;
            final metalType = h.productProfile?.metalTypeEnum;
            final bestPrice = metalType != null
                ? valuation?.metalBreakdown[metalType]?.bestPricePerOz
                : null;
            if (bestPrice != null && h.productProfile != null) {
              final currentValue = WeightCalculations.holdingValue(
                weight: h.productProfile!.weight,
                unit: h.productProfile!.weightUnitEnum,
                purity: h.productProfile!.purity,
                currentPricePerPureOz: bestPrice,
              );
              gainLoss = currentValue - h.purchasePrice;
              gainLossPercent = h.purchasePrice > 0
                  ? (gainLoss / h.purchasePrice) * 100
                  : 0;
            }
            return (
              holding: h,
              bestPricePerOz: bestPrice,
              gainLoss: gainLoss,
              gainLossPercent: gainLossPercent,
            );
          }).toList();

          // Sort
          annotated.sort((a, b) => switch (_sortBy) {
                _SortBy.dateDesc =>
                  b.holding.purchaseDate.compareTo(a.holding.purchaseDate),
                _SortBy.dateAsc =>
                  a.holding.purchaseDate.compareTo(b.holding.purchaseDate),
                _SortBy.gainDesc => (b.gainLoss ?? double.negativeInfinity)
                    .compareTo(a.gainLoss ?? double.negativeInfinity),
                _SortBy.gainAsc => (a.gainLoss ?? double.infinity)
                    .compareTo(b.gainLoss ?? double.infinity),
                _SortBy.priceDesc =>
                  b.holding.purchasePrice.compareTo(a.holding.purchasePrice),
                _SortBy.priceAsc =>
                  a.holding.purchasePrice.compareTo(b.holding.purchasePrice),
              });

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: annotated.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) return PortfolioValuationCard(metalFilter: _metalFilter);
              if (index == 1) {
                return _FilterSortBar(
                  metalFilter: _metalFilter,
                  sortBy: _sortBy,
                  onMetalFilterChanged: (v) =>
                      setState(() => _metalFilter = v),
                  onSortChanged: (v) => setState(() => _sortBy = v),
                );
              }

              final item = annotated[index - 2];
              return _HoldingCard(
                holding: item.holding,
                bestPricePerOz: item.bestPricePerOz,
                gainLoss: item.gainLoss,
                gainLossPercent: item.gainLossPercent,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          HoldingDetailScreen(holding: item.holding),
                    ),
                  );
                  ref.invalidate(holdingsProvider);
                  ref.invalidate(portfolioValuationProvider);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Error: $err',
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }
}

// ── Filter / Sort Bar ─────────────────────────────────────────────────────────

class _FilterSortBar extends StatelessWidget {
  final MetalType? metalFilter;
  final _SortBy sortBy;
  final ValueChanged<MetalType?> onMetalFilterChanged;
  final ValueChanged<_SortBy> onSortChanged;

  const _FilterSortBar({
    required this.metalFilter,
    required this.sortBy,
    required this.onMetalFilterChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Metal filter chips
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(context, null, 'All'),
                  const SizedBox(width: 6),
                  ...MetalType.values.map((m) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _filterChip(context, m, m.displayName),
                      )),
                ],
              ),
            ),
          ),
          // Sort button
          PopupMenuButton<_SortBy>(
            tooltip: 'Sort',
            icon: const Icon(Icons.sort, color: AppColors.textSecondary, size: 20),
            onSelected: onSortChanged,
            itemBuilder: (_) => _SortBy.values
                .map((s) => PopupMenuItem(
                      value: s,
                      child: Row(
                        children: [
                          if (s == sortBy)
                            const Icon(Icons.check,
                                size: 16, color: AppColors.primaryGold)
                          else
                            const SizedBox(width: 16),
                          const SizedBox(width: 8),
                          Text(s.label),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(BuildContext context, MetalType? type, String label) {
    final selected = metalFilter == type;
    final color = type != null
        ? MetalColorHelper.getColorForMetal(type)
        : AppColors.primaryGold;
    return GestureDetector(
      onTap: () => onMetalFilterChanged(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.2)
              : AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : AppColors.textSecondary.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Sold Tab ──────────────────────────────────────────────────────────────────

class _SoldTab extends ConsumerWidget {
  const _SoldTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdingsAsync = ref.watch(soldHoldingsProvider);
    final summaryAsync = ref.watch(soldPortfolioSummaryProvider);

    return RefreshIndicator(
      color: AppColors.primaryGold,
      onRefresh: () async {
        ref.invalidate(soldHoldingsProvider);
        ref.invalidate(soldPortfolioSummaryProvider);
      },
      child: holdingsAsync.when(
        data: (holdings) {
          if (holdings.isEmpty) {
            return const _EmptyState(message: 'No sold holdings yet.');
          }
          final sorted = [...holdings]
            ..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: sorted.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return summaryAsync.when(
                  data: (summary) => _SoldSummaryCard(summary: summary),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              }
              final holding = sorted[index - 1];
              return _SoldHoldingCard(
                holding: holding,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          HoldingDetailScreen(holding: holding),
                    ),
                  );
                  ref.invalidate(soldHoldingsProvider);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Error: $err',
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }
}

// ── Sold Summary Card ─────────────────────────────────────────────────────────

class _SoldSummaryCard extends StatelessWidget {
  final SoldPortfolioSummary summary;
  const _SoldSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final profit = summary.totalProfit;
    final color = profit >= 0 ? AppColors.gainGreen : AppColors.lossRed;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sold Summary (${summary.count} item${summary.count == 1 ? '' : 's'})',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _col('Total Cost',
                  '\$${summary.totalCost.toStringAsFixed(2)}',
                  AppColors.textPrimary),
              _col('Revenue',
                  '\$${summary.totalRevenue.toStringAsFixed(2)}',
                  AppColors.textPrimary),
              _col(
                'Profit',
                '${profit >= 0 ? '+' : ''}\$${profit.toStringAsFixed(2)}\n'
                    '(${summary.totalProfitPercent >= 0 ? '+' : ''}${summary.totalProfitPercent.toStringAsFixed(1)}%)',
                color,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _col(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 10)),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            )),
      ],
    );
  }
}

// ── Active Holding Card ───────────────────────────────────────────────────────

class _HoldingCard extends StatelessWidget {
  final Holding holding;
  final double? bestPricePerOz;
  final double? gainLoss;
  final double? gainLossPercent;
  final VoidCallback onTap;

  const _HoldingCard({
    required this.holding,
    required this.bestPricePerOz,
    required this.gainLoss,
    required this.gainLossPercent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final profile = holding.productProfile;
    if (profile == null) return const SizedBox.shrink();

    final color = MetalColorHelper.getColorForMetal(profile.metalTypeEnum);
    final iconPath = MetalColorHelper.getAssetPathForMetal(profile.metalTypeEnum);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        ),
        child: Row(
          children: [
            // Metal colour bar
            Container(
              width: 4,
              height: 54,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Image.asset(iconPath, width: 18, height: 18, fit: BoxFit.contain),
            const SizedBox(width: 10),

            // Name + profile info + date/price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    holding.productName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${profile.weightDisplay} ${profile.weightUnit} · ${profile.metalType} · ${profile.purity}%',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_dateFmt.format(holding.purchaseDate)} · \$${holding.purchasePrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Gain / Loss
            if (gainLoss != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${gainLoss! >= 0 ? "+" : ""}\$${gainLoss!.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: gainLoss! >= 0
                          ? AppColors.gainGreen
                          : AppColors.lossRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '(${gainLossPercent! >= 0 ? "+" : ""}${gainLossPercent!.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      color: gainLoss! >= 0
                          ? AppColors.gainGreen
                          : AppColors.lossRed,
                      fontSize: 11,
                    ),
                  ),
                ],
              )
            else
              const Text(
                '—',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Sold Holding Card ─────────────────────────────────────────────────────────

class _SoldHoldingCard extends StatelessWidget {
  final Holding holding;
  final VoidCallback onTap;

  const _SoldHoldingCard({required this.holding, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final profile = holding.productProfile;
    if (profile == null) return const SizedBox.shrink();

    final color = MetalColorHelper.getColorForMetal(profile.metalTypeEnum);
    final iconPath = MetalColorHelper.getAssetPathForMetal(profile.metalTypeEnum);

    final soldPrice = holding.soldPrice;
    double? profit;
    double? profitPercent;
    if (soldPrice != null) {
      profit = soldPrice - holding.purchasePrice;
      profitPercent = holding.purchasePrice > 0
          ? (profit / holding.purchasePrice) * 100
          : 0;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 54,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Opacity(
              opacity: 0.5,
              child: Image.asset(iconPath, width: 18, height: 18, fit: BoxFit.contain),
            ),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    holding.productName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${profile.weightDisplay} ${profile.weightUnit} · ${profile.metalType} · ${profile.purity}%',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 3),
                  if (holding.soldDate != null)
                    Text(
                      'Sold ${_dateFmt.format(holding.soldDate!)} · \$${soldPrice?.toStringAsFixed(2) ?? "—"}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Profit / Loss
            if (profit != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${profit >= 0 ? "+" : ""}\$${profit.toStringAsFixed(2)}',
                    style: TextStyle(
                      color:
                          profit >= 0 ? AppColors.gainGreen : AppColors.lossRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '(${profitPercent! >= 0 ? "+" : ""}${profitPercent.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      color:
                          profit >= 0 ? AppColors.gainGreen : AppColors.lossRed,
                      fontSize: 11,
                    ),
                  ),
                ],
              )
            else
              const Text(
                '—',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined,
              size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.white54, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
