// lib/core/widgets/app_scaffold.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:metal_tracker/core/constants/app_constants.dart';
import 'package:metal_tracker/core/utils/time_service.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/core/widgets/app_drawer.dart';
import 'package:metal_tracker/core/widgets/app_logo_title.dart';
import 'package:metal_tracker/features/admin/presentation/providers/admin_providers.dart';
import 'package:metal_tracker/features/home/presentation/providers/home_providers.dart';
import 'package:metal_tracker/features/live_prices/presentation/providers/live_prices_providers.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_profile_providers.dart';
import 'package:metal_tracker/features/settings/presentation/screens/settings_screen.dart';

final _currencyFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
final _footerTimeFmt = DateFormat(AppDateFormats.compact);

/// Shared scaffold used by all screens.
///
/// Tier 1: AppBar — always shown (hamburger + title + optional refresh for home).
/// Tier 2: Sub-header — best prices bar for home, action row for non-home.
/// Tier 3: Optional TabBar.
/// Footer: Persistent timestamps bar.
class AppScaffold extends ConsumerWidget {
  final String title;
  final bool isHome;
  final List<Widget> actions;
  final VoidCallback? onRefresh;
  final TabBar? tabBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.isHome = false,
    this.actions = const [],
    this.onRefresh,
    this.tabBar,
    this.floatingActionButton,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timestampsAsync = ref.watch(footerTimestampsProvider);
    final bestPricesAsync =
        isHome ? ref.watch(homeBestPricesProvider) : null;
    final username = ref.watch(userProfileNotifierProvider).valueOrNull?.username;
    final appVersion = ref.watch(appVersionProvider).valueOrNull ?? '';
    final isAdmin = ref.watch(isAdminProvider);
    final hasPendingItems = isAdmin &&
        ((ref.watch(pendingRequestCountProvider).valueOrNull ?? 0) +
                (ref.watch(pendingUserCountProvider).valueOrNull ?? 0) >
            0);

    // ── Tier 1: AppBar ───────────────────────────────────────────────────────
    final appBar = AppBar(
      backgroundColor: AppColors.backgroundCard,
      elevation: 0,
      iconTheme: const IconThemeData(color: AppColors.primaryGold),
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: isHome
          ? AppLogoTitle(title)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (appVersion.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    'v$appVersion',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ],
            ),
      centerTitle: true,
      actions: [
        if (isHome) ...actions,
        if (username != null && username.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Center(
              child: Text(
                username,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.account_circle_outlined,
                  color: AppColors.primaryGold),
              tooltip: 'Profile',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
            if (hasPendingItems)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.lossRed,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ],
    );

    // ── Tier 2: Sub-header ──────────────────────────────────────────────────
    Widget tier2;
    if (isHome) {
      tier2 = bestPricesAsync!.when(
        data: (prices) => _BestPricesBar(prices: prices, onRefresh: onRefresh),
        loading: () => const LinearProgressIndicator(
          color: AppColors.primaryGold,
          backgroundColor: AppColors.backgroundDark,
          minHeight: 2,
        ),
        error: (_, __) => const SizedBox.shrink(),
      );
    } else {
      tier2 = Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          border: const Border(
            bottom: BorderSide(color: AppColors.backgroundDark),
          ),
        ),
        child: Row(
          children: [
            // Left: back button or spacer
            SizedBox(
              width: 44,
              child: Builder(
                builder: (ctx) => Navigator.canPop(ctx)
                    ? IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 18,
                          color: AppColors.primaryGold,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            // Center: screen actions
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: actions,
              ),
            ),
            // Right: refresh button or spacer
            SizedBox(
              width: 44,
              child: onRefresh != null
                  ? IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.refresh,
                        size: 18,
                        color: AppColors.primaryGold,
                      ),
                      onPressed: onRefresh,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }

    // ── Body column ─────────────────────────────────────────────────────────
    final bodyColumn = Column(
      children: [
        tier2,
        if (tabBar != null)
          Container(
            color: AppColors.backgroundCard,
            child: tabBar!,
          ),
        Expanded(child: body),
      ],
    );

    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.backgroundDark,
      appBar: appBar,
      drawer: const AppDrawer(),
      floatingActionButton: floatingActionButton,
      body: bodyColumn,
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
      padding: const EdgeInsets.symmetric(vertical: 4),
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
                  sellAbbr: data?.sell.retailerAbbr,
                  buybackAbbr: data?.buyback.retailerAbbr,
                );
              }).toList(),
            ),
          ),
          if (onRefresh != null)
            IconButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.refresh,
                  size: 18, color: AppColors.textSecondary),
              tooltip: 'Refresh',
              onPressed: onRefresh,
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
  final String? sellAbbr;
  final String? buybackAbbr;

  const _PriceChip({
    required this.iconPath,
    required this.label,
    required this.color,
    required this.sell,
    required this.buyback,
    this.sellAbbr,
    this.buybackAbbr,
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
            _miniPrice('Sell', sell, sellAbbr, color),
            const SizedBox(width: 6),
            _miniPrice('Buy', buyback, buybackAbbr, color),
          ],
        ),
      ],
    );
  }

  Widget _miniPrice(String tag, double? value, String? abbr, Color valueColor) {
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
        if (abbr != null && abbr.isNotEmpty)
          Text(
            abbr,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 8,
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

  String _fmt(DateTime? dt) {
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
          'Live: ${_fmt(timestamps.livePrices)}'
          '  |  '
          'Listings: ${_fmt(timestamps.productListings)}'
          '  |  '
          'Global Spot: ${_fmt(timestamps.globalSpotPrices)}'
          '  |  '
          'Local Spot: ${_fmt(timestamps.spotPrices)}',
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
