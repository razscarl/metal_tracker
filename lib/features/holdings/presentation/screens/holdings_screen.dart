// lib/features/holdings/presentation/screens/holdings_screen.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:metal_tracker/core/constants/app_constants.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/core/utils/weight_converter.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/core/utils/sort_config.dart';
import 'package:metal_tracker/core/widgets/filter_sheet.dart';
import 'package:metal_tracker/features/holdings/data/models/holding_model.dart';
import 'package:metal_tracker/features/holdings/presentation/providers/holdings_providers.dart';
import 'package:metal_tracker/features/holdings/presentation/screens/add_holding_screen.dart';
import 'package:metal_tracker/features/holdings/presentation/screens/holding_detail_screen.dart';
import 'package:metal_tracker/features/holdings/presentation/widgets/portfolio_valuation_card.dart';

final _dateFmt = DateFormat('d MMM yy');
final _currencyFmt = NumberFormat.currency(symbol: r'$', decimalDigits: 2);

// ── Active tab flex constants ─────────────────────────────────────────────────
const _kADate  = 14;
const _kAMetal =  6;
const _kAName  = 27;
const _kAPaid  = 13;
const _kAValue = 13;
const _kAGain  = 27;

// ── Sold tab flex constants ───────────────────────────────────────────────────
const _kSDate   = 14;
const _kSMetal  =  6;
const _kSName   = 28;
const _kSPaid   = 13;
const _kSSold   = 13;
const _kSProfit = 26;

enum _ASort { date, name, paid, value, gain }
enum _SSort { date, name, paid, sold, profit }

// ─── Screen ───────────────────────────────────────────────────────────────────

class HoldingsScreen extends ConsumerWidget {
  const HoldingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        title: 'My Holdings',
        onRefresh: () {
          ref.invalidate(holdingsProvider);
          ref.invalidate(portfolioValuationProvider);
        },
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Holding',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddHoldingScreen(),
                ),
              );
              ref.invalidate(holdingsProvider);
              ref.invalidate(portfolioValuationProvider);
            },
          ),
        ],
        tabBar: const TabBar(
          tabs: [
            Tab(text: 'Active'),
            Tab(text: 'Sold'),
          ],
          indicatorColor: AppColors.primaryGold,
          labelColor: AppColors.primaryGold,
          unselectedLabelColor: AppColors.textSecondary,
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
  String? _datePreset;
  String? _metalFilter; // MetalType.name or null
  String? _formFilter;  // MetalForm.displayName or null
  String? _gainFilter;  // null | 'gain' | 'loss'
  double? _purityMin, _purityMax;
  double? _valueMin, _valueMax;
  double? _gainPctMin, _gainPctMax;

  // Cache for range slider bounds
  List<({Holding holding, double? currentValue, double? gainLoss, double? gainLossPercent})> _allAnnotated = [];

  SortConfig<_ASort> _sortConfig =
      SortConfig.initial(_ASort.date, ascending: false);

  int get _filterCount =>
      (_datePreset != null ? 1 : 0) +
      (_metalFilter != null ? 1 : 0) +
      (_formFilter != null ? 1 : 0) +
      (_gainFilter != null ? 1 : 0) +
      (_purityMin != null ? 1 : 0) +
      (_valueMin != null ? 1 : 0) +
      (_gainPctMin != null ? 1 : 0);

  bool _matchesDate(DateTime dt) {
    if (_datePreset == null) return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_datePreset) {
      case '30d':      return dt.isAfter(today.subtract(const Duration(days: 30)));
      case '90d':      return dt.isAfter(today.subtract(const Duration(days: 90)));
      case 'thisYear': return dt.year == now.year;
      case 'lastYear': return dt.year == now.year - 1;
      default:         return true;
    }
  }

  void _showFilterSheet(BuildContext context) {
    final vals = _allAnnotated
        .map((a) => a.currentValue)
        .whereType<double>()
        .toList();
    final pcts = _allAnnotated
        .map((a) => a.gainLossPercent)
        .whereType<double>()
        .toList();
    final valueHi =
        vals.isEmpty ? 0.0 : (vals.reduce(math.max) * 1.01).ceilToDouble();
    final gainLo =
        pcts.isEmpty ? 0.0 : (pcts.reduce(math.min) * 1.1).floorToDouble();
    final gainHi =
        pcts.isEmpty ? 0.0 : (pcts.reduce(math.max) * 1.1).ceilToDouble();

    FilterSheet.show(
      context: context,
      title: 'Filter',
      onReset: () => setState(() {
        _datePreset = null;
        _metalFilter = null;
        _formFilter = null;
        _gainFilter = null;
        _purityMin = null;
        _purityMax = null;
        _valueMin = null;
        _valueMax = null;
        _gainPctMin = null;
        _gainPctMax = null;
      }),
      builder: (setSheet) {
        void update(VoidCallback fn) {
          setSheet(fn);
          setState(fn);
        }

        return [
          FilterSection(
            label: 'Date Purchased',
            child: FilterChipGroup<String>(
              options: const [
                FilterChipOption(value: '30d', label: 'Last 30 days'),
                FilterChipOption(value: '90d', label: 'Last 90 days'),
                FilterChipOption(value: 'thisYear', label: 'This year'),
                FilterChipOption(value: 'lastYear', label: 'Last year'),
              ],
              selected: _datePreset,
              onChanged: (v) => update(() => _datePreset = v),
            ),
          ),
          FilterSection(
            label: 'Metal',
            child: FilterChipGroup<String>(
              options: MetalType.values
                  .map((m) =>
                      FilterChipOption(value: m.name, label: m.displayName))
                  .toList(),
              selected: _metalFilter,
              onChanged: (v) => update(() => _metalFilter = v),
            ),
          ),
          FilterSection(
            label: 'Form',
            child: FilterChipGroup<String>(
              options: MetalForm.values
                  .map((f) => FilterChipOption(
                      value: f.displayName, label: f.displayName))
                  .toList(),
              selected: _formFilter,
              onChanged: (v) => update(() => _formFilter = v),
            ),
          ),
          FilterSection(
            label: 'Performance',
            child: FilterChipGroup<String>(
              options: const [
                FilterChipOption(value: 'gain', label: 'Gains'),
                FilterChipOption(value: 'loss', label: 'Losses'),
              ],
              selected: _gainFilter,
              onChanged: (v) => update(() => _gainFilter = v),
            ),
          ),
          FilterSection(
            label: 'Purity (%)',
            child: FilterRangeSlider(
              min: 0,
              max: 100,
              currentMin: _purityMin ?? 0,
              currentMax: _purityMax ?? 100,
              format: (v) => '${v.toStringAsFixed(0)}%',
              onChanged: (r) => update(() {
                _purityMin = r.start <= 0 ? null : r.start;
                _purityMax = r.end >= 100 ? null : r.end;
              }),
            ),
          ),
          if (vals.isNotEmpty)
            FilterSection(
              label: 'Current Value',
              child: FilterRangeSlider(
                min: 0,
                max: valueHi,
                currentMin: _valueMin ?? 0,
                currentMax: _valueMax ?? valueHi,
                format: (v) => '\$${v.toStringAsFixed(0)}',
                onChanged: (r) => update(() {
                  _valueMin = r.start <= 0 ? null : r.start;
                  _valueMax = r.end >= valueHi ? null : r.end;
                }),
              ),
            ),
          if (pcts.isNotEmpty && gainHi > gainLo)
            FilterSection(
              label: 'Gain/Loss %',
              child: FilterRangeSlider(
                min: gainLo,
                max: gainHi,
                currentMin: _gainPctMin ?? gainLo,
                currentMax: _gainPctMax ?? gainHi,
                format: (v) => '${v.toStringAsFixed(1)}%',
                onChanged: (r) => update(() {
                  _gainPctMin = r.start <= gainLo ? null : r.start;
                  _gainPctMax = r.end >= gainHi ? null : r.end;
                }),
              ),
            ),
        ];
      },
    );
  }

  void _onHeaderTap(_ASort col) {
    setState(() {
      _sortConfig = _sortConfig.tap(
        col,
        defaultAscending: (c) => c == _ASort.name,
      );
    });
  }

  static int _cmpNullLast(double? a, double? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

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

          // Annotate with computed current value and gain/loss
          final annotated = _allAnnotated = holdings.map((h) {
            double? gainLoss, gainLossPercent, currentValue;
            final metalType = h.productProfile?.metalTypeEnum;
            final bestPrice = metalType != null
                ? valuation?.metalBreakdown[metalType]?.bestPricePerOz
                : null;
            if (bestPrice != null && h.productProfile != null) {
              currentValue = WeightCalculations.holdingValue(
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
              currentValue: currentValue,
              gainLoss: gainLoss,
              gainLossPercent: gainLossPercent,
            );
          }).toList();

          // Filter
          final filtered = annotated.where((item) {
            if (!_matchesDate(item.holding.purchaseDate)) return false;
            if (_metalFilter != null &&
                item.holding.productProfile?.metalTypeEnum.name !=
                    _metalFilter) {
              return false;
            }
            if (_formFilter != null &&
                item.holding.productProfile?.metalForm != _formFilter) {
              return false;
            }
            if (_gainFilter == 'gain' &&
                (item.gainLoss == null || item.gainLoss! < 0)) {
              return false;
            }
            if (_gainFilter == 'loss' &&
                (item.gainLoss == null || item.gainLoss! >= 0)) {
              return false;
            }
            final purity = item.holding.productProfile?.purity;
            if (purity != null) {
              if (_purityMin != null && purity < _purityMin!) return false;
              if (_purityMax != null && purity > _purityMax!) return false;
            }
            if (item.currentValue != null) {
              if (_valueMin != null && item.currentValue! < _valueMin!) return false;
              if (_valueMax != null && item.currentValue! > _valueMax!) return false;
            }
            if (item.gainLossPercent != null) {
              if (_gainPctMin != null && item.gainLossPercent! < _gainPctMin!) return false;
              if (_gainPctMax != null && item.gainLossPercent! > _gainPctMax!) return false;
            }
            return true;
          }).toList();

          // Sort
          _sortConfig.sortList(filtered, (a, b, col) {
            switch (col) {
              case _ASort.date:
                return a.holding.purchaseDate.compareTo(b.holding.purchaseDate);
              case _ASort.name:
                return a.holding.productName.compareTo(b.holding.productName);
              case _ASort.paid:
                return a.holding.purchasePrice.compareTo(b.holding.purchasePrice);
              case _ASort.value:
                return _cmpNullLast(a.currentValue, b.currentValue);
              case _ASort.gain:
                return _cmpNullLast(a.gainLoss, b.gainLoss);
            }
          });

          final metalTypeFilter = _metalFilter != null
              ? MetalType.values.firstWhere((m) => m.name == _metalFilter)
              : null;

          return Column(
            children: [
              // Portfolio valuation card — always pinned at top
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: PortfolioValuationCard(metalFilter: metalTypeFilter),
              ),
              // Filter row
              _FilterRow(
                filterCount: _filterCount,
                onFilter: () => _showFilterSheet(context),
              ),
              // Table header
              _ActiveTableHeader(
                config: _sortConfig,
                onTap: _onHeaderTap,
              ),
              // Rows
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyState(
                        message: holdings.isEmpty
                            ? 'No holdings yet.\nTap + to add your first.'
                            : 'No holdings match filters.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final item = filtered[i];
                          return _ActiveRow(
                            holding: item.holding,
                            currentValue: item.currentValue,
                            gainLoss: item.gainLoss,
                            gainLossPercent: item.gainLossPercent,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HoldingDetailScreen(
                                    holding: item.holding,
                                  ),
                                ),
                              );
                              ref.invalidate(holdingsProvider);
                              ref.invalidate(portfolioValuationProvider);
                            },
                          );
                        },
                      ),
              ),
            ],
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

// ── Sold Tab ──────────────────────────────────────────────────────────────────

class _SoldTab extends ConsumerStatefulWidget {
  const _SoldTab();

  @override
  ConsumerState<_SoldTab> createState() => _SoldTabState();
}

class _SoldTabState extends ConsumerState<_SoldTab> {
  String? _datePreset;
  String? _metalFilter;
  SortConfig<_SSort> _sortConfig =
      SortConfig.initial(_SSort.date, ascending: false);

  int get _filterCount =>
      (_datePreset != null ? 1 : 0) + (_metalFilter != null ? 1 : 0);

  bool _matchesDate(DateTime? dt) {
    if (_datePreset == null || dt == null) return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_datePreset) {
      case '30d':      return dt.isAfter(today.subtract(const Duration(days: 30)));
      case '90d':      return dt.isAfter(today.subtract(const Duration(days: 90)));
      case 'thisYear': return dt.year == now.year;
      case 'lastYear': return dt.year == now.year - 1;
      default:         return true;
    }
  }

  void _showFilterSheet(BuildContext context) {
    FilterSheet.show(
      context: context,
      title: 'Filter',
      initialSize: 0.55,
      maxSize: 0.85,
      onReset: () => setState(() {
        _datePreset = null;
        _metalFilter = null;
      }),
      builder: (setSheet) {
        void update(VoidCallback fn) {
          setSheet(fn);
          setState(fn);
        }

        return [
          FilterSection(
            label: 'Date Sold',
            child: FilterChipGroup<String>(
              options: const [
                FilterChipOption(value: '30d', label: 'Last 30 days'),
                FilterChipOption(value: '90d', label: 'Last 90 days'),
                FilterChipOption(value: 'thisYear', label: 'This year'),
                FilterChipOption(value: 'lastYear', label: 'Last year'),
              ],
              selected: _datePreset,
              onChanged: (v) => update(() => _datePreset = v),
            ),
          ),
          FilterSection(
            label: 'Metal',
            child: FilterChipGroup<String>(
              options: MetalType.values
                  .map((m) =>
                      FilterChipOption(value: m.name, label: m.displayName))
                  .toList(),
              selected: _metalFilter,
              onChanged: (v) => update(() => _metalFilter = v),
            ),
          ),
        ];
      },
    );
  }

  void _onHeaderTap(_SSort col) {
    setState(() {
      _sortConfig = _sortConfig.tap(
        col,
        defaultAscending: (c) => c == _SSort.name,
      );
    });
  }

  static int _cmpNullLast(double? a, double? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  @override
  Widget build(BuildContext context) {
    final holdingsAsync = ref.watch(soldHoldingsProvider);

    return holdingsAsync.when(
      data: (holdings) {
        // Annotate with profit
        final annotated = holdings.map((h) {
          double? profit, profitPercent;
          final soldPrice = h.soldPrice;
          if (soldPrice != null) {
            profit = soldPrice - h.purchasePrice;
            profitPercent = h.purchasePrice > 0
                ? (profit / h.purchasePrice) * 100
                : 0;
          }
          return (holding: h, profit: profit, profitPercent: profitPercent);
        }).toList();

        // Filter
        final filtered = annotated.where((item) {
          if (!_matchesDate(item.holding.soldDate)) return false;
          if (_metalFilter != null &&
              item.holding.productProfile?.metalTypeEnum.name != _metalFilter) {
            return false;
          }
          return true;
        }).toList();

        // Sort
        _sortConfig.sortList(filtered, (a, b, col) {
          switch (col) {
            case _SSort.date:
              final aDate = a.holding.soldDate ?? DateTime(0);
              final bDate = b.holding.soldDate ?? DateTime(0);
              return aDate.compareTo(bDate);
            case _SSort.name:
              return a.holding.productName.compareTo(b.holding.productName);
            case _SSort.paid:
              return a.holding.purchasePrice.compareTo(b.holding.purchasePrice);
            case _SSort.sold:
              return _cmpNullLast(a.holding.soldPrice, b.holding.soldPrice);
            case _SSort.profit:
              return _cmpNullLast(a.profit, b.profit);
          }
        });

        final summaryAsync = ref.watch(soldPortfolioSummaryProvider);

        return Column(
          children: [
            summaryAsync.when(
              data: (s) =>
                  s != null ? _SoldSummaryCard(summary: s) : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            _FilterRow(
              filterCount: _filterCount,
              onFilter: () => _showFilterSheet(context),
            ),
            _SoldTableHeader(
              config: _sortConfig,
              onTap: _onHeaderTap,
            ),
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyState(
                      message: holdings.isEmpty
                          ? 'No sold holdings yet.'
                          : 'No sold holdings match filters.',
                    )
                  : RefreshIndicator(
                      color: AppColors.primaryGold,
                      onRefresh: () => ref.refresh(soldHoldingsProvider.future),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final item = filtered[i];
                          return _SoldRow(
                            holding: item.holding,
                            profit: item.profit,
                            profitPercent: item.profitPercent,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => HoldingDetailScreen(
                                    holding: item.holding,
                                  ),
                                ),
                              );
                              ref.invalidate(soldHoldingsProvider);
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Text('Error: $err',
            style: const TextStyle(color: AppColors.error)),
      ),
    );
  }
}

// ── Filter Row ────────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final int filterCount;
  final VoidCallback onFilter;

  const _FilterRow({required this.filterCount, required this.onFilter});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundCard,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (filterCount > 0)
            Text(
              '$filterCount filter${filterCount > 1 ? 's' : ''} active',
              style: const TextStyle(
                color: AppColors.primaryGold,
                fontSize: 11,
              ),
            ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: Icon(
                  Icons.tune,
                  size: 20,
                  color: filterCount > 0
                      ? AppColors.primaryGold
                      : AppColors.textSecondary,
                ),
                tooltip: 'Filter',
                onPressed: onFilter,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
              if (filterCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryGold,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$filterCount',
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Active Table Header ───────────────────────────────────────────────────────

class _ActiveTableHeader extends StatelessWidget {
  final SortConfig<_ASort> config;
  final ValueChanged<_ASort> onTap;

  const _ActiveTableHeader({
    required this.config,
    required this.onTap,
  });

  Widget _cell(String label, _ASort col, int flex) {
    final primary   = config.isPrimary(col);
    final secondary = config.isSecondary(col);
    final active    = primary || secondary;
    final color = primary
        ? AppColors.primaryGold
        : secondary
            ? AppColors.primaryGold.withAlpha(160)
            : AppColors.textSecondary;
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: () => onTap(col),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (active) ...[
                const SizedBox(width: 2),
                Icon(
                  config.isAscending(col)
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  size: primary ? 11 : 9,
                  color: color,
                ),
                if (secondary) ...[
                  const SizedBox(width: 1),
                  Text('2', style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w700)),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundCard,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: Row(
        children: [
          _cell('Date', _ASort.date, _kADate),
          const Expanded(flex: _kAMetal, child: SizedBox.shrink()),
          _cell('Holding', _ASort.name, _kAName),
          _cell('Paid', _ASort.paid, _kAPaid),
          _cell('Value', _ASort.value, _kAValue),
          _cell('G/L', _ASort.gain, _kAGain),
        ],
      ),
    );
  }
}

// ── Sold Table Header ─────────────────────────────────────────────────────────

class _SoldTableHeader extends StatelessWidget {
  final SortConfig<_SSort> config;
  final ValueChanged<_SSort> onTap;

  const _SoldTableHeader({
    required this.config,
    required this.onTap,
  });

  Widget _cell(String label, _SSort col, int flex) {
    final primary   = config.isPrimary(col);
    final secondary = config.isSecondary(col);
    final active    = primary || secondary;
    final color = primary
        ? AppColors.primaryGold
        : secondary
            ? AppColors.primaryGold.withAlpha(160)
            : AppColors.textSecondary;
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: () => onTap(col),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (active) ...[
                const SizedBox(width: 2),
                Icon(
                  config.isAscending(col)
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  size: primary ? 11 : 9,
                  color: color,
                ),
                if (secondary) ...[
                  const SizedBox(width: 1),
                  Text('2', style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w700)),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundCard,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: Row(
        children: [
          _cell('Date', _SSort.date, _kSDate),
          const Expanded(flex: _kSMetal, child: SizedBox.shrink()),
          _cell('Holding', _SSort.name, _kSName),
          _cell('Paid', _SSort.paid, _kSPaid),
          _cell('Sold', _SSort.sold, _kSSold),
          _cell('Profit', _SSort.profit, _kSProfit),
        ],
      ),
    );
  }
}

// ── Active Row ────────────────────────────────────────────────────────────────

class _ActiveRow extends StatelessWidget {
  final Holding holding;
  final double? currentValue;
  final double? gainLoss;
  final double? gainLossPercent;
  final VoidCallback onTap;

  const _ActiveRow({
    required this.holding,
    required this.currentValue,
    required this.gainLoss,
    required this.gainLossPercent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final profile = holding.productProfile;
    final metalColor = profile != null
        ? MetalColorHelper.getColorForMetal(profile.metalTypeEnum)
        : AppColors.textSecondary;

    final isGain = gainLoss != null && gainLoss! >= 0;
    final glColor = gainLoss == null
        ? AppColors.textSecondary
        : (isGain ? AppColors.gainGreen : AppColors.lossRed);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white10)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Date
            Expanded(
              flex: _kADate,
              child: Text(
                _dateFmt.format(holding.purchaseDate),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 10),
              ),
            ),
            // Metal icon
            Expanded(
              flex: _kAMetal,
              child: profile != null
                  ? Image.asset(
                      MetalColorHelper.getAssetPathForMetal(
                          profile.metalTypeEnum),
                      width: 16,
                      height: 16,
                      fit: BoxFit.contain,
                    )
                  : const Icon(Icons.help_outline,
                      size: 14, color: AppColors.warning),
            ),
            // Name + spec
            Expanded(
              flex: _kAName,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    holding.productName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: metalColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (profile != null)
                    Text(
                      '${profile.weightDisplay}${profile.weightUnit} · ${profile.purity}%',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 9),
                    ),
                ],
              ),
            ),
            // Paid
            Expanded(
              flex: _kAPaid,
              child: Text(
                _currencyFmt.format(holding.purchasePrice),
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 11),
              ),
            ),
            // Current value
            Expanded(
              flex: _kAValue,
              child: Text(
                currentValue != null ? _currencyFmt.format(currentValue) : '—',
                style: TextStyle(
                  color: currentValue != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
            // Gain / Loss
            Expanded(
              flex: _kAGain,
              child: gainLoss == null
                  ? const Text('—',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 11))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${isGain ? '+' : ''}\$${gainLoss!.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: glColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '(${gainLossPercent! >= 0 ? '+' : ''}${gainLossPercent!.toStringAsFixed(1)}%)',
                          style: TextStyle(color: glColor, fontSize: 9),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sold Row ──────────────────────────────────────────────────────────────────

class _SoldRow extends StatelessWidget {
  final Holding holding;
  final double? profit;
  final double? profitPercent;
  final VoidCallback onTap;

  const _SoldRow({
    required this.holding,
    required this.profit,
    required this.profitPercent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final profile = holding.productProfile;
    final metalColor = profile != null
        ? MetalColorHelper.getColorForMetal(profile.metalTypeEnum)
            .withValues(alpha: 0.6)
        : AppColors.textSecondary;

    final isGain = profit != null && profit! >= 0;
    final pColor = profit == null
        ? AppColors.textSecondary
        : (isGain ? AppColors.gainGreen : AppColors.lossRed);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white10)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Sold date
            Expanded(
              flex: _kSDate,
              child: Text(
                holding.soldDate != null
                    ? _dateFmt.format(holding.soldDate!)
                    : '—',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 10),
              ),
            ),
            // Metal icon (dimmed)
            Expanded(
              flex: _kSMetal,
              child: profile != null
                  ? Opacity(
                      opacity: 0.5,
                      child: Image.asset(
                        MetalColorHelper.getAssetPathForMetal(
                            profile.metalTypeEnum),
                        width: 16,
                        height: 16,
                        fit: BoxFit.contain,
                      ),
                    )
                  : const Icon(Icons.help_outline,
                      size: 14, color: AppColors.textSecondary),
            ),
            // Name + spec
            Expanded(
              flex: _kSName,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    holding.productName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: metalColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (profile != null)
                    Text(
                      '${profile.weightDisplay}${profile.weightUnit} · ${profile.purity}%',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 9),
                    ),
                ],
              ),
            ),
            // Paid
            Expanded(
              flex: _kSPaid,
              child: Text(
                _currencyFmt.format(holding.purchasePrice),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11),
              ),
            ),
            // Sold price
            Expanded(
              flex: _kSSold,
              child: Text(
                holding.soldPrice != null
                    ? _currencyFmt.format(holding.soldPrice)
                    : '—',
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 11),
              ),
            ),
            // Profit
            Expanded(
              flex: _kSProfit,
              child: profit == null
                  ? const Text('—',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 11))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${isGain ? '+' : ''}\$${profit!.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: pColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '(${profitPercent! >= 0 ? '+' : ''}${profitPercent!.toStringAsFixed(1)}%)',
                          style: TextStyle(color: pColor, fontSize: 9),
                        ),
                      ],
                    ),
            ),
          ],
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
    final isGain = summary.gainLoss >= 0;
    final gainColor =
        isGain ? AppColors.gainGreen : AppColors.lossRed;
    final sign = isGain ? '+' : '';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          _SummaryCell(
            label: 'Invested',
            value: _currencyFmt.format(summary.totalInvested),
            color: AppColors.textPrimary,
          ),
          _SummaryCell(
            label: 'Sale Value',
            value: _currencyFmt.format(summary.totalSaleValue),
            color: AppColors.textPrimary,
          ),
          _SummaryCell(
            label: 'Gain/Loss',
            value: '$sign${_currencyFmt.format(summary.gainLoss)}',
            color: gainColor,
          ),
          _SummaryCell(
            label: '%',
            value: '$sign${summary.gainLossPct.toStringAsFixed(2)}%',
            color: gainColor,
          ),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryCell(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
        ],
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

