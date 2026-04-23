// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_prefs_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userLocalSpotPrefsHash() =>
    r'5bf1842bcb8c5f7f7451a0a1780c74cd5c781af6';

/// See also [userLocalSpotPrefs].
@ProviderFor(userLocalSpotPrefs)
final userLocalSpotPrefsProvider =
    FutureProvider<List<UserLocalSpotPref>>.internal(
  userLocalSpotPrefs,
  name: r'userLocalSpotPrefsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userLocalSpotPrefsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserLocalSpotPrefsRef = FutureProviderRef<List<UserLocalSpotPref>>;
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

String _$userMetalTypesNotifierHash() =>
    r'3290b3c4906614e58ba5919166a0010c14650ed7';

/// See also [UserMetalTypesNotifier].
@ProviderFor(UserMetalTypesNotifier)
final userMetalTypesNotifierProvider =
    AsyncNotifierProvider<UserMetalTypesNotifier, List<String>>.internal(
  UserMetalTypesNotifier.new,
  name: r'userMetalTypesNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userMetalTypesNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UserMetalTypesNotifier = AsyncNotifier<List<String>>;
String _$userRetailersNotifierHash() =>
    r'd77da51a78cc2ca373a0fd7339bdc436068a7bf2';

/// See also [UserRetailersNotifier].
@ProviderFor(UserRetailersNotifier)
final userRetailersNotifierProvider =
    AsyncNotifierProvider<UserRetailersNotifier, List<UserRetailer>>.internal(
  UserRetailersNotifier.new,
  name: r'userRetailersNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userRetailersNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UserRetailersNotifier = AsyncNotifier<List<UserRetailer>>;
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
String _$userAnalyticsSettingsNotifierHash() =>
    r'bc0f1b467979c0914074013719e8490e45472965';

/// See also [UserAnalyticsSettingsNotifier].
@ProviderFor(UserAnalyticsSettingsNotifier)
final userAnalyticsSettingsNotifierProvider = AsyncNotifierProvider<
    UserAnalyticsSettingsNotifier, UserAnalyticsSettings>.internal(
  UserAnalyticsSettingsNotifier.new,
  name: r'userAnalyticsSettingsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userAnalyticsSettingsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UserAnalyticsSettingsNotifier = AsyncNotifier<UserAnalyticsSettings>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
