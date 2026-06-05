// lib/features/analytics/presentation/screens/local_premium_screen.dart

import 'dart:math' show min, max;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/utils/sort_config.dart';
import 'package:metal_tracker/core/utils/time_service.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/core/widgets/filter_sheet.dart';
import 'package:metal_tracker/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:metal_tracker/features/analytics/presentation/widgets/analytics_widgets.dart';
import 'package:metal_tracker/features/settings/data/models/user_analytics_settings_model.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_prefs_providers.dart';

final _dateFmt = DateFormat(AppDateFormats.date);
final _chartDateFmt = DateFormat(AppDateFormats.chartLabel);
final _priceFmt = NumberFormat('#,##0.00');
final _pctFmt = NumberFormat('+0.00;-0.00');

enum _PremiumSort { date, metal, pct, movement, guide }

// Flex weights for history table columns
const _kLpDateFlex = 22;
const _kLpMetalFlex = 16;
const _kLpPctFlex = 16;
const _kLpMoveFlex = 8;
const _kLpGuideFlex = 38;

class LocalPremiumScreen extends ConsumerStatefulWidget {
  const LocalPremiumScreen({super.key});

  @override
  ConsumerState<LocalPremiumScreen> createState() => _LocalPremiumScreenState();
}

class _LocalPremiumScreenState extends ConsumerState<LocalPremiumScreen> {
  String _range = '30d';
  String? _metalFilter; // null = All
  SortConfig<_PremiumSort> _sortConfig =
      SortConfig.initial(_PremiumSort.date, ascending: false);

  List<LocalPremiumEntry> _filtered(List<LocalPremiumEntry> all) {
    var result = all;
    if (_metalFilter != null) {
      result = result.where((e) => e.metalType == _metalFilter).toList();
    }
    if (_range == 'all') return result;
    final days = _range == '7d' ? 7 : _range == '30d' ? 30 : 90;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return result.where((e) => e.date.isAfter(cutoff)).toList();
  }

  List<LocalPremiumEntry> _sorted(List<LocalPremiumEntry> data) {
    final result = List<LocalPremiumEntry>.from(data);
    _sortConfig.sortList(result, (a, b, col) {
      switch (col) {
        case _PremiumSort.date:
          return a.date.compareTo(b.date);
        case _PremiumSort.metal:
          return a.metalType.compareTo(b.metalType);
        case _PremiumSort.pct:
          return a.premiumPct.compareTo(b.premiumPct);
        case _PremiumSort.movement:
          final av = a.movementUp == null ? 0 : (a.movementUp! ? 1 : -1);
          final bv = b.movementUp == null ? 0 : (b.movementUp! ? 1 : -1);
          return av.compareTo(bv);
        case _PremiumSort.guide:
          return a.guide.compareTo(b.guide);
      }
    });
    return result;
  }

  void _onHeaderTap(_PremiumSort col) {
    setState(() {
      _sortConfig = _sortConfig.tap(col, defaultAscending: (_) => false);
    });
  }

  void _showFilterSheet() {
    FilterSheet.show(
      context: context,
      title: 'Filter Local Premium',
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
    final historyAsync = ref.watch(localPremiumHistoryProvider);
    final summaryAsync = ref.watch(localPremiumSummaryProvider);
    final settings =
        ref.watch(userAnalyticsPrefsNotifierProvider).valueOrNull;

    return AppScaffold(
      title: 'Local Premium',
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
          child: CircularProgressIndicator(color: AppColors.primaryGold),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.lossRed)),
        ),
        data: (history) {
          final filtered = _filtered(history);
          final sorted = _sorted(filtered);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Info card ───────────────────────────────────────────────
              _InfoCard(),
              const SizedBox(height: 16),

              // ── Today's summary table ────────────────────────────────────
              summaryAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (summary) =>
                    _SummaryTable(summary: summary, settings: settings),
              ),
              const SizedBox(height: 16),

              // ── Chart card (range chips inside) ──────────────────────────
              _PremiumChartCard(
                entries: filtered,
                range: _range,
                settings: settings,
                onRangeChanged: (r) => setState(() => _range = r),
              ),
              const SizedBox(height: 16),

              // ── History table ────────────────────────────────────────────
              if (sorted.isNotEmpty)
                _HistoryTable(
                  entries: sorted,
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.public, color: AppColors.primaryGold, size: 18),
                SizedBox(width: 8),
                Text(
                  'Geographic Premium',
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
              'Compares the best available local spot price (lowest across all retailers) '
              'against the global spot price.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 10),
            _GuideRow(
              color: AppColors.lossRed,
              icon: Icons.block,
              label: '≥ ${(settings?.lpHighMark ?? 2.0).toStringAsFixed(0)}%',
              text: settings?.lpHighText ??
                  'Avoid buying — local supply shortage or high import costs',
            ),
            const SizedBox(height: 4),
            _GuideRow(
              color: AppColors.gainGreen,
              icon: Icons.shopping_cart,
              label: '< ${(settings?.lpLowMark ?? 0.0).toStringAsFixed(0)}%',
              text: settings?.lpLowText ?? 'Buy now — local price below global',
            ),
            const SizedBox(height: 4),
            _GuideRow(
              color: AppColors.textSecondary,
              icon: Icons.search,
              label:
                  '${(settings?.lpLowMark ?? 0.0).toStringAsFixed(0)}–${(settings?.lpHighMark ?? 2.0).toStringAsFixed(0)}%',
              text: settings?.lpMidText ?? 'Consider other factors',
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideRow extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final String text;

  const _GuideRow({
    required this.color,
    required this.icon,
    required this.label,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
        ),
      ],
    );
  }
}

// ─── Summary Table (today's values) ──────────────────────────────────────────

class _SummaryTable extends StatelessWidget {
  final List<LocalPremiumEntry> summary;
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
              'Latest Premium by Metal',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            // Header
            _tableRow(
              metal: 'Metal',
              global: 'Global',
              local: 'Local',
              pct: 'Premium',
              move: '',
              guide: 'Guide',
              isHeader: true,
            ),
            const Divider(color: Colors.white12, height: 8),
            if (summary.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No data — fetch both global and local spot prices.',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              )
            else
              ...summary.map((e) => _tableRow(
                    metal: _metalLabel(e.metalType),
                    global: '\$${_priceFmt.format(e.globalSpot)}',
                    local: '\$${_priceFmt.format(e.bestLocalSpot)}',
                    pct: '${_pctFmt.format(e.premiumPct)}%',
                    move: e.movementUp == null
                        ? '—'
                        : (e.movementUp! ? '▲' : '▼'),
                    guide: e.guide,
                    metalColor: MetalColorHelper.getColorForMetalString(e.metalType),
                    pctColor: _premiumPctColor(e.premiumPct, settings),
                    moveColor: e.movementUp == null
                        ? AppColors.textSecondary
                        : (e.movementUp! ? AppColors.gainGreen : AppColors.lossRed),
                    guideColor: standardGuideColor(
                        e.guide,
                        settings?.lpLowText ?? 'Buy Now',
                        settings?.lpHighText ?? 'Avoid'),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _tableRow({
    required String metal,
    required String global,
    required String local,
    required String pct,
    required String move,
    required String guide,
    bool isHeader = false,
    Color? metalColor,
    Color? pctColor,
    Color? moveColor,
    Color? guideColor,
  }) {
    final style = TextStyle(
      color: isHeader ? AppColors.textSecondary : AppColors.textPrimary,
      fontSize: isHeader ? 11 : 12,
      fontWeight: isHeader ? FontWeight.w500 : FontWeight.normal,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 14,
            child: Text(
              metal,
              style: isHeader
                  ? style
                  : style.copyWith(
                      color: metalColor,
                      fontWeight: FontWeight.w600,
                    ),
            ),
          ),
          Expanded(
            flex: 20,
            child: Text(global, style: style, textAlign: TextAlign.right),
          ),
          Expanded(
            flex: 20,
            child: Text(local, style: style, textAlign: TextAlign.right),
          ),
          Expanded(
            flex: 16,
            child: Text(
              pct,
              style: isHeader ? style : style.copyWith(color: pctColor),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 8,
            child: Text(
              move,
              style: isHeader ? style : style.copyWith(color: moveColor),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 22,
            child: Text(
              guide,
              style: isHeader ? style : style.copyWith(color: guideColor, fontSize: 11),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chart Card (range chips + chart) ────────────────────────────────────────

class _PremiumChartCard extends StatelessWidget {
  final List<LocalPremiumEntry> entries;
  final String range;
  final UserAnalyticsSettings? settings;
  final ValueChanged<String> onRangeChanged;

  const _PremiumChartCard({
    required this.entries,
    required this.range,
    this.settings,
    required this.onRangeChanged,
  });

  List<LocalPremiumEntry> _rangeFiltered() {
    if (range == 'all') return entries;
    final days = range == '7d' ? 7 : range == '30d' ? 30 : 90;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return entries.where((e) => e.date.isAfter(cutoff)).toList();
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
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'No data for selected range.\nFetch global and local spot prices first.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
              )
            else
              _PremiumChart(entries: filtered, settings: settings),
          ],
        ),
      ),
    );
  }
}

// ─── Premium Chart ────────────────────────────────────────────────────────────

class _PremiumChart extends StatelessWidget {
  final List<LocalPremiumEntry> entries;
  final UserAnalyticsSettings? settings;

  const _PremiumChart({required this.entries, this.settings});

  @override
  Widget build(BuildContext context) {
    // Group by metal, collect unique dates sorted oldest-first
    final metals = ['gold', 'silver', 'platinum'];
    final byMetal = <String, Map<String, double>>{};
    for (final m in metals) {
      byMetal[m] = {};
    }

    // entries are newest-first; reverse to oldest-first for chart
    for (final e in entries.reversed) {
      final dayKey =
          '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}';
      byMetal[e.metalType]?[dayKey] = e.premiumPct;
    }

    final allDayKeys = byMetal.values
        .expand((m) => m.keys)
        .toSet()
        .toList()
      ..sort();

    if (allDayKeys.isEmpty) return const SizedBox.shrink();

    final metalColors = {
      'gold': AppColors.primaryGold,
      'silver': AppColors.secondarySilver,
      'platinum': AppColors.accentPlatinum,
    };

    final lines = metals.where((m) => byMetal[m]!.isNotEmpty).map((m) {
      final spots = <FlSpot>[];
      for (var i = 0; i < allDayKeys.length; i++) {
        final val = byMetal[m]![allDayKeys[i]];
        if (val != null) spots.add(FlSpot(i.toDouble(), val));
      }
      return LineChartBarData(
        spots: spots,
        color: metalColors[m],
        barWidth: 2,
        isCurved: true,
        curveSmoothness: 0.25,
        dotData: FlDotData(
          show: allDayKeys.length <= 14,
          getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
            radius: 3,
            color: metalColors[m]!,
            strokeWidth: 0,
          ),
        ),
        belowBarData: BarAreaData(show: false),
      );
    }).toList();

    // Y axis bounds
    final allVals = byMetal.values
        .expand((m) => m.values)
        .toList();
    final highThreshold = settings?.lpHighMark ?? 2.0;
    final lowThreshold = settings?.lpLowMark ?? -2.0;
    final dataMin = allVals.reduce((a, b) => a < b ? a : b);
    final dataMax = allVals.reduce((a, b) => a > b ? a : b);
    final minY = min(dataMin - 0.5, lowThreshold - 0.5).floorToDouble();
    final maxY = max(dataMax + 0.5, highThreshold + 0.5).ceilToDouble();

    // X axis: show up to 6 labels
    final step = (allDayKeys.length / 5).ceil().clamp(1, 999);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 12),
              child: Text(
                'Local Premium Trend (%)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Legend
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 12),
              child: Wrap(
                spacing: 16,
                children: metals
                    .where((m) => byMetal[m]!.isNotEmpty)
                    .map((m) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 16,
                              height: 3,
                              color: metalColors[m],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _metalLabel(m),
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11),
                            ),
                          ],
                        ))
                    .toList(),
              ),
            ),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (val) {
                      if (val.abs() < 0.01) {
                        return const FlLine(
                            color: Colors.white24, strokeWidth: 1.2);
                      }
                      if ((val - highThreshold).abs() < 0.01) {
                        return FlLine(
                            color: AppColors.lossRed.withValues(alpha: 0.4),
                            strokeWidth: 1.2,
                            dashArray: [4, 4]);
                      }
                      if ((val - lowThreshold).abs() < 0.01) {
                        return FlLine(
                            color: AppColors.gainGreen.withValues(alpha: 0.4),
                            strokeWidth: 1.2,
                            dashArray: [4, 4]);
                      }
                      return const FlLine(
                          color: Colors.white10, strokeWidth: 0.5);
                    },
                  ),
                  extraLinesData: ExtraLinesData(horizontalLines: [
                    HorizontalLine(
                      y: highThreshold,
                      color: AppColors.lossRed.withValues(alpha: 0.4),
                      strokeWidth: 1.2,
                      dashArray: [4, 4],
                    ),
                    HorizontalLine(
                      y: lowThreshold,
                      color: AppColors.gainGreen.withValues(alpha: 0.4),
                      strokeWidth: 1.2,
                      dashArray: [4, 4],
                    ),
                  ]),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: 1,
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
                          if (idx < 0 || idx >= allDayKeys.length) {
                            return const SizedBox.shrink();
                          }
                          final date = DateTime.parse(allDayKeys[idx]);
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _chartDateFmt.format(date),
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
                  lineBarsData: lines,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((s) {
                        final idx = s.x.toInt();
                        final dateStr = idx < allDayKeys.length
                            ? _chartDateFmt
                                .format(DateTime.parse(allDayKeys[idx]))
                            : '';
                        final m = metals
                            .where((m) => byMetal[m]!.isNotEmpty)
                            .elementAt(s.barIndex);
                        return LineTooltipItem(
                          '$dateStr\n${_metalLabel(m)}: ${_pctFmt.format(s.y)}%',
                          TextStyle(
                              color: metalColors[m], fontSize: 11),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── History Table ────────────────────────────────────────────────────────────

class _HistoryTable extends StatelessWidget {
  final List<LocalPremiumEntry> entries;
  final SortConfig<_PremiumSort> sortConfig;
  final ValueChanged<_PremiumSort> onHeaderTap;
  final UserAnalyticsSettings? settings;

  const _HistoryTable({
    required this.entries,
    required this.sortConfig,
    required this.onHeaderTap,
    this.settings,
  });

  Widget _headerCell(String label, _PremiumSort col, int flex,
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
    final lowLabel = settings?.lpLowText ?? 'Buy Now';
    final highLabel = settings?.lpHighText ?? 'Avoid';

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
          // Sortable header
          Container(
            color: AppColors.backgroundCard,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: Row(
              children: [
                _headerCell('Date', _PremiumSort.date, _kLpDateFlex),
                _headerCell('Metal', _PremiumSort.metal, _kLpMetalFlex),
                _headerCell('Premium', _PremiumSort.pct, _kLpPctFlex,
                    align: TextAlign.right),
                _headerCell('', _PremiumSort.movement, _kLpMoveFlex),
                _headerCell('Guide', _PremiumSort.guide, _kLpGuideFlex,
                    align: TextAlign.right),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          ...entries.map((e) {
            final metalColor =
                MetalColorHelper.getColorForMetalString(e.metalType);
            final pctColor = _premiumPctColor(e.premiumPct, settings);
            final moveColor = e.movementUp == null
                ? AppColors.textSecondary
                : (e.movementUp! ? AppColors.gainGreen : AppColors.lossRed);
            final guideColor =
                standardGuideColor(e.guide, lowLabel, highLabel);
            const base =
                TextStyle(fontSize: 12);
            return Container(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
              decoration: const BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: _kLpDateFlex,
                    child: Text(_dateFmt.format(e.date),
                        style: base.copyWith(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ),
                  Expanded(
                    flex: _kLpMetalFlex,
                    child: Text(_metalLabel(e.metalType),
                        style: base.copyWith(
                            color: metalColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11)),
                  ),
                  Expanded(
                    flex: _kLpPctFlex,
                    child: Text('${_pctFmt.format(e.premiumPct)}%',
                        style: base.copyWith(color: pctColor, fontSize: 11),
                        textAlign: TextAlign.right),
                  ),
                  Expanded(
                    flex: _kLpMoveFlex,
                    child: Text(
                      e.movementUp == null
                          ? '—'
                          : (e.movementUp! ? '▲' : '▼'),
                      style: base.copyWith(color: moveColor, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: _kLpGuideFlex,
                    child: Text(e.guide,
                        style: base.copyWith(
                            color: guideColor, fontSize: 11),
                        textAlign: TextAlign.right),
                  ),
                ],
              ),
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

Color _premiumPctColor(double pct, UserAnalyticsSettings? settings) {
  final high = settings?.lpHighMark ?? 2.0;
  final low = settings?.lpLowMark ?? -2.0;
  if (pct >= high) return AppColors.lossRed;
  if (pct < low) return AppColors.gainGreen;
  return AppColors.textPrimary;
}
