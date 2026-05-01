// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_prices_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$bestLivePricesPerMetalHash() =>
    r'6970291bffd2760c9c8b7d0a8bbf9ea97fa6e6f3';

/// Single source of truth for best sell + buyback $/oz per metal type.
/// Filtered by user's retailer and metal type preferences.
/// Empty preference set = no filter (show all) until user configures prefs.
/// Consumers: homeBestPricesProvider, InvestmentGuideNotifier.
///
/// Copied from [bestLivePricesPerMetal].
@ProviderFor(bestLivePricesPerMetal)
final bestLivePricesPerMetalProvider =
    AutoDisposeFutureProvider<Map<MetalType, MetalBestPrices>>.internal(
  bestLivePricesPerMetal,
  name: r'bestLivePricesPerMetalProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$bestLivePricesPerMetalHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BestLivePricesPerMetalRef
    = AutoDisposeFutureProviderRef<Map<MetalType, MetalBestPrices>>;
String _$unmappedLivePricesHash() =>
    r'4de3ceb8a6c8573f8955d6263f87234c4d247dd4';

/// Derived provider — filters live prices with no product profile linked.
/// Used by LivePriceMappingScreen.
///
/// Copied from [unmappedLivePrices].
@ProviderFor(unmappedLivePrices)
final unmappedLivePricesProvider =
    AutoDisposeFutureProvider<List<LivePrice>>.internal(
  unmappedLivePrices,
  name: r'unmappedLivePricesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$unmappedLivePricesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UnmappedLivePricesRef = AutoDisposeFutureProviderRef<List<LivePrice>>;
String _$livePricesNotifierHash() =>
    r'ecd1b9f7570c9e4b68c5925f29749ec58baec39f';

/// See also [LivePricesNotifier].
@ProviderFor(LivePricesNotifier)
final livePricesNotifierProvider = AutoDisposeAsyncNotifierProvider<
    LivePricesNotifier, List<LivePrice>>.internal(
  LivePricesNotifier.new,
  name: r'livePricesNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$livePricesNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LivePricesNotifier = AutoDisposeAsyncNotifier<List<LivePrice>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
