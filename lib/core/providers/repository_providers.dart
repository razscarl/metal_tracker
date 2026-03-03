// lib/core/providers/repository_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/holdings/data/repositories/holdings_repository.dart';
import '../../features/product_profiles/data/repositories/product_profiles_repository.dart';
import '../../features/live_prices/data/repositories/live_prices_repository.dart';
import '../../features/metadata/data/repositories/metadata_repository.dart';

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
