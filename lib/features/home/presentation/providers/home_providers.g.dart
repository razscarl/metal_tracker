// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$homeBestPricesHash() => r'e869ba143f94ae67d072fb5b6011d871edfd5fa8';

/// See also [homeBestPrices].
@ProviderFor(homeBestPrices)
final homeBestPricesProvider =
    AutoDisposeFutureProvider<Map<MetalType, MetalBestPrices>>.internal(
  homeBestPrices,
  name: r'homeBestPricesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$homeBestPricesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HomeBestPricesRef
    = AutoDisposeFutureProviderRef<Map<MetalType, MetalBestPrices>>;
String _$homeRecentLivePricesHash() =>
    r'21b726f2df190cfe29460f27a8f1e42d26eef51a';

/// See also [homeRecentLivePrices].
@ProviderFor(homeRecentLivePrices)
final homeRecentLivePricesProvider =
    AutoDisposeFutureProvider<List<LivePrice>>.internal(
  homeRecentLivePrices,
  name: r'homeRecentLivePricesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$homeRecentLivePricesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HomeRecentLivePricesRef = AutoDisposeFutureProviderRef<List<LivePrice>>;
String _$homeGlobalSpotPricesHash() =>
    r'58f8a4bdb93242a29951d0495da4d5cbdbce32e4';

/// See also [homeGlobalSpotPrices].
@ProviderFor(homeGlobalSpotPrices)
final homeGlobalSpotPricesProvider =
    AutoDisposeFutureProvider<List<SpotPrice>>.internal(
  homeGlobalSpotPrices,
  name: r'homeGlobalSpotPricesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$homeGlobalSpotPricesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HomeGlobalSpotPricesRef = AutoDisposeFutureProviderRef<List<SpotPrice>>;
String _$homeLocalSpotPricesHash() =>
    r'c579f0b1484d989084a5fec424f4650eb9cb1578';

/// See also [homeLocalSpotPrices].
@ProviderFor(homeLocalSpotPrices)
final homeLocalSpotPricesProvider =
    AutoDisposeFutureProvider<List<SpotPrice>>.internal(
  homeLocalSpotPrices,
  name: r'homeLocalSpotPricesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$homeLocalSpotPricesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HomeLocalSpotPricesRef = AutoDisposeFutureProviderRef<List<SpotPrice>>;
String _$footerTimestampsHash() => r'ceb482dea759aebc6b9b6b6e9744f5b5508f5a49';

/// See also [footerTimestamps].
@ProviderFor(footerTimestamps)
final footerTimestampsProvider = AutoDisposeFutureProvider<
    ({
      DateTime? livePrices,
      DateTime? productListings,
      DateTime? spotPrices,
      DateTime? globalSpotPrices
    })>.internal(
  footerTimestamps,
  name: r'footerTimestampsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$footerTimestampsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FooterTimestampsRef = AutoDisposeFutureProviderRef<
    ({
      DateTime? livePrices,
      DateTime? productListings,
      DateTime? spotPrices,
      DateTime? globalSpotPrices
    })>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
