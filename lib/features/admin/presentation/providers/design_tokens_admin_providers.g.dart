// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'design_tokens_admin_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allDesignThemesHash() => r'63a2dde3f26218805b14103bac562546fe2c1d7d';

/// See also [allDesignThemes].
@ProviderFor(allDesignThemes)
final allDesignThemesProvider =
    AutoDisposeFutureProvider<List<Map<String, dynamic>>>.internal(
  allDesignThemes,
  name: r'allDesignThemesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$allDesignThemesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllDesignThemesRef
    = AutoDisposeFutureProviderRef<List<Map<String, dynamic>>>;
String _$designTokensAdminHash() => r'b68bfd76a98c89210a04a6a3eaa570e99581681f';

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

/// See also [designTokensAdmin].
@ProviderFor(designTokensAdmin)
const designTokensAdminProvider = DesignTokensAdminFamily();

/// See also [designTokensAdmin].
class DesignTokensAdminFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [designTokensAdmin].
  const DesignTokensAdminFamily();

  /// See also [designTokensAdmin].
  DesignTokensAdminProvider call(
    String themeId,
  ) {
    return DesignTokensAdminProvider(
      themeId,
    );
  }

  @override
  DesignTokensAdminProvider getProviderOverride(
    covariant DesignTokensAdminProvider provider,
  ) {
    return call(
      provider.themeId,
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
  String? get name => r'designTokensAdminProvider';
}

/// See also [designTokensAdmin].
class DesignTokensAdminProvider
    extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
  /// See also [designTokensAdmin].
  DesignTokensAdminProvider(
    String themeId,
  ) : this._internal(
          (ref) => designTokensAdmin(
            ref as DesignTokensAdminRef,
            themeId,
          ),
          from: designTokensAdminProvider,
          name: r'designTokensAdminProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$designTokensAdminHash,
          dependencies: DesignTokensAdminFamily._dependencies,
          allTransitiveDependencies:
              DesignTokensAdminFamily._allTransitiveDependencies,
          themeId: themeId,
        );

  DesignTokensAdminProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.themeId,
  }) : super.internal();

  final String themeId;

  @override
  Override overrideWith(
    FutureOr<List<Map<String, dynamic>>> Function(DesignTokensAdminRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DesignTokensAdminProvider._internal(
        (ref) => create(ref as DesignTokensAdminRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        themeId: themeId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _DesignTokensAdminProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DesignTokensAdminProvider && other.themeId == themeId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, themeId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DesignTokensAdminRef
    on AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `themeId` of this provider.
  String get themeId;
}

class _DesignTokensAdminProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, dynamic>>>
    with DesignTokensAdminRef {
  _DesignTokensAdminProviderElement(super.provider);

  @override
  String get themeId => (origin as DesignTokensAdminProvider).themeId;
}

String _$primitiveTokensByTypeHash() =>
    r'ca9f275ca197ad79b4d0444cdf4749c1bdd3927c';

/// See also [primitiveTokensByType].
@ProviderFor(primitiveTokensByType)
const primitiveTokensByTypeProvider = PrimitiveTokensByTypeFamily();

/// See also [primitiveTokensByType].
class PrimitiveTokensByTypeFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [primitiveTokensByType].
  const PrimitiveTokensByTypeFamily();

  /// See also [primitiveTokensByType].
  PrimitiveTokensByTypeProvider call(
    String tokenType,
  ) {
    return PrimitiveTokensByTypeProvider(
      tokenType,
    );
  }

  @override
  PrimitiveTokensByTypeProvider getProviderOverride(
    covariant PrimitiveTokensByTypeProvider provider,
  ) {
    return call(
      provider.tokenType,
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
  String? get name => r'primitiveTokensByTypeProvider';
}

/// See also [primitiveTokensByType].
class PrimitiveTokensByTypeProvider
    extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
  /// See also [primitiveTokensByType].
  PrimitiveTokensByTypeProvider(
    String tokenType,
  ) : this._internal(
          (ref) => primitiveTokensByType(
            ref as PrimitiveTokensByTypeRef,
            tokenType,
          ),
          from: primitiveTokensByTypeProvider,
          name: r'primitiveTokensByTypeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$primitiveTokensByTypeHash,
          dependencies: PrimitiveTokensByTypeFamily._dependencies,
          allTransitiveDependencies:
              PrimitiveTokensByTypeFamily._allTransitiveDependencies,
          tokenType: tokenType,
        );

  PrimitiveTokensByTypeProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.tokenType,
  }) : super.internal();

  final String tokenType;

  @override
  Override overrideWith(
    FutureOr<List<Map<String, dynamic>>> Function(
            PrimitiveTokensByTypeRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PrimitiveTokensByTypeProvider._internal(
        (ref) => create(ref as PrimitiveTokensByTypeRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        tokenType: tokenType,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _PrimitiveTokensByTypeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PrimitiveTokensByTypeProvider &&
        other.tokenType == tokenType;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, tokenType.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PrimitiveTokensByTypeRef
    on AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `tokenType` of this provider.
  String get tokenType;
}

class _PrimitiveTokensByTypeProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, dynamic>>>
    with PrimitiveTokensByTypeRef {
  _PrimitiveTokensByTypeProviderElement(super.provider);

  @override
  String get tokenType => (origin as PrimitiveTokensByTypeProvider).tokenType;
}

String _$tokenValueEditorHash() => r'ac1399919fd1ec7b2d0aeccb0808f4add5e26d05';

/// See also [TokenValueEditor].
@ProviderFor(TokenValueEditor)
final tokenValueEditorProvider =
    AutoDisposeAsyncNotifierProvider<TokenValueEditor, void>.internal(
  TokenValueEditor.new,
  name: r'tokenValueEditorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$tokenValueEditorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TokenValueEditor = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
