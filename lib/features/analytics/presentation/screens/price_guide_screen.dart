// lib/features/analytics/presentation/screens/price_guide_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/core/utils/sort_config.dart';
import 'package:metal_tracker/core/utils/time_service.dart';
import 'package:metal_tracker/core/utils/signal_color_helper.dart';
import 'package:metal_tracker/core/widgets/card_heading.dart';
import 'package:metal_tracker/core/widgets/table_column_heading.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/core/widgets/filter_sheet.dart';
import 'package:metal_tracker/core/widgets/movement_arrow.dart';
import 'package:metal_tracker/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:metal_tracker/features/analytics/presentation/widgets/analytics_trend_card.dart';

// ─── Sort enum ────────────────────────────────────────────────────────────────

enum _PgSort { date, metal, sell, buyback, spread }

// ─── Flex constants ───────────────────────────────────────────────────────────

const _kPgDateFlex = 22;
const _kPgMetalFlex = 18;
const _kPgSellFlex = 20;
const _kPgBuyFlex = 20;
const _kPgSpreadFlex = 24;

// ─── Formatters ───────────────────────────────────────────────────────────────

final _dateFmt = DateFormat(AppDateFormats.dateShort);
final _chartDateFmt = DateFormat(AppDateFormats.chartLabel);
final _priceFmt = NumberFormat('#,##0.00');

// ─── Screen ───────────────────────────────────────────────────────────────────

class PriceGuideScreen extends ConsumerStatefulWidget {
  const PriceGuideScreen({super.key});

  @override
  ConsumerState<PriceGuideScreen> createState() => _PriceGuideScreenState();
}

class _PriceGuideScreenState extends ConsumerState<PriceGuideScreen> {
  String? _metalFilter;   // filter sheet — controls history table
  String _chartMetal = 'gold'; // chart card metal selector — controls chart only
  String _range = '30d';
  SortConfig<_PgSort> _sortConfig =
      SortConfig.initial(_PgSort.date, ascending: false);

  void _openFilter() {
    FilterSheet.show(
      context: context,
      title: 'Filter',
      initialSize: 0.45,
      onReset: () => setState(() => _metalFilter = null),
      builder: (setSheetState) => [
        FilterSection(
          label: 'Metal',
          child: FilterChipGroup<String>(
            options: const [
              FilterChipOption(
                  value: 'gold',
                  label: 'Gold',
                  color: AppColors.primaryGold),
              FilterChipOption(
                  value: 'silver',
                  label: 'Silver',
                  color: AppColors.secondarySilver),
              FilterChipOption(
                  value: 'platinum',
                  label: 'Platinum',
                  color: AppColors.accentPlatinum),
            ],
            selected: _metalFilter,
            onChanged: (v) {
              setState(() => _metalFilter = v);
              setSheetState(() {});
            },
          ),
        ),
      ],
    );
  }

  List<LocalSpreadEntry> _sorted(List<LocalSpreadEntry> items) {
    final list = List<LocalSpreadEntry>.from(items);
    _sortConfig.sortList(list, (a, b, col) {
      switch (col) {
        case _PgSort.date:
          return a.date.compareTo(b.date);
        case _PgSort.metal:
          return a.metalType.compareTo(b.metalType);
        case _PgSort.sell:
          return a.bestSellPrice.compareTo(b.bestSellPrice);
        case _PgSort.buyback:
          return a.bestBuybackPrice.compareTo(b.bestBuybackPrice);
        case _PgSort.spread:
          return a.spreadDollar.compareTo(b.spreadDollar);
      }
    });
    return list;
  }

  void _onHeaderTap(_PgSort col) {
    setState(() {
      _sortConfig = _sortConfig.tap(col,
          defaultAscending: (c) => c == _PgSort.metal);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final historyAsync = ref.watch(localSpreadHistoryProvider);
    final filterActive = _metalFilter != null;

    return AppScaffold(
      title: 'Price Guide',
      actions: [
        IconButton(
          icon: Icon(
            Icons.tune,
            color: filterActive
                ? AppColors.primaryGold
                : AppColors.textSecondary,
          ),
          tooltip: 'Filter',
          onPressed: _openFilter,
        ),
      ],
      onRefresh: () => ref.invalidate(localSpreadHistoryProvider),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: TextStyle(color: cs.onSurfaceVariant)),
        ),
        data: (allHistory) => _buildContent(context, allHistory),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<LocalSpreadEntry> allHistory) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _metalFilter != null
        ? allHistory.where((e) => e.metalType == _metalFilter).toList()
        : allHistory;

    final cutoff = switch (_range) {
      '7d' => DateTime.now().subtract(const Duration(days: 7)),
      '30d' => DateTime.now().subtract(const Duration(days: 30)),
      '90d' => DateTime.now().subtract(const Duration(days: 90)),
      _ => DateTime(2000),
    };
    final chartEntries = allHistory
        .where((e) => e.metalType == _chartMetal && !e.date.isBefore(cutoff))
        .toList()
        .reversed
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _InfoCard(),
        const SizedBox(height: 16),

        _SummaryCard(history: allHistory, metalFilter: _metalFilter),
        const SizedBox(height: 16),

        AnalyticsTrendCard(
          icon: Icons.show_chart,
          title: 'Price Trend',
          range: _range,
          onRangeChanged: (r) => setState(() => _range = r),
          selectedMetal: _chartMetal,
          onMetalChanged: (m) =>
              setState(() => _chartMetal = m ?? 'gold'),
          chart: chartEntries.length < 2
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'Not enough data for this range.',
                      style: TextStyle(
                          color: cs.onSurfaceVariant, fontSize: 12),
                    ),
                  ),
                )
              : _PgChart(entries: chartEntries, metalType: _chartMetal),
        ),
        const SizedBox(height: 16),

        _HistoryCard(
          entries: _sorted(filtered),
          sortConfig: _sortConfig,
          onHeaderTap: _onHeaderTap,
        ),
      ],
    );
  }
}

// ─── Info Card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CardHeading(
              icon: Icons.trending_up,
              title: 'About Price Guide',
            ),
            const SizedBox(height: 8),
            Text(
              'Tracks the best available sell and buyback prices over time. '
              'Use this to spot pricing trends and compare price changes across metals.',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Summary Card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final List<LocalSpreadEntry> history;
  final String? metalFilter;

  const _SummaryCard({required this.history, this.metalFilter});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final metals = metalFilter != null
        ? [metalFilter!]
        : ['gold', 'silver', 'platinum'];

    final latestByMetal = <String, LocalSpreadEntry>{};
    for (final metal in metals) {
      final entries = history.where((e) => e.metalType == metal).toList();
      if (entries.isNotEmpty) {
        latestByMetal[metal] = entries.first;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Prices',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (latestByMetal.isEmpty)
              Text(
                'No data yet — fetch live prices first.',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              )
            else
              ...metals.where(latestByMetal.containsKey).map((metal) {
                final e = latestByMetal[metal]!;
                final metalColor =
                    MetalColorHelper.getColorForMetalString(metal);
                final iconPath =
                    MetalColorHelper.getAssetPathForMetalString(metal);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Image.asset(iconPath, width: 24, height: 24),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 72,
                        child: Text(
                          '${metal[0].toUpperCase()}${metal.substring(1)}',
                          style: TextStyle(
                            color: metalColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text('Sell',
                                    style: TextStyle(
                                        color: cs.onSurfaceVariant,
                                        fontSize: 11)),
                                const SizedBox(width: 6),
                                Text(
                                  '\$${_priceFmt.format(e.bestSellPrice)}',
                                  style: TextStyle(
                                    color: metalColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text('Buyback',
                                    style: TextStyle(
                                        color: cs.onSurfaceVariant,
                                        fontSize: 11)),
                                const SizedBox(width: 6),
                                Text(
                                  '\$${_priceFmt.format(e.bestBuybackPrice)}',
                                  style: TextStyle(
                                    color: cs.onSurface,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}


// ─── History Card ─────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final List<LocalSpreadEntry> entries;
  final SortConfig<_PgSort> sortConfig;
  final ValueChanged<_PgSort> onHeaderTap;

  const _HistoryCard({
    required this.entries,
    required this.sortConfig,
    required this.onHeaderTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            child: Text(
              'History',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: Row(
              children: [
                TableColumnHeading(
                  label: 'Date',
                  flex: _kPgDateFlex,
                  onTap: () => onHeaderTap(_PgSort.date),
                  sortActive: sortConfig.isActive(_PgSort.date),
                  sortAscending: sortConfig.isAscending(_PgSort.date),
                  sortSecondary: sortConfig.isSecondary(_PgSort.date),
                ),
                TableColumnHeading(
                  label: 'Metal',
                  flex: _kPgMetalFlex,
                  onTap: () => onHeaderTap(_PgSort.metal),
                  sortActive: sortConfig.isActive(_PgSort.metal),
                  sortAscending: sortConfig.isAscending(_PgSort.metal),
                  sortSecondary: sortConfig.isSecondary(_PgSort.metal),
                ),
                TableColumnHeading(
                  label: 'Sell',
                  flex: _kPgSellFlex,
                  align: TextAlign.right,
                  onTap: () => onHeaderTap(_PgSort.sell),
                  sortActive: sortConfig.isActive(_PgSort.sell),
                  sortAscending: sortConfig.isAscending(_PgSort.sell),
                  sortSecondary: sortConfig.isSecondary(_PgSort.sell),
                ),
                TableColumnHeading(
                  label: 'Buyback',
                  flex: _kPgBuyFlex,
                  align: TextAlign.right,
                  onTap: () => onHeaderTap(_PgSort.buyback),
                  sortActive: sortConfig.isActive(_PgSort.buyback),
                  sortAscending: sortConfig.isAscending(_PgSort.buyback),
                  sortSecondary: sortConfig.isSecondary(_PgSort.buyback),
                ),
                TableColumnHeading(
                  label: 'Sprd \$',
                  flex: _kPgSpreadFlex,
                  align: TextAlign.right,
                  onTap: () => onHeaderTap(_PgSort.spread),
                  sortActive: sortConfig.isActive(_PgSort.spread),
                  sortAscending: sortConfig.isAscending(_PgSort.spread),
                  sortSecondary: sortConfig.isSecondary(_PgSort.spread),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No data.',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              ),
            )
          else
            ...entries.map((e) {
              final metalColor =
                  MetalColorHelper.getColorForMetalString(e.metalType);
              return Container(
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
                decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.15))),
                ),
                child: Row(children: [
                  Expanded(
                    flex: _kPgDateFlex,
                    child: Text(_dateFmt.format(e.date),
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 11)),
                  ),
                  Expanded(
                    flex: _kPgMetalFlex,
                    child: Text(
                        _pgMetalLabel(e.metalType),
                        style: TextStyle(
                            color: metalColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11)),
                  ),
                  Expanded(
                    flex: _kPgSellFlex,
                    child: Text(
                        '\$${_priceFmt.format(e.bestSellPrice)}',
                        style: TextStyle(color: metalColor, fontSize: 11),
                        textAlign: TextAlign.right),
                  ),
                  Expanded(
                    flex: _kPgBuyFlex,
                    child: Text(
                        '\$${_priceFmt.format(e.bestBuybackPrice)}',
                        style: TextStyle(color: cs.onSurface, fontSize: 11),
                        textAlign: TextAlign.right),
                  ),
                  Expanded(
                    flex: _kPgSpreadFlex,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '\$${_priceFmt.format(e.spreadDollar)}',
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 11),
                        ),
                        const SizedBox(width: 4),
                        MovementArrow(
                          movementUp: e.movementUp,
                          color: SignalColorHelper.movementColor(
                              e.movementUp,
                              lowerIsBetter: true),
                          size: 11,
                        ),
                      ],
                    ),
                  ),
                ]),
              );
            }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Chart Widget ─────────────────────────────────────────────────────────────

class _PgChart extends StatelessWidget {
  final List<LocalSpreadEntry> entries; // oldest-first
  final String metalType;

  const _PgChart({required this.entries, required this.metalType});

  List<FlSpot> _trendLine(List<FlSpot> spots) {
    final n = spots.length;
    if (n < 2) return [];
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (final s in spots) {
      sumX += s.x;
      sumY += s.y;
      sumXY += s.x * s.y;
      sumX2 += s.x * s.x;
    }
    final denom = n * sumX2 - sumX * sumX;
    if (denom == 0) return [];
    final slope = (n * sumXY - sumX * sumY) / denom;
    final intercept = (sumY - slope * sumX) / n;
    final lastX = spots.last.x;
    return [
      FlSpot(0, intercept),
      FlSpot(lastX, slope * lastX + intercept),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final metalColor = MetalColorHelper.getColorForMetalString(metalType);
    const buybackColor = AppColors.priceBuyback;
    final gridColor = cs.outlineVariant.withValues(alpha: 0.12);

    final sellSpots = entries
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.bestSellPrice))
        .toList();
    final buySpots = entries
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.bestBuybackPrice))
        .toList();

    final sellTrend = _trendLine(sellSpots);
    final buyTrend = _trendLine(buySpots);

    final allPrices = [
      ...entries.map((e) => e.bestSellPrice),
      ...entries.map((e) => e.bestBuybackPrice),
    ];
    final minY =
        (allPrices.reduce((a, b) => a < b ? a : b) * 0.995).floorToDouble();
    final maxY =
        (allPrices.reduce((a, b) => a > b ? a : b) * 1.005).ceilToDouble();

    final step = (entries.length / 4).ceil().clamp(1, 999);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          children: [
            _legendLine(metalColor, 'Sell', cs.onSurfaceVariant),
            _legendDash(metalColor.withValues(alpha: 0.6), 'Sell trend',
                cs.onSurfaceVariant),
            _legendLine(buybackColor, 'Buyback', cs.onSurfaceVariant),
            _legendDash(buybackColor.withValues(alpha: 0.4),
                'Buyback trend', cs.onSurfaceVariant),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: gridColor, strokeWidth: 0.5),
              ),
              borderData: FlBorderData(show: false),
              minY: minY,
              maxY: maxY,
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 56,
                    getTitlesWidget: (val, _) => Text(
                      '\$${NumberFormat('#,##0').format(val)}',
                      style: TextStyle(
                          color: cs.onSurfaceVariant, fontSize: 8),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: step.toDouble(),
                    getTitlesWidget: (val, _) {
                      final idx = val.toInt();
                      if (idx < 0 || idx >= entries.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _chartDateFmt.format(entries[idx].date),
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 8),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: sellSpots,
                  color: metalColor,
                  barWidth: 2,
                  isCurved: true,
                  curveSmoothness: 0.25,
                  dotData: FlDotData(
                    show: entries.length <= 14,
                    getDotPainter: (_, __, ___, ____) =>
                        FlDotCirclePainter(
                            radius: 3,
                            color: metalColor,
                            strokeWidth: 0),
                  ),
                  belowBarData: BarAreaData(show: false),
                ),
                if (sellTrend.length == 2)
                  LineChartBarData(
                    spots: sellTrend,
                    color: metalColor.withValues(alpha: 0.6),
                    barWidth: 1.5,
                    isCurved: false,
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                LineChartBarData(
                  spots: buySpots,
                  color: buybackColor,
                  barWidth: 2,
                  isCurved: true,
                  curveSmoothness: 0.25,
                  dotData: FlDotData(
                    show: entries.length <= 14,
                    getDotPainter: (_, __, ___, ____) =>
                        FlDotCirclePainter(
                            radius: 3,
                            color: buybackColor,
                            strokeWidth: 0),
                  ),
                  belowBarData: BarAreaData(show: false),
                ),
                if (buyTrend.length == 2)
                  LineChartBarData(
                    spots: buyTrend,
                    color: buybackColor.withValues(alpha: 0.4),
                    barWidth: 1.5,
                    isCurved: false,
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) =>
                      touchedSpots.map((s) {
                    final idx = s.x.toInt();
                    if (idx < 0 || idx >= entries.length) return null;
                    final labels = [
                      'Sell',
                      'Sell trend',
                      'Buyback',
                      'Buyback trend'
                    ];
                    final colors = [
                      metalColor,
                      metalColor.withValues(alpha: 0.6),
                      buybackColor,
                      buybackColor.withValues(alpha: 0.4),
                    ];
                    final label = s.barIndex < labels.length
                        ? labels[s.barIndex]
                        : '';
                    final color = s.barIndex < colors.length
                        ? colors[s.barIndex]
                        : Colors.white;
                    final dateStr = _chartDateFmt.format(entries[idx].date);
                    return LineTooltipItem(
                      '$dateStr\n\$${NumberFormat('#,##0.00').format(s.y)}',
                      TextStyle(color: color, fontSize: 11),
                      children: [
                        TextSpan(
                          text: '\n$label',
                          style: TextStyle(
                              color: color.withValues(alpha: 0.7),
                              fontSize: 9),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _legendLine(Color color, String label, Color textColor) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 16, height: 2, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: textColor, fontSize: 10)),
        ],
      );

  Widget _legendDash(Color color, String label, Color textColor) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(
              3,
              (_) => Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Container(width: 4, height: 2, color: color),
                  )),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: textColor, fontSize: 10)),
        ],
      );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _pgMetalLabel(String metalType) {
  switch (metalType) {
    case 'gold':
      return 'Gold';
    case 'silver':
      return 'Silver';
    case 'platinum':
      return 'Platinum';
    default:
      return metalType;
  }
}
