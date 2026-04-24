import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/features/admin/data/models/automation_config_model.dart';
import 'package:metal_tracker/features/admin/data/models/automation_job_model.dart';
import 'package:metal_tracker/features/admin/data/models/automation_schedule_model.dart';
import 'package:metal_tracker/features/admin/data/models/change_request_model.dart';
import 'package:metal_tracker/features/product_listings/data/models/product_listing_status_model.dart';
import 'package:metal_tracker/features/settings/data/models/user_profile_model.dart';

part 'admin_providers.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Pending change request count — shown as badge on admin drawer item
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Future<int> pendingRequestCount(PendingRequestCountRef ref) async {
  // Also depends on the requests notifier so it updates after any admin action
  ref.watch(adminChangeRequestsNotifierProvider());
  final repo = ref.watch(changeRequestRepositoryProvider);
  return repo.getPendingCount();
}

// ─────────────────────────────────────────────────────────────────────────────
// All change requests — admin view
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
class AdminChangeRequestsNotifier extends _$AdminChangeRequestsNotifier {
  @override
  Future<List<ChangeRequest>> build({String? status}) async {
    final repo = ref.watch(changeRequestRepositoryProvider);
    return repo.getAllRequests(status: status);
  }

  Future<void> updateRequest({
    required String id,
    required String status,
    String? adminNotes,
  }) async {
    final repo = ref.read(changeRequestRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repo.updateRequest(
        id: id,
        status: status,
        adminNotes: adminNotes,
      );
      return repo.getAllRequests(status: this.status);
    });
    // Invalidate the count badge
    ref.invalidateSelf();
    ref.invalidate(pendingRequestCountProvider);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// My change requests — user view
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Future<List<ChangeRequest>> myChangeRequests(MyChangeRequestsRef ref) async {
  final repo = ref.watch(changeRequestRepositoryProvider);
  return repo.getMyRequests();
}

// ─────────────────────────────────────────────────────────────────────────────
// Pending user approvals — admin view
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Future<int> pendingUserCount(PendingUserCountRef ref) async {
  ref.watch(pendingUsersNotifierProvider);
  final repo = ref.watch(userProfileRepositoryProvider);
  final users = await repo.getUsersByStatus('pending');
  return users.length;
}

@riverpod
class PendingUsersNotifier extends _$PendingUsersNotifier {
  @override
  Future<List<UserProfile>> build() async {
    final repo = ref.watch(userProfileRepositoryProvider);
    return repo.getUsersByStatus('pending');
  }

  Future<void> approveUser(String userId) async {
    final repo = ref.read(userProfileRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repo.updateUserStatus(userId, 'approved');
      return repo.getUsersByStatus('pending');
    });
    ref.invalidate(pendingUserCountProvider);
    ref.invalidate(pendingRequestCountProvider);
  }

  Future<void> rejectUser(String userId) async {
    final repo = ref.read(userProfileRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repo.updateUserStatus(userId, 'rejected');
      return repo.getUsersByStatus('pending');
    });
    ref.invalidate(pendingUserCountProvider);
    ref.invalidate(pendingRequestCountProvider);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Automation — Config, Schedules, Jobs
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
class AutomationConfigNotifier extends _$AutomationConfigNotifier {
  @override
  Future<AutomationConfig?> build() async {
    return ref.read(automationRepositoryProvider).getConfig();
  }

  Future<void> toggleEnabled(bool enabled) async {
    final config = state.valueOrNull;
    if (config == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(automationRepositoryProvider)
          .updateConfig(config.id, enabled: enabled);
      return ref.read(automationRepositoryProvider).getConfig();
    });
  }

  Future<void> updateTimezone(String timezone) async {
    final config = state.valueOrNull;
    if (config == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(automationRepositoryProvider)
          .updateConfig(config.id, timezone: timezone);
      return ref.read(automationRepositoryProvider).getConfig();
    });
  }
}

@riverpod
class AutomationSchedulesNotifier extends _$AutomationSchedulesNotifier {
  @override
  Future<List<AutomationSchedule>> build() async {
    return ref.read(automationRepositoryProvider).getSchedules();
  }

  Future<void> toggleSchedule(String id, {required bool enabled}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(automationRepositoryProvider)
          .updateSchedule(id, enabled: enabled);
      return ref.read(automationRepositoryProvider).getSchedules();
    });
  }

  Future<void> updateRunTimes(String id, List<String> runTimes) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(automationRepositoryProvider)
          .updateSchedule(id, runTimes: runTimes);
      return ref.read(automationRepositoryProvider).getSchedules();
    });
  }
}

@riverpod
class AutomationJobsNotifier extends _$AutomationJobsNotifier {
  @override
  Future<List<AutomationJob>> build() async {
    return ref.read(automationRepositoryProvider).getJobs(limit: 150);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(automationRepositoryProvider).getJobs(limit: 150),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product Listing Status rules — admin CRUD
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
class ProductListingStatusesNotifier extends _$ProductListingStatusesNotifier {
  @override
  Future<List<ProductListingStatus>> build() async {
    final repo = ref.watch(productListingsRepositoryProvider);
    return repo.getStatusRules();
  }

  Future<void> addRule({
    required String capturedStatus,
    required String storedStatus,
    required String displayLabel,
  }) async {
    final repo = ref.read(productListingsRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repo.createStatusRule(
        capturedStatus: capturedStatus,
        storedStatus: storedStatus,
        displayLabel: displayLabel,
      );
      return repo.getStatusRules();
    });
  }

  Future<void> toggleRule(String id, bool isActive) async {
    final repo = ref.read(productListingsRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repo.toggleStatusRule(id, isActive);
      return repo.getStatusRules();
    });
  }

  Future<void> deleteRule(String id) async {
    final repo = ref.read(productListingsRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repo.deleteStatusRule(id);
      return repo.getStatusRules();
    });
  }
}
