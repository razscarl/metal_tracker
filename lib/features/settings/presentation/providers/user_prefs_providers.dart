import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/features/settings/data/models/user_prefs_models.dart';
import 'package:metal_tracker/features/settings/data/models/user_analytics_settings_model.dart';
import 'package:metal_tracker/features/settings/data/models/user_retailer_model.dart';
import 'package:metal_tracker/features/spot_prices/data/models/global_spot_provider_model.dart';

part 'user_prefs_providers.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// User Metal Types — which metals the user tracks
// ─────────────────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class UserMetalTypesNotifier extends _$UserMetalTypesNotifier {
  @override
  Future<List<String>> build() async {
    return ref.watch(userPrefsRepositoryProvider).getUserMetalTypes();
  }

  Future<void> set(List<String> metals) async {
    final repo = ref.read(userPrefsRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repo.setUserMetalTypes(metals);
      return repo.getUserMetalTypes();
    });
  }

  void clear() => state = const AsyncData([]);
}

// ─────────────────────────────────────────────────────────────────────────────
// User Retailers — which retailers the user tracks
// ─────────────────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class UserRetailersNotifier extends _$UserRetailersNotifier {
  @override
  Future<List<UserRetailer>> build() async {
    return ref.watch(userPrefsRepositoryProvider).getUserRetailers();
  }

  Future<void> set(List<String> retailerIds) async {
    final repo = ref.read(userPrefsRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repo.setUserRetailers(retailerIds);
      return repo.getUserRetailers();
    });
  }

  void clear() => state = const AsyncData([]);
}

// ─────────────────────────────────────────────────────────────────────────────
// Active global spot provider preferences (list — one per provider)
// ─────────────────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class UserGlobalSpotPrefNotifier extends _$UserGlobalSpotPrefNotifier {
  @override
  Future<List<UserGlobalSpotPref>> build() async {
    final repo = ref.watch(userPrefsRepositoryProvider);
    return repo.getGlobalSpotPrefs();
  }

  Future<void> upsert(UserGlobalSpotPref pref) async {
    final repo = ref.read(userPrefsRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repo.upsertGlobalSpotPref(pref);
      return repo.getGlobalSpotPrefs();
    });
  }

  Future<void> delete(String id) async {
    final repo = ref.read(userPrefsRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repo.deleteGlobalSpotPref(id);
      return repo.getGlobalSpotPrefs();
    });
  }

  void clear() => state = const AsyncData([]);
}

// ─────────────────────────────────────────────────────────────────────────────
// Analytics settings (tolerances)
// ─────────────────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class UserAnalyticsSettingsNotifier extends _$UserAnalyticsSettingsNotifier {
  @override
  Future<UserAnalyticsSettings> build() async {
    final repo = ref.watch(userPrefsRepositoryProvider);
    return repo.getAnalyticsSettings();
  }

  Future<void> save(UserAnalyticsSettings settings) async {
    final repo = ref.read(userPrefsRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => repo.upsertAnalyticsSettings(settings),
    );
  }

  Future<void> reset(String userId) async {
    await save(UserAnalyticsSettings.defaults(userId));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// User Local Spot Prefs — which retailers the user uses for local spot prices
// ─────────────────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
Future<List<UserLocalSpotPref>> userLocalSpotPrefs(
    UserLocalSpotPrefsRef ref) async {
  return ref.watch(userPrefsRepositoryProvider).getLocalSpotPrefs();
}

// ─────────────────────────────────────────────────────────────────────────────
// Global spot providers registry (read-only for users; admin can mutate)
// ─────────────────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
Future<List<GlobalSpotProvider>> globalSpotProviders(
  GlobalSpotProvidersRef ref, {
  bool activeOnly = true,
}) async {
  final repo = ref.watch(globalSpotProvidersRepositoryProvider);
  return repo.getProviders(activeOnly: activeOnly);
}
