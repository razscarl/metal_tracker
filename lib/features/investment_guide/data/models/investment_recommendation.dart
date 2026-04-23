import 'package:metal_tracker/features/product_listings/data/models/product_listing_model.dart';
import 'package:metal_tracker/features/product_profiles/data/models/product_profile_model.dart';

enum ListingFlag {
  noProfile,
  noSpotPrice,
  localSpotOnly,
  noBuybackData,
  insufficientHistory,
  noTimingData,
  priceRecentlyJumped,
  staleData,
  outOfStock,
}

extension ListingFlagLabel on ListingFlag {
  String get label => switch (this) {
        ListingFlag.noProfile => 'No profile mapped',
        ListingFlag.noSpotPrice => 'No spot price',
        ListingFlag.localSpotOnly => 'Local spot only',
        ListingFlag.noBuybackData => 'No buyback data',
        ListingFlag.insufficientHistory => 'Limited history',
        ListingFlag.noTimingData => 'No timing data',
        ListingFlag.priceRecentlyJumped => 'Price jumped recently',
        ListingFlag.staleData => 'Data may be stale',
        ListingFlag.outOfStock => 'Out of stock',
      };

  String get detail => switch (this) {
        ListingFlag.noProfile =>
          'No product profile linked — \$/oz and spread cannot be computed.',
        ListingFlag.noSpotPrice =>
          'No spot price available for this metal — premium cannot be computed.',
        ListingFlag.localSpotOnly =>
          'Using local scraper spot price as fallback (less accurate than global API).',
        ListingFlag.noBuybackData =>
          'No buyback price on record for this retailer and profile.',
        ListingFlag.insufficientHistory =>
          'Fewer than 3 historical price points — trend score is neutral.',
        ListingFlag.noTimingData =>
          'Market timing signals (GSR, premium, spread) are unavailable.',
        ListingFlag.priceRecentlyJumped =>
          'Price has risen more than 5% in the last 7 days.',
        ListingFlag.staleData =>
          'Price data is more than 3 days old — current price may differ.',
        ListingFlag.outOfStock => 'This product is currently out of stock.',
      };

  bool get isHigh => this == ListingFlag.noProfile ||
      this == ListingFlag.noSpotPrice ||
      this == ListingFlag.outOfStock;

  bool get isMedium => this == ListingFlag.priceRecentlyJumped ||
      this == ListingFlag.staleData ||
      this == ListingFlag.localSpotOnly;
}

class ScoreBreakdown {
  final double? premiumScore;
  final double? spreadScore;
  final double? trendScore;
  final double? timingScore;
  final double compositeScore;

  // Detail values shown in the breakdown sheet
  final double? premiumPct;
  final double? listingPricePerOz;
  final double? spotPricePerOz;
  final double? spreadPct;
  final double? trendSlopeNormalized;
  final double? gsrValue;
  final double? localPremiumPct;
  final double? marketSpreadPct;

  const ScoreBreakdown({
    this.premiumScore,
    this.spreadScore,
    this.trendScore,
    this.timingScore,
    required this.compositeScore,
    this.premiumPct,
    this.listingPricePerOz,
    this.spotPricePerOz,
    this.spreadPct,
    this.trendSlopeNormalized,
    this.gsrValue,
    this.localPremiumPct,
    this.marketSpreadPct,
  });
}

class InvestmentRecommendation {
  final ProductListing listing;
  final ProductProfile? profile;
  final double compositeScore;
  final ScoreBreakdown breakdown;
  final List<ListingFlag> flags;

  const InvestmentRecommendation({
    required this.listing,
    this.profile,
    required this.compositeScore,
    required this.breakdown,
    required this.flags,
  });

  bool get isAvailable => listing.availability == 'available';
  bool get hasProfile => profile != null;

  String get rankLabel {
    if (compositeScore >= 75) return 'Strong Buy';
    if (compositeScore >= 55) return 'Good Value';
    if (compositeScore >= 35) return 'Neutral';
    return 'Caution';
  }
}
