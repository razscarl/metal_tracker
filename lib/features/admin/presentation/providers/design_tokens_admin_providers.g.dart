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
String _$semanticTokensResolvedHash() =>
    r'4824a8c97f9c5b865abf54794905ec1e437c37bc';

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

/// See also [semanticTokensResolved].
@ProviderFor(semanticTokensResolved)
const semanticTokensResolvedProvider = SemanticTokensResolvedFamily();

/// See also [semanticTokensResolved].
class SemanticTokensResolvedFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [semanticTokensResolved].
  const SemanticTokensResolvedFamily();

  /// See also [semanticTokensResolved].
  SemanticTokensResolvedProvider call(
    String themeId,
  ) {
    return SemanticTokensResolvedProvider(
      themeId,
    );
  }

  @override
  SemanticTokensResolvedProvider getProviderOverride(
    covariant SemanticTokensResolvedProvider provider,
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
  String? get name => r'semanticTokensResolvedProvider';
}

/// See also [semanticTokensResolved].
class SemanticTokensResolvedProvider
    extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
  /// See also [semanticTokensResolved].
  SemanticTokensResolvedProvider(
    String themeId,
  ) : this._internal(
          (ref) => semanticTokensResolved(
            ref as SemanticTokensResolvedRef,
            themeId,
          ),
          from: semanticTokensResolvedProvider,
          name: r'semanticTokensResolvedProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$semanticTokensResolvedHash,
          dependencies: SemanticTokensResolvedFamily._dependencies,
          allTransitiveDependencies:
              SemanticTokensResolvedFamily._allTransitiveDependencies,
          themeId: themeId,
        );

  SemanticTokensResolvedProvider._internal(
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
    FutureOr<List<Map<String, dynamic>>> Function(
            SemanticTokensResolvedRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SemanticTokensResolvedProvider._internal(
        (ref) => create(ref as SemanticTokensResolvedRef),
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
    return _SemanticTokensResolvedProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SemanticTokensResolvedProvider && other.themeId == themeId;
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
mixin SemanticTokensResolvedRef
    on AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `themeId` of this provider.
  String get themeId;
}

class _SemanticTokensResolvedProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, dynamic>>>
    with SemanticTokensResolvedRef {
  _SemanticTokensResolvedProviderElement(super.provider);

  @override
  String get themeId => (origin as SemanticTokensResolvedProvider).themeId;
}

String _$textStylesAdminHash() => r'80e2ff1a7e5f2abab016f245a7c24798f3da1f72';

/// See also [textStylesAdmin].
@ProviderFor(textStylesAdmin)
const textStylesAdminProvider = TextStylesAdminFamily();

/// See also [textStylesAdmin].
class TextStylesAdminFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [textStylesAdmin].
  const TextStylesAdminFamily();

  /// See also [textStylesAdmin].
  TextStylesAdminProvider call(
    String themeId,
  ) {
    return TextStylesAdminProvider(
      themeId,
    );
  }

  @override
  TextStylesAdminProvider getProviderOverride(
    covariant TextStylesAdminProvider provider,
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
  String? get name => r'textStylesAdminProvider';
}

/// See also [textStylesAdmin].
class TextStylesAdminProvider
    extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
  /// See also [textStylesAdmin].
  TextStylesAdminProvider(
    String themeId,
  ) : this._internal(
          (ref) => textStylesAdmin(
            ref as TextStylesAdminRef,
            themeId,
          ),
          from: textStylesAdminProvider,
          name: r'textStylesAdminProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$textStylesAdminHash,
          dependencies: TextStylesAdminFamily._dependencies,
          allTransitiveDependencies:
              TextStylesAdminFamily._allTransitiveDependencies,
          themeId: themeId,
        );

  TextStylesAdminProvider._internal(
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
    FutureOr<List<Map<String, dynamic>>> Function(TextStylesAdminRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TextStylesAdminProvider._internal(
        (ref) => create(ref as TextStylesAdminRef),
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
    return _TextStylesAdminProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TextStylesAdminProvider && other.themeId == themeId;
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
mixin TextStylesAdminRef
    on AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `themeId` of this provider.
  String get themeId;
}

class _TextStylesAdminProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, dynamic>>>
    with TextStylesAdminRef {
  _TextStylesAdminProviderElement(super.provider);

  @override
  String get themeId => (origin as TextStylesAdminProvider).themeId;
}

String _$primitiveTokensWithValuesHash() =>
    r'ae14820cf49fbb430988616bc781d89d1638e5e2';

/// See also [primitiveTokensWithValues].
@ProviderFor(primitiveTokensWithValues)
const primitiveTokensWithValuesProvider = PrimitiveTokensWithValuesFamily();

/// See also [primitiveTokensWithValues].
class PrimitiveTokensWithValuesFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [primitiveTokensWithValues].
  const PrimitiveTokensWithValuesFamily();

  /// See also [primitiveTokensWithValues].
  PrimitiveTokensWithValuesProvider call(
    String tokenType,
    String themeId,
  ) {
    return PrimitiveTokensWithValuesProvider(
      tokenType,
      themeId,
    );
  }

  @override
  PrimitiveTokensWithValuesProvider getProviderOverride(
    covariant PrimitiveTokensWithValuesProvider provider,
  ) {
    return call(
      provider.tokenType,
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
  String? get name => r'primitiveTokensWithValuesProvider';
}

/// See also [primitiveTokensWithValues].
class PrimitiveTokensWithValuesProvider
    extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
  /// See also [primitiveTokensWithValues].
  PrimitiveTokensWithValuesProvider(
    String tokenType,
    String themeId,
  ) : this._internal(
          (ref) => primitiveTokensWithValues(
            ref as PrimitiveTokensWithValuesRef,
            tokenType,
            themeId,
          ),
          from: primitiveTokensWithValuesProvider,
          name: r'primitiveTokensWithValuesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$primitiveTokensWithValuesHash,
          dependencies: PrimitiveTokensWithValuesFamily._dependencies,
          allTransitiveDependencies:
              PrimitiveTokensWithValuesFamily._allTransitiveDependencies,
          tokenType: tokenType,
          themeId: themeId,
        );

  PrimitiveTokensWithValuesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.tokenType,
    required this.themeId,
  }) : super.internal();

  final String tokenType;
  final String themeId;

  @override
  Override overrideWith(
    FutureOr<List<Map<String, dynamic>>> Function(
            PrimitiveTokensWithValuesRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PrimitiveTokensWithValuesProvider._internal(
        (ref) => create(ref as PrimitiveTokensWithValuesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        tokenType: tokenType,
        themeId: themeId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _PrimitiveTokensWithValuesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PrimitiveTokensWithValuesProvider &&
        other.tokenType == tokenType &&
        other.themeId == themeId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, tokenType.hashCode);
    hash = _SystemHash.combine(hash, themeId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PrimitiveTokensWithValuesRef
    on AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `tokenType` of this provider.
  String get tokenType;

  /// The parameter `themeId` of this provider.
  String get themeId;
}

class _PrimitiveTokensWithValuesProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, dynamic>>>
    with PrimitiveTokensWithValuesRef {
  _PrimitiveTokensWithValuesProviderElement(super.provider);

  @override
  String get tokenType =>
      (origin as PrimitiveTokensWithValuesProvider).tokenType;
  @override
  String get themeId => (origin as PrimitiveTokensWithValuesProvider).themeId;
}

String _$semanticColorTokensHash() =>
    r'125c35ad3f08a4c3f62621b71331bdb3ca700143';

/// See also [semanticColorTokens].
@ProviderFor(semanticColorTokens)
const semanticColorTokensProvider = SemanticColorTokensFamily();

/// See also [semanticColorTokens].
class SemanticColorTokensFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [semanticColorTokens].
  const SemanticColorTokensFamily();

  /// See also [semanticColorTokens].
  SemanticColorTokensProvider call(
    String themeId,
  ) {
    return SemanticColorTokensProvider(
      themeId,
    );
  }

  @override
  SemanticColorTokensProvider getProviderOverride(
    covariant SemanticColorTokensProvider provider,
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
  String? get name => r'semanticColorTokensProvider';
}

/// See also [semanticColorTokens].
class SemanticColorTokensProvider
    extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
  /// See also [semanticColorTokens].
  SemanticColorTokensProvider(
    String themeId,
  ) : this._internal(
          (ref) => semanticColorTokens(
            ref as SemanticColorTokensRef,
            themeId,
          ),
          from: semanticColorTokensProvider,
          name: r'semanticColorTokensProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$semanticColorTokensHash,
          dependencies: SemanticColorTokensFamily._dependencies,
          allTransitiveDependencies:
              SemanticColorTokensFamily._allTransitiveDependencies,
          themeId: themeId,
        );

  SemanticColorTokensProvider._internal(
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
    FutureOr<List<Map<String, dynamic>>> Function(
            SemanticColorTokensRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SemanticColorTokensProvider._internal(
        (ref) => create(ref as SemanticColorTokensRef),
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
    return _SemanticColorTokensProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SemanticColorTokensProvider && other.themeId == themeId;
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
mixin SemanticColorTokensRef
    on AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `themeId` of this provider.
  String get themeId;
}

class _SemanticColorTokensProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, dynamic>>>
    with SemanticColorTokensRef {
  _SemanticColorTokensProviderElement(super.provider);

  @override
  String get themeId => (origin as SemanticColorTokensProvider).themeId;
}

String _$semanticTokensByTypeHash() =>
    r'e0253db766e8a44f600a7dfd33fafb4f21e129cf';

/// See also [semanticTokensByType].
@ProviderFor(semanticTokensByType)
const semanticTokensByTypeProvider = SemanticTokensByTypeFamily();

/// See also [semanticTokensByType].
class SemanticTokensByTypeFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [semanticTokensByType].
  const SemanticTokensByTypeFamily();

  /// See also [semanticTokensByType].
  SemanticTokensByTypeProvider call(
    String tokenType,
    String themeId,
  ) {
    return SemanticTokensByTypeProvider(
      tokenType,
      themeId,
    );
  }

  @override
  SemanticTokensByTypeProvider getProviderOverride(
    covariant SemanticTokensByTypeProvider provider,
  ) {
    return call(
      provider.tokenType,
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
  String? get name => r'semanticTokensByTypeProvider';
}

/// See also [semanticTokensByType].
class SemanticTokensByTypeProvider
    extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
  /// See also [semanticTokensByType].
  SemanticTokensByTypeProvider(
    String tokenType,
    String themeId,
  ) : this._internal(
          (ref) => semanticTokensByType(
            ref as SemanticTokensByTypeRef,
            tokenType,
            themeId,
          ),
          from: semanticTokensByTypeProvider,
          name: r'semanticTokensByTypeProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$semanticTokensByTypeHash,
          dependencies: SemanticTokensByTypeFamily._dependencies,
          allTransitiveDependencies:
              SemanticTokensByTypeFamily._allTransitiveDependencies,
          tokenType: tokenType,
          themeId: themeId,
        );

  SemanticTokensByTypeProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.tokenType,
    required this.themeId,
  }) : super.internal();

  final String tokenType;
  final String themeId;

  @override
  Override overrideWith(
    FutureOr<List<Map<String, dynamic>>> Function(
            SemanticTokensByTypeRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SemanticTokensByTypeProvider._internal(
        (ref) => create(ref as SemanticTokensByTypeRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        tokenType: tokenType,
        themeId: themeId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _SemanticTokensByTypeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SemanticTokensByTypeProvider &&
        other.tokenType == tokenType &&
        other.themeId == themeId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, tokenType.hashCode);
    hash = _SystemHash.combine(hash, themeId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SemanticTokensByTypeRef
    on AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `tokenType` of this provider.
  String get tokenType;

  /// The parameter `themeId` of this provider.
  String get themeId;
}

class _SemanticTokensByTypeProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, dynamic>>>
    with SemanticTokensByTypeRef {
  _SemanticTokensByTypeProviderElement(super.provider);

  @override
  String get tokenType => (origin as SemanticTokensByTypeProvider).tokenType;
  @override
  String get themeId => (origin as SemanticTokensByTypeProvider).themeId;
}

String _$tokenValueEditorHash() => r'f94cd606346feeeab418abd812988bceabfd1ef0';

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
String _$textStyleEditorHash() => r'4ba27a78aa671a8d4504823f57a983de8cf3905b';

/// See also [TextStyleEditor].
@ProviderFor(TextStyleEditor)
final textStyleEditorProvider =
    AutoDisposeAsyncNotifierProvider<TextStyleEditor, void>.internal(
  TextStyleEditor.new,
  name: r'textStyleEditorProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$textStyleEditorHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TextStyleEditor = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
