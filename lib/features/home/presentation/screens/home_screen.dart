// lib/features/home/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:metal_tracker/core/constants/app_constants.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/core/widgets/app_drawer.dart';
import 'package:metal_tracker/core/widgets/app_logo_title.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/features/home/presentation/providers/home_providers.dart';
import 'package:metal_tracker/features/holdings/presentation/providers/holdings_providers.dart';
import 'package:metal_tracker/features/holdings/presentation/widgets/portfolio_valuation_card.dart';
import 'package:metal_tracker/features/live_prices/data/models/live_price_model.dart';
import 'package:metal_tracker/features/retailers/presentation/providers/retailers_providers.dart';
import 'package:metal_tracker/features/spot_prices/data/models/spot_price_model.dart';

final _currencyFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
final _dateFmt = DateFormat('d MMM yyyy');

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      drawer: const AppDrawer(),
      showPriceBar: true,
      appBar: AppBar(
        title: const AppLogoTitle('Metal Tracker'),
        centerTitle: true,
        backgroundColor: AppColors.backgroundCard,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryGold),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryGold,
        onRefresh: () async {
          ref.invalidate(homeBestPricesProvider);
          ref.invalidate(homeRecentLivePricesProvider);
          ref.invalidate(homeGlobalSpotPricesProvider);
          ref.invalidate(homeLocalSpotPricesProvider);
          ref.invalidate(portfolioValuationProvider);
          ref.invalidate(footerTimestampsProvider);
        },
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PortfolioSection(),
              SizedBox(height: 16),
              _LivePricesSection(),
              SizedBox(height: 16),
              _GlobalSpotSection(),
              SizedBox(height: 16),
              _LocalSpotSection(),
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared section header + empty state
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryGold, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.primaryGold,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Center(
        child: Text(
          message,
          style:
              const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Portfolio section
// ─────────────────────────────────────────────────────────────────────────────

class _PortfolioSection extends StatelessWidget {
  const _PortfolioSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
            title: 'Portfolio Overview', icon: Icons.account_balance_wallet),
        PortfolioValuationCard(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Live Prices section
// ─────────────────────────────────────────────────────────────────────────────

class _LivePricesSection extends ConsumerWidget {
  const _LivePricesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(homeRecentLivePricesProvider);
    final profilesAsync = ref.watch(productProfilesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
            title: 'Recent Live Prices', icon: Icons.show_chart),
        async.when(
          data: (prices) {
            if (prices.isEmpty) {
              return const _EmptyState(
                  message: 'No live prices recorded yet.');
            }

            if (profilesAsync.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final profileMap = <String, String>{
              for (final p in profilesAsync.valueOrNull ?? [])
                p.id: p.profileName
            };
            final colorMap = <String, Color>{
              for (final p in profilesAsync.valueOrNull ?? [])
                p.id: MetalColorHelper.getColorForMetal(p.metalTypeEnum)
            };

            final byRetailer = <String, List<LivePrice>>{};
            for (final p in prices) {
              byRetailer.putIfAbsent(p.retailerId, () => []).add(p);
            }
            return Column(
              children: byRetailer.entries.map((entry) {
                final label = entry.value.first.retailerName ?? 'Unknown Retailer';
                return _RetailerLivePricesCard(
                  retailerLabel: label,
                  prices: entry.value,
                  profileMap: profileMap,
                  colorMap: colorMap,
                );
              }).toList(),
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              _EmptyState(message: 'Could not load live prices: $e'),
        ),
      ],
    );
  }
}

class _RetailerLivePricesCard extends StatelessWidget {
  final String retailerLabel;
  final List<LivePrice> prices;
  final Map<String, String> profileMap;
  final Map<String, Color> colorMap;

  const _RetailerLivePricesCard({
    required this.retailerLabel,
    required this.prices,
    required this.profileMap,
    required this.colorMap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                retailerLabel,
                style: const TextStyle(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                _dateFmt.format(prices.first.captureDate),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const Divider(height: 12),
          ...prices.map((p) => _LivePriceRow(price: p, profileMap: profileMap, colorMap: colorMap)),
        ],
      ),
    );
  }
}

class _LivePriceRow extends StatelessWidget {
  final LivePrice price;
  final Map<String, String> profileMap;
  final Map<String, Color> colorMap;

  const _LivePriceRow({
    required this.price,
    required this.profileMap,
    required this.colorMap,
  });

  @override
  Widget build(BuildContext context) {
    final name = (price.productProfileId != null
            ? profileMap[price.productProfileId]
            : null) ??
        price.livePriceName ??
        'Unknown';
    final sell = price.sellPrice;
    final buy = price.buybackPrice;
    final priceColor = (price.productProfileId != null
            ? colorMap[price.productProfileId]
            : null) ??
        AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(name,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 12)),
          ),
          if (sell != null) _priceTag('Sell', sell, priceColor),
          if (buy != null) ...[
            const SizedBox(width: 8),
            _priceTag('Buy', buy, priceColor),
          ],
        ],
      ),
    );
  }

  Widget _priceTag(String label, double value, Color color) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 10),
          ),
          TextSpan(
            text: _currencyFmt.format(value),
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Global Spot Prices section
// ─────────────────────────────────────────────────────────────────────────────

class _GlobalSpotSection extends ConsumerWidget {
  const _GlobalSpotSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(homeGlobalSpotPricesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(
            title: 'Global Spot Prices', icon: Icons.public),
        async.when(
          data: (spots) {
            if (spots.isEmpty) {
              return const _EmptyState(
                  message: 'No global spot prices recorded yet.');
            }
            return _GlobalSpotCard(spots: spots);
          },
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              _EmptyState(message: 'Could not load spot prices: $e'),
        ),
      ],
    );
  }
}

class _GlobalSpotCard extends StatelessWidget {
  final List<SpotPrice> spots;

  const _GlobalSpotCard({required this.spots});

  static const _metals = [
    (key: 'gold', symbol: 'Au', name: 'Gold'),
    (key: 'silver', symbol: 'Ag', name: 'Silver'),
    (key: 'platinum', symbol: 'Pt', name: 'Platinum'),
  ];

  @override
  Widget build(BuildContext context) {
    final byMetal = {for (final s in spots) s.metalType.toLowerCase(): s};
    final latestTimestamp = spots
        .map((s) => s.fetchTimestamp)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AUD / troy oz',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              Text(
                DateFormat('d MMM y H:mm').format(latestTimestamp),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: _metals.asMap().entries.map((entry) {
              final m = entry.value;
              final spot = byMetal[m.key];
              final color = MetalColorHelper.getColorForMetalString(m.key);
              return Expanded(
                child: Column(
                  children: [
                    Image.asset(
                      MetalColorHelper.getAssetPathForMetalString(m.key),
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 6),
                    Text(m.name, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      spot != null ? _currencyFmt.format(spot.price) : '—',
                      style: TextStyle(
                        color: spot != null ? color : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Local Spot Prices section
// ─────────────────────────────────────────────────────────────────────────────

class _LocalSpotSection extends ConsumerWidget {
  const _LocalSpotSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(homeLocalSpotPricesProvider);
    final retailersAsync = ref.watch(retailersProvider);

    final retailerMap = {
      for (final r in retailersAsync.valueOrNull ?? [])
        r.id: r.retailerAbbr ?? r.name
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(title: 'Local Spot Prices', icon: Icons.store),
        async.when(
          data: (spots) {
            if (spots.isEmpty) {
              return const _EmptyState(
                  message: 'No local spot prices recorded yet.');
            }
            final byRetailer = <String, List<SpotPrice>>{};
            for (final s in spots) {
              byRetailer.putIfAbsent(s.retailerId ?? s.source, () => []).add(s);
            }
            return Column(
              children: byRetailer.entries.map((entry) {
                final label = retailerMap[entry.key] ??
                    entry.value.first.source;
                return _LocalSpotCard(
                  retailerLabel: label,
                  spots: entry.value,
                );
              }).toList(),
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              _EmptyState(message: 'Could not load local spot prices: $e'),
        ),
      ],
    );
  }
}

class _LocalSpotCard extends StatelessWidget {
  final String retailerLabel;
  final List<SpotPrice> spots;

  const _LocalSpotCard({
    required this.retailerLabel,
    required this.spots,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                retailerLabel,
                style: const TextStyle(
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                _dateFmt.format(spots.first.fetchDate),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const Divider(height: 12),
          ...spots.map((s) {
            final color =
                MetalColorHelper.getColorForMetalString(s.metalType);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Image.asset(
                    MetalColorHelper.getAssetPathForMetalString(s.metalType),
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(s.metalType,
                        style: TextStyle(color: color, fontSize: 13)),
                  ),
                  Text(
                    _currencyFmt.format(s.price),
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '/oz',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
