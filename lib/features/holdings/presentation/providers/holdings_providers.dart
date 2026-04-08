import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/features/holdings/data/models/holding_model.dart';
import 'package:metal_tracker/features/product_profiles/data/models/product_profile_model.dart';
import 'package:metal_tracker/features/live_prices/data/models/live_price_model.dart';
import 'package:metal_tracker/core/constants/app_constants.dart';
import 'package:metal_tracker/core/utils/weight_converter.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';

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

class PortfolioMovement {
  final double changePct;
  PortfolioMovement({required this.changePct});
  bool get isUp => changePct >= 0;
}

class SoldPortfolioSummary {
  final int count;
  final double totalCost;
  final double totalRevenue;
  final double totalProfit;
  final double totalProfitPercent;

  SoldPortfolioSummary({
    required this.count,
    required this.totalCost,
    required this.totalRevenue,
    required this.totalProfit,
    required this.totalProfitPercent,
  });
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
  final livePriceRepo = ref.watch(livePricesRepositoryProvider);

  final profileMap = {for (var p in profiles) p.id: p};

  double totalCurrent = 0;
  double totalCost = 0;
  final breakdown = <MetalType, MetalValuation>{};

  for (final metalType in MetalType.values) {
    final metalHoldings = holdings.where((h) {
      final p = profileMap[h.productProfileId];
      return p != null && p.metalTypeEnum == metalType;
    }).toList();

    if (metalHoldings.isEmpty) continue;

    final bestPriceData =
        await livePriceRepo.getBestBuybackPrice(metalType.displayName);
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
// PORTFOLIO MOVEMENT
// ==========================================

final portfolioMovementProvider =
    FutureProvider<PortfolioMovement?>((ref) async {
  final livePrices = await ref.watch(livePricesProvider.future);
  if (livePrices.isEmpty) return null;

  final holdings = await ref.watch(holdingsProvider.future);
  final profiles = await ref.watch(productProfilesProvider.future);
  if (holdings.isEmpty) return null;

  final profileMap = {for (var p in profiles) p.id: p};

  final dates = livePrices
      .map((p) => DateTime(
          p.captureDate.year, p.captureDate.month, p.captureDate.day))
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a));

  if (dates.length < 2) return null;

  double _valueAtDate(DateTime date, String metalType) {
    double? bestBuyback;
    for (final lp in livePrices) {
      final d = DateTime(
          lp.captureDate.year, lp.captureDate.month, lp.captureDate.day);
      if (d != date) continue;
      if (lp.buybackPrice == null) continue;
      if (lp.productProfileId == null) continue;
      final matching = profiles.where((p) => p.id == lp.productProfileId);
      if (matching.isEmpty) continue;
      final profile = matching.first;
      if (profile.metalType.toLowerCase() != metalType) {
        continue;
      }
      final norm = WeightCalculations.pricePerPureOunce(
        totalPrice: lp.buybackPrice!,
        weight: profile.weight,
        unit: profile.weightUnitEnum,
        purity: profile.purity,
      );
      if (bestBuyback == null || norm > bestBuyback) bestBuyback = norm;
    }
    return bestBuyback ?? 0;
  }

  double _portfolioValue(DateTime date) {
    double total = 0;
    for (final holding in holdings) {
      final profile = profileMap[holding.productProfileId];
      if (profile == null) continue;
      final metalType = profile.metalType.toLowerCase();
      final pricePerOz = _valueAtDate(date, metalType);
      if (pricePerOz == 0) {
        total += holding.purchasePrice;
      } else {
        total += WeightCalculations.holdingValue(
          weight: profile.weight,
          unit: profile.weightUnitEnum,
          purity: profile.purity,
          currentPricePerPureOz: pricePerOz,
        );
      }
    }
    return total;
  }

  final currentVal = _portfolioValue(dates[0]);
  final prevVal = _portfolioValue(dates[1]);
  if (prevVal == 0) return null;

  final changePct = ((currentVal - prevVal) / prevVal) * 100;
  return PortfolioMovement(changePct: changePct);
});

// ==========================================
// SOLD PORTFOLIO SUMMARY
// ==========================================

final soldPortfolioSummaryProvider =
    FutureProvider<SoldPortfolioSummary>((ref) async {
  final holdings = await ref.watch(soldHoldingsProvider.future);
  double totalCost = 0;
  double totalRevenue = 0;

  for (final h in holdings) {
    totalCost += h.purchasePrice;
    totalRevenue += h.soldPrice ?? h.purchasePrice;
  }

  final profit = totalRevenue - totalCost;
  final profitPct = totalCost > 0 ? (profit / totalCost) * 100 : 0.0;

  return SoldPortfolioSummary(
    count: holdings.length,
    totalCost: totalCost,
    totalRevenue: totalRevenue,
    totalProfit: profit,
    totalProfitPercent: profitPct,
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
