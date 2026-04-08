import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/features/admin/presentation/providers/admin_providers.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_profile_providers.dart';

/// Administration section — only shown when the current user is an admin.
///
/// Set [embedded] = true when shown inside settings_screen (no AppScaffold).
/// Set [embedded] = false (default) when opened as a standalone screen.
class AdminSettingsScreen extends ConsumerWidget {
  final bool embedded;

  const AdminSettingsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    if (!isAdmin) return const SizedBox.shrink();

    final body = _buildBody(context, ref);
    if (embedded) return body;
    return AppScaffold(title: 'Administration', body: body);
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingRequestCountProvider);
    final pending = pendingAsync.valueOrNull ?? 0;

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.inbox_outlined,
              color: AppColors.primaryGold, size: 22),
          title: const Text(
            'Change Requests',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
          ),
          subtitle: Text(
            pending > 0 ? '$pending pending' : 'No pending requests',
            style: TextStyle(
              color: pending > 0 ? AppColors.primaryGold : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pending > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$pending',
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.textSecondary),
            ],
          ),
          onTap: () {
            // TODO (Phase 6): Navigate to AdminRequestsScreen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Admin requests screen — coming in next phase'),
                backgroundColor: AppColors.backgroundCard,
              ),
            );
          },
        ),
        const Divider(color: Colors.white10, height: 1),
        ListTile(
          leading: const Icon(Icons.manage_accounts_outlined,
              color: AppColors.textSecondary, size: 22),
          title: const Text(
            'Request Removal of Admin Access',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          trailing: const Icon(Icons.chevron_right,
              size: 18, color: AppColors.textSecondary),
          onTap: () => _showRemoveAdminDialog(context, ref),
        ),
      ],
    );
  }

  void _showRemoveAdminDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'Remove Admin Access',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Submit a request to have your administrator privileges removed. '
          'An admin will review and action this request.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // TODO (Phase 6): Use ChangeRequestDialog widget
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Request submitted — coming in next phase'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }
}
