import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/features/investment_guide/data/models/investment_guide_context.dart';
import 'package:metal_tracker/features/investment_guide/presentation/providers/investment_guide_providers.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_prefs_providers.dart';

final _pctFmt = NumberFormat('0.0');
final _gsrFmt = NumberFormat('0.0');

class MarketContextBanner extends ConsumerWidget {
  const MarketContextBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contextAsync = ref.watch(investmentGuideContextProvider);
    final settings = ref.watch(userAnalyticsPrefsNotifierProvider).valueOrNull;
    final gsrLowMark = settings?.gsrLowMark ?? 60.0;
    final gsrHighMark = settings?.gsrHighMark ?? 70.0;

    return contextAsync.when(
      loading: () => const _BannerShimmer(),
      error: (_, __) => const SizedBox.shrink(),
      data: (ctx) => _BannerContent(
        ctx: ctx,
        gsrLowMark: gsrLowMark,
        gsrHighMark: gsrHighMark,
      ),
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
        
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              strokeWidth: 2),
        ),
      ),
    );
  }
}

class _BannerContent extends StatelessWidget {
  final InvestmentGuideContext ctx;
  final double gsrLowMark;
  final double gsrHighMark;

  const _BannerContent({
    required this.ctx,
    required this.gsrLowMark,
    required this.gsrHighMark,
  });

  static const _metals = ['gold', 'silver', 'platinum'];
  static const _metalColWidth = 86.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Centred header
          const Text(
            'MARKET SNAPSHOT',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          // GSR line
          if (ctx.currentGsr != null) ...[
            const SizedBox(height: 6),
            _GsrLine(
              gsr: ctx.currentGsr!,
              movementUp: ctx.gsrMovementUp,
              gsrLowMark: gsrLowMark,
              gsrHighMark: gsrHighMark,
            ),
          ],
          const SizedBox(height: 10),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 8),
          // Table header
          Row(
            children: [
              const SizedBox(width: _metalColWidth),
              _tableHeader('Premium'),
              _tableHeader('Spread'),
            ],
          ),
          const SizedBox(height: 4),
          // Data rows
          for (final metal in _metals)
            _MetalTableRow(
              ctx: ctx,
              metalType: metal,
              metalColWidth: _metalColWidth,
            ),
        ],
      ),
    );
  }

  Widget _tableHeader(String label) => Expanded(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
      );
}

class _GsrLine extends StatelessWidget {
  final double gsr;
  final bool? movementUp;
  final double gsrLowMark;
  final double gsrHighMark;

  const _GsrLine({
    required this.gsr,
    required this.gsrLowMark,
    required this.gsrHighMark,
    this.movementUp,
  });

  Color get _gsrColor {
    if (gsr <= gsrLowMark) return AppColors.primaryGold;
    if (gsr >= gsrHighMark) return AppColors.secondarySilver;
    return AppColors.textPrimary;
  }

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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Gold / Silver Ratio (GSR):  ',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        Text(
          '${_gsrFmt.format(gsr)}:1',
          style: TextStyle(
            color: _gsrColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (icon != null) ...[
          const SizedBox(width: 3),
          Icon(icon, size: 12, color: trendColor),
        ],
      ],
    );
  }
}

class _MetalTableRow extends StatelessWidget {
  final InvestmentGuideContext ctx;
  final String metalType;
  final double metalColWidth;

  const _MetalTableRow({
    required this.ctx,
    required this.metalType,
    required this.metalColWidth,
  });

  @override
  Widget build(BuildContext context) {
    final premium = ctx.premiumFor(metalType);
    final spread = ctx.spreadFor(metalType);
    final metalColor = MetalColorHelper.getColorForMetalString(metalType);
    final metalLabel = metalType[0].toUpperCase() + metalType.substring(1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: metalColWidth,
            child: Row(
              children: [
                Image.asset(
                  MetalColorHelper.getAssetPathForMetalString(metalType),
                  width: 14,
                  height: 14,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 5),
                Text(
                  metalLabel,
                  style: TextStyle(
                    color: metalColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _valueCell(
            premium != null ? '${_pctFmt.format(premium.premiumPct)}%' : '—',
            premium?.movementUp,
          ),
          _valueCell(
            spread != null ? '${_pctFmt.format(spread.spreadPct)}%' : '—',
            spread?.movementUp,
          ),
        ],
      ),
    );
  }

  Widget _valueCell(String value, bool? movementUp) => Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (movementUp != null) ...[
              const SizedBox(width: 2),
              Icon(
                movementUp ? Icons.arrow_upward : Icons.arrow_downward,
                size: 10,
                color: movementUp ? AppColors.lossRed : AppColors.gainGreen,
              ),
            ],
          ],
        ),
      );
}
