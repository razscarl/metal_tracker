// lib/features/live_prices/presentation/providers/live_prices_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:metal_tracker/core/constants/scraper_constants.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/features/live_prices/data/models/live_price_model.dart';
import 'package:metal_tracker/features/live_prices/data/services/gba_live_price_service.dart';
import 'package:metal_tracker/features/live_prices/data/services/gs_live_price_service.dart';
import 'package:metal_tracker/features/live_prices/data/services/imp_live_price_service.dart';

part 'live_prices_providers.g.dart';

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

        try {
          final result = abbr == 'GBA'
              ? await GbaLivePriceService().scrape(retailer.id, settings)
              : abbr == 'GS'
                  ? await GsLivePriceService().scrape(retailer.id, settings)
                  : await ImpLivePriceService().scrape(retailer.id, settings);

          await ref
              .read(livePricesRepositoryProvider)
              .saveLivePrices(result, nameMap);

          reports.add(RetailerScrapeReport(
            retailerName: retailer.name,
            status: result.scrapeStatus,
            prices: result.prices,
            errors: result.scrapeErrors,
          ));
        } catch (e) {
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

/// Derived provider — filters live prices with no product profile linked.
/// Used by LivePriceMappingScreen.
@riverpod
Future<List<LivePrice>> unmappedLivePrices(UnmappedLivePricesRef ref) async {
  final all = await ref.watch(livePricesNotifierProvider.future);
  return all.where((p) => p.productProfileId == null).toList();
}
