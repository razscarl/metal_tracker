// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$gsrHistoryHash() => r'590e7d1576f59fe6b1190a94173a66f51822fa68';

/// See also [gsrHistory].
@ProviderFor(gsrHistory)
final gsrHistoryProvider =
    AutoDisposeFutureProvider<List<GsrDataPoint>>.internal(
  gsrHistory,
  name: r'gsrHistoryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$gsrHistoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GsrHistoryRef = AutoDisposeFutureProviderRef<List<GsrDataPoint>>;
String _$localPremiumHistoryHash() =>
    r'11fc68cc8fa77b46c26bafabc40e39418cd534d5';

/// See also [localPremiumHistory].
@ProviderFor(localPremiumHistory)
final localPremiumHistoryProvider =
    AutoDisposeFutureProvider<List<LocalPremiumEntry>>.internal(
  localPremiumHistory,
  name: r'localPremiumHistoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$localPremiumHistoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LocalPremiumHistoryRef
    = AutoDisposeFutureProviderRef<List<LocalPremiumEntry>>;
String _$localPremiumSummaryHash() =>
    r'dd98572df355980588be04638a794776a146e916';

/// Returns one entry per metal (the most recent available).
///
/// Copied from [localPremiumSummary].
@ProviderFor(localPremiumSummary)
final localPremiumSummaryProvider =
    AutoDisposeFutureProvider<List<LocalPremiumEntry>>.internal(
  localPremiumSummary,
  name: r'localPremiumSummaryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$localPremiumSummaryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LocalPremiumSummaryRef
    = AutoDisposeFutureProviderRef<List<LocalPremiumEntry>>;
String _$localSpreadHistoryHash() =>
    r'1dd98cff290e7e9d0607818897d304308f451d5a';

/// See also [localSpreadHistory].
@ProviderFor(localSpreadHistory)
final localSpreadHistoryProvider =
    AutoDisposeFutureProvider<List<LocalSpreadEntry>>.internal(
  localSpreadHistory,
  name: r'localSpreadHistoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$localSpreadHistoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LocalSpreadHistoryRef
    = AutoDisposeFutureProviderRef<List<LocalSpreadEntry>>;
String _$localSpreadSummaryHash() =>
    r'cc09037a9a7eff211977d689cfbd88ee171b1f49';

/// Returns the most recent spread entry for each metal.
///
/// Copied from [localSpreadSummary].
@ProviderFor(localSpreadSummary)
final localSpreadSummaryProvider =
    AutoDisposeFutureProvider<List<LocalSpreadEntry>>.internal(
  localSpreadSummary,
  name: r'localSpreadSummaryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$localSpreadSummaryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LocalSpreadSummaryRef
    = AutoDisposeFutureProviderRef<List<LocalSpreadEntry>>;
String _$analyticsSummaryHash() => r'2c724177bb7f30fe11e0bf57c9f57258d26bce99';

/// See also [analyticsSummary].
@ProviderFor(analyticsSummary)
final analyticsSummaryProvider =
    AutoDisposeFutureProvider<AnalyticsSummary>.internal(
  analyticsSummary,
  name: r'analyticsSummaryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$analyticsSummaryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AnalyticsSummaryRef = AutoDisposeFutureProviderRef<AnalyticsSummary>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
