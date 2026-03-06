// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$homeBestPricesHash() => r'8ddc612ce532e4eeefd23813227ef5aa0d6b696d';

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
    r'8bd7157f9e652bae1ced4e69ae8c3d73e76d5716';

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
    r'0017acb858839274123b19a79bf800a46ccb7df1';

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
    r'80fc72404d127cea1caf267c819b330ea1de6ad5';

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
String _$footerTimestampsHash() => r'0fb11152f19ac3818226aebc897b086e9c153ccd';

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
