// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$gsrHistoryHash() => r'cef228fdae02e5176e05a0ddc6a07036b466afbd';

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
    r'db17d3bc1cd0305bb66d6edbe7ffb75d0a414f7e';

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
String _$dealerSpreadHistoryHash() =>
    r'b70cfcf87a8f9caf9cd0e711d2a9f568b572aa13';

/// See also [dealerSpreadHistory].
@ProviderFor(dealerSpreadHistory)
final dealerSpreadHistoryProvider =
    AutoDisposeFutureProvider<List<DealerSpreadEntry>>.internal(
  dealerSpreadHistory,
  name: r'dealerSpreadHistoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dealerSpreadHistoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DealerSpreadHistoryRef
    = AutoDisposeFutureProviderRef<List<DealerSpreadEntry>>;
String _$dealerSpreadSummaryHash() =>
    r'123925cb4e8501689a18148dfa9aad1879531d55';

/// Returns the most recent spread entry for each metal.
///
/// Copied from [dealerSpreadSummary].
@ProviderFor(dealerSpreadSummary)
final dealerSpreadSummaryProvider =
    AutoDisposeFutureProvider<List<DealerSpreadEntry>>.internal(
  dealerSpreadSummary,
  name: r'dealerSpreadSummaryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dealerSpreadSummaryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DealerSpreadSummaryRef
    = AutoDisposeFutureProviderRef<List<DealerSpreadEntry>>;
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
