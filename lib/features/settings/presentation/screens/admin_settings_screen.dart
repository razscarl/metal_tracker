import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/features/admin/presentation/providers/admin_providers.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_profile_providers.dart';

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
    final cs          = Theme.of(context).colorScheme;
    final pendingAsync = ref.watch(pendingRequestCountProvider);
    final pending     = pendingAsync.valueOrNull ?? 0;

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.inbox_outlined, size: 22),
          title: const Text('Change Requests'),
          subtitle: Text(
            pending > 0 ? '$pending pending' : 'No pending requests',
            style: TextStyle(
              color: pending > 0 ? cs.primary : cs.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pending > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$pending',
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Admin requests screen — coming in next phase'),
            ),
          ),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.manage_accounts_outlined, size: 22),
          title: const Text('Request Removal of Admin Access',
              style: TextStyle(fontSize: 14)),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => _showRemoveAdminDialog(context, ref),
        ),
      ],
    );
  }

  void _showRemoveAdminDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Admin Access'),
        content: const Text(
          'Submit a request to have your administrator privileges removed. '
          'An admin will review and action this request.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Request submitted — coming in next phase'),
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
