// lib/features/retailers/presentation/providers/retailers_providers.dart:Retailers Providers
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/retailers_model.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/weight_converter.dart';

// Retailers list provider
final retailersProvider = FutureProvider<List<Retailer>>((ref) async {
  final repository = ref.watch(retailerRepositoryProvider);
  return repository.getRetailers();
});
