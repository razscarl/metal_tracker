// lib/features/home/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:metal_tracker/core/constants/app_constants.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/core/widgets/app_drawer.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/features/home/presentation/providers/home_providers.dart';
import 'package:metal_tracker/features/holdings/presentation/providers/holdings_providers.dart';
import 'package:metal_tracker/features/holdings/presentation/widgets/portfolio_valuation_card.dart';
import 'package:metal_tracker/features/live_prices/data/models/live_price_model.dart';
import 'package:metal_tracker/features/retailers/presentation/providers/retailers_providers.dart';
import 'package:metal_tracker/features/spot_prices/data/models/global_spot_price_model.dart';
import 'package:metal_tracker/features/spot_prices/data/models/local_spot_price_model.dart';

final _currencyFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
final _dateFmt = DateFormat('d MMM yyyy');

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bestPricesAsync = ref.watch(homeBestPricesProvider);

    return AppScaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text(
          'Metal Tracker',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.backgroundCard,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryGold),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: bestPricesAsync.when(
            data: (prices) => _BestPricesBar(prices: prices),
            loading: () => const LinearProgressIndicator(
              color: AppColors.primaryGold,
              backgroundColor: AppColors.backgroundDark,
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
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
// AppBar best prices bar
// ─────────────────────────────────────────────────────────────────────────────

class _BestPricesBar extends StatelessWidget {
  final Map<MetalType, MetalBestPrices> prices;

  const _BestPricesBar({required this.prices});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundCard,
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: MetalType.values.map((metal) {
          final data = prices[metal];
          final color = MetalColorHelper.getColorForMetal(metal);
          return _PriceChip(
            label: metal.displayName,
            color: color,
            sell: data?.sell.pricePerOz,
            buyback: data?.buyback.pricePerOz,
          );
        }).toList(),
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  final String label;
  final Color color;
  final double? sell;
  final double? buyback;

  const _PriceChip({
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
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _miniPrice('Sell', sell, AppColors.lossRed),
            const SizedBox(width: 6),
            _miniPrice('Buy', buyback, AppColors.gainGreen),
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
    final retailersAsync = ref.watch(retailersProvider);

    final retailerMap = {
      for (final r in retailersAsync.valueOrNull ?? [])
        r.id: r.retailerAbbr ?? r.name
    };

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
            final byRetailer = <String, List<LivePrice>>{};
            for (final p in prices) {
              byRetailer.putIfAbsent(p.retailerId, () => []).add(p);
            }
            return Column(
              children: byRetailer.entries.map((entry) {
                final label = retailerMap[entry.key] ??
                    entry.key.substring(0, 8);
                return _RetailerLivePricesCard(
                  retailerLabel: label,
                  prices: entry.value,
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

  const _RetailerLivePricesCard({
    required this.retailerLabel,
    required this.prices,
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
          ...prices.map((p) => _LivePriceRow(price: p)),
        ],
      ),
    );
  }
}

class _LivePriceRow extends StatelessWidget {
  final LivePrice price;

  const _LivePriceRow({required this.price});

  @override
  Widget build(BuildContext context) {
    final name = price.livePriceName ?? 'Unknown';
    final sell = price.sellPrice;
    final buy = price.buybackPrice;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(name,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 12)),
          ),
          if (sell != null) _priceTag('Sell', sell, AppColors.lossRed),
          if (buy != null) ...[
            const SizedBox(width: 8),
            _priceTag('Buy', buy, AppColors.gainGreen),
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
  final List<GlobalSpotPrice> spots;

  const _GlobalSpotCard({required this.spots});

  @override
  Widget build(BuildContext context) {
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
                'Global',
                style: TextStyle(
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
          ...spots.map((s) => _GlobalSpotRow(spot: s)),
        ],
      ),
    );
  }
}

class _GlobalSpotRow extends StatelessWidget {
  final GlobalSpotPrice spot;

  const _GlobalSpotRow({required this.spot});

  @override
  Widget build(BuildContext context) {
    final color = MetalColorHelper.getColorForMetalString(spot.metalType);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.circle, color: color, size: 10),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              spot.metalType,
              style: TextStyle(color: color, fontSize: 13),
            ),
          ),
          Text(
            _currencyFmt.format(spot.globalSpotPrice),
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 4),
          const Text(
            '/oz',
            style:
                TextStyle(color: AppColors.textSecondary, fontSize: 11),
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
            final byRetailer = <String, List<LocalSpotPrice>>{};
            for (final s in spots) {
              byRetailer.putIfAbsent(s.retailerId, () => []).add(s);
            }
            return Column(
              children: byRetailer.entries.map((entry) {
                final label = retailerMap[entry.key] ??
                    entry.key.substring(0, 8);
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
  final List<LocalSpotPrice> spots;

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
                _dateFmt.format(spots.first.scrapeDate),
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
                  Icon(Icons.circle, color: color, size: 10),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(s.metalType,
                        style: TextStyle(color: color, fontSize: 13)),
                  ),
                  Text(
                    _currencyFmt.format(s.localSpotPrice),
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
