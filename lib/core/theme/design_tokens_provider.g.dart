// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'design_tokens_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$designTokensRepositoryHash() =>
    r'885b10d65113f73e6bc57c95030ac3c4e8156957';

/// See also [designTokensRepository].
@ProviderFor(designTokensRepository)
final designTokensRepositoryProvider =
    Provider<DesignTokensRepository>.internal(
  designTokensRepository,
  name: r'designTokensRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$designTokensRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DesignTokensRepositoryRef = ProviderRef<DesignTokensRepository>;
String _$activeThemeIdHash() => r'ea8d0e98eebfb034db36ffc5f20aa53fbbc19ac7';

/// See also [activeThemeId].
@ProviderFor(activeThemeId)
final activeThemeIdProvider = FutureProvider<String>.internal(
  activeThemeId,
  name: r'activeThemeIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeThemeIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveThemeIdRef = FutureProviderRef<String>;
String _$designTokensHash() => r'ff65e69131c53bcedc9e5afebe34a83ee71785b5';

/// See also [designTokens].
@ProviderFor(designTokens)
final designTokensProvider = FutureProvider<DesignTokens>.internal(
  designTokens,
  name: r'designTokensProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$designTokensHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DesignTokensRef = FutureProviderRef<DesignTokens>;
String _$availableThemesHash() => r'0dee60c7b1707e38c9e78ae3cf403228dda6ea38';

/// See also [availableThemes].
@ProviderFor(availableThemes)
final availableThemesProvider =
    AutoDisposeFutureProvider<List<Map<String, dynamic>>>.internal(
  availableThemes,
  name: r'availableThemesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$availableThemesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AvailableThemesRef
    = AutoDisposeFutureProviderRef<List<Map<String, dynamic>>>;
String _$themeSwitchNotifierHash() =>
    r'bf931a233e9b45de9d8c1ae630056c51be39fd7f';

/// See also [ThemeSwitchNotifier].
@ProviderFor(ThemeSwitchNotifier)
final themeSwitchNotifierProvider =
    AutoDisposeAsyncNotifierProvider<ThemeSwitchNotifier, void>.internal(
  ThemeSwitchNotifier.new,
  name: r'themeSwitchNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$themeSwitchNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ThemeSwitchNotifier = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
