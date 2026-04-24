// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'investment_guide_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$investmentGuideContextHash() =>
    r'77696415c2f17d286f297faf864a4351021ebf45';

/// See also [investmentGuideContext].
@ProviderFor(investmentGuideContext)
final investmentGuideContextProvider =
    AutoDisposeFutureProvider<InvestmentGuideContext>.internal(
  investmentGuideContext,
  name: r'investmentGuideContextProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$investmentGuideContextHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef InvestmentGuideContextRef
    = AutoDisposeFutureProviderRef<InvestmentGuideContext>;
String _$investmentGuideNotifierHash() =>
    r'0df238b35fff8b00d031ab5047516d2077ccb78a';

/// See also [InvestmentGuideNotifier].
@ProviderFor(InvestmentGuideNotifier)
final investmentGuideNotifierProvider = AutoDisposeNotifierProvider<
    InvestmentGuideNotifier,
    AsyncValue<List<InvestmentRecommendation>>>.internal(
  InvestmentGuideNotifier.new,
  name: r'investmentGuideNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$investmentGuideNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$InvestmentGuideNotifier
    = AutoDisposeNotifier<AsyncValue<List<InvestmentRecommendation>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
