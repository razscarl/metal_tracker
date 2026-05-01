// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spot_prices_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$spotPricesNotifierHash() =>
    r'3df8bed33dd05a980043749e86e92a2a21330011';

/// See also [SpotPricesNotifier].
@ProviderFor(SpotPricesNotifier)
final spotPricesNotifierProvider = AutoDisposeAsyncNotifierProvider<
    SpotPricesNotifier, List<SpotPrice>>.internal(
  SpotPricesNotifier.new,
  name: r'spotPricesNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$spotPricesNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SpotPricesNotifier = AutoDisposeAsyncNotifier<List<SpotPrice>>;
String _$apiSettingsNotifierHash() =>
    r'868a27d4b91538eeaa5cc7c0f1b82fa4a8b256f9';

/// See also [ApiSettingsNotifier].
@ProviderFor(ApiSettingsNotifier)
final apiSettingsNotifierProvider = AutoDisposeAsyncNotifierProvider<
    ApiSettingsNotifier, List<GlobalSpotPriceApiSetting>>.internal(
  ApiSettingsNotifier.new,
  name: r'apiSettingsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$apiSettingsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ApiSettingsNotifier
    = AutoDisposeAsyncNotifier<List<GlobalSpotPriceApiSetting>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
