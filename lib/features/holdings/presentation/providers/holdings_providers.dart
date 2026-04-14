import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/features/holdings/data/models/holding_model.dart';
import 'package:metal_tracker/features/product_profiles/data/models/product_profile_model.dart';
import 'package:metal_tracker/features/live_prices/data/models/live_price_model.dart';
import 'package:metal_tracker/core/constants/app_constants.dart';
import 'package:metal_tracker/core/utils/weight_converter.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/features/live_prices/presentation/providers/live_prices_providers.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_prefs_providers.dart';

// ==========================================
// MODELS
// ==========================================

class MetalValuation {
  final MetalType metalType;
  final double currentValue;
  final double purchaseCost;
  final double gainLoss;
  final double gainLossPercent;
  final double? bestPricePerOz;
  final String? bestRetailerName;
  final int holdingsCount;

  MetalValuation({
    required this.metalType,
    required this.currentValue,
    required this.purchaseCost,
    required this.gainLoss,
    required this.gainLossPercent,
    this.bestPricePerOz,
    this.bestRetailerName,
    required this.holdingsCount,
  });
}

/// Change in portfolio value between the two most recent live-price captures.
class PortfolioMovement {
  final double totalDelta;
  final double totalPct;
  /// Per-metal delta/pct, only present when previous prices exist for that metal.
  final Map<MetalType, ({double delta, double pct})> byMetal;

  const PortfolioMovement({
    required this.totalDelta,
    required this.totalPct,
    required this.byMetal,
  });

  bool get isUp => totalDelta >= 0;
}

class PortfolioValuation {
  final double totalCurrentValue;
  final double totalPurchaseCost;
  final double totalGainLoss;
  final double totalGainLossPercent;
  final Map<MetalType, MetalValuation> metalBreakdown;

  PortfolioValuation({
    required this.totalCurrentValue,
    required this.totalPurchaseCost,
    required this.totalGainLoss,
    required this.totalGainLossPercent,
    required this.metalBreakdown,
  });

  bool get hasAllPrices =>
      metalBreakdown.values.every((m) => m.bestPricePerOz != null);

  List<MetalType> get missingPrices => metalBreakdown.entries
      .where((e) => e.value.bestPricePerOz == null)
      .map((e) => e.key)
      .toList();
}

// ==========================================
// ACTION NOTIFIER
// ==========================================

// A sentinel type used in place of void for generic type arguments,
// since Dart does not allow void as a type argument in all contexts.
class _VoidResult {}

class HoldingsActionNotifier<T> extends StateNotifier<AsyncValue<T?>> {
  final Future<T> Function(dynamic data) action;
  final VoidCallback? onSuccess;

  HoldingsActionNotifier(this.action, {this.onSuccess})
      : super(const AsyncValue.data(null));

  Future<void> run(dynamic data) async {
    state = const AsyncValue.loading();
    try {
      final result = await action(data);
      state = AsyncValue.data(result);
      if (onSuccess != null) onSuccess!();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ==========================================
// DATA FETCHING PROVIDERS
// ==========================================

final holdingsProvider = FutureProvider<List<Holding>>((ref) {
  return ref.watch(holdingsRepositoryProvider).getHoldings();
});

final soldHoldingsProvider = FutureProvider<List<Holding>>((ref) {
  return ref.watch(holdingsRepositoryProvider).getSoldHoldings();
});

final productProfilesProvider = FutureProvider<List<ProductProfile>>((ref) {
  return ref.watch(productProfilesRepositoryProvider).getProductProfiles();
});

final livePricesProvider = FutureProvider<List<LivePrice>>((ref) {
  return ref.watch(livePricesRepositoryProvider).getLivePrices();
});

// ==========================================
// PORTFOLIO VALUATION PROVIDER
// ==========================================

final portfolioValuationProvider =
    FutureProvider<PortfolioValuation>((ref) async {
  final holdings = await ref.watch(holdingsProvider.future);
  final profiles = await ref.watch(productProfilesProvider.future);
  // Reactive dependency — rebuilds when live prices change (scrape/add/edit/delete)
  final allLivePrices = await ref.watch(livePricesNotifierProvider.future);

  final profileMap = {for (var p in profiles) p.id: p};

  // Resolve preferred retailer IDs for filtering (empty = no filter = all retailers)
  final userRetailers = ref.watch(userRetailersNotifierProvider).valueOrNull ?? [];
  final prefRetailerIds = userRetailers.isEmpty
      ? null
      : userRetailers.map((r) => r.retailerId).toSet();

  // Filter live prices by preferred retailers (if set) and keep only mapped prices
  final candidatePrices = allLivePrices.where((lp) {
    if (lp.buybackPrice == null) return false;
    if (lp.productProfileId == null) return false;
    if (prefRetailerIds != null && !prefRetailerIds.contains(lp.retailerId)) {
      return false;
    }
    return true;
  }).toList();

  // Helper: compute best in-memory buyback for a metal type.
  // Uses same per-retailer-latest algorithm as live_prices_repository._getBestPrice():
  //   1. Per-retailer max captureTimestamp
  //   2. Most recent captureDate across those
  //   3. Exclude retailers whose max timestamp isn't on that date
  //   4. Among included retailers, only use records at their max timestamp
  // Returns {pricePerOz: double, retailerName: String?, retailerAbbr: String?}
  Map<String, dynamic>? bestBuybackForMetal(MetalType metal) {
    final metalPrices = candidatePrices.where((lp) {
      final profile = profileMap[lp.productProfileId];
      return profile != null && profile.metalTypeEnum == metal;
    }).toList();

    if (metalPrices.isEmpty) return null;

    // Step 1: Per-retailer max captureTimestamp
    final retailerMaxTs = <String, DateTime>{};
    for (final lp in metalPrices) {
      final existing = retailerMaxTs[lp.retailerId];
      if (existing == null || lp.captureTimestamp.isAfter(existing)) {
        retailerMaxTs[lp.retailerId] = lp.captureTimestamp;
      }
    }

    // Step 2: Most recent captureDate across all retailers' max timestamps
    DateTime? latestDate;
    for (final ts in retailerMaxTs.values) {
      final d = DateTime(ts.year, ts.month, ts.day);
      if (latestDate == null || d.isAfter(latestDate)) latestDate = d;
    }
    if (latestDate == null) return null;

    // Step 3: Exclude retailers whose max timestamp is not on that date
    final includedRetailers = retailerMaxTs.entries.where((e) {
      final d = DateTime(e.value.year, e.value.month, e.value.day);
      return d == latestDate;
    }).map((e) => e.key).toSet();

    // Step 4: Best price among records at each included retailer's max timestamp
    double? bestVal;
    String? bestRetailer;
    String? bestRetailerAbbr;

    for (final lp in metalPrices) {
      if (!includedRetailers.contains(lp.retailerId)) continue;
      if (lp.captureTimestamp != retailerMaxTs[lp.retailerId]) continue;

      final profile = profileMap[lp.productProfileId]!;
      final pricePerOz = WeightCalculations.pricePerPureOunce(
        totalPrice: lp.buybackPrice!,
        weight: profile.weight,
        unit: profile.weightUnitEnum,
        purity: profile.purity,
      );

      if (bestVal == null || pricePerOz > bestVal) {
        bestVal = pricePerOz;
        bestRetailer = lp.retailerName;
        bestRetailerAbbr = lp.retailerAbbr;
      }
    }

    if (bestVal == null) return null;
    return {
      'pricePerOz': bestVal,
      'retailerName': bestRetailer,
      'retailerAbbr': bestRetailerAbbr,
    };
  }

  double totalCurrent = 0;
  double totalCost = 0;
  final breakdown = <MetalType, MetalValuation>{};

  for (final metalType in MetalType.values) {
    final metalHoldings = holdings.where((h) {
      final p = profileMap[h.productProfileId];
      return p != null && p.metalTypeEnum == metalType;
    }).toList();

    if (metalHoldings.isEmpty) continue;

    final bestPriceData = bestBuybackForMetal(metalType);
    double mCurrentVal = 0;
    double mCostVal = 0;

    for (final holding in metalHoldings) {
      final profile = profileMap[holding.productProfileId]!;
      mCostVal += holding.purchasePrice;

      if (bestPriceData != null) {
        mCurrentVal += WeightCalculations.holdingValue(
          weight: profile.weight,
          unit: profile.weightUnitEnum,
          purity: profile.purity,
          currentPricePerPureOz: bestPriceData['pricePerOz'],
        );
      } else {
        mCurrentVal += holding.purchasePrice;
      }
    }

    breakdown[metalType] = MetalValuation(
      metalType: metalType,
      currentValue: mCurrentVal,
      purchaseCost: mCostVal,
      gainLoss: mCurrentVal - mCostVal,
      gainLossPercent:
          mCostVal > 0 ? ((mCurrentVal - mCostVal) / mCostVal) * 100 : 0,
      bestPricePerOz: bestPriceData?['pricePerOz'],
      bestRetailerName: bestPriceData?['retailerName'],
      holdingsCount: metalHoldings.length,
    );

    totalCurrent += mCurrentVal;
    totalCost += mCostVal;
  }

  return PortfolioValuation(
    totalCurrentValue: totalCurrent,
    totalPurchaseCost: totalCost,
    totalGainLoss: totalCurrent - totalCost,
    totalGainLossPercent:
        totalCost > 0 ? ((totalCurrent - totalCost) / totalCost) * 100 : 0,
    metalBreakdown: breakdown,
  );
});

// ==========================================
// PORTFOLIO MOVEMENT PROVIDER
// ==========================================

/// Compares portfolio value at the two most recent distinct capture dates
/// (per metal) to produce a movement indicator for the portfolio card.
final portfolioMovementProvider =
    FutureProvider<PortfolioMovement?>((ref) async {
  final holdings = await ref.watch(holdingsProvider.future);
  final profiles = await ref.watch(productProfilesProvider.future);
  // Reactive — rebuilds when live prices change
  final allPrices = await ref.watch(livePricesNotifierProvider.future);

  if (holdings.isEmpty || allPrices.isEmpty) return null;

  final profileMap = {for (final p in profiles) p.id: p};

  // Only prices with a buyback value and a mapped profile
  final mapped = allPrices
      .where((p) =>
          p.buybackPrice != null &&
          p.productProfileId != null &&
          profileMap.containsKey(p.productProfileId))
      .toList();

  if (mapped.isEmpty) return null;

  double totalCurrent = 0;
  double totalPrev = 0;
  bool anyPrev = false;
  final byMetal = <MetalType, ({double delta, double pct})>{};

  for (final metalType in MetalType.values) {
    final metalHoldings = holdings
        .where((h) =>
            profileMap[h.productProfileId]?.metalTypeEnum == metalType)
        .toList();
    if (metalHoldings.isEmpty) continue;

    final metalPrices = mapped
        .where((p) =>
            profileMap[p.productProfileId]!.metalTypeEnum == metalType)
        .toList()
      ..sort((a, b) => b.captureTimestamp.compareTo(a.captureTimestamp));

    if (metalPrices.isEmpty) continue;

    // Two most recent distinct dates for this metal
    final dates = metalPrices
        .map((p) => DateTime(
            p.captureTimestamp.year,
            p.captureTimestamp.month,
            p.captureTimestamp.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final currentDate = dates[0];
    final prevDate = dates.length >= 2 ? dates[1] : null;

    // Best buyback price/oz on each date
    double? currentBest;
    double? prevBest;

    for (final price in metalPrices) {
      final profile = profileMap[price.productProfileId]!;
      final d = DateTime(price.captureTimestamp.year,
          price.captureTimestamp.month, price.captureTimestamp.day);
      final pricePerOz = WeightCalculations.pricePerPureOunce(
        totalPrice: price.buybackPrice!,
        weight: profile.weight,
        unit: profile.weightUnitEnum,
        purity: profile.purity,
      );
      if (d == currentDate &&
          (currentBest == null || pricePerOz > currentBest)) {
        currentBest = pricePerOz;
      }
      if (prevDate != null &&
          d == prevDate &&
          (prevBest == null || pricePerOz > prevBest)) {
        prevBest = pricePerOz;
      }
    }

    if (currentBest == null) continue;

    double mCurrent = 0;
    double mPrev = 0;

    for (final holding in metalHoldings) {
      final profile = profileMap[holding.productProfileId]!;
      mCurrent += WeightCalculations.holdingValue(
        weight: profile.weight,
        unit: profile.weightUnitEnum,
        purity: profile.purity,
        currentPricePerPureOz: currentBest,
      );
      if (prevBest != null) {
        mPrev += WeightCalculations.holdingValue(
          weight: profile.weight,
          unit: profile.weightUnitEnum,
          purity: profile.purity,
          currentPricePerPureOz: prevBest,
        );
      }
    }

    totalCurrent += mCurrent;
    if (prevBest != null && mPrev > 0) {
      anyPrev = true;
      totalPrev += mPrev;
      final d = mCurrent - mPrev;
      byMetal[metalType] = (delta: d, pct: (d / mPrev) * 100);
    }
  }

  if (!anyPrev || totalPrev == 0) return null;

  final totalDelta = totalCurrent - totalPrev;
  return PortfolioMovement(
    totalDelta: totalDelta,
    totalPct: (totalDelta / totalPrev) * 100,
    byMetal: byMetal,
  );
});

// ==========================================
// SOLD PORTFOLIO SUMMARY PROVIDER
// ==========================================

class SoldPortfolioSummary {
  final double totalInvested;
  final double totalSaleValue;
  final double gainLoss;
  final double gainLossPct;
  final int count;

  const SoldPortfolioSummary({
    required this.totalInvested,
    required this.totalSaleValue,
    required this.gainLoss,
    required this.gainLossPct,
    required this.count,
  });
}

final soldPortfolioSummaryProvider =
    FutureProvider<SoldPortfolioSummary?>((ref) async {
  final holdings = await ref.watch(soldHoldingsProvider.future);
  if (holdings.isEmpty) return null;

  double totalInvested = 0;
  double totalSaleValue = 0;

  for (final h in holdings) {
    totalInvested += h.purchasePrice;
    if (h.soldPrice != null) {
      totalSaleValue += h.soldPrice!;
    }
  }

  final gainLoss = totalSaleValue - totalInvested;
  final gainLossPct =
      totalInvested == 0 ? 0.0 : (gainLoss / totalInvested) * 100;

  return SoldPortfolioSummary(
    totalInvested: totalInvested,
    totalSaleValue: totalSaleValue,
    gainLoss: gainLoss,
    gainLossPct: gainLossPct,
    count: holdings.length,
  );
});

// ==========================================
// ACTION PROVIDERS
// ==========================================

final createHoldingProvider = StateNotifierProvider<
    HoldingsActionNotifier<Holding>, AsyncValue<Holding?>>((ref) {
  return HoldingsActionNotifier<Holding>(
    (data) => ref.read(holdingsRepositoryProvider).createHolding(
          productName: data['productName'],
          productProfileId: data['productProfileId'],
          retailerId: data['retailerId'],
          purchaseDate: data['purchaseDate'],
          purchasePrice: data['purchasePrice'],
        ),
    onSuccess: () => ref.invalidate(holdingsProvider),
  );
});

final updateHoldingProvider = StateNotifierProvider<
    HoldingsActionNotifier<Holding>, AsyncValue<Holding?>>((ref) {
  return HoldingsActionNotifier<Holding>(
    (data) => ref.read(holdingsRepositoryProvider).updateHolding(
          id: data['id'],
          productName: data['productName'],
          purchaseDate: data['purchaseDate'],
          purchasePrice: data['purchasePrice'],
          retailerId: data['retailerId'],
          productProfileId: data['productProfileId'],
        ),
    onSuccess: () => ref.invalidate(holdingsProvider),
  );
});

final sellHoldingProvider = StateNotifierProvider<
    HoldingsActionNotifier<Holding>, AsyncValue<Holding?>>((ref) {
  return HoldingsActionNotifier<Holding>(
    (data) => ref.read(holdingsRepositoryProvider).sellHolding(
          id: data['id'],
          soldDate: data['soldDate'],
          soldPrice: data['soldPrice'],
        ),
    onSuccess: () {
      ref.invalidate(holdingsProvider);
      ref.invalidate(soldHoldingsProvider);
      ref.invalidate(portfolioValuationProvider);
    },
  );
});

// NOTE: void cannot be used as a generic type argument in Dart, so we use
// _VoidResult as a sentinel. Callers checking this provider's state can
// simply ignore the T? value and only inspect loading/error states.
final deleteHoldingProvider = StateNotifierProvider<
    HoldingsActionNotifier<_VoidResult>, AsyncValue<_VoidResult?>>((ref) {
  return HoldingsActionNotifier<_VoidResult>(
    (id) async {
      await ref.read(holdingsRepositoryProvider).deleteHolding(id.toString());
      return _VoidResult();
    },
    onSuccess: () => ref.invalidate(holdingsProvider),
  );
});
