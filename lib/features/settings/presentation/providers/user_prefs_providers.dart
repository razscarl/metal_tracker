import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/features/settings/data/models/user_prefs_models.dart';
import 'package:metal_tracker/features/settings/data/models/user_analytics_settings_model.dart';
import 'package:metal_tracker/features/settings/data/models/user_retailer_pref_model.dart';
import 'package:metal_tracker/features/settings/data/models/user_metaltype_pref_model.dart';
import 'package:metal_tracker/features/spot_prices/data/models/global_spot_provider_model.dart';

part 'user_prefs_providers.g.dart';


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

// ─────────────────────────────────────────────────────────────────────────────
// User Retailer Prefs — which retailers the user tracks
// ─────────────────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class UserRetailerPrefsNotifier extends _$UserRetailerPrefsNotifier {
  @override
  Future<List<UserRetailerPref>> build() async {
    return ref.watch(userPrefsRepositoryProvider).getUserRetailerPrefs();
  }

  Future<void> set(List<String> retailerIds) async {
    final repo = ref.read(userPrefsRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repo.setUserRetailerPrefs(retailerIds);
      return repo.getUserRetailerPrefs();
    });
  }

  void clear() => state = const AsyncData([]);
}

// ─────────────────────────────────────────────────────────────────────────────
// User Metaltype Prefs — which metal types the user tracks
// ─────────────────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class UserMetaltypePrefsNotifier extends _$UserMetaltypePrefsNotifier {
  @override
  Future<List<UserMetaltypePref>> build() async {
    return ref.watch(userPrefsRepositoryProvider).getUserMetaltypePrefs();
  }

  Future<void> set(List<String> metalTypeIds) async {
    final repo = ref.read(userPrefsRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repo.setUserMetaltypePrefs(metalTypeIds);
      return repo.getUserMetaltypePrefs();
    });
  }

  void clear() => state = const AsyncData([]);
}

// ─────────────────────────────────────────────────────────────────────────────
// User Analytics Prefs — renamed from UserAnalyticsSettingsNotifier
// ─────────────────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class UserAnalyticsPrefsNotifier extends _$UserAnalyticsPrefsNotifier {
  @override
  Future<UserAnalyticsSettings> build() async {
    return ref.watch(userPrefsRepositoryProvider).getAnalyticsSettings();
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
// Derived filter sets — consumed by all data providers for filtering
// ─────────────────────────────────────────────────────────────────────────────

/// Set of retailer IDs the user has selected. Empty = no filter applied yet.
@Riverpod(keepAlive: true)
Future<Set<String>> userRetailerIdSet(UserRetailerIdSetRef ref) async {
  final prefs = await ref.watch(userRetailerPrefsNotifierProvider.future);
  return prefs.map((p) => p.retailerId).toSet();
}

/// Set of metal type names (e.g. {'gold', 'silver'}) the user has selected.
/// Empty = no filter applied yet.
@Riverpod(keepAlive: true)
Future<Set<String>> userMetalNameSet(UserMetalNameSetRef ref) async {
  final prefs = await ref.watch(userMetaltypePrefsNotifierProvider.future);
  return prefs.map((p) => p.metalTypeName).toSet();
}
