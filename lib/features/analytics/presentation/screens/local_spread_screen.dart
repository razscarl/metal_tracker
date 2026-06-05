// lib/features/analytics/presentation/screens/local_spread_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/utils/sort_config.dart';
import 'package:metal_tracker/core/utils/time_service.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/core/widgets/filter_sheet.dart';
import 'package:metal_tracker/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:metal_tracker/features/analytics/presentation/widgets/analytics_widgets.dart';
import 'package:metal_tracker/features/settings/data/models/user_analytics_settings_model.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_prefs_providers.dart';

final _dateFmt = DateFormat(AppDateFormats.date);
final _chartDateFmt = DateFormat(AppDateFormats.chartLabel);
final _priceFmt = NumberFormat('#,##0.00');
final _pctFmt = NumberFormat('0.00');

enum _SpreadSort { date, metal, pct, movement, guide }

const _kLsDateFlex = 20;
const _kLsMetalFlex = 13;
const _kLsPctFlex = 13;
const _kLsMoveFlex = 6;
const _kLsGuideFlex = 18;

class LocalSpreadScreen extends ConsumerStatefulWidget {
  const LocalSpreadScreen({super.key});

  @override
  ConsumerState<LocalSpreadScreen> createState() => _LocalSpreadScreenState();
}

class _LocalSpreadScreenState extends ConsumerState<LocalSpreadScreen> {
  String _range = '30d';
  String? _metalFilter; // null = All (applies to chart + history table)
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
        case _SpreadSort.movement:
          final av = a.movementUp == null ? 0 : (a.movementUp! ? 1 : -1);
          final bv = b.movementUp == null ? 0 : (b.movementUp! ? 1 : -1);
          return av.compareTo(bv);
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
      body: historyAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.lossRed)),
        ),
        data: (history) {
          // Chart metal: use filter selection or default to gold
          final chartMetal = _metalFilter ?? 'gold';
          final tableEntries = _filteredForTable(history);
          final sortedEntries = _sorted(tableEntries);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _InfoCard(),
              const SizedBox(height: 16),

              // Today's summary table
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

              // Chart card (range chips inside)
              _SpreadChartCard(
                allEntries: _filtered(history)
                    .where((e) => e.metalType == chartMetal)
                    .toList(),
                metalType: chartMetal,
                range: _range,
                onRangeChanged: (r) => setState(() => _range = r),
                settings: settings,
              ),
              const SizedBox(height: 16),

              // History table
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
    final settings =
        ref.watch(userAnalyticsPrefsNotifierProvider).valueOrNull;

    final lowLabel  = settings?.spreadLowLabel  ?? 'Buy';
    final midLabel  = settings?.spreadMidLabel  ?? 'Hold';
    final highLabel = settings?.spreadHighLabel ?? 'Avoid';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.compare_arrows,
                    color: AppColors.primaryGold, size: 18),
                SizedBox(width: 8),
                Text(
                  'Local Spread',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'The local spread is the difference between sell and buyback prices as a percentage. '
              'A narrower spread means more efficient buying conditions.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 10),
            // ── Investment guidance zones ─────────────────────────────────
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
              color: AppColors.textSecondary,
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
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 10),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Latest Spread by Metal',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _headerRow(),
            const Divider(color: Colors.white12, height: 8),
            if (summary.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No data — fetch live prices and ensure product profiles are mapped.',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              )
            else
              ...summary.map(_dataRow),
          ],
        ),
      ),
    );
  }

  Widget _headerRow() {
    const s = TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w500);
    return Row(children: [
      Expanded(flex: 13, child: Text('Metal', style: s)),
      Expanded(
          flex: 18,
          child:
              Text('Best Sell', style: s, textAlign: TextAlign.right)),
      Expanded(
          flex: 18,
          child: Text('Best Buyback', style: s, textAlign: TextAlign.right)),
      Expanded(
          flex: 14,
          child: Text('Spread \$', style: s, textAlign: TextAlign.right)),
      Expanded(
          flex: 13,
          child: Text('Spread %', style: s, textAlign: TextAlign.right)),
      Expanded(flex: 6, child: const SizedBox()),
      Expanded(
          flex: 18,
          child: Text('Guide', style: s, textAlign: TextAlign.right)),
    ]);
  }

  Widget _dataRow(LocalSpreadEntry e) {
    final metalColor =
        MetalColorHelper.getColorForMetalString(e.metalType);
    final guideColor = standardGuideColor(
        e.guide,
        settings?.spreadLowLabel ?? 'Buy',
        settings?.spreadHighLabel ?? 'Avoid');
    final moveColor = e.movementUp == null
        ? AppColors.textSecondary
        : (e.movementUp! ? AppColors.lossRed : AppColors.gainGreen);

    const base =
        TextStyle(fontSize: 12);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Expanded(
          flex: 13,
          child: Text(
            _metalLabel(e.metalType),
            style: base.copyWith(
                color: metalColor, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          flex: 18,
          child: Text('\$${_priceFmt.format(e.bestSellPrice)}',
              style: base, textAlign: TextAlign.right),
        ),
        Expanded(
          flex: 18,
          child: Text('\$${_priceFmt.format(e.bestBuybackPrice)}',
              style: base, textAlign: TextAlign.right),
        ),
        Expanded(
          flex: 14,
          child: Text('\$${_priceFmt.format(e.spreadDollar)}',
              style: base, textAlign: TextAlign.right),
        ),
        Expanded(
          flex: 13,
          child: Text('${_pctFmt.format(e.spreadPct)}%',
              style: base.copyWith(
                  color: _spreadPctColor(e.metalType, e.spreadPct, settings)),
              textAlign: TextAlign.right),
        ),
        Expanded(
          flex: 6,
          child: e.movementUp == null
              ? const SizedBox()
              : Icon(
                  e.movementUp!
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: moveColor,
                  size: 14,
                ),
        ),
        Expanded(
          flex: 18,
          child: Text(e.guide,
              style: base.copyWith(color: guideColor, fontSize: 11),
              textAlign: TextAlign.right),
        ),
      ]),
    );
  }
}

// ─── Spread Chart Card (range chips + chart) ─────────────────────────────────

class _SpreadChartCard extends StatelessWidget {
  final List<LocalSpreadEntry> allEntries; // range-unfiltered, metal-filtered
  final String metalType;
  final String range;
  final ValueChanged<String> onRangeChanged;
  final UserAnalyticsSettings? settings;

  const _SpreadChartCard({
    required this.allEntries,
    required this.metalType,
    required this.range,
    required this.onRangeChanged,
    this.settings,
  });

  List<LocalSpreadEntry> _rangeFiltered() {
    if (range == 'all') return allEntries;
    final days = range == '7d' ? 7 : range == '30d' ? 30 : 90;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return allEntries.where((e) => e.date.isAfter(cutoff)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _rangeFiltered();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnalyticsRangeChips(selected: range, onChanged: onRangeChanged),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'No ${_metalLabel(metalType)} spread data for selected range.',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              _SpreadChart(
                  entries: filtered, metalType: metalType, settings: settings),
          ],
        ),
      ),
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
    // Compute thresholds from settings or fall back to per-metal defaults
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

    // entries are newest-first; reverse to oldest-first for chart
    final sorted = entries.reversed.toList();
    final n = sorted.length;
    final spots = sorted
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.spreadPct))
        .toList();

    // Linear regression trendline
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

    final metalColor =
        MetalColorHelper.getColorForMetalString(metalType);

    final allVals = sorted.map((e) => e.spreadPct).toList();
    final minY = (allVals.reduce((a, b) => a < b ? a : b) - 1).floorToDouble().clamp(0, 999).toDouble();
    final maxY = (allVals.reduce((a, b) => a > b ? a : b) + 1).ceilToDouble();

    final step = (sorted.length / 5).ceil().clamp(1, 999);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Text(
                '${_metalLabel(metalType)} Spread Trend (%)',
                style: const TextStyle(
                  color: AppColors.textPrimary,
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
                  _legendDot(metalColor, 'Spread'),
                  _legendDash(Colors.white54, 'Trend'),
                  _legendDot(AppColors.gainGreen,
                      '${settings?.spreadLowLabel ?? 'Buy'} ≤ ${buyThreshold.toStringAsFixed(0)}%'),
                  _legendDot(AppColors.lossRed,
                      '${settings?.spreadHighLabel ?? 'Avoid'} ≥ ${holdThreshold.toStringAsFixed(0)}%'),
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
                      return const FlLine(
                          color: Colors.white10, strokeWidth: 0.5);
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
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 9),
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
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 9),
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
                    // Actual spread line
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
                    // Linear regression trendline
                    if (trendSpots.length == 2)
                      LineChartBarData(
                        spots: trendSpots,
                        color: Colors.white54,
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

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 2, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 10)),
      ],
    );
  }

  Widget _legendDash(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dashed line representation
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
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 10)),
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

  Widget _headerCell(String label, _SpreadSort col, int flex,
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
    final lowLabel = settings?.spreadLowLabel ?? 'Buy';
    final highLabel = settings?.spreadHighLabel ?? 'Avoid';

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
                _headerCell('Date', _SpreadSort.date, _kLsDateFlex),
                _headerCell('Metal', _SpreadSort.metal, _kLsMetalFlex),
                _headerCell('Spread %', _SpreadSort.pct, _kLsPctFlex,
                    align: TextAlign.right),
                _headerCell('', _SpreadSort.movement, _kLsMoveFlex),
                _headerCell('Guide', _SpreadSort.guide, _kLsGuideFlex,
                    align: TextAlign.right),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          ...entries.map((e) {
            final metalColor =
                MetalColorHelper.getColorForMetalString(e.metalType);
            final moveColor = e.movementUp == null
                ? AppColors.textSecondary
                : (e.movementUp! ? AppColors.lossRed : AppColors.gainGreen);
            const base =
                TextStyle(fontSize: 12);
            return Container(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
              decoration: const BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: Row(children: [
                Expanded(
                  flex: _kLsDateFlex,
                  child: Text(_dateFmt.format(e.date),
                      style: base.copyWith(
                          color: AppColors.textSecondary, fontSize: 11)),
                ),
                Expanded(
                  flex: _kLsMetalFlex,
                  child: Text(_metalLabel(e.metalType),
                      style: base.copyWith(
                          color: metalColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11)),
                ),
                Expanded(
                  flex: _kLsPctFlex,
                  child: Text('${_pctFmt.format(e.spreadPct)}%',
                      style: base.copyWith(
                          color: _spreadPctColor(
                              e.metalType, e.spreadPct, settings),
                          fontSize: 11),
                      textAlign: TextAlign.right),
                ),
                Expanded(
                  flex: _kLsMoveFlex,
                  child: e.movementUp == null
                      ? const SizedBox()
                      : Icon(
                          e.movementUp!
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          color: moveColor,
                          size: 13,
                        ),
                ),
                Expanded(
                  flex: _kLsGuideFlex,
                  child: Text(e.guide,
                      style: base.copyWith(
                          color: standardGuideColor(
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
    String metal, double pct, UserAnalyticsSettings? settings) {
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
  return AppColors.textPrimary;
}
