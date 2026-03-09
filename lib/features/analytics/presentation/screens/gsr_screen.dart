// lib/features/analytics/presentation/screens/gsr_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/features/analytics/presentation/providers/analytics_providers.dart';

final _dateFmt = DateFormat('d MMM y');
final _chartDateFmt = DateFormat('d MMM');
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
  _GsrSort _sortCol = _GsrSort.date;
  bool _sortAsc = false;

  List<GsrDataPoint> _filtered(List<GsrDataPoint> all) {
    if (_range == 'all') return all;
    final days = _range == '7d'
        ? 7
        : _range == '30d'
            ? 30
            : 90;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return all.where((p) => p.date.isAfter(cutoff)).toList();
  }

  List<GsrDataPoint> _sorted(List<GsrDataPoint> data) {
    int compare(GsrDataPoint a, GsrDataPoint b) {
      switch (_sortCol) {
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
    }

    final sorted = List<GsrDataPoint>.from(data)..sort(compare);
    return _sortAsc ? sorted : sorted.reversed.toList();
  }

  void _onHeaderTap(_GsrSort col) {
    setState(() {
      if (_sortCol == col) {
        _sortAsc = !_sortAsc;
      } else {
        _sortCol = col;
        _sortAsc = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(gsrHistoryProvider);

    return AppScaffold(
      appBar: AppBar(
        title: const Text(
          'Gold to Silver Ratio',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.backgroundCard,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: historyAsync.when(
        data: _buildContent,
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }

  Widget _buildContent(List<GsrDataPoint> allHistory) {
    if (allHistory.isEmpty) {
      return const _EmptyState();
    }

    final filtered = _filtered(allHistory);
    final sorted = _sorted(filtered);

    return Column(
      children: [
        // Table header
        _TableHeader(
          sortCol: _sortCol,
          sortAsc: _sortAsc,
          onTap: _onHeaderTap,
        ),
        // Table rows
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: sorted.length,
            itemBuilder: (ctx, i) => _GsrRow(point: sorted[i]),
          ),
        ),
        // Chart section
        _ChartSection(
          allHistory: allHistory,
          range: _range,
          onRangeChanged: (r) => setState(() => _range = r),
        ),
      ],
    );
  }
}

// ─── Table Header ─────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  final _GsrSort sortCol;
  final bool sortAsc;
  final ValueChanged<_GsrSort> onTap;

  const _TableHeader({
    required this.sortCol,
    required this.sortAsc,
    required this.onTap,
  });

  Widget _cell(String label, _GsrSort col, int flex) {
    final active = sortCol == col;
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
                  color: active ? AppColors.primaryGold : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (active) ...[
                const SizedBox(width: 2),
                Icon(
                  sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 11,
                  color: AppColors.primaryGold,
                ),
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
          _cell('Date', _GsrSort.date, _kDateFlex),
          _cell('GSR', _GsrSort.gsr, _kGsrFlex),
          _cell('Move', _GsrSort.movement, _kMoveFlex),
          _cell('Investment Guide', _GsrSort.guide, _kGuideFlex),
        ],
      ),
    );
  }
}

// ─── Table Row ────────────────────────────────────────────────────────────────

class _GsrRow extends StatelessWidget {
  final GsrDataPoint point;
  const _GsrRow({required this.point});

  Color _guideColor() {
    switch (point.guide) {
      case 'Buy Silver':
        return AppColors.secondarySilver;
      case 'Buy Gold':
        return AppColors.primaryGold;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final movementColor = point.movementUp == null
        ? AppColors.textSecondary
        : point.movementUp!
            ? AppColors.gainGreen
            : AppColors.lossRed;
    final movementText = point.movementUp == null
        ? '—'
        : point.movementUp!
            ? '↑'
            : '↓';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: _kDateFlex,
            child: Text(
              _dateFmt.format(point.date),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ),
          Expanded(
            flex: _kGsrFlex,
            child: Text(
              _gsrFmt.format(point.gsr),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: _kMoveFlex,
            child: Text(
              movementText,
              style: TextStyle(
                color: movementColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
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
    // allHistory is newest-first, so reversed = oldest-first
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

    return Container(
      color: AppColors.backgroundCard,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Range chips
          Row(
            children: [
              const Text(
                'Range:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              const SizedBox(width: 8),
              ...['7d', '30d', '90d', 'All'].map((r) => _RangeChip(
                    label: r == 'all' ? 'All' : r.toUpperCase(),
                    selected: range == r,
                    onTap: () => onRangeChanged(r),
                  )),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: filteredOldestFirst.length < 2
                ? const Center(
                    child: Text(
                      'Not enough data for this range',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  )
                : _GsrLineChart(data: filteredOldestFirst),
          ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryGold.withValues(alpha: 0.15)
                : AppColors.backgroundDark,
            border: Border.all(
              color: selected ? AppColors.primaryGold : Colors.white12,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.primaryGold : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
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
    final n = data.length;
    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.gsr))
        .toList();

    // Linear regression trendline
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

    // Determine bottom label interval
    final labelInterval = (data.length / 4).ceil().toDouble();

    return LineChart(
      LineChartData(
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: ((maxGsr - minGsr) / 4).clamp(1, double.infinity),
          getDrawingHorizontalLine: (_) => const FlLine(
            color: Colors.white10,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: minGsr - padding,
        maxY: maxGsr + padding,
        lineBarsData: [
          // GSR data line
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
                  color: isLatest ? AppColors.primaryGold : AppColors.primaryGold.withValues(alpha: 0.4),
                  strokeWidth: isLatest ? 2 : 0,
                  strokeColor: AppColors.textPrimary,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primaryGold.withValues(alpha: 0.07),
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
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: ((maxGsr - minGsr) / 4).clamp(1, double.infinity),
              getTitlesWidget: (value, meta) => Text(
                _gsrFmt.format(value),
                style: const TextStyle(
                  color: AppColors.textSecondary,
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
                if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                if (idx % labelInterval.toInt() != 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _chartDateFmt.format(data[idx].date),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
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
                  color: AppColors.textPrimary,
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
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.show_chart, size: 56, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text(
            'No GSR data yet',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          SizedBox(height: 8),
          Text(
            'Fetch global spot prices (Gold + Silver) to see GSR analysis.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
