// lib/features/retailers/presentation/providers/retailers_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/features/retailers/data/models/retailers_model.dart';
import 'package:metal_tracker/features/retailers/data/models/retailer_scraper_setting_model.dart';

final retailersProvider = FutureProvider<List<Retailer>>((ref) async {
  final repository = ref.watch(retailerRepositoryProvider);
  return repository.getRetailers();
});

final retailerScraperSettingsProvider =
    FutureProvider.family<List<RetailerScraperSetting>, String>(
        (ref, retailerId) async {
  final repository = ref.watch(scraperRepositoryProvider);
  return repository.getRetailerScraperSettings(retailerId: retailerId);
});
