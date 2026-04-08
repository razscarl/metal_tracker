import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/features/settings/data/models/user_profile_model.dart';

part 'user_profile_providers.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// User profile — kept alive because it is read on every screen
// ─────────────────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class UserProfileNotifier extends _$UserProfileNotifier {
  @override
  Future<UserProfile?> build() async {
    final repo = ref.watch(userProfileRepositoryProvider);
    return repo.getProfile();
  }

  /// Called after onboarding completes or when the user edits their profile.
  Future<void> upsert({required String username, String? phone}) async {
    final repo = ref.read(userProfileRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () async => repo.upsertProfile(username: username, phone: phone),
    );
  }

  Future<void> saveProfile({String? username, String? phone}) async {
    final repo = ref.read(userProfileRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () async => repo.updateProfile(username: username, phone: phone),
    );
  }

  /// Call after sign-out to clear cached profile.
  void clear() => state = const AsyncData(null);
}

// ─────────────────────────────────────────────────────────────────────────────
// isAdmin — derived from userProfileNotifier; kept alive for global gating
// ─────────────────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
bool isAdmin(IsAdminRef ref) {
  final profileAsync = ref.watch(userProfileNotifierProvider);
  return profileAsync.valueOrNull?.isAdmin ?? false;
}
