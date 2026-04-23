import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/features/holdings/presentation/screens/add_holding_screen.dart';
import 'package:metal_tracker/features/investment_guide/data/models/investment_recommendation.dart';

final _currFmt = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
final _ozFmt = NumberFormat.currency(symbol: r'$', decimalDigits: 0);
final _pctFmt = NumberFormat('0.0');

class ScoreBreakdownSheet extends StatelessWidget {
  final InvestmentRecommendation rec;

  const ScoreBreakdownSheet({super.key, required this.rec});

  static void show(BuildContext context, InvestmentRecommendation rec) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (_) => ScoreBreakdownSheet(rec: rec),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = rec.breakdown;
    final metalColor = MetalColorHelper.getColorForMetalString(
      rec.profile?.metalType ?? 'gold',
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (context, scrollCtrl) => Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                // Title
                Text(
                  rec.listing.listingName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (rec.listing.retailerAbbr != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    rec.listing.retailerAbbr!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      _currFmt.format(rec.listing.listingSellPrice),
                      style: TextStyle(
                          color: metalColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    if (b.listingPricePerOz != null) ...[
                      const Text('  ·  ',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                      Text(
                        '${_ozFmt.format(b.listingPricePerOz!)}/oz',
                        style: TextStyle(color: metalColor, fontSize: 13),
                      ),
                    ],
                  ],
                ),
                if (b.spotPricePerOz != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Text(
                        'Spot  ·  ',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                      Text(
                        '${_ozFmt.format(b.spotPricePerOz!)}/oz',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                      if (b.premiumPct != null) ...[
                        const Text('  ·  ',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                        Text(
                          '${b.premiumPct! >= 0 ? '+' : ''}${_pctFmt.format(b.premiumPct!)}% premium',
                          style: TextStyle(
                            color: b.premiumPct! <= 0
                                ? AppColors.gainGreen
                                : AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(color: Colors.white12),
                const SizedBox(height: 12),

                // Score bars
                _ScoreBar(
                  label: 'Premium over Spot',
                  score: b.premiumScore,
                  maxPts: 40,
                  detail: b.premiumPct != null
                      ? 'Premium: ${_pctFmt.format(b.premiumPct!)}% over spot'
                      : 'No spot data',
                  color: AppColors.primaryGold,
                ),
                const SizedBox(height: 12),
                _ScoreBar(
                  label: 'Buy/Sell Spread',
                  score: b.spreadScore,
                  maxPts: 25,
                  detail: b.spreadPct != null
                      ? 'Spread: ${_pctFmt.format(b.spreadPct!)}%'
                      : 'No buyback data',
                  color: AppColors.secondarySilver,
                ),
                const SizedBox(height: 12),
                _ScoreBar(
                  label: 'Price Trend',
                  score: b.trendScore,
                  maxPts: 20,
                  detail: b.trendSlopeNormalized != null
                      ? 'Slope: ${_pctFmt.format(b.trendSlopeNormalized!)}%/day'
                      : 'Insufficient history',
                  color: AppColors.accentPlatinum,
                ),
                const SizedBox(height: 12),
                _ScoreBar(
                  label: 'Market Timing',
                  score: b.timingScore,
                  maxPts: 15,
                  detail: _timingDetail(b),
                  color: const Color(0xFF7CB9E8),
                ),

                if (rec.flags.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 8),
                  const Text(
                    'DATA FLAGS',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final flag in rec.flags) _FlagRow(flag: flag),
                ],

                const SizedBox(height: 24),

                // Buy This button
                if (rec.isAvailable)
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                      label: const Text(
                        'Buy This',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AddHoldingScreen(
                              prefillProductName: rec.listing.listingName,
                              prefillProfileId: rec.profile?.id,
                              prefillRetailerId: rec.listing.retailerId,
                              prefillPrice: rec.listing.listingSellPrice,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timingDetail(ScoreBreakdown b) {
    final parts = <String>[];
    if (b.gsrValue != null) parts.add('GSR ${_pctFmt.format(b.gsrValue!)}');
    if (b.localPremiumPct != null) {
      parts.add('Premium ${_pctFmt.format(b.localPremiumPct!)}%');
    }
    if (b.marketSpreadPct != null) {
      parts.add('Spread ${_pctFmt.format(b.marketSpreadPct!)}%');
    }
    return parts.isEmpty ? 'No timing data' : parts.join('  ·  ');
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final double? score;
  final int maxPts;
  final String detail;
  final Color color;

  const _ScoreBar({
    required this.label,
    required this.score,
    required this.maxPts,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pts = score != null ? (score! / 100 * maxPts).round() : null;
    final fill = score != null ? (score! / 100).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              pts != null ? '$pts / $maxPts' : '— / $maxPts',
              style: TextStyle(
                color: pts != null ? color : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: fill,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(
              score == null ? Colors.white24 : color,
            ),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          detail,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

class _FlagRow extends StatelessWidget {
  final ListingFlag flag;

  const _FlagRow({required this.flag});

  @override
  Widget build(BuildContext context) {
    final isHigh = flag.isHigh;
    final isMed = flag.isMedium;
    final color = isHigh
        ? AppColors.lossRed
        : isMed
            ? AppColors.primaryGold
            : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isHigh
                ? Icons.error_outline
                : isMed
                    ? Icons.warning_amber_outlined
                    : Icons.info_outline,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  flag.label,
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  flag.detail,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
