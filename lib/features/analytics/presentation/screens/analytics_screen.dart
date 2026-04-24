// lib/features/analytics/presentation/screens/analytics_screen.dart

import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/utils/time_service.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:metal_tracker/features/analytics/presentation/screens/gsr_screen.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/features/analytics/presentation/screens/local_spread_screen.dart';
import 'package:metal_tracker/features/analytics/presentation/screens/local_premium_screen.dart';
import 'package:metal_tracker/features/admin/data/models/change_request_model.dart';
import 'package:metal_tracker/features/admin/presentation/widgets/change_request_dialog.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_prefs_providers.dart';

final _gsrFmt = NumberFormat('0.00');

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(analyticsSummaryProvider);
    final settingsAsync = ref.watch(userAnalyticsSettingsNotifierProvider);

    return AppScaffold(
      title: 'Analytics',
      actions: [
        IconButton(
          icon: const Icon(Icons.add_chart_outlined),
          tooltip: 'Request analytics feature',
          onPressed: () => showChangeRequestDialog(
            context,
            requestType: ChangeRequestType.newAnalytics,
            prefillSubject: 'Request new analytics feature',
          ),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Price Guide Card ───────────────────────────────────────────────
          _PriceGuideCard(),
          const SizedBox(height: 16),

          // ── GSR Card ──────────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  const Row(
                    children: [
                      Icon(Icons.show_chart,
                          color: AppColors.primaryGold, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Gold to Silver Ratio',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  // Dynamic subtitle from settings
                  settingsAsync.when(
                    data: (s) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'GSR ≥ ${s.gsrHighMark.toInt()} → ${s.gsrHighText}  |  GSR ≤ ${s.gsrLowMark.toInt()} → ${s.gsrLowText}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 20),

                  // GSR Slider
                  summaryAsync.when(
                    data: (summary) => settingsAsync.when(
                      data: (settings) => summary.currentGsr != null
                          ? _GsrSlider(
                              currentGsr: summary.currentGsr!,
                              lowMark: settings.gsrLowMark,
                              highMark: settings.gsrHighMark,
                            )
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 20),

                  // Current GSR + movement indicator
                  summaryAsync.when(
                    data: (summary) => summary.currentGsr != null
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Current GSR: ',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                _gsrFmt.format(summary.currentGsr),
                                style: const TextStyle(
                                  color: AppColors.primaryGold,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (summary.movementUp != null) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  summary.movementUp!
                                      ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded,
                                  color: summary.movementUp!
                                      ? AppColors.gainGreen
                                      : AppColors.lossRed,
                                  size: 22,
                                ),
                              ],
                              if (summary.currentGuide != null) ...[
                                const SizedBox(width: 8),
                                const Text(
                                  '|',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    summary.currentGuide!,
                                    style: TextStyle(
                                      color: _guideColor(summary.currentGuide!),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          )
                        : const Text(
                            'No data yet — fetch global spot prices first.',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12),
                          ),
                    loading: () => const SizedBox(
                      height: 20,
                      child: LinearProgressIndicator(
                        color: AppColors.primaryGold,
                        backgroundColor: Colors.white10,
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GsrScreen()),
                      ),
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('View GSR Analysis'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        foregroundColor: AppColors.textDark,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Local Premium Card ──────────────────────────────────────────
          _LocalPremiumCard(),
          const SizedBox(height: 16),

          // ── Local Spread Card ──────────────────────────────────────────
          _LocalSpreadCard(),
        ],
      ),
    );
  }
}

// ─── Price Guide Card ─────────────────────────────────────────────────────────

class _PriceGuideCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PriceGuideCard> createState() => _PriceGuideCardState();
}

class _PriceGuideCardState extends ConsumerState<_PriceGuideCard> {
  String _metal = 'gold';

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(localSpreadHistoryProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + metal toggle row
            Row(
              children: [
                const Icon(Icons.trending_up,
                    color: AppColors.primaryGold, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Price Guide',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Metal toggle chips
                ...[
                  ('gold', AppColors.primaryGold),
                  ('silver', AppColors.secondarySilver),
                  ('platinum', AppColors.accentPlatinum),
                ].map((m) {
                  final isSelected = _metal == m.$1;
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _metal = m.$1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? m.$2.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? m.$2 : Colors.white12,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          m.$1[0].toUpperCase() + m.$1.substring(1, 2),
                          style: TextStyle(
                            color: isSelected
                                ? m.$2
                                : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Best sell & buyback prices with trend',
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
            const SizedBox(height: 16),
            historyAsync.when(
              loading: () => const SizedBox(
                height: 20,
                child: LinearProgressIndicator(
                  color: AppColors.primaryGold,
                  backgroundColor: Colors.white10,
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (history) {
                final metalEntries = history
                    .where((e) => e.metalType == _metal)
                    .toList()
                    .reversed
                    .toList(); // oldest-first

                if (metalEntries.length < 2) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Not enough data — fetch live prices on multiple days.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  );
                }

                return _PriceGuideChart(
                    entries: metalEntries, metal: _metal);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceGuideChart extends StatelessWidget {
  final List<LocalSpreadEntry> entries; // oldest-first
  final String metal;

  const _PriceGuideChart({required this.entries, required this.metal});

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
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;
    final lastX = spots.last.x;
    return [
      FlSpot(0, intercept),
      FlSpot(lastX, slope * lastX + intercept),
    ];
  }

  @override
  Widget build(BuildContext context) {
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

    final metalColor = MetalColorHelper.getColorForMetalString(metal);
    const buybackColor = AppColors.gainGreen;

    final allPrices = [
      ...entries.map((e) => e.bestSellPrice),
      ...entries.map((e) => e.bestBuybackPrice),
    ];
    final minY =
        (allPrices.reduce((a, b) => a < b ? a : b) * 0.995).floorToDouble();
    final maxY =
        (allPrices.reduce((a, b) => a > b ? a : b) * 1.005).ceilToDouble();

    final step = (entries.length / 4).ceil().clamp(1, 999);
    final chartDateFmt = DateFormat(AppDateFormats.chartLabel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        Wrap(
          spacing: 12,
          children: [
            _legendLine(metalColor, 'Sell'),
            _legendDash(metalColor.withValues(alpha: 0.6), 'Sell trend'),
            _legendLine(buybackColor, 'Buyback'),
            _legendDash(
                buybackColor.withValues(alpha: 0.6), 'Buyback trend'),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
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
                    reservedSize: 52,
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
                          chartDateFmt.format(entries[idx].date),
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 8),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                // Sell price line
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
                // Sell trend
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
                // Buyback price line
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
                // Buyback trend
                if (buyTrend.length == 2)
                  LineChartBarData(
                    spots: buyTrend,
                    color: buybackColor.withValues(alpha: 0.6),
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
                    final labels = ['Sell', 'Sell trend', 'Buyback', 'Buyback trend'];
                    final colors = [
                      metalColor,
                      metalColor.withValues(alpha: 0.6),
                      buybackColor,
                      buybackColor.withValues(alpha: 0.6),
                    ];
                    final label = s.barIndex < labels.length
                        ? labels[s.barIndex]
                        : '';
                    final color = s.barIndex < colors.length
                        ? colors[s.barIndex]
                        : AppColors.textPrimary;
                    return LineTooltipItem(
                      '$label\n\$${NumberFormat('#,##0.00').format(s.y)}',
                      TextStyle(color: color, fontSize: 11),
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

// ─── Local Spread Card ───────────────────────────────────────────────────────

class _LocalSpreadCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(localSpreadSummaryProvider);
    final settings = ref.watch(userAnalyticsSettingsNotifierProvider).valueOrNull;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.compare_arrows,
                    color: AppColors.primaryGold, size: 20),
                SizedBox(width: 8),
                Text(
                  'Local Spread',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Difference between sell and buyback prices as a percentage.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
            const SizedBox(height: 16),
            summaryAsync.when(
              loading: () => const SizedBox(
                height: 20,
                child: LinearProgressIndicator(
                  color: AppColors.primaryGold,
                  backgroundColor: Colors.white10,
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (summary) {
                if (summary.isEmpty) {
                  return const Text(
                    'No data yet — fetch live prices first.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  );
                }
                return Row(
                  children: summary.map((e) {
                    final metalColor =
                        MetalColorHelper.getColorForMetalString(e.metalType);
                    final iconPath =
                        MetalColorHelper.getAssetPathForMetalString(
                            e.metalType);
                    final lowLabel = settings?.spreadLowLabel ?? 'Buy';
                    final highLabel = settings?.spreadHighLabel ?? 'Avoid';
                    final pctColor = e.guide == lowLabel
                        ? AppColors.gainGreen
                        : e.guide == highLabel
                            ? AppColors.lossRed
                            : AppColors.textPrimary;

                    return Expanded(
                      child: Column(
                        children: [
                          Image.asset(iconPath, width: 36, height: 36),
                          const SizedBox(height: 6),
                          Text(
                            '${e.metalType[0].toUpperCase()}${e.metalType.substring(1)}',
                            style: TextStyle(
                              color: metalColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${e.spreadPct.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  color: pctColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (e.movementUp != null) ...[
                                const SizedBox(width: 3),
                                Icon(
                                  e.movementUp!
                                      ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded,
                                  // wider spread = bad = red; narrower = good = green
                                  color: e.movementUp!
                                      ? AppColors.lossRed
                                      : AppColors.gainGreen,
                                  size: 14,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            e.guide,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: pctColor == AppColors.textPrimary
                                  ? AppColors.textSecondary
                                  : pctColor,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LocalSpreadScreen()),
                ),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('View Local Spread Analysis'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.textDark,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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

// ─── Local Premium Card ───────────────────────────────────────────────────────

class _LocalPremiumCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(localPremiumSummaryProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.public, color: AppColors.primaryGold, size: 20),
                SizedBox(width: 8),
                Text(
                  'Local Premium',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Geographic premium vs global spot price',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
            const SizedBox(height: 16),
            summaryAsync.when(
              loading: () => const SizedBox(
                height: 20,
                child: LinearProgressIndicator(
                  color: AppColors.primaryGold,
                  backgroundColor: Colors.white10,
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (summary) {
                if (summary.isEmpty) {
                  return const Text(
                    'No data yet — fetch global and local spot prices first.',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  );
                }
                return Row(
                  children: summary.map((e) {
                    final pct = e.premiumPct;
                    final pctColor = e.guide == 'Avoid buying'
                        ? AppColors.lossRed
                        : e.guide == 'Buy now'
                            ? AppColors.gainGreen
                            : AppColors.textPrimary;
                    final metalColor = e.metalType == 'gold'
                        ? AppColors.primaryGold
                        : e.metalType == 'silver'
                            ? AppColors.secondarySilver
                            : AppColors.accentPlatinum;
                    final iconPath =
                        MetalColorHelper.getAssetPathForMetalString(
                            e.metalType);

                    return Expanded(
                      child: Column(
                        children: [
                          Image.asset(iconPath, width: 36, height: 36),
                          const SizedBox(height: 6),
                          Text(
                            '${e.metalType[0].toUpperCase()}${e.metalType.substring(1)}',
                            style: TextStyle(
                              color: metalColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                pct >= 0
                                    ? '+${pct.toStringAsFixed(2)}%'
                                    : '${pct.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  color: pctColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (e.movementUp != null) ...[
                                const SizedBox(width: 3),
                                Icon(
                                  e.movementUp!
                                      ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded,
                                  color: e.movementUp!
                                      ? AppColors.gainGreen
                                      : AppColors.lossRed,
                                  size: 14,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            e.guide,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: pctColor == AppColors.textPrimary
                                  ? AppColors.textSecondary
                                  : pctColor,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LocalPremiumScreen()),
                ),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('View Local Premium Analysis'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.textDark,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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

// ─── Helpers ─────────────────────────────────────────────────────────────────

Color _guideColor(String guide) {
  switch (guide) {
    case 'Buy Silver':
      return AppColors.secondarySilver;
    case 'Buy Gold':
      return AppColors.primaryGold;
    default:
      return AppColors.textSecondary;
  }
}

// ─── GSR Slider ───────────────────────────────────────────────────────────────

class _GsrSlider extends StatelessWidget {
  final double currentGsr;
  final double lowMark;
  final double highMark;

  const _GsrSlider({
    required this.currentGsr,
    required this.lowMark,
    required this.highMark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: CustomPaint(
        painter: _GsrSliderPainter(
          currentGsr: currentGsr,
          lowMark: lowMark,
          highMark: highMark,
        ),
        size: const Size(double.infinity, 72),
      ),
    );
  }
}

class _GsrSliderPainter extends CustomPainter {
  final double currentGsr;
  final double lowMark;
  final double highMark;

  static const _min = 1.0;
  static const _max = 100.0;
  static const _trackH = 8.0;
  static const _thumbR = 12.0;
  static const _trackCY = 36.0; // center of track (leaves space above for thumb label)

  _GsrSliderPainter({
    required this.currentGsr,
    required this.lowMark,
    required this.highMark,
  });

  double _toX(double val, double w) =>
      (val - _min) / (_max - _min) * w;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    const trackTop = _trackCY - _trackH / 2;
    const trackBot = _trackCY + _trackH / 2;

    final lowX = _toX(lowMark, w);
    final highX = _toX(highMark, w);
    final thumbX = _toX(currentGsr.clamp(_min, _max), w);

    // ── Track (clipped to rounded rect) ──────────────────────────────────
    final rr = RRect.fromLTRBR(
        0, trackTop, w, trackBot, const Radius.circular(4));
    canvas.save();
    canvas.clipRRect(rr);

    // Gold zone (left of lowMark)
    canvas.drawRect(
      Rect.fromLTRB(0, trackTop, lowX, trackBot),
      Paint()..color = AppColors.primaryGold,
    );

    // Gradient zone (lowMark to highMark)
    if (highX > lowX) {
      final gradPaint = Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.primaryGold, AppColors.secondarySilver],
        ).createShader(Rect.fromLTWH(lowX, trackTop, highX - lowX, _trackH));
      canvas.drawRect(
          Rect.fromLTRB(lowX, trackTop, highX, trackBot), gradPaint);
    }

    // Silver zone (right of highMark)
    canvas.drawRect(
      Rect.fromLTRB(highX, trackTop, w, trackBot),
      Paint()..color = AppColors.secondarySilver,
    );

    canvas.restore();

    // ── Boundary markers (thin lines at lowMark and highMark) ────────────
    final markerPaint = Paint()
      ..color = AppColors.backgroundCard.withValues(alpha: 0.8)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(lowX, trackTop), Offset(lowX, trackBot), markerPaint);
    canvas.drawLine(Offset(highX, trackTop), Offset(highX, trackBot), markerPaint);

    // ── Tick marks (every 10 points) ─────────────────────────────────────
    final tickPaint = Paint()
      ..color = Colors.white30
      ..strokeWidth = 1;

    final tp = TextPainter(textDirection: ui.TextDirection.ltr);

    // "1" label at far left
    tp.text = const TextSpan(
      text: '1',
      style: TextStyle(color: AppColors.textSecondary, fontSize: 8),
    );
    tp.layout();
    tp.paint(canvas, const Offset(0, trackBot + 7));

    for (var v = 10; v <= 100; v += 10) {
      final x = _toX(v.toDouble(), w);

      // Tick
      canvas.drawLine(
          Offset(x, trackBot), Offset(x, trackBot + 5), tickPaint);

      // Label every 20 points
      if (v % 20 == 0 || v == 10 || v == 100) {
        tp.text = TextSpan(
          text: '$v',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 8),
        );
        tp.layout();
        tp.paint(canvas,
            Offset((x - tp.width / 2).clamp(0, w - tp.width), trackBot + 7));
      }
    }

    // ── Low / High mark labels (above track, at boundaries) ──────────────
    tp.text = TextSpan(
      text: '${lowMark.toInt()}',
      style: const TextStyle(
          color: AppColors.primaryGold,
          fontSize: 8,
          fontWeight: FontWeight.w600),
    );
    tp.layout();
    tp.paint(
        canvas,
        Offset((lowX - tp.width / 2).clamp(0, w - tp.width),
            trackTop - tp.height - 2));

    tp.text = TextSpan(
      text: '${highMark.toInt()}',
      style: const TextStyle(
          color: AppColors.secondarySilver,
          fontSize: 8,
          fontWeight: FontWeight.w600),
    );
    tp.layout();
    tp.paint(
        canvas,
        Offset((highX - tp.width / 2).clamp(0, w - tp.width),
            trackTop - tp.height - 2));

    // ── Thumb ─────────────────────────────────────────────────────────────
    // Shadow
    canvas.drawCircle(
      Offset(thumbX, _trackCY + 1),
      _thumbR,
      Paint()
        ..color = Colors.black45
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Fill
    canvas.drawCircle(
      Offset(thumbX, _trackCY),
      _thumbR,
      Paint()..color = AppColors.backgroundCard,
    );

    // Border
    canvas.drawCircle(
      Offset(thumbX, _trackCY),
      _thumbR,
      Paint()
        ..color = AppColors.primaryGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // ── Thumb value label (above thumb) ───────────────────────────────────
    final gsrLabel = currentGsr.toStringAsFixed(1);
    tp.text = TextSpan(
      text: gsrLabel,
      style: const TextStyle(
        color: AppColors.primaryGold,
        fontSize: 9,
        fontWeight: FontWeight.w700,
      ),
    );
    tp.layout();
    final labelX = (thumbX - tp.width / 2).clamp(0, w - tp.width).toDouble();
    final labelY = _trackCY - _thumbR - tp.height - 3;
    tp.paint(canvas, Offset(labelX, labelY));
  }

  @override
  bool shouldRepaint(_GsrSliderPainter old) =>
      old.currentGsr != currentGsr ||
      old.lowMark != lowMark ||
      old.highMark != highMark;
}
