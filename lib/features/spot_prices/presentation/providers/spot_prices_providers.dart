// lib/features/spot_prices/presentation/providers/spot_prices_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/features/spot_prices/data/models/global_spot_price_api_setting_model.dart';
import 'package:metal_tracker/features/spot_prices/data/models/spot_price_model.dart';
import 'package:metal_tracker/features/spot_prices/data/services/base_global_spot_price_service.dart';
import 'package:metal_tracker/features/spot_prices/data/services/global_spot_price_service_factory.dart';

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
