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
    r'63a6d588d53f13649dca8a84e2b75810ab3c8f32';

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
    r'b83b0b19031db4c1f18fe45eb6b18f650013dace';

/// See also [homeGlobalSpotPrices].
@ProviderFor(homeGlobalSpotPrices)
final homeGlobalSpotPricesProvider =
    AutoDisposeFutureProvider<List<GlobalSpotPrice>>.internal(
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
typedef HomeGlobalSpotPricesRef
    = AutoDisposeFutureProviderRef<List<GlobalSpotPrice>>;
String _$homeLocalSpotPricesHash() =>
    r'95273291b0705eed7a5ec79941a44cb2f1dd0a6d';

/// See also [homeLocalSpotPrices].
@ProviderFor(homeLocalSpotPrices)
final homeLocalSpotPricesProvider =
    AutoDisposeFutureProvider<List<LocalSpotPrice>>.internal(
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
typedef HomeLocalSpotPricesRef
    = AutoDisposeFutureProviderRef<List<LocalSpotPrice>>;
String _$footerTimestampsHash() => r'3e4b202a66a2dc2901f3729c5ccca6b2688a633c';

/// See also [footerTimestamps].
@ProviderFor(footerTimestamps)
final footerTimestampsProvider = AutoDisposeFutureProvider<
    ({
      DateTime? livePrices,
      DateTime? productListings,
      DateTime? spotPrices
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
    ({DateTime? livePrices, DateTime? productListings, DateTime? spotPrices})>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
