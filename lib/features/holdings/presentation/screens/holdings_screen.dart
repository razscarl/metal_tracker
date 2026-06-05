// lib/features/holdings/presentation/screens/holdings_screen.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:metal_tracker/core/constants/app_constants.dart';
import 'package:metal_tracker/features/metadata/presentation/providers/metadata_providers.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/core/utils/time_service.dart';
import 'package:metal_tracker/core/utils/weight_converter.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/core/utils/sort_config.dart';
import 'package:metal_tracker/core/widgets/filter_sheet.dart';
import 'package:metal_tracker/features/holdings/data/models/holding_model.dart';
import 'package:metal_tracker/features/holdings/presentation/providers/holdings_providers.dart';
import 'package:metal_tracker/features/holdings/presentation/screens/add_holding_screen.dart';
import 'package:metal_tracker/features/holdings/presentation/screens/holding_detail_screen.dart';
import 'package:metal_tracker/features/holdings/presentation/widgets/portfolio_valuation_card.dart';

final _dateFmt     = DateFormat(AppDateFormats.dateShort);
final _currencyFmt = NumberFormat.currency(symbol: r'$', decimalDigits: 2);

// ── Flex constants ────────────────────────────────────────────────────────────
const _kADate  = 14; const _kAMetal =  6; const _kAName = 27;
const _kAPaid  = 13; const _kAValue = 13; const _kAGain = 27;
const _kSDate  = 14; const _kSMetal =  6; const _kSName = 28;
const _kSPaid  = 13; const _kSSold  = 13; const _kSProfit = 26;

enum _ASort { date, name, paid, value, gain }
enum _SSort { date, name, paid, sold, profit }

// ── Screen ────────────────────────────────────────────────────────────────────

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
            icon:    const Icon(Icons.add),
            tooltip: 'Add Holding',
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddHoldingScreen()));
              ref.invalidate(holdingsProvider);
              ref.invalidate(portfolioValuationProvider);
            },
          ),
        ],
        tabBar: const TabBar(
          tabs: [Tab(text: 'Active'), Tab(text: 'Sold')],
        ),
        body: const TabBarView(
          children: [_ActiveTab(), _SoldTab()],
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
  String? _datePreset, _metalFilter, _formFilter, _gainFilter;
  double? _purityMin, _purityMax, _valueMin, _valueMax, _gainPctMin, _gainPctMax;
  List<({Holding holding, double? currentValue, double? gainLoss, double? gainLossPercent})>
      _allAnnotated = [];
  SortConfig<_ASort> _sortConfig = SortConfig.initial(_ASort.date, ascending: false);

  int get _filterCount =>
      (_datePreset  != null ? 1 : 0) + (_metalFilter != null ? 1 : 0) +
      (_formFilter  != null ? 1 : 0) + (_gainFilter  != null ? 1 : 0) +
      (_purityMin   != null ? 1 : 0) + (_valueMin    != null ? 1 : 0) +
      (_gainPctMin  != null ? 1 : 0);

  bool _matchesDate(DateTime dt) {
    if (_datePreset == null) return true;
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (_datePreset) {
      '30d'      => dt.isAfter(today.subtract(const Duration(days: 30))),
      '90d'      => dt.isAfter(today.subtract(const Duration(days: 90))),
      'thisYear' => dt.year == now.year,
      'lastYear' => dt.year == now.year - 1,
      _          => true,
    };
  }

  void _showFilterSheet(BuildContext context, List<String> formNames) {
    final vals   = _allAnnotated.map((a) => a.currentValue).whereType<double>().toList();
    final pcts   = _allAnnotated.map((a) => a.gainLossPercent).whereType<double>().toList();
    final valueHi = vals.isEmpty ? 0.0 : (vals.reduce(math.max) * 1.01).ceilToDouble();
    final gainLo  = pcts.isEmpty ? 0.0 : (pcts.reduce(math.min) * 1.1).floorToDouble();
    final gainHi  = pcts.isEmpty ? 0.0 : (pcts.reduce(math.max) * 1.1).ceilToDouble();

    FilterSheet.show(
      context: context,
      title:   'Filter',
      onReset: () => setState(() {
        _datePreset = _metalFilter = _formFilter = _gainFilter = null;
        _purityMin = _purityMax = _valueMin = _valueMax = _gainPctMin = _gainPctMax = null;
      }),
      builder: (setSheet) {
        void update(VoidCallback fn) { setSheet(fn); setState(fn); }
        return [
          FilterSection(label: 'Date Purchased', child: FilterChipGroup<String>(
            options: const [
              FilterChipOption(value: '30d',      label: 'Last 30 days'),
              FilterChipOption(value: '90d',      label: 'Last 90 days'),
              FilterChipOption(value: 'thisYear', label: 'This year'),
              FilterChipOption(value: 'lastYear', label: 'Last year'),
            ],
            selected: _datePreset, onChanged: (v) => update(() => _datePreset = v),
          )),
          FilterSection(label: 'Metal', child: FilterChipGroup<String>(
            options: MetalType.values
                .map((m) => FilterChipOption(value: m.name, label: m.displayName))
                .toList(),
            selected: _metalFilter, onChanged: (v) => update(() => _metalFilter = v),
          )),
          FilterSection(label: 'Form', child: FilterChipGroup<String>(
            options: formNames.map((n) => FilterChipOption(value: n, label: n)).toList(),
            selected: _formFilter, onChanged: (v) => update(() => _formFilter = v),
          )),
          FilterSection(label: 'Performance', child: FilterChipGroup<String>(
            options: const [
              FilterChipOption(value: 'gain', label: 'Gains'),
              FilterChipOption(value: 'loss', label: 'Losses'),
            ],
            selected: _gainFilter, onChanged: (v) => update(() => _gainFilter = v),
          )),
          FilterSection(label: 'Purity (%)', child: FilterRangeSlider(
            min: 0, max: 100,
            currentMin: _purityMin ?? 0, currentMax: _purityMax ?? 100,
            format: (v) => '${v.toStringAsFixed(0)}%',
            onChanged: (r) => update(() {
              _purityMin = r.start <= 0 ? null : r.start;
              _purityMax = r.end >= 100 ? null : r.end;
            }),
          )),
          if (vals.isNotEmpty)
            FilterSection(label: 'Current Value', child: FilterRangeSlider(
              min: 0, max: valueHi,
              currentMin: _valueMin ?? 0, currentMax: _valueMax ?? valueHi,
              format: (v) => '\$${v.toStringAsFixed(0)}',
              onChanged: (r) => update(() {
                _valueMin = r.start <= 0 ? null : r.start;
                _valueMax = r.end >= valueHi ? null : r.end;
              }),
            )),
          if (pcts.isNotEmpty && gainHi > gainLo)
            FilterSection(label: 'Gain/Loss %', child: FilterRangeSlider(
              min: gainLo, max: gainHi,
              currentMin: _gainPctMin ?? gainLo, currentMax: _gainPctMax ?? gainHi,
              format: (v) => '${v.toStringAsFixed(1)}%',
              onChanged: (r) => update(() {
                _gainPctMin = r.start <= gainLo ? null : r.start;
                _gainPctMax = r.end >= gainHi ? null : r.end;
              }),
            )),
        ];
      },
    );
  }

  void _onHeaderTap(_ASort col) => setState(() {
    _sortConfig = _sortConfig.tap(col, defaultAscending: (c) => c == _ASort.name);
  });

  static int _cmpNull(double? a, double? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  @override
  Widget build(BuildContext context) {
    final cs           = Theme.of(context).colorScheme;
    final holdingsAsync = ref.watch(holdingsProvider);
    final valuationAsync = ref.watch(portfolioValuationProvider);
    final formNames    = ref.watch(metalFormsProvider).valueOrNull
        ?.map((r) => r.name).toList() ?? [];

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(holdingsProvider);
        ref.invalidate(portfolioValuationProvider);
      },
      child: holdingsAsync.when(
        data: (holdings) {
          final valuation = valuationAsync.valueOrNull;
          final annotated = _allAnnotated = holdings.map((h) {
            double? gainLoss, gainLossPercent, currentValue;
            final metalType = h.productProfile?.metalTypeEnum;
            final bestPrice = metalType != null
                ? valuation?.metalBreakdown[metalType]?.bestPricePerOz
                : null;
            if (bestPrice != null && h.productProfile != null) {
              currentValue = WeightCalculations.holdingValue(
                weight: h.productProfile!.weight,
                unit:   h.productProfile!.weightUnitEnum,
                purity: h.productProfile!.purity,
                currentPricePerPureOz: bestPrice,
              );
              gainLoss = currentValue - h.purchasePrice;
              gainLossPercent = h.purchasePrice > 0
                  ? (gainLoss / h.purchasePrice) * 100 : 0;
            }
            return (holding: h, currentValue: currentValue,
                gainLoss: gainLoss, gainLossPercent: gainLossPercent);
          }).toList();

          final filtered = annotated.where((item) {
            if (!_matchesDate(item.holding.purchaseDate)) return false;
            if (_metalFilter != null &&
                item.holding.productProfile?.metalTypeEnum.name != _metalFilter) return false;
            if (_formFilter != null &&
                item.holding.productProfile?.metalForm != _formFilter) return false;
            if (_gainFilter == 'gain' && (item.gainLoss == null || item.gainLoss! < 0)) return false;
            if (_gainFilter == 'loss' && (item.gainLoss == null || item.gainLoss! >= 0)) return false;
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

          _sortConfig.sortList(filtered, (a, b, col) => switch (col) {
            _ASort.date  => a.holding.purchaseDate.compareTo(b.holding.purchaseDate),
            _ASort.name  => a.holding.productName.compareTo(b.holding.productName),
            _ASort.paid  => a.holding.purchasePrice.compareTo(b.holding.purchasePrice),
            _ASort.value => _cmpNull(a.currentValue, b.currentValue),
            _ASort.gain  => _cmpNull(a.gainLoss, b.gainLoss),
          });

          final metalTypeFilter = _metalFilter != null
              ? MetalType.values.firstWhere((m) => m.name == _metalFilter)
              : null;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: PortfolioValuationCard(metalFilter: metalTypeFilter),
              ),
              _FilterRow(filterCount: _filterCount,
                  onFilter: () => _showFilterSheet(context, formNames)),
              _TableHeader<_ASort>(
                config:  _sortConfig,
                onTap:   _onHeaderTap,
                columns: [
                  (label: 'Date',    col: _ASort.date,  flex: _kADate),
                  (label: '',        col: _ASort.date,  flex: _kAMetal), // spacer
                  (label: 'Holding', col: _ASort.name,  flex: _kAName),
                  (label: 'Paid',    col: _ASort.paid,  flex: _kAPaid),
                  (label: 'Value',   col: _ASort.value, flex: _kAValue),
                  (label: 'G/L',     col: _ASort.gain,  flex: _kAGain),
                ],
                spacerCol: _ASort.date, // reused as spacer — skipped in header
              ),
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyState(message: holdings.isEmpty
                        ? 'No holdings yet.\nTap + to add your first.'
                        : 'No holdings match filters.')
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final item = filtered[i];
                          return _ActiveRow(
                            holding:          item.holding,
                            currentValue:     item.currentValue,
                            gainLoss:         item.gainLoss,
                            gainLossPercent:  item.gainLossPercent,
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => HoldingDetailScreen(holding: item.holding)));
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
          child: SelectableText('Error: $err',
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
  String? _datePreset, _metalFilter;
  SortConfig<_SSort> _sortConfig = SortConfig.initial(_SSort.date, ascending: false);

  int get _filterCount =>
      (_datePreset  != null ? 1 : 0) + (_metalFilter != null ? 1 : 0);

  bool _matchesDate(DateTime? dt) {
    if (_datePreset == null || dt == null) return true;
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (_datePreset) {
      '30d'      => dt.isAfter(today.subtract(const Duration(days: 30))),
      '90d'      => dt.isAfter(today.subtract(const Duration(days: 90))),
      'thisYear' => dt.year == now.year,
      'lastYear' => dt.year == now.year - 1,
      _          => true,
    };
  }

  void _showFilterSheet(BuildContext context) {
    FilterSheet.show(
      context:     context,
      title:       'Filter',
      initialSize: 0.55,
      maxSize:     0.85,
      onReset: () => setState(() { _datePreset = null; _metalFilter = null; }),
      builder: (setSheet) {
        void update(VoidCallback fn) { setSheet(fn); setState(fn); }
        return [
          FilterSection(label: 'Date Sold', child: FilterChipGroup<String>(
            options: const [
              FilterChipOption(value: '30d',      label: 'Last 30 days'),
              FilterChipOption(value: '90d',      label: 'Last 90 days'),
              FilterChipOption(value: 'thisYear', label: 'This year'),
              FilterChipOption(value: 'lastYear', label: 'Last year'),
            ],
            selected: _datePreset, onChanged: (v) => update(() => _datePreset = v),
          )),
          FilterSection(label: 'Metal', child: FilterChipGroup<String>(
            options: MetalType.values
                .map((m) => FilterChipOption(value: m.name, label: m.displayName))
                .toList(),
            selected: _metalFilter, onChanged: (v) => update(() => _metalFilter = v),
          )),
        ];
      },
    );
  }

  void _onHeaderTap(_SSort col) => setState(() {
    _sortConfig = _sortConfig.tap(col, defaultAscending: (c) => c == _SSort.name);
  });

  static int _cmpNull(double? a, double? b) {
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
        final annotated = holdings.map((h) {
          double? profit, profitPercent;
          final soldPrice = h.soldPrice;
          if (soldPrice != null) {
            profit        = soldPrice - h.purchasePrice;
            profitPercent = h.purchasePrice > 0
                ? (profit / h.purchasePrice) * 100 : 0;
          }
          return (holding: h, profit: profit, profitPercent: profitPercent);
        }).toList();

        final filtered = annotated.where((item) {
          if (!_matchesDate(item.holding.soldDate)) return false;
          if (_metalFilter != null &&
              item.holding.productProfile?.metalTypeEnum.name != _metalFilter) return false;
          return true;
        }).toList();

        _sortConfig.sortList(filtered, (a, b, col) => switch (col) {
          _SSort.date   => (a.holding.soldDate ?? DateTime(0))
              .compareTo(b.holding.soldDate ?? DateTime(0)),
          _SSort.name   => a.holding.productName.compareTo(b.holding.productName),
          _SSort.paid   => a.holding.purchasePrice.compareTo(b.holding.purchasePrice),
          _SSort.sold   => _cmpNull(a.holding.soldPrice, b.holding.soldPrice),
          _SSort.profit => _cmpNull(a.profit, b.profit),
        });

        final summaryAsync = ref.watch(soldPortfolioSummaryProvider);

        return Column(
          children: [
            summaryAsync.when(
              data:    (s) => s != null ? _SoldSummaryCard(summary: s) : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error:   (_, __) => const SizedBox.shrink(),
            ),
            _FilterRow(filterCount: _filterCount,
                onFilter: () => _showFilterSheet(context)),
            _SoldTableHeader(config: _sortConfig, onTap: _onHeaderTap),
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyState(message: holdings.isEmpty
                      ? 'No sold holdings yet.'
                      : 'No sold holdings match filters.')
                  : RefreshIndicator(
                      onRefresh: () => ref.refresh(soldHoldingsProvider.future),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final item = filtered[i];
                          return _SoldRow(
                            holding:       item.holding,
                            profit:        item.profit,
                            profitPercent: item.profitPercent,
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => HoldingDetailScreen(holding: item.holding)));
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
        child: SelectableText('Error: $err',
            style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ),
    );
  }
}

// ── Filter Row ────────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final int          filterCount;
  final VoidCallback onFilter;
  const _FilterRow({required this.filterCount, required this.onFilter});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return ColoredBox(
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (filterCount > 0)
              Text(
                '$filterCount filter${filterCount > 1 ? 's' : ''} active',
                style: tt.labelSmall?.copyWith(color: cs.primary),
              ),
            Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: Icon(Icons.tune, size: 20,
                      color: filterCount > 0 ? cs.primary : cs.onSurfaceVariant),
                  tooltip:      'Filter',
                  onPressed:    onFilter,
                  padding:      const EdgeInsets.all(8),
                  constraints:  const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
                if (filterCount > 0)
                  Positioned(
                    top: 4, right: 4,
                    child: Container(
                      width: 14, height: 14,
                      decoration: BoxDecoration(
                          color: cs.primary, shape: BoxShape.circle),
                      child: Center(
                        child: Text('$filterCount',
                            style: TextStyle(
                                color: cs.onPrimary,
                                fontSize: 8,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Generic sortable table header ─────────────────────────────────────────────

class _TableHeader<T extends Enum> extends StatelessWidget {
  final SortConfig<T>   config;
  final ValueChanged<T> onTap;
  final List<({String label, T col, int flex})> columns;
  final T spacerCol; // column used as spacer (no label, no tap)

  const _TableHeader({
    required this.config,
    required this.onTap,
    required this.columns,
    required this.spacerCol,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
        child: Row(
          children: columns.map((c) {
            if (c.label.isEmpty) {
              return Expanded(flex: c.flex, child: const SizedBox.shrink());
            }
            final primary   = config.isPrimary(c.col);
            final secondary = config.isSecondary(c.col);
            final active    = primary || secondary;
            final color = primary
                ? cs.primary
                : secondary
                    ? cs.primary.withValues(alpha: 0.6)
                    : cs.onSurfaceVariant;
            return Expanded(
              flex: c.flex,
              child: GestureDetector(
                onTap: () => onTap(c.col),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(c.label, style: TextStyle(
                          color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                      if (active) ...[
                        const SizedBox(width: 2),
                        Icon(config.isAscending(c.col)
                            ? Icons.arrow_upward : Icons.arrow_downward,
                            size: primary ? 11 : 9, color: color),
                        if (secondary)
                          Text('2', style: TextStyle(
                              color: color, fontSize: 8, fontWeight: FontWeight.w700)),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Sold table header (uses separate _SSort enum) ─────────────────────────────

class _SoldTableHeader extends StatelessWidget {
  final SortConfig<_SSort>   config;
  final ValueChanged<_SSort> onTap;
  const _SoldTableHeader({required this.config, required this.onTap});

  Widget _cell(BuildContext context, String label, _SSort col, int flex) {
    final cs        = Theme.of(context).colorScheme;
    final primary   = config.isPrimary(col);
    final secondary = config.isSecondary(col);
    final active    = primary || secondary;
    final color = primary
        ? cs.primary
        : secondary
            ? cs.primary.withValues(alpha: 0.6)
            : cs.onSurfaceVariant;
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
              Text(label, style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w700)),
              if (active) ...[
                const SizedBox(width: 2),
                Icon(config.isAscending(col)
                    ? Icons.arrow_upward : Icons.arrow_downward,
                    size: primary ? 11 : 9, color: color),
                if (secondary)
                  Text('2', style: TextStyle(
                      color: color, fontSize: 8, fontWeight: FontWeight.w700)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
        child: Row(
          children: [
            _cell(context, 'Date',    _SSort.date,   _kSDate),
            const Expanded(flex: _kSMetal, child: SizedBox.shrink()),
            _cell(context, 'Holding', _SSort.name,   _kSName),
            _cell(context, 'Paid',    _SSort.paid,   _kSPaid),
            _cell(context, 'Sold',    _SSort.sold,   _kSSold),
            _cell(context, 'Profit',  _SSort.profit, _kSProfit),
          ],
        ),
      ),
    );
  }
}

// ── Active Row ────────────────────────────────────────────────────────────────

class _ActiveRow extends StatelessWidget {
  final Holding  holding;
  final double?  currentValue, gainLoss, gainLossPercent;
  final VoidCallback onTap;

  const _ActiveRow({
    required this.holding, required this.currentValue,
    required this.gainLoss, required this.gainLossPercent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs         = Theme.of(context).colorScheme;
    final profile    = holding.productProfile;
    final metalColor = profile != null
        ? MetalColorHelper.getTextColorForMetal(context, profile.metalTypeEnum)
        : cs.onSurfaceVariant;
    final isGain  = gainLoss != null && gainLoss! >= 0;
    final glColor = gainLoss == null
        ? cs.onSurfaceVariant
        : (isGain ? AppColors.gainGreen : AppColors.lossRed);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: cs.outlineVariant)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(flex: _kADate, child: Text(_dateFmt.format(holding.purchaseDate),
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10))),
            Expanded(flex: _kAMetal, child: profile != null
                ? Image.asset(MetalColorHelper.getAssetPathForMetal(profile.metalTypeEnum),
                    width: 16, height: 16, fit: BoxFit.contain)
                : Icon(Icons.help_outline, size: 14, color: AppColors.warning)),
            Expanded(flex: _kAName, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(holding.productName, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: metalColor, fontSize: 11, fontWeight: FontWeight.w600)),
                if (profile != null)
                  Text('${profile.weightDisplay}${profile.weightUnit} · ${profile.purity}%',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 9)),
              ],
            )),
            Expanded(flex: _kAPaid, child: Text(_currencyFmt.format(holding.purchasePrice),
                style: const TextStyle(fontSize: 11))),
            Expanded(flex: _kAValue, child: Text(
              currentValue != null ? _currencyFmt.format(currentValue) : '—',
              style: TextStyle(
                  color: currentValue != null ? null : cs.onSurfaceVariant,
                  fontSize: 11),
            )),
            Expanded(flex: _kAGain, child: gainLoss == null
                ? Text('—', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11))
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${isGain ? '+' : ''}\$${gainLoss!.toStringAsFixed(2)}',
                        style: TextStyle(color: glColor, fontSize: 11, fontWeight: FontWeight.w600)),
                    Text('(${gainLossPercent! >= 0 ? '+' : ''}${gainLossPercent!.toStringAsFixed(1)}%)',
                        style: TextStyle(color: glColor, fontSize: 9)),
                  ])),
          ],
        ),
      ),
    );
  }
}

// ── Sold Row ──────────────────────────────────────────────────────────────────

class _SoldRow extends StatelessWidget {
  final Holding  holding;
  final double?  profit, profitPercent;
  final VoidCallback onTap;

  const _SoldRow({
    required this.holding, required this.profit,
    required this.profitPercent, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs         = Theme.of(context).colorScheme;
    final profile    = holding.productProfile;
    final metalColor = profile != null
        ? MetalColorHelper.getTextColorForMetal(context, profile.metalTypeEnum).withValues(alpha: 0.6)
        : cs.onSurfaceVariant;
    final isGain  = profit != null && profit! >= 0;
    final pColor  = profit == null
        ? cs.onSurfaceVariant
        : (isGain ? AppColors.gainGreen : AppColors.lossRed);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: cs.outlineVariant)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(flex: _kSDate, child: Text(
              holding.soldDate != null ? _dateFmt.format(holding.soldDate!) : '—',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10))),
            Expanded(flex: _kSMetal, child: profile != null
                ? Opacity(opacity: 0.5, child: Image.asset(
                    MetalColorHelper.getAssetPathForMetal(profile.metalTypeEnum),
                    width: 16, height: 16, fit: BoxFit.contain))
                : Icon(Icons.help_outline, size: 14, color: cs.onSurfaceVariant)),
            Expanded(flex: _kSName, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(holding.productName, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: metalColor, fontSize: 11, fontWeight: FontWeight.w600)),
                if (profile != null)
                  Text('${profile.weightDisplay}${profile.weightUnit} · ${profile.purity}%',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 9)),
              ],
            )),
            Expanded(flex: _kSPaid, child: Text(_currencyFmt.format(holding.purchasePrice),
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11))),
            Expanded(flex: _kSSold, child: Text(
              holding.soldPrice != null ? _currencyFmt.format(holding.soldPrice) : '—',
              style: const TextStyle(fontSize: 11))),
            Expanded(flex: _kSProfit, child: profit == null
                ? Text('—', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11))
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${isGain ? '+' : ''}\$${profit!.toStringAsFixed(2)}',
                        style: TextStyle(color: pColor, fontSize: 11, fontWeight: FontWeight.w600)),
                    Text('(${profitPercent! >= 0 ? '+' : ''}${profitPercent!.toStringAsFixed(1)}%)',
                        style: TextStyle(color: pColor, fontSize: 9)),
                  ])),
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
    final isGain    = summary.gainLoss >= 0;
    final gainColor = isGain ? AppColors.gainGreen : AppColors.lossRed;
    final sign      = isGain ? '+' : '';

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            _SummaryCell(label: 'Invested',   value: _currencyFmt.format(summary.totalInvested)),
            _SummaryCell(label: 'Sale Value', value: _currencyFmt.format(summary.totalSaleValue)),
            _SummaryCell(label: 'Gain/Loss',
                value: '$sign${_currencyFmt.format(summary.gainLoss)}', color: gainColor),
            _SummaryCell(label: '%',
                value: '$sign${summary.gainLossPct.toStringAsFixed(2)}%', color: gainColor),
          ],
        ),
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _SummaryCell({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text(value,
              style: tt.labelMedium?.copyWith(
                  color: color, fontWeight: FontWeight.w600),
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64,
              color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(message,
              style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
