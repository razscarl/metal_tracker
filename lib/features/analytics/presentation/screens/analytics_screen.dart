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
import 'package:metal_tracker/features/analytics/presentation/screens/price_guide_screen.dart';
import 'package:metal_tracker/features/admin/data/models/change_request_model.dart';
import 'package:metal_tracker/features/admin/presentation/widgets/change_request_dialog.dart';
import 'package:metal_tracker/core/widgets/filter_sheet.dart';
import 'package:metal_tracker/core/utils/signal_color_helper.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_prefs_providers.dart';

final _gsrFmt = NumberFormat('0.00');

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String? _metalFilter;

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

  @override
  Widget build(BuildContext context) {
    final cs           = Theme.of(context).colorScheme;
    final tt           = Theme.of(context).textTheme;
    final summaryAsync = ref.watch(analyticsSummaryProvider);
    final settingsAsync = ref.watch(userAnalyticsPrefsNotifierProvider);
    final settings     = settingsAsync.valueOrNull;
    final filterActive = _metalFilter != null;

    return AppScaffold(
      title: 'Analytics',
      actions: [
        IconButton(
          icon: Icon(Icons.tune,
              color: filterActive ? cs.primary : cs.onSurfaceVariant),
          tooltip: 'Filter',
          onPressed: _openFilter,
        ),
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
          _PriceGuideCard(metalFilter: _metalFilter),
          const SizedBox(height: 16),

          // ── GSR Card ────────────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.show_chart, color: cs.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('Gold to Silver Ratio', style: tt.titleSmall),
                    ],
                  ),
                  settingsAsync.when(
                    data: (s) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'GSR ≥ ${s.gsrHighMark.toInt()} → ${s.gsrHighText}  |  GSR ≤ ${s.gsrLowMark.toInt()} → ${s.gsrLowText}',
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 20),
                  summaryAsync.when(
                    data: (summary) => settingsAsync.when(
                      data: (s) => summary.currentGsr != null
                          ? _GsrSlider(
                              currentGsr: summary.currentGsr!,
                              lowMark: s.gsrLowMark,
                              highMark: s.gsrHighMark,
                              surfaceColor: cs.surfaceContainerHighest,
                              labelColor: cs.onSurfaceVariant,
                              primaryColor: cs.primary,
                            )
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 20),
                  summaryAsync.when(
                    data: (summary) => summary.currentGsr != null
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text('Current GSR: ',
                                  style: tt.bodyMedium
                                      ?.copyWith(color: cs.onSurfaceVariant)),
                              Text(
                                _gsrFmt.format(summary.currentGsr),
                                style: tt.headlineSmall
                                    ?.copyWith(color: cs.primary),
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
                                Text('|',
                                    style: tt.bodyMedium
                                        ?.copyWith(color: cs.onSurfaceVariant)),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    summary.currentGuide!,
                                    style: tt.bodyMedium?.copyWith(
                                      color: settings != null
                                          ? SignalColorHelper.gsrGuideColor(
                                              summary.currentGuide!, settings)
                                          : cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          )
                        : Text(
                            'No data yet — fetch global spot prices first.',
                            style: tt.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                    loading: () => const SizedBox(
                      height: 20,
                      child: LinearProgressIndicator(),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const GsrScreen())),
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('View GSR Analysis'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          _LocalPremiumCard(metalFilter: _metalFilter),
          const SizedBox(height: 16),

          _LocalSpreadCard(metalFilter: _metalFilter),
        ],
      ),
    );
  }
}

// ─── Price Guide Card ─────────────────────────────────────────────────────────

class _PriceGuideCard extends ConsumerWidget {
  final String? metalFilter;
  const _PriceGuideCard({this.metalFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs           = Theme.of(context).colorScheme;
    final tt           = Theme.of(context).textTheme;
    final historyAsync = ref.watch(localSpreadHistoryProvider);
    final metal        = metalFilter ?? 'gold';
    final metalColor   = MetalColorHelper.getColorForMetalString(metal);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Price Guide — ${metal[0].toUpperCase()}${metal.substring(1)}',
                    style: tt.titleSmall,
                  ),
                ),
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                      color: metalColor, shape: BoxShape.circle),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Best sell & buyback prices with trend',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),
            historyAsync.when(
              loading: () =>
                  const SizedBox(height: 20, child: LinearProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
              data: (history) {
                final metalEntries = history
                    .where((e) => e.metalType == metal)
                    .toList()
                    .reversed
                    .toList();
                if (metalEntries.length < 2) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Not enough data — fetch live prices on multiple days.',
                        textAlign: TextAlign.center,
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                  );
                }
                return _PriceGuideChart(
                    entries: metalEntries, metal: metal);
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const PriceGuideScreen())),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('View Price Guide Analysis'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceGuideChart extends StatelessWidget {
  final List<LocalSpreadEntry> entries;
  final String metal;

  const _PriceGuideChart({required this.entries, required this.metal});

  List<FlSpot> _trendLine(List<FlSpot> spots) {
    final n = spots.length;
    if (n < 2) return [];
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (final s in spots) {
      sumX += s.x; sumY += s.y;
      sumXY += s.x * s.y; sumX2 += s.x * s.x;
    }
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;
    final lastX = spots.last.x;
    return [FlSpot(0, intercept), FlSpot(lastX, slope * lastX + intercept)];
  }

  @override
  Widget build(BuildContext context) {
    final cs           = Theme.of(context).colorScheme;
    final sellSpots    = entries.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.bestSellPrice))
        .toList();
    final buySpots     = entries.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.bestBuybackPrice))
        .toList();
    final sellTrend    = _trendLine(sellSpots);
    final buyTrend     = _trendLine(buySpots);
    final metalColor   = MetalColorHelper.getColorForMetalString(metal);
    const buybackColor = AppColors.priceBuyback;

    final allPrices = [
      ...entries.map((e) => e.bestSellPrice),
      ...entries.map((e) => e.bestBuybackPrice),
    ];
    final minY = (allPrices.reduce((a, b) => a < b ? a : b) * 0.995).floorToDouble();
    final maxY = (allPrices.reduce((a, b) => a > b ? a : b) * 1.005).ceilToDouble();
    final step = (entries.length / 4).ceil().clamp(1, 999);
    final chartDateFmt = DateFormat(AppDateFormats.chartLabel);
    final labelStyle = TextStyle(color: cs.onSurfaceVariant, fontSize: 8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 12, children: [
          _legendLine(metalColor, 'Sell', cs),
          _legendDash(metalColor.withValues(alpha: 0.6), 'Sell trend', cs),
          _legendLine(buybackColor, 'Buyback', cs),
          _legendDash(buybackColor.withValues(alpha: 0.4), 'Buyback trend', cs),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: cs.outlineVariant, strokeWidth: 0.5),
              ),
              borderData: FlBorderData(show: false),
              minY: minY, maxY: maxY,
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 52,
                  getTitlesWidget: (val, _) => Text(
                    '\$${NumberFormat('#,##0').format(val)}',
                    style: labelStyle,
                  ),
                )),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 22,
                  interval: step.toDouble(),
                  getTitlesWidget: (val, _) {
                    final idx = val.toInt();
                    if (idx < 0 || idx >= entries.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(chartDateFmt.format(entries[idx].date),
                          style: labelStyle),
                    );
                  },
                )),
              ),
              lineBarsData: [
                LineChartBarData(spots: sellSpots, color: metalColor,
                    barWidth: 2, isCurved: true, curveSmoothness: 0.25,
                    dotData: FlDotData(show: entries.length <= 14,
                      getDotPainter: (_, __, ___, ____) =>
                          FlDotCirclePainter(radius: 3, color: metalColor, strokeWidth: 0)),
                    belowBarData: BarAreaData(show: false)),
                if (sellTrend.length == 2)
                  LineChartBarData(spots: sellTrend,
                      color: metalColor.withValues(alpha: 0.6),
                      barWidth: 1.5, isCurved: false, dashArray: [6, 4],
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false)),
                LineChartBarData(spots: buySpots, color: buybackColor,
                    barWidth: 2, isCurved: true, curveSmoothness: 0.25,
                    dotData: FlDotData(show: entries.length <= 14,
                      getDotPainter: (_, __, ___, ____) =>
                          FlDotCirclePainter(radius: 3, color: buybackColor, strokeWidth: 0)),
                    belowBarData: BarAreaData(show: false)),
                if (buyTrend.length == 2)
                  LineChartBarData(spots: buyTrend,
                      color: buybackColor.withValues(alpha: 0.4),
                      barWidth: 1.5, isCurved: false, dashArray: [6, 4],
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false)),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                    final idx = s.x.toInt();
                    if (idx < 0 || idx >= entries.length) return null;
                    final labels = ['Sell', 'Sell trend', 'Buyback', 'Buyback trend'];
                    final colors = [
                      metalColor, metalColor.withValues(alpha: 0.6),
                      buybackColor, buybackColor.withValues(alpha: 0.4),
                    ];
                    final label = s.barIndex < labels.length ? labels[s.barIndex] : '';
                    final color = s.barIndex < colors.length
                        ? colors[s.barIndex] : cs.onSurface;
                    return LineTooltipItem('$label\n\$${NumberFormat('#,##0.00').format(s.y)}',
                        TextStyle(color: color, fontSize: 11));
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _legendLine(Color color, String label, ColorScheme cs) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 16, height: 2, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10)),
    ],
  );

  Widget _legendDash(Color color, String label, ColorScheme cs) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ...List.generate(3, (_) => Padding(
        padding: const EdgeInsets.only(right: 2),
        child: Container(width: 4, height: 2, color: color),
      )),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10)),
    ],
  );
}

// ─── Local Spread Card ────────────────────────────────────────────────────────

class _LocalSpreadCard extends ConsumerWidget {
  final String? metalFilter;
  const _LocalSpreadCard({this.metalFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs           = Theme.of(context).colorScheme;
    final tt           = Theme.of(context).textTheme;
    final summaryAsync = ref.watch(localSpreadSummaryProvider);
    final settings     = ref.watch(userAnalyticsPrefsNotifierProvider).valueOrNull;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.compare_arrows, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text('Local Spread', style: tt.titleSmall),
              ],
            ),
            const SizedBox(height: 4),
            Text('Difference between sell and buyback prices as a percentage.',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),
            summaryAsync.when(
              loading: () =>
                  const SizedBox(height: 20, child: LinearProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
              data: (summary) {
                final filtered = metalFilter != null
                    ? summary.where((e) => e.metalType == metalFilter).toList()
                    : summary;
                if (filtered.isEmpty) {
                  return Text('No data yet — fetch live prices first.',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant));
                }
                return Row(
                  children: filtered.map((e) {
                    final metalColor =
                        MetalColorHelper.getColorForMetalString(e.metalType);
                    final iconPath =
                        MetalColorHelper.getAssetPathForMetalString(e.metalType);
                    final lowLabel  = settings?.spreadLowLabel ?? 'Buy';
                    final highLabel = settings?.spreadHighLabel ?? 'Avoid';
                    final pctColor  = e.guide == lowLabel
                        ? AppColors.gainGreen
                        : e.guide == highLabel
                            ? AppColors.lossRed
                            : cs.onSurface;

                    return Expanded(
                      child: Column(
                        children: [
                          Image.asset(iconPath, width: 36, height: 36),
                          const SizedBox(height: 6),
                          Text(
                            '${e.metalType[0].toUpperCase()}${e.metalType.substring(1)}',
                            style: TextStyle(color: metalColor, fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${e.spreadPct.toStringAsFixed(2)}%',
                                  style: TextStyle(color: pctColor, fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                              if (e.movementUp != null) ...[
                                const SizedBox(width: 3),
                                Icon(
                                  e.movementUp!
                                      ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded,
                                  color: e.movementUp!
                                      ? AppColors.lossRed
                                      : AppColors.gainGreen,
                                  size: 14,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(e.guide,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: pctColor == cs.onSurface
                                    ? cs.onSurfaceVariant
                                    : pctColor,
                                fontSize: 10,
                              )),
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
              child: FilledButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const LocalSpreadScreen())),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('View Local Spread Analysis'),
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
  final String? metalFilter;
  const _LocalPremiumCard({this.metalFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs           = Theme.of(context).colorScheme;
    final tt           = Theme.of(context).textTheme;
    final summaryAsync = ref.watch(localPremiumSummaryProvider);
    final settings     = ref.watch(userAnalyticsPrefsNotifierProvider).valueOrNull;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.public, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text('Local Premium', style: tt.titleSmall),
              ],
            ),
            const SizedBox(height: 4),
            Text('Geographic premium vs global spot price',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),
            summaryAsync.when(
              loading: () =>
                  const SizedBox(height: 20, child: LinearProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
              data: (summary) {
                final filtered = metalFilter != null
                    ? summary.where((e) => e.metalType == metalFilter).toList()
                    : summary;
                if (filtered.isEmpty) {
                  return Text(
                      'No data yet — fetch global and local spot prices first.',
                      style:
                          tt.bodySmall?.copyWith(color: cs.onSurfaceVariant));
                }
                final lowLabel  = settings?.lpLowText ?? 'Buy Now';
                final highLabel = settings?.lpHighText ?? 'Avoid';
                return Row(
                  children: filtered.map((e) {
                    final pct      = e.premiumPct;
                    final pctColor = e.guide == highLabel
                        ? AppColors.lossRed
                        : e.guide == lowLabel
                            ? AppColors.gainGreen
                            : cs.onSurface;
                    final metalColor =
                        MetalColorHelper.getColorForMetalString(e.metalType);
                    final iconPath =
                        MetalColorHelper.getAssetPathForMetalString(e.metalType);

                    return Expanded(
                      child: Column(
                        children: [
                          Image.asset(iconPath, width: 36, height: 36),
                          const SizedBox(height: 6),
                          Text(
                            '${e.metalType[0].toUpperCase()}${e.metalType.substring(1)}',
                            style: TextStyle(color: metalColor, fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                pct >= 0
                                    ? '+${pct.toStringAsFixed(2)}%'
                                    : '${pct.toStringAsFixed(2)}%',
                                style: TextStyle(color: pctColor, fontSize: 16,
                                    fontWeight: FontWeight.w700),
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
                          Text(e.guide,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: pctColor == cs.onSurface
                                    ? cs.onSurfaceVariant
                                    : pctColor,
                                fontSize: 10,
                              )),
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
              child: FilledButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const LocalPremiumScreen())),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('View Local Premium Analysis'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── GSR Slider ───────────────────────────────────────────────────────────────

class _GsrSlider extends StatelessWidget {
  final double currentGsr;
  final double lowMark;
  final double highMark;
  final Color  surfaceColor;
  final Color  labelColor;
  final Color  primaryColor;

  const _GsrSlider({
    required this.currentGsr,
    required this.lowMark,
    required this.highMark,
    required this.surfaceColor,
    required this.labelColor,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: CustomPaint(
        painter: _GsrSliderPainter(
          currentGsr:   currentGsr,
          lowMark:      lowMark,
          highMark:     highMark,
          surfaceColor: surfaceColor,
          labelColor:   labelColor,
          primaryColor: primaryColor,
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
  final Color  surfaceColor;
  final Color  labelColor;
  final Color  primaryColor;

  static const _min    = 1.0;
  static const _max    = 100.0;
  static const _trackH = 8.0;
  static const _thumbR = 12.0;
  static const _trackCY = 36.0;

  const _GsrSliderPainter({
    required this.currentGsr,
    required this.lowMark,
    required this.highMark,
    required this.surfaceColor,
    required this.labelColor,
    required this.primaryColor,
  });

  double _toX(double val, double w) => (val - _min) / (_max - _min) * w;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    const trackTop = _trackCY - _trackH / 2;
    const trackBot = _trackCY + _trackH / 2;
    final lowX  = _toX(lowMark, w);
    final highX = _toX(highMark, w);
    final thumbX = _toX(currentGsr.clamp(_min, _max), w);

    final rr = RRect.fromLTRBR(0, trackTop, w, trackBot, const Radius.circular(4));
    canvas.save();
    canvas.clipRRect(rr);

    // Gold zone
    canvas.drawRect(Rect.fromLTRB(0, trackTop, lowX, trackBot),
        Paint()..color = AppColors.primaryGold);

    // Gradient zone
    if (highX > lowX) {
      final gradPaint = Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.primaryGold, AppColors.secondarySilver],
        ).createShader(Rect.fromLTWH(lowX, trackTop, highX - lowX, _trackH));
      canvas.drawRect(Rect.fromLTRB(lowX, trackTop, highX, trackBot), gradPaint);
    }

    // Silver zone
    canvas.drawRect(Rect.fromLTRB(highX, trackTop, w, trackBot),
        Paint()..color = AppColors.secondarySilver);

    canvas.restore();

    // Markers
    final markerPaint = Paint()
      ..color = surfaceColor.withValues(alpha: 0.8)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(lowX, trackTop), Offset(lowX, trackBot), markerPaint);
    canvas.drawLine(Offset(highX, trackTop), Offset(highX, trackBot), markerPaint);

    // Ticks
    final tickPaint = Paint()..color = Colors.white30..strokeWidth = 1;
    final tp = TextPainter(textDirection: ui.TextDirection.ltr);

    tp.text = TextSpan(text: '1', style: TextStyle(color: labelColor, fontSize: 8));
    tp.layout();
    tp.paint(canvas, const Offset(0, trackBot + 7));

    for (var v = 10; v <= 100; v += 10) {
      final x = _toX(v.toDouble(), w);
      canvas.drawLine(Offset(x, trackBot), Offset(x, trackBot + 5), tickPaint);
      if (v % 20 == 0 || v == 10 || v == 100) {
        tp.text = TextSpan(text: '$v', style: TextStyle(color: labelColor, fontSize: 8));
        tp.layout();
        tp.paint(canvas, Offset((x - tp.width / 2).clamp(0, w - tp.width), trackBot + 7));
      }
    }

    // Low/high labels
    tp.text = TextSpan(text: '${lowMark.toInt()}',
        style: TextStyle(color: AppColors.primaryGold, fontSize: 8, fontWeight: FontWeight.w600));
    tp.layout();
    tp.paint(canvas, Offset((lowX - tp.width / 2).clamp(0, w - tp.width), trackTop - tp.height - 2));

    tp.text = TextSpan(text: '${highMark.toInt()}',
        style: TextStyle(color: AppColors.secondarySilver, fontSize: 8, fontWeight: FontWeight.w600));
    tp.layout();
    tp.paint(canvas, Offset((highX - tp.width / 2).clamp(0, w - tp.width), trackTop - tp.height - 2));

    // Thumb shadow
    canvas.drawCircle(Offset(thumbX, _trackCY + 1), _thumbR,
        Paint()..color = Colors.black45..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    // Thumb fill
    canvas.drawCircle(Offset(thumbX, _trackCY), _thumbR,
        Paint()..color = surfaceColor);

    // Thumb border
    canvas.drawCircle(Offset(thumbX, _trackCY), _thumbR,
        Paint()..color = primaryColor..style = PaintingStyle.stroke..strokeWidth = 2);

    // Thumb label
    final gsrLabel = currentGsr.toStringAsFixed(1);
    tp.text = TextSpan(text: gsrLabel,
        style: TextStyle(color: primaryColor, fontSize: 9, fontWeight: FontWeight.w700));
    tp.layout();
    final labelX = (thumbX - tp.width / 2).clamp(0, w - tp.width).toDouble();
    tp.paint(canvas, Offset(labelX, _trackCY - _thumbR - tp.height - 3));
  }

  @override
  bool shouldRepaint(_GsrSliderPainter old) =>
      old.currentGsr != currentGsr || old.lowMark != lowMark || old.highMark != highMark;
}
