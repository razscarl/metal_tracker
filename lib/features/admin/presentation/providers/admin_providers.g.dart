// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pendingRequestCountHash() =>
    r'8e19c97a4b2956c1f7c305f13e84bfd757aba4ef';

/// See also [pendingRequestCount].
@ProviderFor(pendingRequestCount)
final pendingRequestCountProvider = AutoDisposeFutureProvider<int>.internal(
  pendingRequestCount,
  name: r'pendingRequestCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingRequestCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendingRequestCountRef = AutoDisposeFutureProviderRef<int>;
String _$myChangeRequestsHash() => r'2e306bbfaef549ab26b0e3f5882a0584bdbe178d';

/// See also [myChangeRequests].
@ProviderFor(myChangeRequests)
final myChangeRequestsProvider =
    AutoDisposeFutureProvider<List<ChangeRequest>>.internal(
  myChangeRequests,
  name: r'myChangeRequestsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$myChangeRequestsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MyChangeRequestsRef = AutoDisposeFutureProviderRef<List<ChangeRequest>>;
String _$pendingUserCountHash() => r'2161829f4aaba787c4441eb332668e6dc591a3b9';

/// See also [pendingUserCount].
@ProviderFor(pendingUserCount)
final pendingUserCountProvider = AutoDisposeFutureProvider<int>.internal(
  pendingUserCount,
  name: r'pendingUserCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingUserCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendingUserCountRef = AutoDisposeFutureProviderRef<int>;
String _$adminChangeRequestsNotifierHash() =>
    r'528d3f27a655ffec770be490458ebc5af53582c4';

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

abstract class _$AdminChangeRequestsNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<ChangeRequest>> {
  late final String? status;

  FutureOr<List<ChangeRequest>> build({
    String? status,
  });
}

/// See also [AdminChangeRequestsNotifier].
@ProviderFor(AdminChangeRequestsNotifier)
const adminChangeRequestsNotifierProvider = AdminChangeRequestsNotifierFamily();

/// See also [AdminChangeRequestsNotifier].
class AdminChangeRequestsNotifierFamily
    extends Family<AsyncValue<List<ChangeRequest>>> {
  /// See also [AdminChangeRequestsNotifier].
  const AdminChangeRequestsNotifierFamily();

  /// See also [AdminChangeRequestsNotifier].
  AdminChangeRequestsNotifierProvider call({
    String? status,
  }) {
    return AdminChangeRequestsNotifierProvider(
      status: status,
    );
  }

  @override
  AdminChangeRequestsNotifierProvider getProviderOverride(
    covariant AdminChangeRequestsNotifierProvider provider,
  ) {
    return call(
      status: provider.status,
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
  String? get name => r'adminChangeRequestsNotifierProvider';
}

/// See also [AdminChangeRequestsNotifier].
class AdminChangeRequestsNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<AdminChangeRequestsNotifier,
        List<ChangeRequest>> {
  /// See also [AdminChangeRequestsNotifier].
  AdminChangeRequestsNotifierProvider({
    String? status,
  }) : this._internal(
          () => AdminChangeRequestsNotifier()..status = status,
          from: adminChangeRequestsNotifierProvider,
          name: r'adminChangeRequestsNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$adminChangeRequestsNotifierHash,
          dependencies: AdminChangeRequestsNotifierFamily._dependencies,
          allTransitiveDependencies:
              AdminChangeRequestsNotifierFamily._allTransitiveDependencies,
          status: status,
        );

  AdminChangeRequestsNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.status,
  }) : super.internal();

  final String? status;

  @override
  FutureOr<List<ChangeRequest>> runNotifierBuild(
    covariant AdminChangeRequestsNotifier notifier,
  ) {
    return notifier.build(
      status: status,
    );
  }

  @override
  Override overrideWith(AdminChangeRequestsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: AdminChangeRequestsNotifierProvider._internal(
        () => create()..status = status,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        status: status,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<AdminChangeRequestsNotifier,
      List<ChangeRequest>> createElement() {
    return _AdminChangeRequestsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AdminChangeRequestsNotifierProvider &&
        other.status == status;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, status.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AdminChangeRequestsNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<ChangeRequest>> {
  /// The parameter `status` of this provider.
  String? get status;
}

class _AdminChangeRequestsNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<AdminChangeRequestsNotifier,
        List<ChangeRequest>> with AdminChangeRequestsNotifierRef {
  _AdminChangeRequestsNotifierProviderElement(super.provider);

  @override
  String? get status => (origin as AdminChangeRequestsNotifierProvider).status;
}

String _$pendingUsersNotifierHash() =>
    r'b4ed2634bd90eba33a5abd7168173f57f03e22d6';

/// See also [PendingUsersNotifier].
@ProviderFor(PendingUsersNotifier)
final pendingUsersNotifierProvider = AutoDisposeAsyncNotifierProvider<
    PendingUsersNotifier, List<UserProfile>>.internal(
  PendingUsersNotifier.new,
  name: r'pendingUsersNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingUsersNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PendingUsersNotifier = AutoDisposeAsyncNotifier<List<UserProfile>>;
String _$automationConfigNotifierHash() =>
    r'512715b0379fd368791090fc0773d4b0f7f45988';

/// See also [AutomationConfigNotifier].
@ProviderFor(AutomationConfigNotifier)
final automationConfigNotifierProvider = AutoDisposeAsyncNotifierProvider<
    AutomationConfigNotifier, AutomationConfig?>.internal(
  AutomationConfigNotifier.new,
  name: r'automationConfigNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$automationConfigNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AutomationConfigNotifier
    = AutoDisposeAsyncNotifier<AutomationConfig?>;
String _$automationSchedulesNotifierHash() =>
    r'd4e8b642727c343c0f40163352738f6ed463b667';

/// See also [AutomationSchedulesNotifier].
@ProviderFor(AutomationSchedulesNotifier)
final automationSchedulesNotifierProvider = AutoDisposeAsyncNotifierProvider<
    AutomationSchedulesNotifier, List<AutomationSchedule>>.internal(
  AutomationSchedulesNotifier.new,
  name: r'automationSchedulesNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$automationSchedulesNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AutomationSchedulesNotifier
    = AutoDisposeAsyncNotifier<List<AutomationSchedule>>;
String _$automationJobsNotifierHash() =>
    r'582522fd75461d7812c7377dc5ccf8cc862edafd';

/// See also [AutomationJobsNotifier].
@ProviderFor(AutomationJobsNotifier)
final automationJobsNotifierProvider = AutoDisposeAsyncNotifierProvider<
    AutomationJobsNotifier, List<AutomationJob>>.internal(
  AutomationJobsNotifier.new,
  name: r'automationJobsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$automationJobsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AutomationJobsNotifier
    = AutoDisposeAsyncNotifier<List<AutomationJob>>;
String _$productListingStatusesNotifierHash() =>
    r'129f0070973b4f0a608d4d2219a413011444a345';

/// See also [ProductListingStatusesNotifier].
@ProviderFor(ProductListingStatusesNotifier)
final productListingStatusesNotifierProvider = AutoDisposeAsyncNotifierProvider<
    ProductListingStatusesNotifier, List<ProductListingStatus>>.internal(
  ProductListingStatusesNotifier.new,
  name: r'productListingStatusesNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$productListingStatusesNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ProductListingStatusesNotifier
    = AutoDisposeAsyncNotifier<List<ProductListingStatus>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
