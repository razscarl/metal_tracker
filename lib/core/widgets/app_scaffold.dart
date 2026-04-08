// lib/core/widgets/app_scaffold.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:metal_tracker/core/constants/app_constants.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/features/home/presentation/providers/home_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _currencyFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
final _footerTimeFmt = DateFormat('d/M/y H:mm');

/// Shared scaffold used by all screens.
///
/// Supports two usage modes:
/// - [title] mode (preferred): pass [title], optional [actions], [tabBar],
///   [onRefresh]. The scaffold builds its own AppBar and shows the username.
/// - [appBar] mode (legacy): pass a fully-built [PreferredSizeWidget] directly.
class AppScaffold extends ConsumerWidget {
  // Title-based API
  final String? title;
  final List<Widget>? actions;
  final TabBar? tabBar;
  final VoidCallback? onRefresh;

  // Legacy appBar API
  final PreferredSizeWidget? appBar;

  // Common
  final Widget body;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool showPriceBar;

  const AppScaffold({
    super.key,
    this.title,
    this.actions,
    this.tabBar,
    this.onRefresh,
    this.appBar,
    required this.body,
    this.drawer,
    this.floatingActionButton,
    this.backgroundColor,
    this.showPriceBar = false,
  }) : assert(title != null || appBar != null,
            'AppScaffold requires either title or appBar');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timestampsAsync = ref.watch(footerTimestampsProvider);
    final bestPricesAsync =
        showPriceBar ? ref.watch(homeBestPricesProvider) : null;

    final effectiveAppBar = appBar ?? _buildAppBar(context, ref);

    final priceBar = showPriceBar && bestPricesAsync != null
        ? bestPricesAsync.when(
            data: (prices) =>
                _BestPricesBar(prices: prices, onRefresh: onRefresh),
            loading: () => const LinearProgressIndicator(
              color: AppColors.primaryGold,
              backgroundColor: AppColors.backgroundDark,
              minHeight: 2,
            ),
            error: (_, __) => const SizedBox.shrink(),
          )
        : null;

    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.backgroundDark,
      appBar: effectiveAppBar,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      body: priceBar != null
          ? Column(
              children: [
                priceBar,
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: timestampsAsync.when(
        data: (ts) => _FooterBar(timestamps: ts),
        loading: () => const _FooterBar(
          timestamps: (
            livePrices: null,
            productListings: null,
            spotPrices: null,
            globalSpotPrices: null,
          ),
        ),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref) {
    final username = Supabase.instance.client.auth.currentUser?.email ?? '';
    final displayName =
        username.contains('@') ? username.split('@').first : username;

    return AppBar(
      title: Text(title!),
      centerTitle: false,
      backgroundColor: AppColors.backgroundCard,
      elevation: 0,
      iconTheme: const IconThemeData(color: AppColors.primaryGold),
      titleTextStyle: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      actions: [
        if (actions != null) ...actions!,
        if (displayName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                displayName,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
      bottom: tabBar,
    );
  }
}

// ── Best Prices Bar ───────────────────────────────────────────────────────────

class _BestPricesBar extends StatelessWidget {
  final Map<MetalType, MetalBestPrices> prices;
  final VoidCallback? onRefresh;

  const _BestPricesBar({required this.prices, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundCard,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: MetalType.values.map((metal) {
                final data = prices[metal];
                final color = MetalColorHelper.getColorForMetal(metal);
                return _PriceChip(
                  iconPath: MetalColorHelper.getAssetPathForMetal(metal),
                  label: metal.displayName,
                  color: color,
                  sell: data?.sell.pricePerOz,
                  buyback: data?.buyback.pricePerOz,
                );
              }).toList(),
            ),
          ),
          if (onRefresh != null)
            IconButton(
              icon: const Icon(Icons.refresh,
                  size: 18, color: AppColors.textSecondary),
              onPressed: onRefresh,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  final String iconPath;
  final String label;
  final Color color;
  final double? sell;
  final double? buyback;

  const _PriceChip({
    required this.iconPath,
    required this.label,
    required this.color,
    required this.sell,
    required this.buyback,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(iconPath, width: 20, height: 20, fit: BoxFit.contain),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _miniPrice('Sell', sell, color),
            const SizedBox(width: 6),
            _miniPrice('Buy', buyback, color),
          ],
        ),
      ],
    );
  }

  Widget _miniPrice(String tag, double? value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(tag,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 9)),
        Text(
          value != null ? _currencyFmt.format(value) : '—',
          style: TextStyle(
            color: value != null ? valueColor : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Footer Bar ────────────────────────────────────────────────────────────────

class _FooterBar extends StatelessWidget {
  final ({
    DateTime? livePrices,
    DateTime? productListings,
    DateTime? spotPrices,
    DateTime? globalSpotPrices,
  }) timestamps;

  const _FooterBar({required this.timestamps});

  String _fmtDate(DateTime? dt) {
    if (dt == null) return 'Never';
    return DateFormat('d/M/y').format(dt);
  }

  String _fmtDateTime(DateTime? dt) {
    if (dt == null) return 'Never';
    return _footerTimeFmt.format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundCard,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SafeArea(
        top: false,
        child: Text(
          'Live: ${_fmtDate(timestamps.livePrices)}'
          '  |  '
          'Listings: ${_fmtDate(timestamps.productListings)}'
          '  |  '
          'Spot: ${_fmtDate(timestamps.spotPrices)}'
          '  |  '
          'Global Spot: ${_fmtDateTime(timestamps.globalSpotPrices)}',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
