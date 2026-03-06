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
