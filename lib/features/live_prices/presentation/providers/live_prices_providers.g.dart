// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_prices_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

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
    r'32d484a07657f1f7332d03f9e7b96758adba66ef';

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
