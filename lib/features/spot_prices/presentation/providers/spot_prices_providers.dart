// lib/features/spot_prices/presentation/providers/spot_prices_providers.dart

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:metal_tracker/core/constants/scraper_constants.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/features/spot_prices/data/models/global_spot_price_api_setting_model.dart';
import 'package:metal_tracker/features/spot_prices/data/models/spot_price_model.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_prefs_providers.dart';
import 'package:metal_tracker/features/spot_prices/data/services/base_global_spot_price_service.dart';
import 'package:metal_tracker/features/spot_prices/data/services/gba_local_spot_service.dart';
import 'package:metal_tracker/features/spot_prices/data/services/global_spot_price_service_factory.dart';
import 'package:metal_tracker/features/spot_prices/data/services/gs_local_spot_service.dart';
import 'package:metal_tracker/features/spot_prices/data/services/imp_local_spot_service.dart';

part 'spot_prices_providers.g.dart';

/// Per-source scrape result for spot price fetches (local and global).
class SpotScrapeReport {
  final String sourceName;
  /// 'success' | 'duplicate' | 'partial' | 'failed' | 'error'
  final String status;
  /// metalType → price (AUD per oz)
  final Map<String, double> prices;
  final List<String> errors;

  const SpotScrapeReport({
    required this.sourceName,
    required this.status,
    required this.prices,
    required this.errors,
  });
}

// ─── Spot Prices Notifier ────────────────────────────────────────────────────

@riverpod
class SpotPricesNotifier extends _$SpotPricesNotifier {
  @override
  Future<List<SpotPrice>> build() async {
    return ref.watch(spotPricesRepositoryProvider).getSpotPrices();
  }

  /// Checks API usage quota for the given service. Returns null if the service
  /// has no usage endpoint (UI should skip the usage dialog in that case).
  Future<SpotPriceUsageResult?> checkUsage(
    String apiKey,
    String serviceType,
    Map<String, String> config,
  ) async {
    final service = GlobalSpotPriceServiceFactory.forType(serviceType);
    return service.checkUsage(apiKey, config);
  }

  /// Scrapes local spot prices from GBA, GS, and IMP and saves them.
  /// Returns a per-retailer [SpotScrapeReport] list for the results dialog.
  Future<List<SpotScrapeReport>> fetchLocalSpotPrices() async {
    state = const AsyncValue.loading();
    final reports = <SpotScrapeReport>[];

    try {
      final retailerRepo = ref.read(retailerRepositoryProvider);
      final spotRepo = ref.read(spotPricesRepositoryProvider);
      final retailers = await retailerRepo.getRetailers(includeInactive: false);

      final supported = retailers.where(
        (r) => ['GBA', 'GS', 'IMP'].contains(r.retailerAbbr?.toUpperCase()),
      ).toList();

      if (supported.isEmpty) {
        state = AsyncValue.data(await spotRepo.getSpotPrices());
        return [
          const SpotScrapeReport(
            sourceName: 'Local Scrapers',
            status: 'error',
            prices: {},
            errors: ['No supported retailers found (need GBA, GS or IMP)'],
          ),
        ];
      }

      for (final retailer in supported) {
        final abbr = retailer.retailerAbbr!.toUpperCase();
        final settings = await retailerRepo.getScraperSettingsForType(
          retailer.id,
          ScraperType.localSpot,
        );

        if (settings.isEmpty) {
          reports.add(SpotScrapeReport(
            sourceName: retailer.name,
            status: 'failed',
            prices: {},
            errors: ['No local_spot scraper settings configured'],
          ));
          continue;
        }

        try {
          final Map<String, double> prices;
          if (abbr == 'GBA') {
            prices = await GbaLocalSpotService().scrape(settings);
          } else if (abbr == 'GS') {
            prices = await GsLocalSpotService().scrape(settings);
          } else {
            prices = await ImpLocalSpotService().scrape(settings);
          }

          if (prices.isEmpty) {
            reports.add(SpotScrapeReport(
              sourceName: retailer.name,
              status: 'failed',
              prices: {},
              errors: ['Fetched page but no prices found — check search strings'],
            ));
          } else {
            // Shared timestamp so all metals for this batch group into one row.
            final batchTimestamp = DateTime.now().toUtc();
            var saved = 0;
            for (final entry in prices.entries) {
              final result = await spotRepo.saveSpotPrice(
                metalType: entry.key,
                price: entry.value,
                sourceType: 'local_scraper',
                source: retailer.name,
                retailerId: retailer.id,
                fetchTimestamp: batchTimestamp,
              );
              if (!result.wasDuplicate) saved++;
            }
            reports.add(SpotScrapeReport(
              sourceName: retailer.name,
              status: saved > 0 ? 'success' : 'duplicate',
              prices: prices,
              errors: [],
            ));
          }
        } catch (e) {
          debugPrint('Local spot scrape error for $abbr: $e');
          reports.add(SpotScrapeReport(
            sourceName: retailer.name,
            status: 'error',
            prices: {},
            errors: [e.toString()],
          ));
        }
      }

      state = AsyncValue.data(await spotRepo.getSpotPrices());
      return reports;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return [
        SpotScrapeReport(
          sourceName: 'System',
          status: 'error',
          prices: {},
          errors: ['Fatal error: $e'],
        ),
      ];
    }
  }

  /// Fetches global spot prices using all active configured user providers.
  /// Returns a list of [SpotScrapeReport] — one per provider.
  Future<List<SpotScrapeReport>> fetchGlobalSpotPrices() async {
    final allPrefs =
        await ref.read(userGlobalSpotPrefNotifierProvider.future);
    final prefs = allPrefs.where((p) => p.isActive).toList();

    if (prefs.isEmpty) {
      return [
        const SpotScrapeReport(
          sourceName: 'None',
          status: 'no_provider',
          prices: {},
          errors: ['No global spot provider configured. Go to Settings > Global Spot to add one.'],
        ),
      ];
    }

    state = const AsyncValue.loading();
    final reports = <SpotScrapeReport>[];

    try {
      final repo = ref.read(spotPricesRepositoryProvider);

      for (final pref in prefs) {
        try {
          final service =
              GlobalSpotPriceServiceFactory.forType(pref.providerKey);
          final result =
              await service.fetchLatestRates(pref.apiKey, {});

          if (!result.isSuccess) {
            reports.add(SpotScrapeReport(
              sourceName: service.displayName,
              status: 'error',
              prices: {},
              errors: [result.errorMessage ?? 'Unknown error'],
            ));
            continue;
          }

          final metals = service.resolveMetals(result.rates, {});
          final prices = <String, double>{};
          var savedCount = 0;

          for (final entry in metals.entries) {
            final price = entry.value;
            if (price != null) {
              prices[entry.key] = price;
              final saved = await repo.saveSpotPrice(
                metalType: entry.key,
                price: price,
                sourceType: 'global_api',
                source: service.displayName,
                fetchTimestamp: result.timestamp,
              );
              if (!saved.wasDuplicate) savedCount++;
            }
          }

          reports.add(SpotScrapeReport(
            sourceName: service.displayName,
            status: savedCount > 0 ? 'success' : 'duplicate',
            prices: prices,
            errors: [],
          ));
        } catch (e) {
          reports.add(SpotScrapeReport(
            sourceName: pref.providerKey,
            status: 'error',
            prices: {},
            errors: [e.toString()],
          ));
        }
      }

      state = AsyncValue.data(await repo.getSpotPrices());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      reports.add(SpotScrapeReport(
        sourceName: 'System',
        status: 'error',
        prices: {},
        errors: ['Fatal error: $e'],
      ));
    }

    return reports;
  }

  /// Fetches latest global spot rates and saves them.
  /// Returns a [SpotScrapeReport] for the results dialog.
  Future<SpotScrapeReport> fetchAndSave({
    required String apiKey,
    required String serviceType,
    required Map<String, String> config,
  }) async {
    state = const AsyncValue.loading();

    try {
      final service = GlobalSpotPriceServiceFactory.forType(serviceType);
      final result = await service.fetchLatestRates(apiKey, config);

      if (!result.isSuccess) {
        state = AsyncValue.data(
          await ref.read(spotPricesRepositoryProvider).getSpotPrices(),
        );
        return SpotScrapeReport(
          sourceName: service.displayName,
          status: 'error',
          prices: {},
          errors: [result.errorMessage ?? 'Unknown error'],
        );
      }

      final repo = ref.read(spotPricesRepositoryProvider);
      final metals = service.resolveMetals(result.rates, config);
      final prices = <String, double>{};
      var savedCount = 0;

      for (final entry in metals.entries) {
        final price = entry.value;
        if (price != null) {
          prices[entry.key] = price;
          final saved = await repo.saveSpotPrice(
            metalType: entry.key,
            price: price,
            sourceType: 'global_api',
            source: service.displayName,
            fetchTimestamp: result.timestamp,
          );
          if (!saved.wasDuplicate) savedCount++;
        }
      }

      final newList = await repo.getSpotPrices();
      state = AsyncValue.data(newList);
      return SpotScrapeReport(
        sourceName: service.displayName,
        status: savedCount > 0 ? 'success' : 'duplicate',
        prices: prices,
        errors: [],
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return SpotScrapeReport(
        sourceName: 'Global API',
        status: 'error',
        prices: {},
        errors: [e.toString()],
      );
    }
  }
}

// ─── API Settings Notifier ──────────────────────────────────────────────────

@riverpod
class ApiSettingsNotifier extends _$ApiSettingsNotifier {
  @override
  Future<List<GlobalSpotPriceApiSetting>> build() async {
    return ref.watch(spotPricesRepositoryProvider).getApiSettings();
  }

  Future<void> create({
    required String apiKey,
    required String serviceType,
    required Map<String, String> config,
    bool isActive = true,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(spotPricesRepositoryProvider).createApiSetting(
            apiKey: apiKey,
            serviceType: serviceType,
            config: config,
            isActive: isActive,
          );
      return ref.read(spotPricesRepositoryProvider).getApiSettings();
    });
  }

  Future<void> updateSetting({
    required String id,
    String? apiKey,
    String? serviceType,
    Map<String, String>? config,
    bool? isActive,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(spotPricesRepositoryProvider).updateApiSetting(
            id: id,
            apiKey: apiKey,
            serviceType: serviceType,
            config: config,
            isActive: isActive,
          );
      return ref.read(spotPricesRepositoryProvider).getApiSettings();
    });
  }

  Future<void> delete(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(spotPricesRepositoryProvider).deleteApiSetting(id);
      return ref.read(spotPricesRepositoryProvider).getApiSettings();
    });
  }
}
