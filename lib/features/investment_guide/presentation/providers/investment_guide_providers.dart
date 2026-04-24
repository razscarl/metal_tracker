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
    final results = await Future.wait([
      ref.read(productListingsRepositoryProvider).getLatestListings(),
      ref.read(productProfilesNotifierProvider.future),
      ref.read(spotPricesNotifierProvider.future),           // global fallback
      ref.read(userAnalyticsSettingsNotifierProvider.future),
      ref.read(gsrHistoryProvider.future),
      ref.read(localPremiumSummaryProvider.future),          // local spot + timing
      ref.read(localSpreadSummaryProvider.future),
    ]);

    final listings = results[0] as List;
    final profiles = results[1] as List<ProductProfile>;
    final spots = results[2] as List<SpotPrice>;
    final settings = results[3] as UserAnalyticsSettings;
    final gsrHistory = results[4] as List<GsrDataPoint>;
    final premiumSummary = results[5] as List<LocalPremiumEntry>;
    final spreadSummary = results[6] as List<LocalSpreadEntry>;

    final profileMap = {for (final p in profiles) p.id: p};

    // Build spot price map per metal.
    // Primary:  localPremiumSummary.bestLocalSpot  (best local scraper price)
    // Fallback: latest global_api from spot_prices table
    final spotPerMetal = <String, ({double price, bool isLocal})>{};
    final premiumByMetal = <String, LocalPremiumEntry>{
      for (final e in premiumSummary) e.metalType: e,
    };

    for (final metal in ['gold', 'silver', 'platinum']) {
      final localEntry = premiumByMetal[metal];
      if (localEntry != null) {
        spotPerMetal[metal] =
            (price: localEntry.bestLocalSpot, isLocal: true);
        continue;
      }
      // No local spot — fall back to global API
      final global = spots
          .where((s) =>
              s.metalType.toLowerCase() == metal &&
              s.sourceType == 'global_api' &&
              s.status == 'success')
          .toList()
        ..sort((a, b) => b.fetchTimestamp.compareTo(a.fetchTimestamp));
      if (global.isNotEmpty) {
        spotPerMetal[metal] = (price: global.first.price, isLocal: false);
      }
    }

    final currentGsr = gsrHistory.isNotEmpty ? gsrHistory.first.gsr : null;

    final marketPremiumByMetal = <String, double?>{
      for (final e in premiumSummary) e.metalType: e.premiumPct,
    };
    final marketSpreadByMetal = <String, double?>{
      for (final e in spreadSummary) e.metalType: e.spreadPct,
    };

    final listingsRepo = ref.read(productListingsRepositoryProvider);
    final livePricesRepo = ref.read(livePricesRepositoryProvider);

    // Pre-fetch best market buyback per metal for spread fallback
    final buybackFetch = await Future.wait<Map<String, dynamic>?>([
      livePricesRepo.getBestBuybackPrice('gold'),
      livePricesRepo.getBestBuybackPrice('silver'),
      livePricesRepo.getBestBuybackPrice('platinum'),
    ]);
    final bestBuybackPerOz = <String, double?>{
      'gold': buybackFetch[0]?['pricePerOz'] as double?,
      'silver': buybackFetch[1]?['pricePerOz'] as double?,
      'platinum': buybackFetch[2]?['pricePerOz'] as double?,
    };

    final recommendations = <InvestmentRecommendation>[];

    for (final listing in listings) {
      if (listing.listingSellPrice > budget) continue;

      final profile = listing.productProfileId != null
          ? profileMap[listing.productProfileId]
          : null;
      final metalType = profile?.metalType.toLowerCase();

      if (metalFilter != null &&
          metalFilter.isNotEmpty &&
          metalType != metalFilter) { continue; }

      final spotData = metalType != null ? spotPerMetal[metalType] : null;

      final priceHistory = await listingsRepo.getListingPriceHistory(
        retailerId: listing.retailerId,
        listingName: listing.listingName,
        dayCount: 30,
      );

      recommendations.add(InvestmentGuideScorer.score(
        listing: listing,
        profile: profile,
        spotPerOz: spotData?.price,
        isLocalSpot: spotData?.isLocal ?? false,
        fallbackBuybackPerOz: metalType != null ? bestBuybackPerOz[metalType] : null,
        priceHistory: priceHistory,
        marketPremiumPct:
            metalType != null ? marketPremiumByMetal[metalType] : null,
        marketSpreadPct:
            metalType != null ? marketSpreadByMetal[metalType] : null,
        currentGsr: currentGsr,
        settings: settings,
      ));
    }

    recommendations.sort((a, b) {
      final aOos = !a.isAvailable;
      final bOos = !b.isAvailable;
      if (aOos != bOos) return aOos ? 1 : -1;
      return b.compositeScore.compareTo(a.compositeScore);
    });

    return recommendations;
  }
}
