// lib/features/analytics/presentation/providers/analytics_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:metal_tracker/core/constants/app_constants.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/core/utils/weight_converter.dart';
import 'package:metal_tracker/features/spot_prices/presentation/providers/spot_prices_providers.dart';
import 'package:metal_tracker/features/spot_prices/data/models/spot_price_model.dart';
import 'package:metal_tracker/features/settings/presentation/providers/settings_providers.dart';

part 'analytics_providers.g.dart';

// ─── Data Models ──────────────────────────────────────────────────────────────

class GsrDataPoint {
  final DateTime date;
  final double goldPrice;
  final double silverPrice;
  final double gsr;
  final bool? movementUp; // null = no prior day
  final String guide; // 'Buy Silver' | 'Buy Gold' | 'Hold / Other factors'

  const GsrDataPoint({
    required this.date,
    required this.goldPrice,
    required this.silverPrice,
    required this.gsr,
    required this.movementUp,
    required this.guide,
  });
}

class AnalyticsSummary {
  final double? currentGsr;
  final bool? movementUp;
  final String? currentGuide;
  final String goldGuide;
  final String silverGuide;
  final String platinumGuide;

  const AnalyticsSummary({
    required this.currentGsr,
    required this.movementUp,
    required this.currentGuide,
    required this.goldGuide,
    required this.silverGuide,
    required this.platinumGuide,
  });
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _computeGuide(double gsr, double lowMark, double highMark) {
  if (gsr >= highMark) return 'Buy Silver';
  if (gsr <= lowMark) return 'Buy Gold';
  return 'Hold / Other factors';
}

List<GsrDataPoint> _buildGsrHistory(
  List<SpotPrice> allPrices,
  double lowMark,
  double highMark,
) {
  final global = allPrices.where((p) => p.sourceType == 'global_api').toList();

  // day string -> metal -> latest SpotPrice
  final byDay = <String, Map<String, SpotPrice>>{};
  for (final p in global) {
    final dayKey =
        '${p.fetchDate.year}-${p.fetchDate.month}-${p.fetchDate.day}';
    final metal = p.metalType.toLowerCase();
    if (metal != 'gold' && metal != 'silver') continue;

    byDay.putIfAbsent(dayKey, () => {});
    final existing = byDay[dayKey]![metal];
    if (existing == null ||
        p.fetchTimestamp.isAfter(existing.fetchTimestamp)) {
      byDay[dayKey]![metal] = p;
    }
  }

  // Collect days that have both gold and silver
  final validDays = byDay.entries
      .where(
          (e) => e.value.containsKey('gold') && e.value.containsKey('silver'))
      .map((e) {
        final gold = e.value['gold']!;
        final silver = e.value['silver']!;
        return (
          date: gold.fetchDate,
          goldPrice: gold.price,
          silverPrice: silver.price,
          gsr: gold.price / silver.price,
        );
      })
      .toList();

  // Sort oldest-first to compute movement
  validDays.sort((a, b) => a.date.compareTo(b.date));

  final result = <GsrDataPoint>[];
  for (var i = 0; i < validDays.length; i++) {
    final day = validDays[i];
    bool? movementUp;
    if (i > 0) {
      final prevGsr = validDays[i - 1].gsr;
      if (day.gsr > prevGsr) {
        movementUp = true;
      } else if (day.gsr < prevGsr) {
        movementUp = false;
      }
    }
    result.add(GsrDataPoint(
      date: day.date,
      goldPrice: day.goldPrice,
      silverPrice: day.silverPrice,
      gsr: day.gsr,
      movementUp: movementUp,
      guide: _computeGuide(day.gsr, lowMark, highMark),
    ));
  }

  // Return newest-first
  return result.reversed.toList();
}

// ─── Local Premium Models ─────────────────────────────────────────────────────

class LocalPremiumEntry {
  final DateTime date;
  final String metalType;
  final double globalSpot;
  final double bestLocalSpot;
  final double premiumPct;
  final bool? movementUp;
  final String guide;

  const LocalPremiumEntry({
    required this.date,
    required this.metalType,
    required this.globalSpot,
    required this.bestLocalSpot,
    required this.premiumPct,
    required this.movementUp,
    required this.guide,
  });
}

String _premiumGuide(double pct) {
  if (pct >= 2.0) return 'Avoid buying';
  if (pct < 0.0) return 'Buy now';
  return 'Other factors';
}

List<LocalPremiumEntry> _buildLocalPremiumHistory(List<SpotPrice> allPrices) {
  // day|metal -> latest global price
  final globalByKey = <String, SpotPrice>{};
  // day|metal -> lowest local price (best deal for buyer)
  final localByKey = <String, SpotPrice>{};

  for (final p in allPrices) {
    final dayKey =
        '${p.fetchDate.year}-${p.fetchDate.month.toString().padLeft(2, '0')}-${p.fetchDate.day.toString().padLeft(2, '0')}';
    final key = '$dayKey|${p.metalType.toLowerCase()}';

    if (p.sourceType == 'global_api') {
      final existing = globalByKey[key];
      if (existing == null ||
          p.fetchTimestamp.isAfter(existing.fetchTimestamp)) {
        globalByKey[key] = p;
      }
    } else if (p.sourceType == 'local_scraper') {
      final existing = localByKey[key];
      if (existing == null || p.price < existing.price) {
        localByKey[key] = p;
      }
    }
  }

  // Build unsorted entries where both global and local exist
  final raw = <({DateTime date, String metal, double global, double local})>[];
  for (final key in globalByKey.keys) {
    if (!localByKey.containsKey(key)) continue;
    final g = globalByKey[key]!;
    final l = localByKey[key]!;
    raw.add((
      date: g.fetchDate,
      metal: g.metalType.toLowerCase(),
      global: g.price,
      local: l.price,
    ));
  }

  // Sort oldest-first so movement can be computed sequentially
  raw.sort((a, b) {
    final d = a.date.compareTo(b.date);
    return d != 0 ? d : a.metal.compareTo(b.metal);
  });

  final lastPremium = <String, double>{};
  final result = <LocalPremiumEntry>[];

  for (final e in raw) {
    final pct = (e.local - e.global) / e.global * 100;
    final prev = lastPremium[e.metal];
    bool? movementUp;
    if (prev != null) {
      if (pct > prev) movementUp = true;
      if (pct < prev) movementUp = false;
    }
    lastPremium[e.metal] = pct;

    result.add(LocalPremiumEntry(
      date: e.date,
      metalType: e.metal,
      globalSpot: e.global,
      bestLocalSpot: e.local,
      premiumPct: pct,
      movementUp: movementUp,
      guide: _premiumGuide(pct),
    ));
  }

  return result.reversed.toList(); // newest-first
}

// ─── Dealer Spread Models ─────────────────────────────────────────────────────

class DealerSpreadEntry {
  final DateTime date;
  final String metalType;
  final double bestSellPrice;
  final double bestBuybackPrice;
  final double spreadDollar;
  final double spreadPct;
  final bool? movementUp; // spread going wider = true (bad)
  final String guide;

  const DealerSpreadEntry({
    required this.date,
    required this.metalType,
    required this.bestSellPrice,
    required this.bestBuybackPrice,
    required this.spreadDollar,
    required this.spreadPct,
    required this.movementUp,
    required this.guide,
  });
}

String _spreadGuide(String metal, double pct) {
  switch (metal) {
    case 'gold':
      if (pct <= 2.0) return 'Buy';
      if (pct >= 5.0) return 'Hold';
      return 'Other factors';
    case 'silver':
      if (pct <= 10.0) return 'Buy';
      if (pct >= 20.0) return 'Hold';
      return 'Other factors';
    case 'platinum':
      if (pct <= 25.0) return 'Buy';
      if (pct >= 35.0) return 'Hold';
      return 'Other factors';
    default:
      return 'Other factors';
  }
}

List<DealerSpreadEntry> _buildSpreadHistory(
    List<Map<String, dynamic>> rawPrices) {
  // day|metal -> {bestSell, bestBuyback}
  final byKey = <String, ({double? bestSell, double? bestBuyback})>{};

  for (final row in rawPrices) {
    final profile = row['product_profiles'] as Map<String, dynamic>?;
    if (profile == null) continue;

    final metal = (profile['metal_type'] as String?)?.toLowerCase();
    if (metal == null) continue;

    final capDate = row['capture_date'] as String?;
    if (capDate == null) continue;

    final weight = (profile['weight'] as num?)?.toDouble();
    final unitStr = profile['weight_unit'] as String?;
    final purity = (profile['purity'] as num?)?.toDouble();
    if (weight == null || unitStr == null || purity == null) continue;

    final unit = WeightUnit.fromString(unitStr);

    final sellRaw = (row['sell_price'] as num?)?.toDouble();
    final buyRaw = (row['buyback_price'] as num?)?.toDouble();

    double? sellNorm;
    double? buyNorm;

    if (sellRaw != null) {
      sellNorm = WeightCalculations.pricePerPureOunce(
        totalPrice: sellRaw,
        weight: weight,
        unit: unit,
        purity: purity,
      );
    }
    if (buyRaw != null) {
      buyNorm = WeightCalculations.pricePerPureOunce(
        totalPrice: buyRaw,
        weight: weight,
        unit: unit,
        purity: purity,
      );
    }

    final key = '$capDate|$metal';
    final existing = byKey[key];

    final prevSell = existing?.bestSell;
    final prevBuy = existing?.bestBuyback;

    byKey[key] = (
      bestSell: (sellNorm != null && (prevSell == null || sellNorm < prevSell))
          ? sellNorm
          : prevSell,
      bestBuyback:
          (buyNorm != null && (prevBuy == null || buyNorm > prevBuy))
              ? buyNorm
              : prevBuy,
    );
  }

  // Build entries where both sell and buyback exist
  final raw = <({DateTime date, String metal, double sell, double buy})>[];
  for (final entry in byKey.entries) {
    final parts = entry.key.split('|');
    if (parts.length != 2) continue;
    final sell = entry.value.bestSell;
    final buy = entry.value.bestBuyback;
    if (sell == null || buy == null || sell <= 0) continue;
    raw.add((
      date: DateTime.parse(parts[0]),
      metal: parts[1],
      sell: sell,
      buy: buy,
    ));
  }

  // Sort oldest-first for movement computation
  raw.sort((a, b) {
    final d = a.date.compareTo(b.date);
    return d != 0 ? d : a.metal.compareTo(b.metal);
  });

  final lastSpread = <String, double>{};
  final result = <DealerSpreadEntry>[];

  for (final e in raw) {
    final spreadDollar = e.sell - e.buy;
    final spreadPct = spreadDollar / e.sell * 100;

    final prev = lastSpread[e.metal];
    bool? movementUp;
    if (prev != null) {
      if (spreadPct > prev) movementUp = true;
      if (spreadPct < prev) movementUp = false;
    }
    lastSpread[e.metal] = spreadPct;

    result.add(DealerSpreadEntry(
      date: e.date,
      metalType: e.metal,
      bestSellPrice: e.sell,
      bestBuybackPrice: e.buy,
      spreadDollar: spreadDollar,
      spreadPct: spreadPct,
      movementUp: movementUp,
      guide: _spreadGuide(e.metal, spreadPct),
    ));
  }

  return result.reversed.toList(); // newest-first
}

// ─── Providers ────────────────────────────────────────────────────────────────

@riverpod
Future<List<GsrDataPoint>> gsrHistory(GsrHistoryRef ref) async {
  final prices = await ref.watch(spotPricesNotifierProvider.future);
  final settings = await ref.watch(gsrSettingsNotifierProvider.future);
  return _buildGsrHistory(prices, settings.lowMark, settings.highMark);
}

@riverpod
Future<List<LocalPremiumEntry>> localPremiumHistory(
    LocalPremiumHistoryRef ref) async {
  final prices = await ref.watch(spotPricesNotifierProvider.future);
  return _buildLocalPremiumHistory(prices);
}

/// Returns one entry per metal (the most recent available).
@riverpod
Future<List<LocalPremiumEntry>> localPremiumSummary(
    LocalPremiumSummaryRef ref) async {
  final history = await ref.watch(localPremiumHistoryProvider.future);
  final seen = <String>{};
  final result = <LocalPremiumEntry>[];
  for (final e in history) {
    if (seen.add(e.metalType)) result.add(e);
    if (seen.length == 3) break;
  }
  return result;
}

@riverpod
Future<List<DealerSpreadEntry>> dealerSpreadHistory(
    DealerSpreadHistoryRef ref) async {
  final repo = ref.watch(livePricesRepositoryProvider);
  final rawPrices = await repo.getLivePricesWithProfiles();
  return _buildSpreadHistory(rawPrices);
}

/// Returns the most recent spread entry for each metal.
@riverpod
Future<List<DealerSpreadEntry>> dealerSpreadSummary(
    DealerSpreadSummaryRef ref) async {
  final history = await ref.watch(dealerSpreadHistoryProvider.future);
  final seen = <String>{};
  final result = <DealerSpreadEntry>[];
  for (final e in history) {
    if (seen.add(e.metalType)) result.add(e);
    if (seen.length == 3) break;
  }
  return result;
}

// ─── Local Spread Aliases (LocalSpread == DealerSpread) ──────────────────────
// The screen was renamed from "Dealer Spread" to "Local Spread". These aliases
// keep the screen code working without touching the underlying providers.

typedef LocalSpreadEntry = DealerSpreadEntry;
final localSpreadHistoryProvider = dealerSpreadHistoryProvider;
final localSpreadSummaryProvider = dealerSpreadSummaryProvider;

@riverpod
Future<AnalyticsSummary> analyticsSummary(AnalyticsSummaryRef ref) async {
  final history = await ref.watch(gsrHistoryProvider.future);

  if (history.isEmpty) {
    return const AnalyticsSummary(
      currentGsr: null,
      movementUp: null,
      currentGuide: null,
      goldGuide: '—',
      silverGuide: '—',
      platinumGuide: 'N/A',
    );
  }

  final latest = history.first;
  return AnalyticsSummary(
    currentGsr: latest.gsr,
    movementUp: latest.movementUp,
    currentGuide: latest.guide,
    goldGuide: latest.guide == 'Buy Gold' ? 'Buy Gold' : 'Hold',
    silverGuide: latest.guide == 'Buy Silver' ? 'Buy Silver' : 'Hold',
    platinumGuide: 'N/A',
  );
}
