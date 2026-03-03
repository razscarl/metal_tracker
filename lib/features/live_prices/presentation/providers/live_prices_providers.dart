// lib/features/live_prices/presentation/providers/live_prices_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../data/models/live_price_model.dart';

part 'live_prices_providers.g.dart';

@riverpod
class LivePricesNotifier extends _$LivePricesNotifier {
  @override
  Future<List<LivePrice>> build() async {
    return ref.watch(livePricesRepositoryProvider).getLivePrices();
  }

  Future<void> addManualPrice({
    required String productProfileId,
    required String retailerId,
    required DateTime captureDate,
    double? sellPrice,
    double? buybackPrice,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(livePricesRepositoryProvider).createLivePrice(
            productProfileId: productProfileId,
            retailerId: retailerId,
            captureDate: captureDate,
            sellPrice: sellPrice,
            buybackPrice: buybackPrice,
          );
      return ref.read(livePricesRepositoryProvider).getLivePrices();
    });
  }

  // Logic for the phone-based scraper will be integrated here later
}

/// Derived provider — filters live prices with no product profile linked.
/// Used by LivePriceMappingScreen.
@riverpod
Future<List<LivePrice>> unmappedLivePrices(UnmappedLivePricesRef ref) async {
  final all = await ref.watch(livePricesNotifierProvider.future);
  return all.where((p) => p.productProfileId == null).toList();
}
