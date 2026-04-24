// lib/features/live_prices/presentation/providers/live_prices_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:metal_tracker/core/constants/app_constants.dart';
import 'package:metal_tracker/core/constants/scraper_constants.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/core/utils/weight_converter.dart';
import 'package:metal_tracker/features/admin/data/models/automation_job_model.dart';
import 'package:metal_tracker/features/admin/data/models/automation_schedule_model.dart';
import 'package:metal_tracker/features/live_prices/data/models/live_price_model.dart';
import 'package:metal_tracker/features/live_prices/data/services/gba_live_price_service.dart';
import 'package:metal_tracker/features/live_prices/data/services/gs_live_price_service.dart';
import 'package:metal_tracker/features/live_prices/data/services/imp_live_price_service.dart';
import 'package:metal_tracker/features/product_profiles/presentation/providers/product_profiles_providers.dart';

part 'live_prices_providers.g.dart';

typedef BestPriceData = ({double? pricePerOz, String? retailerName, String? retailerAbbr});
typedef MetalBestPrices = ({BestPriceData sell, BestPriceData buyback});

/// Per-retailer scrape result returned by [LivePricesNotifier.scrapeAll].
class RetailerScrapeReport {
  final String retailerName;
  /// 'success' | 'partial' | 'failed' | 'error'
  final String status;
  /// metalType → {sell, buyback}
  final Map<String, Map<String, double>> prices;
  final List<String> errors;

  const RetailerScrapeReport({
    required this.retailerName,
    required this.status,
    required this.prices,
    required this.errors,
  });
}

@riverpod
class LivePricesNotifier extends _$LivePricesNotifier {
  @override
  Future<List<LivePrice>> build() async {
    return ref.watch(livePricesRepositoryProvider).getLivePrices();
  }

  Future<void> addManualPrice({
    required String productProfileId,
    required String retailerId,
    required DateTime captureDate,
    double? sellPrice,
    double? buybackPrice,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(livePricesRepositoryProvider).createLivePrice(
            productProfileId: productProfileId,
            retailerId: retailerId,
            captureDate: captureDate,
            sellPrice: sellPrice,
            buybackPrice: buybackPrice,
          );
      return ref.read(livePricesRepositoryProvider).getLivePrices();
    });
  }

  Future<void> deletePrice(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(livePricesRepositoryProvider).deleteLivePrice(id);
      return ref.read(livePricesRepositoryProvider).getLivePrices();
    });
  }

  Future<void> updatePrice({
    required String id,
    double? sellPrice,
    double? buybackPrice,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(livePricesRepositoryProvider).updateLivePrice(
            id: id,
            sellPrice: sellPrice,
            buybackPrice: buybackPrice,
          );
      return ref.read(livePricesRepositoryProvider).getLivePrices();
    });
  }

  /// Scrapes live prices from all configured retailers.
  /// Returns a per-retailer report with captured metals and any errors.
  Future<List<RetailerScrapeReport>> scrapeAll() async {
    final reports = <RetailerScrapeReport>[];
    state = const AsyncValue.loading();
    try {
      final retailers =
          await ref.read(retailerRepositoryProvider).getRetailers();

      for (final retailer in retailers) {
        if (!retailer.isActive) continue;

        final settings = await ref
            .read(retailerRepositoryProvider)
            .getScraperSettingsForType(
              retailer.id,
              ScraperType.livePrice,
            );

        if (settings.isEmpty) continue;

        final nameMap = {
          for (final s in settings)
            if (s.metalType != null) s.metalType!: s.searchString,
        };

        final abbr = retailer.retailerAbbr?.toUpperCase();
        if (abbr != 'GBA' && abbr != 'GS' && abbr != 'IMP') {
          reports.add(RetailerScrapeReport(
            retailerName: retailer.name,
            status: 'failed',
            prices: {},
            errors: ['No scraper configured for this retailer'],
          ));
          continue;
        }

        // Log manual scrape to automation_jobs (best-effort — never blocks scraping)
        AutomationJob? job;
        try {
          job = await ref.read(automationRepositoryProvider).insertJob(AutomationJob(
            id: '',
            jobType: ScrapeType.livePrices,
            retailerId: retailer.id,
            retailerName: retailer.name,
            scheduledAt: DateTime.now(),
            startedAt: DateTime.now(),
            status: JobStatus.running,
            triggeredBy: JobTrigger.manual,
          ));
        } catch (_) {}

        try {
          final result = abbr == 'GBA'
              ? await GbaLivePriceService().scrape(retailer.id, settings)
              : abbr == 'GS'
                  ? await GsLivePriceService().scrape(retailer.id, settings)
                  : await ImpLivePriceService().scrape(retailer.id, settings);

          await ref
              .read(livePricesRepositoryProvider)
              .saveLivePrices(result, nameMap);

          try {
            if (job != null) {
              await ref.read(automationRepositoryProvider).updateJob(
                job.id,
                status: JobStatus.success,
                completedAt: DateTime.now(),
                resultSummary: {
                  'prices_scraped': result.prices.length,
                  'scrape_status': result.scrapeStatus,
                  if (result.scrapeErrors.isNotEmpty) 'warnings': result.scrapeErrors,
                },
              );
            }
          } catch (_) {}

          reports.add(RetailerScrapeReport(
            retailerName: retailer.name,
            status: result.scrapeStatus,
            prices: result.prices,
            errors: result.scrapeErrors,
          ));
        } catch (e) {
          try {
            if (job != null) {
              await ref.read(automationRepositoryProvider).updateJob(
                job.id,
                status: JobStatus.failed,
                completedAt: DateTime.now(),
                errorLog: {'error': e.toString(), 'retailer': retailer.name},
              );
            }
          } catch (_) {}

          reports.add(RetailerScrapeReport(
            retailerName: retailer.name,
            status: 'error',
            prices: {},
            errors: [e.toString()],
          ));
        }
      }

      final newList =
          await ref.read(livePricesRepositoryProvider).getLivePrices();
      state = AsyncValue.data(newList);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return [
        RetailerScrapeReport(
          retailerName: 'System',
          status: 'error',
          prices: {},
          errors: ['Scrape failed: $e'],
        ),
      ];
    }

    return reports;
  }
}

/// Single source of truth for best sell + buyback $/oz per metal type.
/// Computed in-memory from already-loaded live prices — reactive, no extra DB queries.
/// Consumers: homeBestPricesProvider, InvestmentGuideNotifier.
@riverpod
Future<Map<MetalType, MetalBestPrices>> bestLivePricesPerMetal(
    BestLivePricesPerMetalRef ref) async {
  final allLivePrices = await ref.watch(livePricesNotifierProvider.future);
  final profiles = await ref.watch(productProfilesNotifierProvider.future);
  final profileMap = {for (final p in profiles) p.id: p};

  final mapped = allLivePrices
      .where((lp) =>
          lp.productProfileId != null &&
          profileMap.containsKey(lp.productProfileId))
      .toList();

  BestPriceData best(MetalType metal, bool isBuyback) {
    final candidates = mapped.where((lp) {
      final profile = profileMap[lp.productProfileId]!;
      if (profile.metalTypeEnum != metal) return false;
      return isBuyback ? lp.buybackPrice != null : lp.sellPrice != null;
    }).toList();

    if (candidates.isEmpty) {
      return (pricePerOz: null, retailerName: null, retailerAbbr: null);
    }

    final retailerMaxTs = <String, DateTime>{};
    for (final lp in candidates) {
      final existing = retailerMaxTs[lp.retailerId];
      if (existing == null || lp.captureTimestamp.isAfter(existing)) {
        retailerMaxTs[lp.retailerId] = lp.captureTimestamp;
      }
    }

    DateTime? latestDate;
    for (final ts in retailerMaxTs.values) {
      final d = DateTime(ts.year, ts.month, ts.day);
      if (latestDate == null || d.isAfter(latestDate)) latestDate = d;
    }
    if (latestDate == null) {
      return (pricePerOz: null, retailerName: null, retailerAbbr: null);
    }

    final included = retailerMaxTs.entries
        .where((e) {
          final d = DateTime(e.value.year, e.value.month, e.value.day);
          return d == latestDate;
        })
        .map((e) => e.key)
        .toSet();

    double? bestVal;
    String? bestRetailer;
    String? bestRetailerAbbr;

    for (final lp in candidates) {
      if (!included.contains(lp.retailerId)) continue;
      if (lp.captureTimestamp != retailerMaxTs[lp.retailerId]) continue;

      final profile = profileMap[lp.productProfileId]!;
      final rawPrice = (isBuyback ? lp.buybackPrice : lp.sellPrice)!;
      final perOz = WeightCalculations.pricePerPureOunce(
        totalPrice: rawPrice,
        weight: profile.weight,
        unit: profile.weightUnitEnum,
        purity: profile.purity,
      );

      final isBetter =
          bestVal == null || (isBuyback ? perOz > bestVal : perOz < bestVal);
      if (isBetter) {
        bestVal = perOz;
        bestRetailer = lp.retailerName;
        bestRetailerAbbr = lp.retailerAbbr;
      }
    }

    return (
      pricePerOz: bestVal,
      retailerName: bestRetailer,
      retailerAbbr: bestRetailerAbbr,
    );
  }

  return {
    for (final metal in MetalType.values)
      metal: (sell: best(metal, false), buyback: best(metal, true)),
  };
}

/// Derived provider — filters live prices with no product profile linked.
/// Used by LivePriceMappingScreen.
@riverpod
Future<List<LivePrice>> unmappedLivePrices(UnmappedLivePricesRef ref) async {
  final all = await ref.watch(livePricesNotifierProvider.future);
  return all.where((p) => p.productProfileId == null).toList();
}
