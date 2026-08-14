// lib/features/analytics/presentation/screens/local_spread_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/core/utils/signal_color_helper.dart';
import 'package:metal_tracker/core/utils/sort_config.dart';
import 'package:metal_tracker/core/utils/time_service.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/core/widgets/filter_sheet.dart';
import 'package:metal_tracker/core/widgets/movement_arrow.dart';
import 'package:metal_tracker/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:metal_tracker/core/widgets/card_heading.dart';
import 'package:metal_tracker/core/widgets/table_column_heading.dart';
import 'package:metal_tracker/features/analytics/presentation/widgets/analytics_trend_card.dart';
import 'package:metal_tracker/features/settings/data/models/user_analytics_settings_model.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_prefs_providers.dart';

final _dateFmt = DateFormat(AppDateFormats.date);
final _chartDateFmt = DateFormat(AppDateFormats.chartLabel);
final _priceFmt = NumberFormat('#,##0.00');
final _pctFmt = NumberFormat('0.00');

enum _SpreadSort { date, metal, pct, guide }

const _kLsDateFlex = 20;
const _kLsMetalFlex = 13;
const _kLsPctFlex = 19;
const _kLsGuideFlex = 18;

class LocalSpreadScreen extends ConsumerStatefulWidget {
  const LocalSpreadScreen({super.key});

  @override
  ConsumerState<LocalSpreadScreen> createState() =>
      _LocalSpreadScreenState();
}

class _LocalSpreadScreenState extends ConsumerState<LocalSpreadScreen> {
  String _range = '30d';
  String? _metalFilter;   // filter sheet — controls summary + history table
  String _chartMetal = 'gold'; // chart card metal selector — controls chart only
  SortConfig<_SpreadSort> _sortConfig =
      SortConfig.initial(_SpreadSort.date, ascending: false);

  List<LocalSpreadEntry> _filtered(List<LocalSpreadEntry> all) {
    if (_range == 'all') return all;
    final days = _range == '7d' ? 7 : _range == '30d' ? 30 : 90;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return all.where((e) => e.date.isAfter(cutoff)).toList();
  }

  List<LocalSpreadEntry> _filteredForTable(List<LocalSpreadEntry> all) {
    final byRange = _filtered(all);
    if (_metalFilter == null) return byRange;
    return byRange.where((e) => e.metalType == _metalFilter).toList();
  }

  List<LocalSpreadEntry> _sorted(List<LocalSpreadEntry> data) {
    final result = List<LocalSpreadEntry>.from(data);
    _sortConfig.sortList(result, (a, b, col) {
      switch (col) {
        case _SpreadSort.date:
          return a.date.compareTo(b.date);
        case _SpreadSort.metal:
          return a.metalType.compareTo(b.metalType);
        case _SpreadSort.pct:
          return a.spreadPct.compareTo(b.spreadPct);
        case _SpreadSort.guide:
          return a.guide.compareTo(b.guide);
      }
    });
    return result;
  }

  void _onHeaderTap(_SpreadSort col) {
    setState(() {
      _sortConfig = _sortConfig.tap(col, defaultAscending: (_) => false);
    });
  }

  void _showFilterSheet() {
    FilterSheet.show(
      context: context,
      title: 'Filter Local Spread',
      onReset: () => setState(() => _metalFilter = null),
      builder: (setSheetState) => [
        FilterSection(
          label: 'Metal Type',
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

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(localSpreadHistoryProvider);
    final summaryAsync = ref.watch(localSpreadSummaryProvider);
    final settings =
        ref.watch(userAnalyticsPrefsNotifierProvider).valueOrNull;

    return AppScaffold(
      title: 'Local Spread',
      actions: [
        IconButton(
          icon: Icon(
            Icons.tune,
            size: 20,
            color: _metalFilter != null
                ? AppColors.primaryGold
                : AppColors.textSecondary,
          ),
          tooltip: 'Filter',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onPressed: _showFilterSheet,
        ),
      ],
      onRefresh: () {
        ref.invalidate(localSpreadHistoryProvider);
        ref.invalidate(localSpreadSummaryProvider);
      },
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.lossRed)),
        ),
        data: (history) {
          final cs = Theme.of(context).colorScheme;
          final tableEntries = _filteredForTable(history);
          final sortedEntries = _sorted(tableEntries);
          final chartEntries = _filtered(history)
              .where((e) => e.metalType == _chartMetal)
              .toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _InfoCard(),
              const SizedBox(height: 16),
              summaryAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (summary) {
                  final displaySummary = _metalFilter == null
                      ? summary
                      : summary
                          .where((e) => e.metalType == _metalFilter)
                          .toList();
                  return _SummaryTable(
                      summary: displaySummary, settings: settings);
                },
              ),
              const SizedBox(height: 16),
              AnalyticsTrendCard(
                icon: Icons.show_chart,
                title: 'Spread Trend',
                range: _range,
                onRangeChanged: (r) => setState(() => _range = r),
                selectedMetal: _chartMetal,
                onMetalChanged: (m) =>
                    setState(() => _chartMetal = m ?? 'gold'),
                chart: chartEntries.isEmpty
                    ? Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'No ${_metalLabel(_chartMetal)} spread data for selected range.',
                            style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : _SpreadChart(
                        entries: chartEntries,
                        metalType: _chartMetal,
                        settings: settings),
              ),
              const SizedBox(height: 16),
              if (sortedEntries.isNotEmpty)
                _HistoryTable(
                  entries: sortedEntries,
                  sortConfig: _sortConfig,
                  onHeaderTap: _onHeaderTap,
                  settings: settings,
                ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Info Card ────────────────────────────────────────────────────────────────

class _InfoCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final settings =
        ref.watch(userAnalyticsPrefsNotifierProvider).valueOrNull;

    final lowLabel = settings?.spreadLowLabel ?? 'Buy';
    final midLabel = settings?.spreadMidLabel ?? 'Hold';
    final highLabel = settings?.spreadHighLabel ?? 'Avoid';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CardHeading(
              icon: Icons.compare_arrows,
              title: 'Local Spread',
            ),
            const SizedBox(height: 8),
            Text(
              'The local spread is the difference between sell and buyback prices as a percentage. '
              'A narrower spread means more efficient buying conditions.',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 10),
            _GuideZone(
              color: AppColors.gainGreen,
              icon: Icons.shopping_cart,
              label: lowLabel,
              sublabels: [
                'Gold ≤ ${settings?.spreadGoldBuyPct.toStringAsFixed(0) ?? '2'}%',
                'Silver ≤ ${settings?.spreadSilverBuyPct.toStringAsFixed(0) ?? '10'}%',
                'Platinum ≤ ${settings?.spreadPlatBuyPct.toStringAsFixed(0) ?? '25'}%',
              ],
            ),
            const SizedBox(height: 6),
            _GuideZone(
              color: cs.onSurface,
              icon: Icons.search,
              label: midLabel,
              sublabels: const ['Between buy and avoid thresholds'],
            ),
            const SizedBox(height: 6),
            _GuideZone(
              color: AppColors.lossRed,
              icon: Icons.block,
              label: highLabel,
              sublabels: [
                'Gold ≥ ${settings?.spreadGoldHoldPct.toStringAsFixed(0) ?? '5'}%',
                'Silver ≥ ${settings?.spreadSilverHoldPct.toStringAsFixed(0) ?? '20'}%',
                'Platinum ≥ ${settings?.spreadPlatHoldPct.toStringAsFixed(0) ?? '35'}%',
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideZone extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final List<String> sublabels;

  const _GuideZone({
    required this.color,
    required this.icon,
    required this.label,
    required this.sublabels,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                sublabels.join(' · '),
                style:
                    TextStyle(color: cs.onSurfaceVariant, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Summary Table ────────────────────────────────────────────────────────────

class _SummaryTable extends StatelessWidget {
  final List<LocalSpreadEntry> summary;
  final UserAnalyticsSettings? settings;

  const _SummaryTable({required this.summary, this.settings});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lowLabel = settings?.spreadLowLabel ?? 'Buy';
    final highLabel = settings?.spreadHighLabel ?? 'Avoid';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Latest Spread by Metal',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _headerRow(cs),
            const Divider(height: 8),
            if (summary.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No data — fetch live prices and ensure product profiles are mapped.',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              )
            else
              ...summary.map((e) => _dataRow(e, cs, lowLabel, highLabel)),
          ],
        ),
      ),
    );
  }

  Widget _headerRow(ColorScheme cs) {
    final s = TextStyle(
        color: cs.onSurfaceVariant,
        fontSize: 11,
        fontWeight: FontWeight.w500);
    return Row(children: [
      Expanded(flex: 13, child: Text('Metal', style: s)),
      Expanded(
          flex: 18,
          child: Text('Best Sell', style: s, textAlign: TextAlign.right)),
      Expanded(
          flex: 18,
          child:
              Text('Best Buyback', style: s, textAlign: TextAlign.right)),
      Expanded(
          flex: 14,
          child: Text('Spread \$', style: s, textAlign: TextAlign.right)),
      Expanded(
          flex: 19,
          child: Text('Spread %', style: s, textAlign: TextAlign.right)),
      Expanded(
          flex: 18,
          child: Text('Guide', style: s, textAlign: TextAlign.right)),
    ]);
  }

  Widget _dataRow(
      LocalSpreadEntry e, ColorScheme cs, String lowLabel, String highLabel) {
    final metalColor = MetalColorHelper.getColorForMetalString(e.metalType);
    final guideColor = SignalColorHelper.standardGuideColor(
        e.guide, lowLabel, highLabel);
    final moveColor = SignalColorHelper.movementColor(
        e.movementUp,
        lowerIsBetter: true);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Expanded(
          flex: 13,
          child: Text(
            _metalLabel(e.metalType),
            style: TextStyle(
                color: metalColor,
                fontWeight: FontWeight.w600,
                fontSize: 12),
          ),
        ),
        Expanded(
          flex: 18,
          child: Text('\$${_priceFmt.format(e.bestSellPrice)}',
              style: TextStyle(color: cs.onSurface, fontSize: 12),
              textAlign: TextAlign.right),
        ),
        Expanded(
          flex: 18,
          child: Text('\$${_priceFmt.format(e.bestBuybackPrice)}',
              style: TextStyle(color: cs.onSurface, fontSize: 12),
              textAlign: TextAlign.right),
        ),
        Expanded(
          flex: 14,
          child: Text('\$${_priceFmt.format(e.spreadDollar)}',
              style: TextStyle(color: cs.onSurface, fontSize: 12),
              textAlign: TextAlign.right),
        ),
        Expanded(
          flex: 19,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('${_pctFmt.format(e.spreadPct)}%',
                  style: TextStyle(
                      color: _spreadPctColor(
                          e.metalType, e.spreadPct, settings, cs.onSurface),
                      fontSize: 12)),
              const SizedBox(width: 4),
              MovementArrow(
                movementUp: e.movementUp,
                color: moveColor,
                size: 12,
              ),
            ],
          ),
        ),
        Expanded(
          flex: 18,
          child: Text(e.guide,
              style: TextStyle(color: guideColor, fontSize: 11),
              textAlign: TextAlign.right),
        ),
      ]),
    );
  }
}

// ─── Spread Chart ─────────────────────────────────────────────────────────────

class _SpreadChart extends StatelessWidget {
  final List<LocalSpreadEntry> entries;
  final String metalType;
  final UserAnalyticsSettings? settings;

  const _SpreadChart({
    required this.entries,
    required this.metalType,
    this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gridColor = cs.outlineVariant.withValues(alpha: 0.12);
    final trendColor = cs.onSurface.withValues(alpha: 0.35);

    final double buyThreshold;
    final double holdThreshold;
    if (settings != null) {
      switch (metalType) {
        case 'gold':
          buyThreshold = settings!.spreadGoldBuyPct;
          holdThreshold = settings!.spreadGoldHoldPct;
        case 'silver':
          buyThreshold = settings!.spreadSilverBuyPct;
          holdThreshold = settings!.spreadSilverHoldPct;
        case 'platinum':
          buyThreshold = settings!.spreadPlatBuyPct;
          holdThreshold = settings!.spreadPlatHoldPct;
        default:
          buyThreshold = 0;
          holdThreshold = 100;
      }
    } else {
      switch (metalType) {
        case 'gold':
          buyThreshold = 2.0;
          holdThreshold = 5.0;
        case 'silver':
          buyThreshold = 10.0;
          holdThreshold = 20.0;
        case 'platinum':
          buyThreshold = 25.0;
          holdThreshold = 35.0;
        default:
          buyThreshold = 0;
          holdThreshold = 100;
      }
    }

    final sorted = entries.reversed.toList();
    final n = sorted.length;
    final spots = sorted
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.spreadPct))
        .toList();

    List<FlSpot> trendSpots = [];
    if (n >= 2) {
      double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
      for (var i = 0; i < n; i++) {
        final y = sorted[i].spreadPct;
        sumX += i;
        sumY += y;
        sumXY += i * y;
        sumX2 += i * i.toDouble();
      }
      final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
      final intercept = (sumY - slope * sumX) / n;
      trendSpots = [
        FlSpot(0, intercept),
        FlSpot((n - 1).toDouble(), slope * (n - 1) + intercept),
      ];
    }

    final metalColor = MetalColorHelper.getColorForMetalString(metalType);

    final allVals = sorted.map((e) => e.spreadPct).toList();
    final minY = (allVals.reduce((a, b) => a < b ? a : b) - 1)
        .floorToDouble()
        .clamp(0, 999)
        .toDouble();
    final maxY =
        (allVals.reduce((a, b) => a > b ? a : b) + 1).ceilToDouble();

    final step = (sorted.length / 5).ceil().clamp(1, 999);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Text(
            '${_metalLabel(metalType)} Spread Trend (%)',
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Wrap(
            spacing: 12,
            children: [
              _legendDot(metalColor, 'Spread', cs.onSurfaceVariant),
              _legendDash(trendColor, 'Trend', cs.onSurfaceVariant),
              _legendDot(AppColors.gainGreen,
                  '${settings?.spreadLowLabel ?? 'Buy'} ≤ ${buyThreshold.toStringAsFixed(0)}%',
                  cs.onSurfaceVariant),
              _legendDot(AppColors.lossRed,
                  '${settings?.spreadHighLabel ?? 'Avoid'} ≥ ${holdThreshold.toStringAsFixed(0)}%',
                  cs.onSurfaceVariant),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (val) {
                  if ((val - buyThreshold).abs() < 0.01) {
                    return FlLine(
                        color: AppColors.gainGreen.withValues(alpha: 0.5),
                        strokeWidth: 1.2,
                        dashArray: [4, 4]);
                  }
                  if ((val - holdThreshold).abs() < 0.01) {
                    return FlLine(
                        color: AppColors.lossRed.withValues(alpha: 0.4),
                        strokeWidth: 1.2,
                        dashArray: [4, 4]);
                  }
                  return FlLine(color: gridColor, strokeWidth: 0.5);
                },
              ),
              borderData: FlBorderData(show: false),
              extraLinesData: ExtraLinesData(horizontalLines: [
                HorizontalLine(
                  y: buyThreshold,
                  color: AppColors.gainGreen.withValues(alpha: 0.5),
                  strokeWidth: 1.2,
                  dashArray: [4, 4],
                ),
                HorizontalLine(
                  y: holdThreshold,
                  color: AppColors.lossRed.withValues(alpha: 0.4),
                  strokeWidth: 1.2,
                  dashArray: [4, 4],
                ),
              ]),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: (maxY - minY) / 4,
                    getTitlesWidget: (val, _) => Text(
                      '${val.toStringAsFixed(0)}%',
                      style: TextStyle(
                          color: cs.onSurfaceVariant, fontSize: 9),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: step.toDouble(),
                    getTitlesWidget: (val, _) {
                      final idx = val.toInt();
                      if (idx < 0 || idx >= sorted.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _chartDateFmt.format(sorted[idx].date),
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 9),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              minY: minY,
              maxY: maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  color: metalColor,
                  barWidth: 2,
                  isCurved: true,
                  curveSmoothness: 0.25,
                  dotData: FlDotData(
                    show: sorted.length <= 14,
                    getDotPainter: (_, __, ___, ____) =>
                        FlDotCirclePainter(
                      radius: 3,
                      color: metalColor,
                      strokeWidth: 0,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: metalColor.withValues(alpha: 0.07),
                  ),
                ),
                if (trendSpots.length == 2)
                  LineChartBarData(
                    spots: trendSpots,
                    color: trendColor,
                    barWidth: 1.5,
                    isCurved: false,
                    dashArray: [6, 4],
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((s) {
                    final idx = s.x.toInt();
                    final dateStr = idx < sorted.length
                        ? _chartDateFmt.format(sorted[idx].date)
                        : '';
                    return LineTooltipItem(
                      '$dateStr\n${_pctFmt.format(s.y)}%',
                      TextStyle(color: metalColor, fontSize: 11),
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

  Widget _legendDot(Color color, String label, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 2, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: textColor, fontSize: 10)),
      ],
    );
  }

  Widget _legendDash(Color color, String label, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Container(width: 4, height: 2, color: color),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: textColor, fontSize: 10)),
      ],
    );
  }
}

// ─── History Table ────────────────────────────────────────────────────────────

class _HistoryTable extends StatelessWidget {
  final List<LocalSpreadEntry> entries;
  final SortConfig<_SpreadSort> sortConfig;
  final ValueChanged<_SpreadSort> onHeaderTap;
  final UserAnalyticsSettings? settings;

  const _HistoryTable({
    required this.entries,
    required this.sortConfig,
    required this.onHeaderTap,
    this.settings,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lowLabel = settings?.spreadLowLabel ?? 'Buy';
    final highLabel = settings?.spreadHighLabel ?? 'Avoid';

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
                  flex: _kLsDateFlex,
                  onTap: () => onHeaderTap(_SpreadSort.date),
                  sortActive: sortConfig.isActive(_SpreadSort.date),
                  sortAscending: sortConfig.isAscending(_SpreadSort.date),
                  sortSecondary: sortConfig.isSecondary(_SpreadSort.date),
                ),
                TableColumnHeading(
                  label: 'Metal',
                  flex: _kLsMetalFlex,
                  onTap: () => onHeaderTap(_SpreadSort.metal),
                  sortActive: sortConfig.isActive(_SpreadSort.metal),
                  sortAscending: sortConfig.isAscending(_SpreadSort.metal),
                  sortSecondary: sortConfig.isSecondary(_SpreadSort.metal),
                ),
                TableColumnHeading(
                  label: 'Spread %',
                  flex: _kLsPctFlex,
                  align: TextAlign.right,
                  onTap: () => onHeaderTap(_SpreadSort.pct),
                  sortActive: sortConfig.isActive(_SpreadSort.pct),
                  sortAscending: sortConfig.isAscending(_SpreadSort.pct),
                  sortSecondary: sortConfig.isSecondary(_SpreadSort.pct),
                ),
                TableColumnHeading(
                  label: 'Guide',
                  flex: _kLsGuideFlex,
                  align: TextAlign.right,
                  onTap: () => onHeaderTap(_SpreadSort.guide),
                  sortActive: sortConfig.isActive(_SpreadSort.guide),
                  sortAscending: sortConfig.isAscending(_SpreadSort.guide),
                  sortSecondary: sortConfig.isSecondary(_SpreadSort.guide),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...entries.map((e) {
            final metalColor =
                MetalColorHelper.getColorForMetalString(e.metalType);
            final moveColor = SignalColorHelper.movementColor(
                e.movementUp,
                lowerIsBetter: true);
            return Container(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.15))),
              ),
              child: Row(children: [
                Expanded(
                  flex: _kLsDateFlex,
                  child: Text(_dateFmt.format(e.date),
                      style: TextStyle(
                          color: cs.onSurfaceVariant, fontSize: 11)),
                ),
                Expanded(
                  flex: _kLsMetalFlex,
                  child: Text(_metalLabel(e.metalType),
                      style: TextStyle(
                          color: metalColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11)),
                ),
                Expanded(
                  flex: _kLsPctFlex,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('${_pctFmt.format(e.spreadPct)}%',
                          style: TextStyle(
                              color: _spreadPctColor(
                                  e.metalType, e.spreadPct, settings,
                                  cs.onSurface),
                              fontSize: 11)),
                      const SizedBox(width: 4),
                      MovementArrow(
                        movementUp: e.movementUp,
                        color: moveColor,
                        size: 11,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: _kLsGuideFlex,
                  child: Text(e.guide,
                      style: TextStyle(
                          color: SignalColorHelper.standardGuideColor(
                              e.guide, lowLabel, highLabel),
                          fontSize: 11),
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

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _metalLabel(String metalType) {
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

Color _spreadPctColor(
    String metal, double pct, UserAnalyticsSettings? settings, Color neutral) {
  final double buy;
  final double hold;
  switch (metal) {
    case 'silver':
      buy = settings?.spreadSilverBuyPct ?? 10.0;
      hold = settings?.spreadSilverHoldPct ?? 20.0;
    case 'platinum':
      buy = settings?.spreadPlatBuyPct ?? 25.0;
      hold = settings?.spreadPlatHoldPct ?? 35.0;
    default:
      buy = settings?.spreadGoldBuyPct ?? 2.0;
      hold = settings?.spreadGoldHoldPct ?? 5.0;
  }
  if (pct <= buy) return AppColors.gainGreen;
  if (pct >= hold) return AppColors.lossRed;
  return neutral;
}
