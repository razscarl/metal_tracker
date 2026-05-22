import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/features/investment_guide/data/models/investment_guide_context.dart';
import 'package:metal_tracker/features/investment_guide/presentation/providers/investment_guide_providers.dart';

final _pctFmt = NumberFormat('0.0');
final _gsrFmt = NumberFormat('0.0');

class MarketContextBanner extends ConsumerWidget {
  const MarketContextBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contextAsync = ref.watch(investmentGuideContextProvider);

    return contextAsync.when(
      loading: () => const _BannerShimmer(),
      error: (_, __) => const SizedBox.shrink(),
      data: (ctx) => _BannerContent(ctx: ctx),
    );
  }
}

class _BannerShimmer extends StatelessWidget {
  const _BannerShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.primaryGold),
        ),
      ),
    );
  }
}

class _BannerContent extends StatelessWidget {
  final InvestmentGuideContext ctx;

  const _BannerContent({required this.ctx});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Text(
                'MARKET SNAPSHOT',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              if (ctx.currentGsr != null) ...[
                const Spacer(),
                _GsrBadge(
                  gsr: ctx.currentGsr!,
                  movementUp: ctx.gsrMovementUp,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Metal rows
          Row(
            children: [
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final metal in ['gold', 'silver', 'platinum'])
                      _MetalRow(ctx: ctx, metalType: metal),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GsrBadge extends StatelessWidget {
  final double gsr;
  final bool? movementUp;

  const _GsrBadge({required this.gsr, this.movementUp});

  @override
  Widget build(BuildContext context) {
    IconData? icon;
    Color trendColor = AppColors.textSecondary;
    if (movementUp == true) {
      icon = Icons.arrow_upward;
      trendColor = AppColors.lossRed;
    } else if (movementUp == false) {
      icon = Icons.arrow_downward;
      trendColor = AppColors.gainGreen;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Gold/Silver Ratio: ',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
        Text(
          _gsrFmt.format(gsr),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (icon != null) ...[
          const SizedBox(width: 2),
          Icon(icon, size: 11, color: trendColor),
        ],
      ],
    );
  }
}

class _MetalRow extends StatelessWidget {
  final InvestmentGuideContext ctx;
  final String metalType;

  const _MetalRow({required this.ctx, required this.metalType});

  @override
  Widget build(BuildContext context) {
    final premium = ctx.premiumFor(metalType);
    final spread = ctx.spreadFor(metalType);
    if (premium == null && spread == null) return const SizedBox.shrink();

    final metalColor = MetalColorHelper.getColorForMetalString(metalType);
    final metalLabel =
        metalType[0].toUpperCase() + metalType.substring(1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              metalLabel,
              style: TextStyle(
                color: metalColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (premium != null) ...[
            Text(
              'Premium: ',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            Text(
              '${_pctFmt.format(premium.premiumPct)}%',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (premium != null && spread != null)
            const Text(
              '  ·  ',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          if (spread != null) ...[
            Text(
              'Spread: ',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            Text(
              '${_pctFmt.format(spread.spreadPct)}%',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
