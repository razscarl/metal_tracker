import 'package:metal_tracker/core/utils/weight_converter.dart';
import 'package:metal_tracker/features/investment_guide/data/models/investment_recommendation.dart';
import 'package:metal_tracker/features/product_listings/data/models/product_listing_model.dart';
import 'package:metal_tracker/features/product_profiles/data/models/product_profile_model.dart';
import 'package:metal_tracker/features/settings/data/models/user_analytics_settings_model.dart';

class InvestmentGuideScorer {
  InvestmentGuideScorer._();

  /// Scores a single listing against current market data.
  ///
  /// [priceHistory] must be newest-first raw AUD sell prices.
  /// [livePriceRow] is the most recent `live_prices` row for (retailer, profile).
  /// [spotPerOz] is the current global (preferred) or local spot in AUD/oz.
  /// [marketPremiumPct] and [marketSpreadPct] are the market-wide timing signals
  ///   from `localPremiumSummaryProvider` and `localSpreadSummaryProvider`.
  /// [currentGsr] is the latest gold/silver ratio from `gsrHistoryProvider`.
  static InvestmentRecommendation score({
    required ProductListing listing,
    required ProductProfile? profile,
    required double? spotPerOz,
    required bool isLocalSpot,
    required Map<String, dynamic>? livePriceRow,
    required List<({DateTime date, double price})> priceHistory,
    required double? marketPremiumPct,
    required double? marketSpreadPct,
    required double? currentGsr,
    required UserAnalyticsSettings settings,
  }) {
    final flags = <ListingFlag>[];
    final metalType = profile?.metalType.toLowerCase();

    double? listingPerOz;
    if (profile != null) {
      listingPerOz = WeightCalculations.pricePerPureOunce(
        totalPrice: listing.listingSellPrice,
        weight: profile.weight,
        unit: profile.weightUnitEnum,
        purity: profile.purity,
      );
    }

    final ageDays = DateTime.now().difference(listing.scrapeDate).inDays;
    if (ageDays > 3) flags.add(ListingFlag.staleData);
    if (listing.availability != 'available') flags.add(ListingFlag.outOfStock);

    // ── Component 1: Premium over spot (40 pts) ────────────────────────────

    double? premiumScore;
    double? premiumPct;

    if (profile == null) {
      flags.add(ListingFlag.noProfile);
    } else if (spotPerOz == null) {
      flags.add(ListingFlag.noSpotPrice);
    } else {
      if (isLocalSpot) flags.add(ListingFlag.localSpotOnly);
      premiumPct = (listingPerOz! - spotPerOz) / spotPerOz * 100;
      premiumScore = _linearScore(
        premiumPct,
        _premiumFloor(metalType ?? '', settings),
        _premiumCeiling(metalType ?? '', settings),
      );
    }

    // ── Component 2: Sell/Buyback spread (25 pts) ──────────────────────────

    double? spreadScore;
    double? spreadPct;

    if (profile != null && livePriceRow != null) {
      final sellRaw = (livePriceRow['sell_price'] as num?)?.toDouble();
      final buyRaw = (livePriceRow['buyback_price'] as num?)?.toDouble();

      if (sellRaw != null && buyRaw != null && sellRaw > 0) {
        final sellPerOz = WeightCalculations.pricePerPureOunce(
          totalPrice: sellRaw,
          weight: profile.weight,
          unit: profile.weightUnitEnum,
          purity: profile.purity,
        );
        final buyPerOz = WeightCalculations.pricePerPureOunce(
          totalPrice: buyRaw,
          weight: profile.weight,
          unit: profile.weightUnitEnum,
          purity: profile.purity,
        );
        spreadPct = (sellPerOz - buyPerOz) / sellPerOz * 100;

        final buyT = _spreadBuy(metalType ?? '', settings);
        final avoidT = _spreadAvoid(metalType ?? '', settings);
        if (avoidT > buyT) {
          spreadScore =
              ((avoidT - spreadPct) / (avoidT - buyT) * 100).clamp(0.0, 100.0);
        }
      } else {
        flags.add(ListingFlag.noBuybackData);
        spreadScore = 50.0;
      }
    } else if (profile != null) {
      flags.add(ListingFlag.noBuybackData);
      spreadScore = 50.0;
    }

    // ── Component 3: Price trend (20 pts) ─────────────────────────────────

    double? trendScore;
    double? trendSlopeNormalized;

    if (priceHistory.length < 3) {
      if (priceHistory.isNotEmpty) flags.add(ListingFlag.insufficientHistory);
      trendScore = priceHistory.isEmpty ? null : 50.0;
    } else {
      final slope = _linearRegressionSlope(priceHistory);
      final mean = priceHistory.map((e) => e.price).reduce((a, b) => a + b) /
          priceHistory.length;
      trendSlopeNormalized = mean > 0 ? (slope / mean * 100) : 0.0;

      // 100 pts at ≤ −0.1%/day, 70 pts at 0%/day, 0 pts at ≥ +0.3%/day
      trendScore = switch (true) {
        _ when trendSlopeNormalized <= -0.1 => 100.0,
        _ when trendSlopeNormalized <= 0.0 =>
          70.0 + ((-trendSlopeNormalized) / 0.1) * 30.0,
        _ => (70.0 - (trendSlopeNormalized / 0.3) * 70.0).clamp(0.0, 70.0),
      };

      // Flag if most-recent price > 7-day-ago price × 1.05
      final recent = priceHistory.first.price;
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final baseline = priceHistory
          .where((e) => e.date.isBefore(sevenDaysAgo))
          .firstOrNull;
      if (baseline != null && recent > baseline.price * 1.05) {
        flags.add(ListingFlag.priceRecentlyJumped);
      }
    }

    // ── Component 4: Market timing (15 pts) ───────────────────────────────

    double? timingScore;

    if (metalType != null &&
        marketPremiumPct != null &&
        marketSpreadPct != null) {
      final gsrSignal = _gsrSignal(metalType, currentGsr, settings);
      final premiumSignal = marketPremiumPct <= settings.lpLowMark ? 1.0 : 0.0;
      final spreadSignal =
          marketSpreadPct <= _spreadBuy(metalType, settings) ? 1.0 : 0.0;

      // Platinum has no GSR signal — max denominator is 2 instead of 3
      final maxSignals = metalType == 'platinum' ? 2.0 : 3.0;
      timingScore =
          ((gsrSignal + premiumSignal + spreadSignal) / maxSignals) * 100;
    } else if (metalType != null) {
      flags.add(ListingFlag.noTimingData);
    }

    // ── Composite (renormalized over present components) ───────────────────

    final components = [
      if (premiumScore != null) (score: premiumScore, weight: 40.0),
      if (spreadScore != null) (score: spreadScore, weight: 25.0),
      if (trendScore != null) (score: trendScore, weight: 20.0),
      if (timingScore != null) (score: timingScore, weight: 15.0),
    ];

    final composite = components.isEmpty
        ? 50.0
        : components.fold(0.0, (acc, c) => acc + c.score * c.weight) /
            components.fold(0.0, (acc, c) => acc + c.weight);

    return InvestmentRecommendation(
      listing: listing,
      profile: profile,
      compositeScore: composite,
      breakdown: ScoreBreakdown(
        premiumScore: premiumScore,
        spreadScore: spreadScore,
        trendScore: trendScore,
        timingScore: timingScore,
        compositeScore: composite,
        premiumPct: premiumPct,
        listingPricePerOz: listingPerOz,
        spotPricePerOz: spotPerOz,
        spreadPct: spreadPct,
        trendSlopeNormalized: trendSlopeNormalized,
        gsrValue: currentGsr,
        localPremiumPct: marketPremiumPct,
        marketSpreadPct: marketSpreadPct,
      ),
      flags: flags,
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static double _premiumFloor(String metal, UserAnalyticsSettings s) =>
      switch (metal) {
        'gold' => s.premiumGoldLowPct,
        'silver' => s.premiumSilverLowPct,
        'platinum' => s.premiumPlatLowPct,
        _ => s.premiumGoldLowPct,
      };

  static double _premiumCeiling(String metal, UserAnalyticsSettings s) =>
      switch (metal) {
        'gold' => s.premiumGoldHighPct,
        'silver' => s.premiumSilverHighPct,
        'platinum' => s.premiumPlatHighPct,
        _ => s.premiumGoldHighPct,
      };

  static double _spreadBuy(String metal, UserAnalyticsSettings s) =>
      switch (metal) {
        'gold' => s.spreadGoldBuyPct,
        'silver' => s.spreadSilverBuyPct,
        'platinum' => s.spreadPlatBuyPct,
        _ => s.spreadGoldBuyPct,
      };

  static double _spreadAvoid(String metal, UserAnalyticsSettings s) =>
      switch (metal) {
        'gold' => s.spreadGoldHoldPct,
        'silver' => s.spreadSilverHoldPct,
        'platinum' => s.spreadPlatHoldPct,
        _ => s.spreadGoldHoldPct,
      };

  static double _gsrSignal(
      String metal, double? gsr, UserAnalyticsSettings s) {
    if (gsr == null) return 0.0;
    if (metal == 'gold') return gsr <= s.gsrLowMark ? 1.0 : 0.0;
    if (metal == 'silver') return gsr >= s.gsrHighMark ? 1.0 : 0.0;
    return 0.0;
  }

  /// Linear score: 100 at ≤ [floor], 0 at ≥ [ceiling].
  static double _linearScore(double value, double floor, double ceiling) {
    if (value <= floor) return 100.0;
    if (value >= ceiling) return 0.0;
    return (ceiling - value) / (ceiling - floor) * 100;
  }

  /// OLS slope over (day-index, price) pairs. History is newest-first.
  static double _linearRegressionSlope(
      List<({DateTime date, double price})> history) {
    final data = history.reversed.toList();
    final n = data.length.toDouble();
    final base = data.first.date;

    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (final p in data) {
      final x = p.date.difference(base).inDays.toDouble();
      final y = p.price;
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    final denom = n * sumX2 - sumX * sumX;
    return denom == 0 ? 0 : (n * sumXY - sumX * sumY) / denom;
  }
}
