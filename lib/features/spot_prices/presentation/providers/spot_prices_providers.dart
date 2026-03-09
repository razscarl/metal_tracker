// lib/features/spot_prices/presentation/providers/spot_prices_providers.dart

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:metal_tracker/core/constants/scraper_constants.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/features/spot_prices/data/models/global_spot_price_api_setting_model.dart';
import 'package:metal_tracker/features/spot_prices/data/models/spot_price_model.dart';
import 'package:metal_tracker/features/spot_prices/data/services/base_global_spot_price_service.dart';
import 'package:metal_tracker/features/spot_prices/data/services/gba_local_spot_service.dart';
import 'package:metal_tracker/features/spot_prices/data/services/global_spot_price_service_factory.dart';
import 'package:metal_tracker/features/spot_prices/data/services/gs_local_spot_service.dart';
import 'package:metal_tracker/features/spot_prices/data/services/imp_local_spot_service.dart';

part 'spot_prices_providers.g.dart';

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
  /// Returns a list of per-retailer result lines for display in a dialog.
  Future<({int savedCount, List<String> details})> fetchLocalSpotPrices() async {
    state = const AsyncValue.loading();
    final details = <String>[];

    try {
      var totalSaved = 0;
      final retailerRepo = ref.read(retailerRepositoryProvider);
      final spotRepo = ref.read(spotPricesRepositoryProvider);
      final retailers = await retailerRepo.getRetailers(includeInactive: false);

      final supported = retailers.where(
        (r) => ['GBA', 'GS', 'IMP'].contains(r.retailerAbbr?.toUpperCase()),
      ).toList();

      if (supported.isEmpty) {
        details.add('No supported retailers found (need GBA, GS or IMP).');
        state = AsyncValue.data(await spotRepo.getSpotPrices());
        return (savedCount: 0, details: details);
      }

      for (final retailer in supported) {
        final abbr = retailer.retailerAbbr!.toUpperCase();
        final settings = await retailerRepo.getScraperSettingsForType(
          retailer.id,
          ScraperType.localSpot,
        );

        if (settings.isEmpty) {
          details.add('$abbr: no local_spot settings configured');
          continue;
        }

        try {
          Map<String, double> prices;
          if (abbr == 'GBA') {
            prices = await GbaLocalSpotService().scrape(settings);
          } else if (abbr == 'GS') {
            prices = await GsLocalSpotService().scrape(settings);
          } else {
            prices = await ImpLocalSpotService().scrape(settings);
          }

          if (prices.isEmpty) {
            details.add('$abbr: fetched page but no prices found — check search strings');
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
              if (!result.wasDuplicate) {
                saved++;
                totalSaved++;
              }
            }
            final priceLines = prices.entries
                .map((e) => '${e.key}: \$${e.value.toStringAsFixed(2)}')
                .join(', ');
            details.add(saved > 0
                ? '$abbr ✓  $priceLines'
                : '$abbr: already up to date ($priceLines)');
          }
        } catch (e) {
          debugPrint('Local spot scrape error for $abbr: $e');
          details.add('$abbr ✗  $e');
        }
      }

      state = AsyncValue.data(await spotRepo.getSpotPrices());
      return (savedCount: totalSaved, details: details);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      details.add('Fatal error: $e');
      return (savedCount: 0, details: details);
    }
  }

  /// Fetches latest spot rates and saves them.
  /// Returns ({error: String, savedCount: 0}) on failure,
  /// ({error: null, savedCount: N}) on success (N=0 means already up to date).
  Future<({String? error, int savedCount})> fetchAndSave({
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
        return (error: result.errorMessage, savedCount: 0);
      }

      final repo = ref.read(spotPricesRepositoryProvider);
      final metals = service.resolveMetals(result.rates, config);
      var savedCount = 0;

      for (final entry in metals.entries) {
        final price = entry.value;
        if (price != null) {
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
      return (error: null, savedCount: savedCount);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return (error: e.toString(), savedCount: 0);
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
