// lib/features/analytics/presentation/screens/price_guide_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/core/utils/sort_config.dart';
import 'package:metal_tracker/core/utils/time_service.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/core/widgets/filter_sheet.dart';
import 'package:metal_tracker/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:metal_tracker/features/analytics/presentation/widgets/analytics_widgets.dart';

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
  String? _metalFilter;
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
      body: historyAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
        data: (allHistory) => _buildContent(allHistory),
      ),
    );
  }

  Widget _buildContent(List<LocalSpreadEntry> allHistory) {
    final filtered = _metalFilter != null
        ? allHistory.where((e) => e.metalType == _metalFilter).toList()
        : allHistory;

    final chartMetal = _metalFilter ?? 'gold';

    final now = DateTime.now();
    final cutoff = switch (_range) {
      '7d' => now.subtract(const Duration(days: 7)),
      '30d' => now.subtract(const Duration(days: 30)),
      '90d' => now.subtract(const Duration(days: 90)),
      _ => DateTime(2000),
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Info Card ───────────────────────────────────────────────────────
        const Card(
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_up,
                        color: AppColors.primaryGold, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'About Price Guide',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Tracks the best available sell and buyback prices over time. '
                  'Use this to spot pricing trends and compare price changes across metals.',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Summary Card ────────────────────────────────────────────────────
        _SummaryCard(history: allHistory, metalFilter: _metalFilter),
        const SizedBox(height: 16),

        // ── Chart Card ──────────────────────────────────────────────────────
        _ChartCard(
          allHistory: allHistory,
          metalType: chartMetal,
          range: _range,
          cutoff: cutoff,
          onRangeChanged: (r) => setState(() => _range = r),
        ),
        const SizedBox(height: 16),

        // ── History Card ────────────────────────────────────────────────────
        _HistoryCard(
          entries: _sorted(filtered),
          sortConfig: _sortConfig,
          onHeaderTap: _onHeaderTap,
        ),
      ],
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
    final metals = metalFilter != null
        ? [metalFilter!]
        : ['gold', 'silver', 'platinum'];

    final latestByMetal = <String, LocalSpreadEntry>{};
    for (final metal in metals) {
      final entries = history.where((e) => e.metalType == metal).toList();
      if (entries.isNotEmpty) {
        latestByMetal[metal] = entries.first; // history is newest-first
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Prices',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (latestByMetal.isEmpty)
              const Text(
                'No data yet — fetch live prices first.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
                                const Text('Sell',
                                    style: TextStyle(
                                        color: AppColors.textSecondary,
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
                                const Text('Buyback',
                                    style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11)),
                                const SizedBox(width: 6),
                                Text(
                                  '\$${_priceFmt.format(e.bestBuybackPrice)}',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
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

// ─── Chart Card ───────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final List<LocalSpreadEntry> allHistory;
  final String metalType;
  final String range;
  final DateTime cutoff;
  final ValueChanged<String> onRangeChanged;

  const _ChartCard({
    required this.allHistory,
    required this.metalType,
    required this.range,
    required this.cutoff,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final entries = allHistory
        .where((e) =>
            e.metalType == metalType && !e.date.isBefore(cutoff))
        .toList()
        .reversed
        .toList(); // oldest-first for chart

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${metalType[0].toUpperCase()}${metalType.substring(1)} Price Trend',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AnalyticsRangeChips(
                  selected: range,
                  onChanged: onRangeChanged,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (entries.length < 2)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'Not enough data for this range.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
              )
            else
              _PgChart(entries: entries, metalType: metalType),
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

  Widget _headerCell(String label, _PgSort col, int flex,
      {TextAlign align = TextAlign.start}) {
    final primary = sortConfig.isPrimary(col);
    final secondary = sortConfig.isSecondary(col);
    final active = primary || secondary;
    final color = primary
        ? AppColors.primaryGold
        : secondary
            ? AppColors.primaryGold.withAlpha(160)
            : AppColors.textSecondary;
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: () => onHeaderTap(col),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: align == TextAlign.right
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
              if (active) ...[
                const SizedBox(width: 2),
                Icon(
                  sortConfig.isAscending(col)
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  size: primary ? 11 : 9,
                  color: color,
                ),
                if (secondary)
                  Text('2',
                      style: TextStyle(
                          color: color,
                          fontSize: 8,
                          fontWeight: FontWeight.w700)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 14, 14, 6),
            child: Text(
              'History',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: Row(
              children: [
                _headerCell('Date', _PgSort.date, _kPgDateFlex),
                _headerCell('Metal', _PgSort.metal, _kPgMetalFlex),
                _headerCell('Sell', _PgSort.sell, _kPgSellFlex,
                    align: TextAlign.right),
                _headerCell('Buyback', _PgSort.buyback, _kPgBuyFlex,
                    align: TextAlign.right),
                _headerCell('Sprd \$', _PgSort.spread, _kPgSpreadFlex,
                    align: TextAlign.right),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No data.',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            )
          else
            ...entries.map((e) {
              final metalColor =
                  MetalColorHelper.getColorForMetalString(e.metalType);
              const base =
                  TextStyle(fontSize: 12);
              return Container(
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
                decoration: const BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: Colors.white10)),
                ),
                child: Row(children: [
                  Expanded(
                    flex: _kPgDateFlex,
                    child: Text(_dateFmt.format(e.date),
                        style: base.copyWith(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ),
                  Expanded(
                    flex: _kPgMetalFlex,
                    child: Text(
                        _pgMetalLabel(e.metalType),
                        style: base.copyWith(
                            color: metalColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11)),
                  ),
                  Expanded(
                    flex: _kPgSellFlex,
                    child: Text(
                        '\$${_priceFmt.format(e.bestSellPrice)}',
                        style: base.copyWith(
                            color: metalColor, fontSize: 11),
                        textAlign: TextAlign.right),
                  ),
                  Expanded(
                    flex: _kPgBuyFlex,
                    child: Text(
                        '\$${_priceFmt.format(e.bestBuybackPrice)}',
                        style: base.copyWith(
                            fontSize: 11),
                        textAlign: TextAlign.right),
                  ),
                  Expanded(
                    flex: _kPgSpreadFlex,
                    child: Text(
                        '\$${_priceFmt.format(e.spreadDollar)}',
                        style: base.copyWith(
                            color: AppColors.textSecondary, fontSize: 11),
                        textAlign: TextAlign.right),
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
    final metalColor = MetalColorHelper.getColorForMetalString(metalType);
    const buybackColor = AppColors.priceBuyback;

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
            _legendLine(metalColor, 'Sell'),
            _legendDash(metalColor.withValues(alpha: 0.6), 'Sell trend'),
            _legendLine(buybackColor, 'Buyback'),
            _legendDash(
                buybackColor.withValues(alpha: 0.4), 'Buyback trend'),
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
                getDrawingHorizontalLine: (_) => const FlLine(
                    color: Colors.white10, strokeWidth: 0.5),
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
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 8),
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
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 8),
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
                        : AppColors.textPrimary;
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

  Widget _legendLine(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 16, height: 2, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 10)),
        ],
      );

  Widget _legendDash(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(
              3,
              (_) => Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Container(width: 4, height: 2, color: color),
                  )),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 10)),
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
