// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_profiles_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$getPurityValueHash() => r'95f37fba9889859efa3722b2c7a5fb3446dcbe0f';

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

/// See also [getPurityValue].
@ProviderFor(getPurityValue)
const getPurityValueProvider = GetPurityValueFamily();

/// See also [getPurityValue].
class GetPurityValueFamily extends Family<AsyncValue<double>> {
  /// See also [getPurityValue].
  const GetPurityValueFamily();

  /// See also [getPurityValue].
  GetPurityValueProvider call(
    String input,
  ) {
    return GetPurityValueProvider(
      input,
    );
  }

  @override
  GetPurityValueProvider getProviderOverride(
    covariant GetPurityValueProvider provider,
  ) {
    return call(
      provider.input,
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
  String? get name => r'getPurityValueProvider';
}

/// See also [getPurityValue].
class GetPurityValueProvider extends AutoDisposeFutureProvider<double> {
  /// See also [getPurityValue].
  GetPurityValueProvider(
    String input,
  ) : this._internal(
          (ref) => getPurityValue(
            ref as GetPurityValueRef,
            input,
          ),
          from: getPurityValueProvider,
          name: r'getPurityValueProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$getPurityValueHash,
          dependencies: GetPurityValueFamily._dependencies,
          allTransitiveDependencies:
              GetPurityValueFamily._allTransitiveDependencies,
          input: input,
        );

  GetPurityValueProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.input,
  }) : super.internal();

  final String input;

  @override
  Override overrideWith(
    FutureOr<double> Function(GetPurityValueRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GetPurityValueProvider._internal(
        (ref) => create(ref as GetPurityValueRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        input: input,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<double> createElement() {
    return _GetPurityValueProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GetPurityValueProvider && other.input == input;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, input.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GetPurityValueRef on AutoDisposeFutureProviderRef<double> {
  /// The parameter `input` of this provider.
  String get input;
}

class _GetPurityValueProviderElement
    extends AutoDisposeFutureProviderElement<double> with GetPurityValueRef {
  _GetPurityValueProviderElement(super.provider);

  @override
  String get input => (origin as GetPurityValueProvider).input;
}

String _$productProfilesNotifierHash() =>
    r'683867c910cc6d55ab9e29933f3489804ff82f15';

/// See also [ProductProfilesNotifier].
@ProviderFor(ProductProfilesNotifier)
final productProfilesNotifierProvider = AutoDisposeAsyncNotifierProvider<
    ProductProfilesNotifier, List<ProductProfile>>.internal(
  ProductProfilesNotifier.new,
  name: r'productProfilesNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$productProfilesNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ProductProfilesNotifier
    = AutoDisposeAsyncNotifier<List<ProductProfile>>;
String _$createProductProfileHash() =>
    r'd9884e7cb279918e2f370de9cb3c04895f1e2672';

/// See also [CreateProductProfile].
@ProviderFor(CreateProductProfile)
final createProductProfileProvider = AutoDisposeNotifierProvider<
    CreateProductProfile, AsyncValue<ProductProfile?>>.internal(
  CreateProductProfile.new,
  name: r'createProductProfileProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$createProductProfileHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CreateProductProfile
    = AutoDisposeNotifier<AsyncValue<ProductProfile?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
