import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/features/investment_guide/data/models/investment_guide_context.dart';
import 'package:metal_tracker/features/investment_guide/presentation/providers/investment_guide_providers.dart';

final _pctFmt = NumberFormat('0.0');

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
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _label('MARKET'),
            const SizedBox(width: 8),
            if (ctx.currentGsr != null) ...[
              _GsrChip(gsr: ctx.currentGsr!, movementUp: ctx.gsrMovementUp),
              const SizedBox(width: 8),
            ],
            for (final metal in ['gold', 'silver', 'platinum']) ...[
              _MetalSignalChip(ctx: ctx, metalType: metal),
              const SizedBox(width: 6),
            ],
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _GsrChip extends StatelessWidget {
  final double gsr;
  final bool? movementUp;

  const _GsrChip({required this.gsr, this.movementUp});

  @override
  Widget build(BuildContext context) {
    IconData? icon;
    Color iconColor = AppColors.textSecondary;
    if (movementUp == true) {
      icon = Icons.trending_up;
      iconColor = AppColors.lossRed;
    } else if (movementUp == false) {
      icon = Icons.trending_down;
      iconColor = AppColors.gainGreen;
    }

    return _Chip(
      label: 'GSR ${_pctFmt.format(gsr)}',
      icon: icon,
      iconColor: iconColor,
      color: AppColors.textSecondary,
    );
  }
}

class _MetalSignalChip extends StatelessWidget {
  final InvestmentGuideContext ctx;
  final String metalType;

  const _MetalSignalChip({required this.ctx, required this.metalType});

  @override
  Widget build(BuildContext context) {
    final premium = ctx.premiumFor(metalType);
    final spread = ctx.spreadFor(metalType);
    final metalColor = MetalColorHelper.getColorForMetalString(metalType);
    final metalLabel = metalType[0].toUpperCase() + metalType.substring(1, 3);

    if (premium == null && spread == null) return const SizedBox.shrink();

    final premiumStr = premium != null
        ? 'P:${_pctFmt.format(premium.premiumPct)}%'
        : null;
    final spreadStr = spread != null
        ? 'S:${_pctFmt.format(spread.spreadPct)}%'
        : null;

    final label = [metalLabel, premiumStr, spreadStr]
        .whereType<String>()
        .join(' ');

    return _Chip(label: label, color: metalColor);
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final Color? iconColor;

  const _Chip({
    required this.label,
    required this.color,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: iconColor ?? color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
