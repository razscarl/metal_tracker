import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/features/analytics/presentation/providers/analytics_providers.dart';
import 'package:metal_tracker/features/investment_guide/data/models/investment_guide_context.dart';
import 'package:metal_tracker/features/investment_guide/data/models/investment_recommendation.dart';
import 'package:metal_tracker/features/investment_guide/domain/investment_guide_scorer.dart';
import 'package:metal_tracker/features/product_profiles/data/models/product_profile_model.dart';
import 'package:metal_tracker/features/product_profiles/presentation/providers/product_profiles_providers.dart';
import 'package:metal_tracker/features/settings/data/models/user_analytics_settings_model.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_prefs_providers.dart';
import 'package:metal_tracker/features/spot_prices/data/models/spot_price_model.dart';
import 'package:metal_tracker/features/spot_prices/presentation/providers/spot_prices_providers.dart';

part 'investment_guide_providers.g.dart';

// ── Market context banner (loads independently of the guide run) ──────────────

@riverpod
Future<InvestmentGuideContext> investmentGuideContext(
    InvestmentGuideContextRef ref) async {
  final gsrHistory = await ref.watch(gsrHistoryProvider.future);
  final premiumSummary = await ref.watch(localPremiumSummaryProvider.future);
  final spreadSummary = await ref.watch(localSpreadSummaryProvider.future);

  final latest = gsrHistory.isNotEmpty ? gsrHistory.first : null;
  return InvestmentGuideContext(
    currentGsr: latest?.gsr,
    gsrMovementUp: latest?.movementUp,
    premiumSummary: premiumSummary,
    spreadSummary: spreadSummary,
  );
}

// ── Investment Guide Notifier ─────────────────────────────────────────────────

@riverpod
class InvestmentGuideNotifier extends _$InvestmentGuideNotifier {
  @override
  AsyncValue<List<InvestmentRecommendation>> build() {
    return const AsyncData([]);
  }

  Future<void> runGuide({
    required double budget,
    String? metalFilter,
  }) async {
    state = const AsyncLoading();

    try {
      final results = await _compute(budget: budget, metalFilter: metalFilter);
      state = AsyncData(results);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<List<InvestmentRecommendation>> _compute({
    required double budget,
    String? metalFilter,
  }) async {
    // Load all required data in parallel
    final listingsFuture =
        ref.read(productListingsRepositoryProvider).getLatestListings();
    final profilesFuture =
        ref.read(productProfilesNotifierProvider.future);
    final spotsFuture =
        ref.read(spotPricesNotifierProvider.future);
    final settingsFuture =
        ref.read(userAnalyticsSettingsNotifierProvider.future);
    final gsrFuture =
        ref.read(gsrHistoryProvider.future);
    final premiumFuture =
        ref.read(localPremiumSummaryProvider.future);
    final spreadFuture =
        ref.read(localSpreadSummaryProvider.future);

    final results = await Future.wait([
      listingsFuture,
      profilesFuture,
      spotsFuture,
      settingsFuture,
      gsrFuture,
      premiumFuture,
      spreadFuture,
    ]);

    final listings = results[0] as List;
    final profiles = results[1] as List<ProductProfile>;
    final spots = results[2] as List<SpotPrice>;
    final settings = results[3] as UserAnalyticsSettings;
    final gsrHistory = results[4] as List<GsrDataPoint>;
    final premiumSummary = results[5] as List<LocalPremiumEntry>;
    final spreadSummary = results[6] as List<LocalSpreadEntry>;

    // Build lookup maps
    final profileMap = {for (final p in profiles) p.id: p};

    // Best spot price per metal: global_api preferred, local_scraper fallback
    final spotPerMetal = <String, ({double price, bool isLocal})>{};
    final metalTypes = ['gold', 'silver', 'platinum'];
    for (final metal in metalTypes) {
      final metalSpots = spots
          .where((s) => s.metalType.toLowerCase() == metal && s.status == 'success')
          .toList();
      final global = metalSpots
          .where((s) => s.sourceType == 'global_api')
          .toList()
        ..sort((a, b) => b.fetchTimestamp.compareTo(a.fetchTimestamp));
      if (global.isNotEmpty) {
        spotPerMetal[metal] = (price: global.first.price, isLocal: false);
        continue;
      }
      final local = metalSpots
          .where((s) => s.sourceType == 'local_scraper')
          .toList()
        ..sort((a, b) => b.fetchTimestamp.compareTo(a.fetchTimestamp));
      if (local.isNotEmpty) {
        spotPerMetal[metal] = (price: local.first.price, isLocal: true);
      }
    }

    final currentGsr =
        gsrHistory.isNotEmpty ? gsrHistory.first.gsr : null;

    // Market timing signals — most recent per metal from summary providers
    Map<String, double?> marketPremiumByMetal = {};
    for (final e in premiumSummary) {
      marketPremiumByMetal[e.metalType] = e.premiumPct;
    }
    Map<String, double?> marketSpreadByMetal = {};
    for (final e in spreadSummary) {
      marketSpreadByMetal[e.metalType] = e.spreadPct;
    }

    final listingsRepo = ref.read(productListingsRepositoryProvider);
    final livePricesRepo = ref.read(livePricesRepositoryProvider);

    final recommendations = <InvestmentRecommendation>[];

    for (final listing in listings) {
      // Budget filter — exclude listings above budget
      if (listing.listingSellPrice > budget) continue;

      final profile = listing.productProfileId != null
          ? profileMap[listing.productProfileId]
          : null;

      final metalType = profile?.metalType.toLowerCase();

      // Metal type filter
      if (metalFilter != null &&
          metalFilter.isNotEmpty &&
          metalType != metalFilter) continue;

      final spotData = metalType != null ? spotPerMetal[metalType] : null;

      // Fetch price history and live price row concurrently
      final priceHistoryFuture = listingsRepo.getListingPriceHistory(
        retailerId: listing.retailerId,
        listingName: listing.listingName,
        dayCount: 30,
      );

      final livePriceRowFuture = (profile != null)
          ? livePricesRepo.getLatestLivePriceForProfile(
              listing.retailerId, profile.id)
          : Future.value(null);

      final pair = await Future.wait([priceHistoryFuture, livePriceRowFuture]);
      final priceHistory =
          pair[0] as List<({DateTime date, double price})>;
      final livePriceRow = pair[1] as Map<String, dynamic>?;

      final rec = InvestmentGuideScorer.score(
        listing: listing,
        profile: profile,
        spotPerOz: spotData?.price,
        isLocalSpot: spotData?.isLocal ?? false,
        livePriceRow: livePriceRow,
        priceHistory: priceHistory,
        marketPremiumPct:
            metalType != null ? marketPremiumByMetal[metalType] : null,
        marketSpreadPct:
            metalType != null ? marketSpreadByMetal[metalType] : null,
        currentGsr: currentGsr,
        settings: settings,
      );

      recommendations.add(rec);
    }

    // Sort: available listings by score desc, out-of-stock pushed to end
    recommendations.sort((a, b) {
      final aOos = !a.isAvailable;
      final bOos = !b.isAvailable;
      if (aOos != bOos) return aOos ? 1 : -1;
      return b.compositeScore.compareTo(a.compositeScore);
    });

    return recommendations;
  }
}
