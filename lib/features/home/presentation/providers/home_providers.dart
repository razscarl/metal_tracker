// lib/features/home/presentation/providers/home_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:metal_tracker/core/constants/app_constants.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/features/live_prices/data/models/live_price_model.dart';
import 'package:metal_tracker/features/spot_prices/data/models/spot_price_model.dart';
import 'package:metal_tracker/features/spot_prices/presentation/providers/spot_prices_providers.dart';
import 'package:metal_tracker/features/live_prices/presentation/providers/live_prices_providers.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_prefs_providers.dart';

part 'home_providers.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data types
// ─────────────────────────────────────────────────────────────────────────────

typedef BestPriceData = ({double? pricePerOz, String? retailerName, String? retailerAbbr});
typedef MetalBestPrices = ({BestPriceData sell, BestPriceData buyback});

// ─────────────────────────────────────────────────────────────────────────────
// Best sell + buyback prices for each metal (used in AppBar)
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Future<Map<MetalType, MetalBestPrices>> homeBestPrices(
    HomeBestPricesRef ref) async {
  // Reactive dependency — rebuilds whenever live prices are scraped/edited
  await ref.watch(livePricesNotifierProvider.future);
  final repo = ref.watch(livePricesRepositoryProvider);

  final result = <MetalType, MetalBestPrices>{};

  for (final metal in MetalType.values) {
    final sellData = await repo.getBestSellPrice(metal.displayName);
    final buybackData = await repo.getBestBuybackPrice(metal.displayName);
    result[metal] = (
      sell: (
        pricePerOz: sellData?['pricePerOz'] as double?,
        retailerName: sellData?['retailerName'] as String?,
        retailerAbbr: sellData?['retailerAbbr'] as String?,
      ),
      buyback: (
        pricePerOz: buybackData?['pricePerOz'] as double?,
        retailerName: buybackData?['retailerName'] as String?,
        retailerAbbr: buybackData?['retailerAbbr'] as String?,
      ),
    );
  }
  return result;
}

// ─────────────────────────────────────────────────────────────────────────────
// Most recent live prices (latest capture date only)
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Future<List<LivePrice>> homeRecentLivePrices(
    HomeRecentLivePricesRef ref) async {
  // Watch the notifier — rebuilds automatically when live prices are scraped/edited
  final all = await ref.watch(livePricesNotifierProvider.future);
  if (all.isEmpty) return [];

  // Keep the single most-recent entry per (retailer, metalType).
  // This gives at most one row per metal per retailer — regardless of how
  // search strings or product profiles change over time.
  // Records without a metalType are legacy pre-migration rows; skip them.
  final latest = <String, LivePrice>{};
  for (final price in all) {
    if (price.metalType == null) continue;
    final key = '${price.retailerId}|${price.metalType}';
    final existing = latest[key];
    if (existing == null ||
        price.captureTimestamp.isAfter(existing.captureTimestamp)) {
      latest[key] = price;
    }
  }

  return latest.values.toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// Most recent global spot prices (latest fetch date only)
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Future<List<SpotPrice>> homeGlobalSpotPrices(
    HomeGlobalSpotPricesRef ref) async {
  // Watch the notifier — rebuilds automatically when spot prices are fetched
  final all = await ref.watch(spotPricesNotifierProvider.future);
  var global = all.where((p) => p.sourceType == 'global_api').toList();
  if (global.isEmpty) return [];

  // Filter by user's configured global spot providers (if any are set)
  final userPrefs =
      ref.watch(userGlobalSpotPrefNotifierProvider).valueOrNull ?? [];
  if (userPrefs.isNotEmpty) {
    final allProviders =
        ref.watch(globalSpotProvidersProvider(activeOnly: false)).valueOrNull ??
            [];
    final configuredProviderNames = userPrefs
        .map((up) {
          final match = allProviders.firstWhere(
            (p) => p.providerKey == up.providerKey,
            orElse: () => allProviders.isEmpty
                ? throw StateError('no providers')
                : allProviders.first,
          );
          return allProviders.isEmpty ? null : match.name;
        })
        .whereType<String>()
        .toSet();
    if (configuredProviderNames.isNotEmpty) {
      final filtered =
          global.where((p) => configuredProviderNames.contains(p.source)).toList();
      if (filtered.isNotEmpty) global = filtered;
    }
  }

  // Keep the most recent entry per (source, metalType) so every configured
  // provider's latest data is shown, even if fetched on different dates.
  final latestPerSourceMetal = <String, SpotPrice>{};
  for (final p in global) {
    final key = '${p.source}|${p.metalType.toLowerCase()}';
    final existing = latestPerSourceMetal[key];
    if (existing == null ||
        p.fetchTimestamp.isAfter(existing.fetchTimestamp)) {
      latestPerSourceMetal[key] = p;
    }
  }

  return latestPerSourceMetal.values.toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// Most recent local spot prices (latest per retailer+metal)
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Future<List<SpotPrice>> homeLocalSpotPrices(
    HomeLocalSpotPricesRef ref) async {
  // Watch the notifier — rebuilds automatically when local spot is fetched
  final all = await ref.watch(spotPricesNotifierProvider.future);
  final localSpot =
      all.where((p) => p.sourceType == 'local_scraper').toList();
  if (localSpot.isEmpty) return [];

  // Keep the most recent entry per (retailer, metalType) so every retailer's
  // latest batch is shown regardless of when other retailers were last fetched.
  final latest = <String, SpotPrice>{};
  for (final p in localSpot) {
    final key = '${p.retailerId ?? p.source}|${p.metalType.toLowerCase()}';
    final existing = latest[key];
    if (existing == null ||
        p.fetchTimestamp.isAfter(existing.fetchTimestamp)) {
      latest[key] = p;
    }
  }

  return latest.values.toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer timestamps — last updated for each data type
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Future<
    ({
      DateTime? livePrices,
      DateTime? productListings,
      DateTime? spotPrices,
      DateTime? globalSpotPrices,
    })> footerTimestamps(FooterTimestampsRef ref) async {
  // Watch notifiers — rebuilds automatically after fetches/mutations
  final livePrices = await ref.watch(livePricesNotifierProvider.future);
  final allSpotPrices = await ref.watch(spotPricesNotifierProvider.future);
  final productListings = await ref
      .watch(productListingsRepositoryProvider)
      .getLatestListings();
  final localSpotPrices =
      allSpotPrices.where((p) => p.sourceType == 'local_scraper').toList();

  final livePricesLast = livePrices.isEmpty
      ? null
      : livePrices
          .map((p) => p.captureTimestamp)
          .reduce((a, b) => a.isAfter(b) ? a : b);

  final productListingsLast = productListings.isEmpty
      ? null
      : productListings
          .map((p) => p.scrapeTimestamp)
          .reduce((a, b) => a.isAfter(b) ? a : b);

  final spotPricesLast = localSpotPrices.isEmpty
      ? null
      : localSpotPrices
          .map((p) => p.fetchTimestamp)
          .reduce((a, b) => a.isAfter(b) ? a : b);

  final globalSpotPrices =
      allSpotPrices.where((p) => p.sourceType == 'global_api').toList();
  final globalSpotLast = globalSpotPrices.isEmpty
      ? null
      : globalSpotPrices
          .map((p) => p.fetchTimestamp)
          .reduce((a, b) => a.isAfter(b) ? a : b);

  return (
    livePrices: livePricesLast,
    productListings: productListingsLast,
    spotPrices: spotPricesLast,
    globalSpotPrices: globalSpotLast,
  );
}
