// lib/features/analytics/presentation/screens/local_premium_screen.dart

import 'dart:math' show min, max;

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
import 'package:metal_tracker/features/analytics/presentation/widgets/analytics_widgets.dart';
import 'package:metal_tracker/features/settings/data/models/user_analytics_settings_model.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_prefs_providers.dart';

final _dateFmt = DateFormat(AppDateFormats.date);
final _chartDateFmt = DateFormat(AppDateFormats.chartLabel);
final _priceFmt = NumberFormat('#,##0.00');
final _pctFmt = NumberFormat('+0.00;-0.00');

enum _PremiumSort { date, metal, pct, movement, guide }

const _kLpDateFlex = 22;
const _kLpMetalFlex = 16;
const _kLpPctFlex = 16;
const _kLpMoveFlex = 8;
const _kLpGuideFlex = 38;

class LocalPremiumScreen extends ConsumerStatefulWidget {
  const LocalPremiumScreen({super.key});

  @override
  ConsumerState<LocalPremiumScreen> createState() =>
      _LocalPremiumScreenState();
}

class _LocalPremiumScreenState extends ConsumerState<LocalPremiumScreen> {
  String _range = '30d';
  String? _metalFilter;
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
      onRefresh: () {
        ref.invalidate(localPremiumHistoryProvider);
        ref.invalidate(localPremiumSummaryProvider);
      },
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
              _InfoCard(),
              const SizedBox(height: 16),
              summaryAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (summary) =>
                    _SummaryTable(summary: summary, settings: settings),
              ),
              const SizedBox(height: 16),
              _PremiumChartCard(
                entries: filtered,
                range: _range,
                settings: settings,
                onRangeChanged: (r) => setState(() => _range = r),
              ),
              const SizedBox(height: 16),
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
    final cs = Theme.of(context).colorScheme;
    final settings =
        ref.watch(userAnalyticsPrefsNotifierProvider).valueOrNull;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.public,
                    color: AppColors.primaryGold, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Local Premium',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Local spot price vs global spot price (lower is better).',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 10),
            _GuideRow(
              color: AppColors.lossRed,
              icon: Icons.block,
              label:
                  '≥ ${(settings?.lpHighMark ?? 2.0).toStringAsFixed(0)}%',
              text: settings?.lpHighText ??
                  'Avoid buying — local supply shortage or high import costs',
            ),
            const SizedBox(height: 4),
            _GuideRow(
              color: AppColors.gainGreen,
              icon: Icons.shopping_cart,
              label:
                  '< ${(settings?.lpLowMark ?? 0.0).toStringAsFixed(0)}%',
              text:
                  settings?.lpLowText ?? 'Buy now — local price below global',
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
    final cs = Theme.of(context).colorScheme;
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
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
        ),
      ],
    );
  }
}

// ─── Summary Table ────────────────────────────────────────────────────────────

class _SummaryTable extends StatelessWidget {
  final List<LocalPremiumEntry> summary;
  final UserAnalyticsSettings? settings;

  const _SummaryTable({required this.summary, this.settings});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lowLabel = settings?.lpLowText ?? 'Buy Now';
    final highLabel = settings?.lpHighText ?? 'Avoid';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Latest Premium by Metal',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _tableRow(
              context: context,
              metal: 'Metal',
              global: 'Global',
              local: 'Local',
              pct: 'Premium',
              moveCell: const SizedBox.shrink(),
              guide: 'Guide',
              isHeader: true,
            ),
            const Divider(height: 8),
            if (summary.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No data — fetch both global and local spot prices.',
                  style:
                      TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              )
            else
              ...summary.map((e) {
                final moveColor = SignalColorHelper.movementColor(
                    e.movementUp,
                    lowerIsBetter: true);
                return _tableRow(
                  context: context,
                  metal: _metalLabel(e.metalType),
                  global: '\$${_priceFmt.format(e.globalSpot)}',
                  local: '\$${_priceFmt.format(e.bestLocalSpot)}',
                  pct: '${_pctFmt.format(e.premiumPct)}%',
                  moveCell: MovementArrow(
                    movementUp: e.movementUp,
                    color: moveColor,
                    size: 11,
                  ),
                  guide: e.guide,
                  metalColor:
                      MetalColorHelper.getColorForMetalString(e.metalType),
                  pctColor: _premiumPctColor(e.premiumPct, settings,
                      cs.onSurface),
                  guideColor: SignalColorHelper.standardGuideColor(
                      e.guide, lowLabel, highLabel),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _tableRow({
    required BuildContext context,
    required String metal,
    required String global,
    required String local,
    required String pct,
    required Widget moveCell,
    required String guide,
    bool isHeader = false,
    Color? metalColor,
    Color? pctColor,
    Color? guideColor,
  }) {
    final cs = Theme.of(context).colorScheme;
    final style = TextStyle(
      color: isHeader ? cs.onSurfaceVariant : cs.onSurface,
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
            child: Center(child: moveCell),
          ),
          Expanded(
            flex: 22,
            child: Text(
              guide,
              style: isHeader
                  ? style
                  : style.copyWith(color: guideColor, fontSize: 11),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chart Card ───────────────────────────────────────────────────────────────

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
    final cs = Theme.of(context).colorScheme;
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
                    'No data for selected range.\nFetch global and local spot prices first.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: cs.onSurfaceVariant, fontSize: 13),
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
// Note: this widget returns a Column directly — it is already inside a Card
// (_PremiumChartCard), so no wrapper Card is needed here.

class _PremiumChart extends StatelessWidget {
  final List<LocalPremiumEntry> entries;
  final UserAnalyticsSettings? settings;

  const _PremiumChart({required this.entries, this.settings});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gridColor = cs.outlineVariant.withValues(alpha: 0.12);
    final zeroLineColor = cs.outlineVariant.withValues(alpha: 0.5);

    final metals = ['gold', 'silver', 'platinum'];
    final byMetal = <String, Map<String, double>>{};
    for (final m in metals) {
      byMetal[m] = {};
    }

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

    const metalColors = {
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

    final allVals =
        byMetal.values.expand((m) => m.values).toList();
    final highThreshold = settings?.lpHighMark ?? 2.0;
    final lowThreshold = settings?.lpLowMark ?? -2.0;
    final dataMin = allVals.reduce((a, b) => a < b ? a : b);
    final dataMax = allVals.reduce((a, b) => a > b ? a : b);
    final minY =
        min(dataMin - 0.5, lowThreshold - 0.5).floorToDouble();
    final maxY =
        max(dataMax + 0.5, highThreshold + 0.5).ceilToDouble();

    final step = (allDayKeys.length / 5).ceil().clamp(1, 999);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            'Local Premium Trend (%)',
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
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 11),
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
                    return FlLine(color: zeroLineColor, strokeWidth: 1.2);
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
                  return FlLine(color: gridColor, strokeWidth: 0.5);
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
                      if (idx < 0 || idx >= allDayKeys.length) {
                        return const SizedBox.shrink();
                      }
                      final date = DateTime.parse(allDayKeys[idx]);
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _chartDateFmt.format(date),
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
                      TextStyle(color: metalColors[m], fontSize: 11),
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

  Widget _headerCell(String label, _PremiumSort col, int flex, ColorScheme cs,
      {TextAlign align = TextAlign.start}) {
    final primary = sortConfig.isPrimary(col);
    final secondary = sortConfig.isSecondary(col);
    final active = primary || secondary;
    final color = primary
        ? AppColors.primaryGold
        : secondary
            ? AppColors.primaryGold.withAlpha(160)
            : cs.onSurfaceVariant;
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
    final cs = Theme.of(context).colorScheme;
    final lowLabel = settings?.lpLowText ?? 'Buy Now';
    final highLabel = settings?.lpHighText ?? 'Avoid';

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
                _headerCell('Date', _PremiumSort.date, _kLpDateFlex, cs),
                _headerCell('Metal', _PremiumSort.metal, _kLpMetalFlex, cs),
                _headerCell('Premium', _PremiumSort.pct, _kLpPctFlex, cs,
                    align: TextAlign.right),
                _headerCell('', _PremiumSort.movement, _kLpMoveFlex, cs),
                _headerCell('Guide', _PremiumSort.guide, _kLpGuideFlex, cs,
                    align: TextAlign.right),
              ],
            ),
          ),
          const Divider(height: 1),
          ...entries.map((e) {
            final metalColor =
                MetalColorHelper.getColorForMetalString(e.metalType);
            final pctColor =
                _premiumPctColor(e.premiumPct, settings, cs.onSurface);
            final moveColor = SignalColorHelper.movementColor(
                e.movementUp,
                lowerIsBetter: true);
            final guideColor =
                SignalColorHelper.standardGuideColor(e.guide, lowLabel, highLabel);
            return Container(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.15))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: _kLpDateFlex,
                    child: Text(_dateFmt.format(e.date),
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 11)),
                  ),
                  Expanded(
                    flex: _kLpMetalFlex,
                    child: Text(_metalLabel(e.metalType),
                        style: TextStyle(
                            color: metalColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11)),
                  ),
                  Expanded(
                    flex: _kLpPctFlex,
                    child: Text('${_pctFmt.format(e.premiumPct)}%',
                        style: TextStyle(color: pctColor, fontSize: 11),
                        textAlign: TextAlign.right),
                  ),
                  Expanded(
                    flex: _kLpMoveFlex,
                    child: Center(
                      child: MovementArrow(
                        movementUp: e.movementUp,
                        color: moveColor,
                        size: 11,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: _kLpGuideFlex,
                    child: Text(e.guide,
                        style: TextStyle(
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

Color _premiumPctColor(
    double pct, UserAnalyticsSettings? settings, Color neutral) {
  final high = settings?.lpHighMark ?? 2.0;
  final low = settings?.lpLowMark ?? -2.0;
  if (pct >= high) return AppColors.lossRed;
  if (pct < low) return AppColors.gainGreen;
  return neutral;
}
