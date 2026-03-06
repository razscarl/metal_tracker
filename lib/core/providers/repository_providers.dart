// lib/core/providers/repository_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:metal_tracker/features/holdings/data/repositories/holdings_repository.dart';
import 'package:metal_tracker/features/product_profiles/data/repositories/product_profiles_repository.dart';
import 'package:metal_tracker/features/live_prices/data/repositories/live_prices_repository.dart';
import 'package:metal_tracker/features/metadata/data/repositories/metadata_repository.dart';
import 'package:metal_tracker/features/scrapers/data/repositories/scraper_repository.dart';
import 'package:metal_tracker/features/retailers/data/repositories/retailers_repository.dart';
import 'package:metal_tracker/features/spot_prices/data/repositories/spot_prices_repository.dart';

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

// ScraperRepository uses Supabase.instance.client internally
final scraperRepositoryProvider = Provider<ScraperRepository>((ref) {
  return ScraperRepository();
});

final retailerRepositoryProvider = Provider<RetailerRepository>((ref) {
  return RetailerRepository();
});

final spotPricesRepositoryProvider = Provider<SpotPricesRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SpotPricesRepository(supabase);
});
