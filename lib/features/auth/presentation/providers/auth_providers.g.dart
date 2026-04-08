// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentAuthUserHash() => r'd2da101a57d9dc6c44c11ef618f4bfb6fd62a678';

/// See also [currentAuthUser].
@ProviderFor(currentAuthUser)
final currentAuthUserProvider = AutoDisposeProvider<AuthUser?>.internal(
  currentAuthUser,
  name: r'currentAuthUserProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentAuthUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentAuthUserRef = AutoDisposeProviderRef<AuthUser?>;
String _$authNotifierHash() => r'2e68c987e9fc9d11b282828c2e7fd064333c44d4';

/// See also [AuthNotifier].
@ProviderFor(AuthNotifier)
final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, void>.internal(
  AuthNotifier.new,
  name: r'authNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$authNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AuthNotifier = AsyncNotifier<void>;
String _$sessionTimeoutHash() => r'e72b6f9c7dd453cc56595e76408c2b4fb5133d79';

/// See also [SessionTimeout].
@ProviderFor(SessionTimeout)
final sessionTimeoutProvider =
    AsyncNotifierProvider<SessionTimeout, int>.internal(
  SessionTimeout.new,
  name: r'sessionTimeoutProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sessionTimeoutHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SessionTimeout = AsyncNotifier<int>;
String _$savedEmailHash() => r'bb41d1f4a6f4b5d1b903c50cb31f74d1fbcfe57e';

/// See also [SavedEmail].
@ProviderFor(SavedEmail)
final savedEmailProvider = AsyncNotifierProvider<SavedEmail, String?>.internal(
  SavedEmail.new,
  name: r'savedEmailProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$savedEmailHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SavedEmail = AsyncNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
