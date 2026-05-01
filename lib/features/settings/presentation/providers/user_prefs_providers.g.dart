// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_prefs_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$globalSpotProvidersHash() =>
    r'b717489e53cbbaf5356c786510b23d0c863172a1';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [globalSpotProviders].
@ProviderFor(globalSpotProviders)
const globalSpotProvidersProvider = GlobalSpotProvidersFamily();

/// See also [globalSpotProviders].
class GlobalSpotProvidersFamily
    extends Family<AsyncValue<List<GlobalSpotProvider>>> {
  /// See also [globalSpotProviders].
  const GlobalSpotProvidersFamily();

  /// See also [globalSpotProviders].
  GlobalSpotProvidersProvider call({
    bool activeOnly = true,
  }) {
    return GlobalSpotProvidersProvider(
      activeOnly: activeOnly,
    );
  }

  @override
  GlobalSpotProvidersProvider getProviderOverride(
    covariant GlobalSpotProvidersProvider provider,
  ) {
    return call(
      activeOnly: provider.activeOnly,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'globalSpotProvidersProvider';
}

/// See also [globalSpotProviders].
class GlobalSpotProvidersProvider
    extends FutureProvider<List<GlobalSpotProvider>> {
  /// See also [globalSpotProviders].
  GlobalSpotProvidersProvider({
    bool activeOnly = true,
  }) : this._internal(
          (ref) => globalSpotProviders(
            ref as GlobalSpotProvidersRef,
            activeOnly: activeOnly,
          ),
          from: globalSpotProvidersProvider,
          name: r'globalSpotProvidersProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$globalSpotProvidersHash,
          dependencies: GlobalSpotProvidersFamily._dependencies,
          allTransitiveDependencies:
              GlobalSpotProvidersFamily._allTransitiveDependencies,
          activeOnly: activeOnly,
        );

  GlobalSpotProvidersProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.activeOnly,
  }) : super.internal();

  final bool activeOnly;

  @override
  Override overrideWith(
    FutureOr<List<GlobalSpotProvider>> Function(GlobalSpotProvidersRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GlobalSpotProvidersProvider._internal(
        (ref) => create(ref as GlobalSpotProvidersRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        activeOnly: activeOnly,
      ),
    );
  }

  @override
  FutureProviderElement<List<GlobalSpotProvider>> createElement() {
    return _GlobalSpotProvidersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GlobalSpotProvidersProvider &&
        other.activeOnly == activeOnly;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, activeOnly.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GlobalSpotProvidersRef on FutureProviderRef<List<GlobalSpotProvider>> {
  /// The parameter `activeOnly` of this provider.
  bool get activeOnly;
}

class _GlobalSpotProvidersProviderElement
    extends FutureProviderElement<List<GlobalSpotProvider>>
    with GlobalSpotProvidersRef {
  _GlobalSpotProvidersProviderElement(super.provider);

  @override
  bool get activeOnly => (origin as GlobalSpotProvidersProvider).activeOnly;
}

String _$userRetailerIdSetHash() => r'a0a735b19bf1888ca825f73a30416c911817d3ec';

/// Set of retailer IDs the user has selected. Empty = no filter applied yet.
///
/// Copied from [userRetailerIdSet].
@ProviderFor(userRetailerIdSet)
final userRetailerIdSetProvider = FutureProvider<Set<String>>.internal(
  userRetailerIdSet,
  name: r'userRetailerIdSetProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userRetailerIdSetHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserRetailerIdSetRef = FutureProviderRef<Set<String>>;
String _$userMetalNameSetHash() => r'aac7eca62e3ccc0b51c69e25e865da87263bf17d';

/// Set of metal type names (e.g. {'gold', 'silver'}) the user has selected.
/// Empty = no filter applied yet.
///
/// Copied from [userMetalNameSet].
@ProviderFor(userMetalNameSet)
final userMetalNameSetProvider = FutureProvider<Set<String>>.internal(
  userMetalNameSet,
  name: r'userMetalNameSetProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userMetalNameSetHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserMetalNameSetRef = FutureProviderRef<Set<String>>;
String _$userGlobalSpotPrefNotifierHash() =>
    r'dffb375c3bf4cdcf7cee359b9a7f1bf0678b7003';

/// See also [UserGlobalSpotPrefNotifier].
@ProviderFor(UserGlobalSpotPrefNotifier)
final userGlobalSpotPrefNotifierProvider = AsyncNotifierProvider<
    UserGlobalSpotPrefNotifier, List<UserGlobalSpotPref>>.internal(
  UserGlobalSpotPrefNotifier.new,
  name: r'userGlobalSpotPrefNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userGlobalSpotPrefNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UserGlobalSpotPrefNotifier = AsyncNotifier<List<UserGlobalSpotPref>>;
String _$userRetailerPrefsNotifierHash() =>
    r'bc7b51a1e4b2d9d5f643f2973cab2028a8a080b6';

/// See also [UserRetailerPrefsNotifier].
@ProviderFor(UserRetailerPrefsNotifier)
final userRetailerPrefsNotifierProvider = AsyncNotifierProvider<
    UserRetailerPrefsNotifier, List<UserRetailerPref>>.internal(
  UserRetailerPrefsNotifier.new,
  name: r'userRetailerPrefsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userRetailerPrefsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UserRetailerPrefsNotifier = AsyncNotifier<List<UserRetailerPref>>;
String _$userMetaltypePrefsNotifierHash() =>
    r'81e0b80d9e35f74c0df8228811ae0cff6595a1f7';

/// See also [UserMetaltypePrefsNotifier].
@ProviderFor(UserMetaltypePrefsNotifier)
final userMetaltypePrefsNotifierProvider = AsyncNotifierProvider<
    UserMetaltypePrefsNotifier, List<UserMetaltypePref>>.internal(
  UserMetaltypePrefsNotifier.new,
  name: r'userMetaltypePrefsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userMetaltypePrefsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UserMetaltypePrefsNotifier = AsyncNotifier<List<UserMetaltypePref>>;
String _$userAnalyticsPrefsNotifierHash() =>
    r'65da103e5dceb85682b2c0b960aefbf37d764e1a';

/// See also [UserAnalyticsPrefsNotifier].
@ProviderFor(UserAnalyticsPrefsNotifier)
final userAnalyticsPrefsNotifierProvider = AsyncNotifierProvider<
    UserAnalyticsPrefsNotifier, UserAnalyticsSettings>.internal(
  UserAnalyticsPrefsNotifier.new,
  name: r'userAnalyticsPrefsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userAnalyticsPrefsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UserAnalyticsPrefsNotifier = AsyncNotifier<UserAnalyticsSettings>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
