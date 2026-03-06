// lib/features/home/presentation/providers/home_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:metal_tracker/core/constants/app_constants.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/features/live_prices/data/models/live_price_model.dart';
import 'package:metal_tracker/features/spot_prices/data/models/spot_price_model.dart';

part 'home_providers.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data types
// ─────────────────────────────────────────────────────────────────────────────

typedef BestPriceData = ({double? pricePerOz, String? retailerName});
typedef MetalBestPrices = ({BestPriceData sell, BestPriceData buyback});

// ─────────────────────────────────────────────────────────────────────────────
// Best sell + buyback prices for each metal (used in AppBar)
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Future<Map<MetalType, MetalBestPrices>> homeBestPrices(
    HomeBestPricesRef ref) async {
  final repo = ref.watch(livePricesRepositoryProvider);
  final result = <MetalType, MetalBestPrices>{};

  for (final metal in MetalType.values) {
    final sellData = await repo.getBestSellPrice(metal.displayName);
    final buybackData = await repo.getBestBuybackPrice(metal.displayName);
    result[metal] = (
      sell: (
        pricePerOz: sellData?['pricePerOz'] as double?,
        retailerName: sellData?['retailerName'] as String?,
      ),
      buyback: (
        pricePerOz: buybackData?['pricePerOz'] as double?,
        retailerName: buybackData?['retailerName'] as String?,
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
  final repo = ref.watch(livePricesRepositoryProvider);
  final all = await repo.getLivePrices();
  if (all.isEmpty) return [];

  // Keep the latest entry per retailer + product profile (or live price name
  // for unmapped entries). productProfileId is preferred because livePriceName
  // can be null for older/manual entries, which would otherwise collide.
  final latest = <String, LivePrice>{};
  for (final price in all) {
    final key =
        '${price.retailerId}|${price.productProfileId ?? price.livePriceName}';
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
  final repo = ref.watch(spotPricesRepositoryProvider);
  final all = await repo.getSpotPrices();
  final global = all.where((p) => p.sourceType == 'global_api').toList();
  if (global.isEmpty) return [];

  final latestDate =
      global.map((p) => p.fetchDate).reduce((a, b) => a.isAfter(b) ? a : b);

  return global
      .where((p) =>
          p.fetchDate.year == latestDate.year &&
          p.fetchDate.month == latestDate.month &&
          p.fetchDate.day == latestDate.day)
      .toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// Most recent local spot prices (latest scrape date only)
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Future<List<SpotPrice>> homeLocalSpotPrices(
    HomeLocalSpotPricesRef ref) async {
  final repo = ref.watch(scraperRepositoryProvider);
  final all = await repo.getLocalSpotPrices();
  if (all.isEmpty) return [];

  final latestDate =
      all.map((p) => p.fetchDate).reduce((a, b) => a.isAfter(b) ? a : b);

  return all
      .where((p) =>
          p.fetchDate.year == latestDate.year &&
          p.fetchDate.month == latestDate.month &&
          p.fetchDate.day == latestDate.day)
      .toList();
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
  final livePricesRepo = ref.watch(livePricesRepositoryProvider);
  final scraperRepo = ref.watch(scraperRepositoryProvider);
  final spotRepo = ref.watch(spotPricesRepositoryProvider);

  final livePrices = await livePricesRepo.getLivePrices();
  final productListings = await scraperRepo.getProductListings();
  final localSpotPrices = await scraperRepo.getLocalSpotPrices();
  final globalSpotPrices = await spotRepo.getSpotPrices();

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
