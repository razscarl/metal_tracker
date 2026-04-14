// lib/core/providers/repository_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:metal_tracker/features/holdings/data/repositories/holdings_repository.dart';
import 'package:metal_tracker/features/product_profiles/data/repositories/product_profiles_repository.dart';
import 'package:metal_tracker/features/live_prices/data/repositories/live_prices_repository.dart';
import 'package:metal_tracker/features/metadata/data/repositories/metadata_repository.dart';
import 'package:metal_tracker/features/retailers/data/repositories/retailers_repository.dart';
import 'package:metal_tracker/features/spot_prices/data/repositories/spot_prices_repository.dart';
import 'package:metal_tracker/features/spot_prices/data/repositories/global_spot_providers_repository.dart';
import 'package:metal_tracker/features/settings/data/repositories/user_profile_repository.dart';
import 'package:metal_tracker/features/settings/data/repositories/user_prefs_repository.dart';
import 'package:metal_tracker/features/admin/data/repositories/change_request_repository.dart';
import 'package:metal_tracker/features/product_listings/data/repositories/product_listings_repository.dart';

// App version — reads from pubspec.yaml at runtime via package_info_plus
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

// The base Supabase client provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Repository Providers
final holdingsRepositoryProvider = Provider<HoldingsRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return HoldingsRepository(supabase);
});

final productProfilesRepositoryProvider =
    Provider<ProductProfilesRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ProductProfilesRepository(supabase);
});

final livePricesRepositoryProvider = Provider<LivePricesRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return LivePricesRepository(supabase);
});

final metadataRepositoryProvider = Provider<MetadataRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return MetadataRepository(supabase);
});

final retailerRepositoryProvider = Provider<RetailerRepository>((ref) {
  return RetailerRepository();
});

final spotPricesRepositoryProvider = Provider<SpotPricesRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SpotPricesRepository(supabase);
});

final globalSpotProvidersRepositoryProvider =
    Provider<GlobalSpotProvidersRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return GlobalSpotProvidersRepository(supabase);
});

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return UserProfileRepository(supabase);
});

final userPrefsRepositoryProvider = Provider<UserPrefsRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return UserPrefsRepository(supabase);
});

final changeRequestRepositoryProvider =
    Provider<ChangeRequestRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ChangeRequestRepository(supabase);
});

final productListingsRepositoryProvider =
    Provider<ProductListingsRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ProductListingsRepository(supabase);
});
