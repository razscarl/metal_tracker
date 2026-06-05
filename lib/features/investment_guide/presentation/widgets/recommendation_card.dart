import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/features/investment_guide/data/models/investment_recommendation.dart';
import 'package:metal_tracker/features/investment_guide/presentation/widgets/score_breakdown_sheet.dart';

final _currFmt = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
final _ozFmt = NumberFormat.currency(symbol: r'$', decimalDigits: 0);

Color _rankColor(double score) {
  if (score >= 75) return AppColors.gainGreen;
  if (score >= 55) return AppColors.success;
  if (score >= 35) return AppColors.primaryGold;
  return AppColors.lossRed;
}

class RecommendationCard extends StatelessWidget {
  final InvestmentRecommendation rec;

  const RecommendationCard({super.key, required this.rec});

  @override
  Widget build(BuildContext context) {
    final metalType = rec.profile?.metalType ?? 'gold';
    final metalColor = MetalColorHelper.getColorForMetalString(metalType);
    final b = rec.breakdown;
    final rankColor = _rankColor(rec.compositeScore);

    return GestureDetector(
      onTap: () => ScoreBreakdownSheet.show(context, rec),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column: rank chip above score ring
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _RankChip(label: rec.rankLabel, color: rankColor),
                const SizedBox(height: 6),
                _ScoreRing(score: rec.compositeScore),
              ],
            ),
            const SizedBox(width: 14),

            // Main content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Retailer name
                  if (rec.listing.retailerName != null)
                    Text(
                      rec.listing.retailerName!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  const SizedBox(height: 3),

                  // Metal icon + listing name
                  Row(
                    children: [
                      Image.asset(
                        MetalColorHelper.getAssetPathForMetalString(metalType),
                        width: 14,
                        height: 14,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          rec.listing.listingName,
                          style: TextStyle(
                            color: metalColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Prices
                  Row(
                    children: [
                      Text(
                        _currFmt.format(rec.listing.listingSellPrice),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (b.listingPricePerOz != null) ...[
                        const Text(
                          '  ·  ',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                        Text(
                          '${_ozFmt.format(b.listingPricePerOz!)}/oz',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Flag chips (medium + high only)
                  if (_visibleFlags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: _visibleFlags
                          .map((f) => _FlagChip(flag: f))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),

            // Chevron
            const Padding(
              padding: EdgeInsets.only(top: 18),
              child: Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  List<ListingFlag> get _visibleFlags => rec.flags
      .where((f) => f.isHigh || f.isMedium)
      .where((f) => f != ListingFlag.outOfStock)
      .toList();
}

class _ScoreRing extends StatelessWidget {
  final double score;

  const _ScoreRing({required this.score});

  Color get _ringColor => _rankColor(score);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: CustomPaint(
        painter: _RingPainter(score: score, color: _ringColor),
        child: Center(
          child: Text(
            score.round().toString(),
            style: TextStyle(
              color: _ringColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double score;
  final Color color;

  const _RingPainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    final sweepAngle = (score / 100) * 2 * pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.score != score || old.color != color;
}

class _RankChip extends StatelessWidget {
  final String label;
  final Color color;

  const _RankChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _FlagChip extends StatelessWidget {
  final ListingFlag flag;

  const _FlagChip({required this.flag});

  @override
  Widget build(BuildContext context) {
    final color = flag.isHigh ? AppColors.lossRed : AppColors.primaryGold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Text(
        flag.label,
        style: TextStyle(color: color, fontSize: 10),
      ),
    );
  }
}
