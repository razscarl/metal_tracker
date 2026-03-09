// lib/features/analytics/presentation/screens/dealer_spread_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/features/analytics/presentation/providers/analytics_providers.dart';

final _dateFmt = DateFormat('d MMM y');
final _chartDateFmt = DateFormat('d MMM');
final _priceFmt = NumberFormat('#,##0.00');
final _pctFmt = NumberFormat('0.00');

// Investment guide thresholds per metal
const _buyThresholds = {'gold': 2.0, 'silver': 10.0, 'platinum': 25.0};
const _holdThresholds = {'gold': 5.0, 'silver': 20.0, 'platinum': 35.0};

class DealerSpreadScreen extends ConsumerStatefulWidget {
  const DealerSpreadScreen({super.key});

  @override
  ConsumerState<DealerSpreadScreen> createState() => _DealerSpreadScreenState();
}

class _DealerSpreadScreenState extends ConsumerState<DealerSpreadScreen> {
  String _range = '30d';
  String _chartMetal = 'gold';

  List<DealerSpreadEntry> _filtered(List<DealerSpreadEntry> all) {
    if (_range == 'all') return all;
    final days = _range == '7d' ? 7 : _range == '30d' ? 30 : 90;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return all.where((e) => e.date.isAfter(cutoff)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(dealerSpreadHistoryProvider);
    final summaryAsync = ref.watch(dealerSpreadSummaryProvider);

    return AppScaffold(
      appBar: AppBar(
        title: const Text(
          'Local Spread',
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
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGold),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.lossRed)),
        ),
        data: (history) {
          final filtered = _filtered(history);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _InfoCard(),
              const SizedBox(height: 16),

              // Today's summary table
              summaryAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (summary) => _SummaryTable(summary: summary),
              ),
              const SizedBox(height: 16),

              // Range selector + metal toggle
              _RangeSelector(
                selected: _range,
                onChanged: (r) => setState(() => _range = r),
              ),
              const SizedBox(height: 10),
              _MetalToggle(
                selected: _chartMetal,
                onChanged: (m) => setState(() => _chartMetal = m),
              ),
              const SizedBox(height: 12),

              // Chart for selected metal
              if (filtered.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'No data for selected range.\nFetch live prices first.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                )
              else
                _SpreadChart(
                  entries: filtered
                      .where((e) => e.metalType == _chartMetal)
                      .toList(),
                  metalType: _chartMetal,
                ),
              const SizedBox(height: 16),

              // History table
              if (filtered.isNotEmpty) _HistoryTable(entries: filtered),
            ],
          );
        },
      ),
    );
  }
}

// ─── Info Card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
                  'Round-Trip Cost',
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
              'The spread is how much the price must rise for you to break even. '
              'Look for days where the spread narrows — dealers tighten spreads '
              'when overstocked, making it a more efficient day to buy.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 10),
            _ThresholdRow(
                metal: 'Gold', buy: '≤ 2%', hold: '≥ 5%'),
            const SizedBox(height: 4),
            _ThresholdRow(
                metal: 'Silver', buy: '≤ 10%', hold: '≥ 20%'),
            const SizedBox(height: 4),
            _ThresholdRow(
                metal: 'Platinum', buy: '≤ 25%', hold: '≥ 35%'),
          ],
        ),
      ),
    );
  }
}

class _ThresholdRow extends StatelessWidget {
  final String metal;
  final String buy;
  final String hold;

  const _ThresholdRow(
      {required this.metal, required this.buy, required this.hold});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(metal,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
        ),
        Icon(Icons.shopping_cart, color: AppColors.gainGreen, size: 13),
        const SizedBox(width: 4),
        Text('Buy $buy',
            style: const TextStyle(
                color: AppColors.gainGreen, fontSize: 12)),
        const SizedBox(width: 16),
        Icon(Icons.pause_circle_outline,
            color: AppColors.textSecondary, size: 13),
        const SizedBox(width: 4),
        Text('Hold $hold',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}

// ─── Summary Table ────────────────────────────────────────────────────────────

class _SummaryTable extends StatelessWidget {
  final List<DealerSpreadEntry> summary;

  const _SummaryTable({required this.summary});

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

  Widget _dataRow(DealerSpreadEntry e) {
    final metalColor =
        MetalColorHelper.getColorForMetalString(e.metalType);
    final guideColor = _guideColor(e.guide);
    final moveColor = e.movementUp == null
        ? AppColors.textSecondary
        : (e.movementUp! ? AppColors.lossRed : AppColors.gainGreen);

    const base =
        TextStyle(color: AppColors.textPrimary, fontSize: 12);

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
                  color: _spreadPctColor(e.metalType, e.spreadPct)),
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

// ─── Range Selector ───────────────────────────────────────────────────────────

class _RangeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _RangeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Range:',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(width: 8),
        for (final r in ['7d', '30d', '90d', 'all'])
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onChanged(r),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: selected == r
                      ? AppColors.primaryGold
                      : AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  r,
                  style: TextStyle(
                    color: selected == r
                        ? AppColors.textDark
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight:
                        selected == r ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Metal Toggle ─────────────────────────────────────────────────────────────

class _MetalToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _MetalToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final metals = [
      ('gold', AppColors.primaryGold),
      ('silver', AppColors.secondarySilver),
      ('platinum', AppColors.accentPlatinum),
    ];

    return Row(
      children: [
        const Text('Chart:',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(width: 8),
        ...metals.map((m) {
          final isSelected = selected == m.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onChanged(m.$1),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? m.$2.withValues(alpha: 0.2)
                      : AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? m.$2 : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  _metalLabel(m.$1),
                  style: TextStyle(
                    color: isSelected ? m.$2 : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─── Spread Chart ─────────────────────────────────────────────────────────────

class _SpreadChart extends StatelessWidget {
  final List<DealerSpreadEntry> entries;
  final String metalType;

  const _SpreadChart({required this.entries, required this.metalType});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No ${_metalLabel(metalType)} spread data for selected range.',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
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
    final buyThreshold = _buyThresholds[metalType] ?? 0;
    final holdThreshold = _holdThresholds[metalType] ?? 100;

    final allVals = sorted.map((e) => e.spreadPct).toList();
    final minY = (allVals.reduce((a, b) => a < b ? a : b) - 1).floorToDouble().clamp(0, 999).toDouble();
    final maxY = (allVals.reduce((a, b) => a > b ? a : b) + 1).ceilToDouble();

    final step = (sorted.length / 5).ceil().clamp(1, 999);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: Column(
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
                  _legendDot(AppColors.gainGreen, 'Buy ≤ ${buyThreshold.toStringAsFixed(0)}%'),
                  _legendDot(AppColors.lossRed, 'Hold ≥ ${holdThreshold.toStringAsFixed(0)}%'),
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
        ),
      ),
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
  final List<DealerSpreadEntry> entries;

  const _HistoryTable({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'History',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            _headerRow(),
            const Divider(color: Colors.white12, height: 8),
            ...entries.map(_dataRow),
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
      Expanded(flex: 20, child: Text('Date', style: s)),
      Expanded(flex: 13, child: Text('Metal', style: s)),
      Expanded(
          flex: 13,
          child: Text('Spread %', style: s, textAlign: TextAlign.right)),
      Expanded(flex: 6, child: const SizedBox()),
      Expanded(
          flex: 18,
          child: Text('Guide', style: s, textAlign: TextAlign.right)),
    ]);
  }

  Widget _dataRow(DealerSpreadEntry e) {
    final metalColor =
        MetalColorHelper.getColorForMetalString(e.metalType);
    final moveColor = e.movementUp == null
        ? AppColors.textSecondary
        : (e.movementUp! ? AppColors.lossRed : AppColors.gainGreen);

    const base = TextStyle(color: AppColors.textPrimary, fontSize: 12);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(
            flex: 20,
            child: Text(_dateFmt.format(e.date), style: base)),
        Expanded(
          flex: 13,
          child: Text(_metalLabel(e.metalType),
              style: base.copyWith(
                  color: metalColor, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          flex: 13,
          child: Text('${_pctFmt.format(e.spreadPct)}%',
              style: base.copyWith(
                  color: _spreadPctColor(e.metalType, e.spreadPct)),
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
                  size: 13,
                ),
        ),
        Expanded(
          flex: 18,
          child: Text(e.guide,
              style: base.copyWith(
                  color: _guideColor(e.guide), fontSize: 11),
              textAlign: TextAlign.right),
        ),
      ]),
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

Color _spreadPctColor(String metal, double pct) {
  final buy = _buyThresholds[metal] ?? 0;
  final hold = _holdThresholds[metal] ?? 100;
  if (pct <= buy) return AppColors.gainGreen;
  if (pct >= hold) return AppColors.lossRed;
  return AppColors.textPrimary;
}

Color _guideColor(String guide) {
  switch (guide) {
    case 'Buy':
      return AppColors.gainGreen;
    case 'Hold':
      return AppColors.lossRed;
    default:
      return AppColors.textSecondary;
  }
}
