// lib/features/analytics/presentation/screens/gsr_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/utils/signal_color_helper.dart';
import 'package:metal_tracker/core/utils/time_service.dart';
import 'package:metal_tracker/core/utils/sort_config.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/core/widgets/filter_sheet.dart';
import 'package:metal_tracker/core/widgets/movement_arrow.dart';
import 'package:metal_tracker/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:metal_tracker/features/analytics/presentation/widgets/analytics_widgets.dart';
import 'package:metal_tracker/features/settings/data/models/user_analytics_settings_model.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_prefs_providers.dart';

final _dateFmt = DateFormat(AppDateFormats.date);
final _chartDateFmt = DateFormat(AppDateFormats.chartLabel);
final _gsrFmt = NumberFormat('0.00');

// Flex weights
const _kDateFlex = 22;
const _kGsrFlex = 18;
const _kMoveFlex = 14;
const _kGuideFlex = 46;

enum _GsrSort { date, gsr, movement, guide }

class GsrScreen extends ConsumerStatefulWidget {
  const GsrScreen({super.key});

  @override
  ConsumerState<GsrScreen> createState() => _GsrScreenState();
}

class _GsrScreenState extends ConsumerState<GsrScreen> {
  String _range = '30d';
  String? _sourceFilter;
  SortConfig<_GsrSort> _sortConfig =
      SortConfig.initial(_GsrSort.date, ascending: false);

  List<GsrDataPoint> _filtered(List<GsrDataPoint> all) {
    var result = all;
    if (_sourceFilter != null) {
      result = result.where((p) => p.source == _sourceFilter).toList();
    }
    if (_range == 'all') return result;
    final days = _range == '7d'
        ? 7
        : _range == '30d'
            ? 30
            : 90;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return result.where((p) => p.date.isAfter(cutoff)).toList();
  }

  void _showFilterSheet(List<String> availableSources) {
    FilterSheet.show(
      context: context,
      title: 'Filter GSR',
      onReset: () => setState(() => _sourceFilter = null),
      builder: (setSheetState) => [
        FilterSection(
          label: 'Global Spot Provider',
          child: FilterChipGroup<String>(
            options: availableSources
                .map((s) => FilterChipOption(value: s, label: s))
                .toList(),
            selected: _sourceFilter,
            onChanged: (v) {
              setState(() => _sourceFilter = v);
              setSheetState(() {});
            },
          ),
        ),
      ],
    );
  }

  List<GsrDataPoint> _sorted(List<GsrDataPoint> data) {
    final result = List<GsrDataPoint>.from(data);
    _sortConfig.sortList(result, (a, b, col) {
      switch (col) {
        case _GsrSort.date:
          return a.date.compareTo(b.date);
        case _GsrSort.gsr:
          return a.gsr.compareTo(b.gsr);
        case _GsrSort.movement:
          final av = a.movementUp == null ? 0 : (a.movementUp! ? 1 : -1);
          final bv = b.movementUp == null ? 0 : (b.movementUp! ? 1 : -1);
          return av.compareTo(bv);
        case _GsrSort.guide:
          return a.guide.compareTo(b.guide);
      }
    });
    return result;
  }

  void _onHeaderTap(_GsrSort col) {
    setState(() {
      _sortConfig = _sortConfig.tap(col, defaultAscending: (_) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(gsrHistoryProvider);
    final settings =
        ref.watch(userAnalyticsPrefsNotifierProvider).valueOrNull;
    final availableSources = historyAsync.valueOrNull
            ?.map((e) => e.source)
            .toSet()
            .toList()
            .cast<String>() ??
        [];

    return AppScaffold(
      title: 'Gold to Silver Ratio',
      actions: [
        IconButton(
          icon: Icon(
            Icons.tune,
            size: 20,
            color: _sourceFilter != null
                ? AppColors.primaryGold
                : AppColors.textSecondary,
          ),
          tooltip: 'Filter',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onPressed: availableSources.isNotEmpty
              ? () => _showFilterSheet(availableSources)
              : null,
        ),
      ],
      onRefresh: () => ref.invalidate(gsrHistoryProvider),
      body: historyAsync.when(
        data: (history) => _buildContent(history, settings),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.lossRed)),
        ),
      ),
    );
  }

  Widget _buildContent(
      List<GsrDataPoint> allHistory, UserAnalyticsSettings? settings) {
    if (allHistory.isEmpty) {
      return const _EmptyState();
    }

    final filtered = _filtered(allHistory);
    final sorted = _sorted(filtered);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _InfoCard(),
        const SizedBox(height: 16),
        _ChartSection(
          allHistory: allHistory,
          range: _range,
          onRangeChanged: (r) => setState(() => _range = r),
        ),
        const SizedBox(height: 16),
        _HistoryCard(
          entries: sorted,
          sortConfig: _sortConfig,
          onHeaderTap: _onHeaderTap,
          settings: settings,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── Info Card ────────────────────────────────────────────────────────────────

class _InfoCard extends ConsumerWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final settings =
        ref.watch(userAnalyticsPrefsNotifierProvider).valueOrNull;
    final lowMark = settings?.gsrLowMark ?? 60.0;
    final highMark = settings?.gsrHighMark ?? 70.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.swap_horiz,
                    color: AppColors.primaryGold, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Gold-Silver Ratio',
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
              'Measures how many ounces of silver it takes to buy one ounce of gold. '
              'A high ratio favours silver; a low ratio favours gold.',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 10),
            _GuideRow(
              color: AppColors.secondarySilver,
              icon: Icons.arrow_upward,
              label: '≥ ${highMark.toStringAsFixed(0)}',
              text: settings?.gsrHighText ?? 'Buy Silver',
            ),
            const SizedBox(height: 4),
            _GuideRow(
              color: AppColors.primaryGold,
              icon: Icons.arrow_downward,
              label: '≤ ${lowMark.toStringAsFixed(0)}',
              text: settings?.gsrLowText ?? 'Buy Gold',
            ),
            const SizedBox(height: 4),
            _GuideRow(
              color: AppColors.textSecondary,
              icon: Icons.remove,
              label:
                  '${lowMark.toStringAsFixed(0)}–${highMark.toStringAsFixed(0)}',
              text: settings?.gsrMidText ?? 'Hold',
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
          child: Text(
            text,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

// ─── History Card ─────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final List<GsrDataPoint> entries;
  final SortConfig<_GsrSort> sortConfig;
  final ValueChanged<_GsrSort> onHeaderTap;
  final UserAnalyticsSettings? settings;

  const _HistoryCard({
    required this.entries,
    required this.sortConfig,
    required this.onHeaderTap,
    this.settings,
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
          _TableHeader(config: sortConfig, onTap: onHeaderTap),
          const Divider(height: 1),
          ...entries.map((p) => _GsrRow(point: p, settings: settings)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Table Header ─────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  final SortConfig<_GsrSort> config;
  final ValueChanged<_GsrSort> onTap;

  const _TableHeader({
    required this.config,
    required this.onTap,
  });

  Widget _cell(String label, _GsrSort col, int flex, ColorScheme cs) {
    final primary = config.isPrimary(col);
    final secondary = config.isSecondary(col);
    final active = primary || secondary;
    final color = primary
        ? AppColors.primaryGold
        : secondary
            ? AppColors.primaryGold.withAlpha(160)
            : cs.onSurfaceVariant;
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: () => onTap(col),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
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
                  Text('2',
                      style: TextStyle(
                          color: color,
                          fontSize: 8,
                          fontWeight: FontWeight.w700)),
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
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: Row(
        children: [
          _cell('Date', _GsrSort.date, _kDateFlex, cs),
          _cell('GSR', _GsrSort.gsr, _kGsrFlex, cs),
          _cell('Move', _GsrSort.movement, _kMoveFlex, cs),
          _cell('Investment Guide', _GsrSort.guide, _kGuideFlex, cs),
        ],
      ),
    );
  }
}

// ─── Table Row ────────────────────────────────────────────────────────────────

class _GsrRow extends StatelessWidget {
  final GsrDataPoint point;
  final UserAnalyticsSettings? settings;

  const _GsrRow({required this.point, this.settings});

  Color _guideColor() {
    if (settings != null) {
      return SignalColorHelper.gsrGuideColor(point.guide, settings!);
    }
    // Fallback before settings load
    if (point.guide == 'Buy Silver') return AppColors.secondarySilver;
    if (point.guide == 'Buy Gold') return AppColors.primaryGold;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
            flex: _kDateFlex,
            child: Text(
              _dateFmt.format(point.date),
              style:
                  TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
            ),
          ),
          Expanded(
            flex: _kGsrFlex,
            child: Text(
              _gsrFmt.format(point.gsr),
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: _kMoveFlex,
            // Arrow uses the GSR guide colour (gold/silver/neutral),
            // NOT gain/loss green/red — GSR direction is metal preference,
            // not a simple good/bad signal.
            child: MovementArrow(
              movementUp: point.movementUp,
              color: _guideColor(),
              size: 12,
            ),
          ),
          Expanded(
            flex: _kGuideFlex,
            child: Text(
              point.guide,
              style: TextStyle(
                color: _guideColor(),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chart Section ────────────────────────────────────────────────────────────

class _ChartSection extends StatelessWidget {
  final List<GsrDataPoint> allHistory;
  final String range;
  final ValueChanged<String> onRangeChanged;

  const _ChartSection({
    required this.allHistory,
    required this.range,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final oldestFirst = allHistory.reversed.toList();
    final filteredOldestFirst = range == 'all'
        ? oldestFirst
        : oldestFirst.where((p) {
            final days = range == '7d'
                ? 7
                : range == '30d'
                    ? 30
                    : 90;
            final cutoff = DateTime.now().subtract(Duration(days: days));
            return p.date.isAfter(cutoff);
          }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnalyticsRangeChips(
              selected: range,
              onChanged: onRangeChanged,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: filteredOldestFirst.length < 2
                  ? Center(
                      child: Text(
                        'Not enough data for this range',
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 12),
                      ),
                    )
                  : _GsrLineChart(data: filteredOldestFirst),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── GSR Line Chart ───────────────────────────────────────────────────────────

class _GsrLineChart extends StatelessWidget {
  final List<GsrDataPoint> data; // oldest-first

  const _GsrLineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gridColor = cs.outlineVariant.withValues(alpha: 0.12);
    final trendColor = cs.onSurface.withValues(alpha: 0.35);

    final n = data.length;
    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.gsr))
        .toList();

    List<FlSpot> trendSpots = [];
    if (n >= 2) {
      double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
      for (var i = 0; i < n; i++) {
        final y = data[i].gsr;
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

    final minGsr = data.map((p) => p.gsr).reduce((a, b) => a < b ? a : b);
    final maxGsr = data.map((p) => p.gsr).reduce((a, b) => a > b ? a : b);
    final padding = (maxGsr - minGsr) * 0.1 + 1;

    final labelInterval = (data.length / 4).ceil().toDouble();

    return LineChart(
      LineChartData(
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval:
              ((maxGsr - minGsr) / 4).clamp(1, double.infinity),
          getDrawingHorizontalLine: (_) =>
              FlLine(color: gridColor, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        minY: minGsr - padding,
        maxY: maxGsr + padding,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.primaryGold,
            barWidth: 2,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, index) {
                final isLatest = index == data.length - 1;
                return FlDotCirclePainter(
                  radius: isLatest ? 5 : 2,
                  color: isLatest
                      ? AppColors.primaryGold
                      : AppColors.primaryGold.withValues(alpha: 0.4),
                  strokeWidth: isLatest ? 2 : 0,
                  strokeColor: cs.onSurface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primaryGold.withValues(alpha: 0.07),
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
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval:
                  ((maxGsr - minGsr) / 4).clamp(1, double.infinity),
              getTitlesWidget: (value, meta) => Text(
                _gsrFmt.format(value),
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 9,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: labelInterval > 0 ? labelInterval : 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) {
                  return const SizedBox.shrink();
                }
                if (idx % labelInterval.toInt() != 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _chartDateFmt.format(data[idx].date),
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 9,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) {
              final idx = s.x.toInt();
              if (idx < 0 || idx >= data.length) return null;
              final point = data[idx];
              return LineTooltipItem(
                '${_chartDateFmt.format(point.date)}\nGSR: ${_gsrFmt.format(point.gsr)}',
                const TextStyle(
                  color: AppColors.primaryGold,
                  fontSize: 11,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.show_chart, size: 56, color: cs.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'No GSR data yet',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            'Fetch global spot prices (Gold + Silver) to see GSR analysis.',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
