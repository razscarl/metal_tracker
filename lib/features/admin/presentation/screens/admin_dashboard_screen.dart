// lib/features/admin/presentation/screens/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/features/admin/presentation/providers/admin_providers.dart';
import 'package:metal_tracker/features/admin/presentation/screens/admin_requests_screen.dart';
import 'package:metal_tracker/features/admin/presentation/screens/automation_screen.dart';
import 'package:metal_tracker/features/admin/presentation/screens/metal_form_admin_screen.dart';
import 'package:metal_tracker/features/admin/presentation/screens/metal_type_admin_screen.dart';
import 'package:metal_tracker/features/admin/presentation/screens/product_listing_status_screen.dart';
import 'package:metal_tracker/features/admin/presentation/screens/design_tokens_screen.dart';
import 'package:metal_tracker/features/admin/presentation/screens/user_approval_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingRequestCountProvider);
    final pendingUsersAsync = ref.watch(pendingUserCountProvider);

    return AppScaffold(
      title: 'Admin Dashboard',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CountQuickLink(
            icon: Icons.person_add_outlined,
            label: 'User Approvals',
            subtitle: 'Approve or reject new user accounts',
            countAsync: pendingUsersAsync,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserApprovalScreen()),
            ),
          ),
          _CountQuickLink(
            icon: Icons.list_alt,
            label: 'Change Requests',
            subtitle: 'Review and action all user requests',
            countAsync: pendingAsync,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminRequestsScreen()),
            ),
          ),
          _QuickLink(
            icon: Icons.auto_mode_outlined,
            label: 'Automation',
            subtitle: 'Schedule status, job history and failure logs',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AutomationScreen()),
            ),
          ),
          _QuickLink(
            icon: Icons.label_outline_rounded,
            label: 'Listing Statuses',
            subtitle: 'Manage availability status mappings for scrapers',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ProductListingStatusScreen()),
            ),
          ),
          _QuickLink(
            icon: Icons.diamond_outlined,
            label: 'Metal Types',
            subtitle: 'Add, rename or deactivate metal types',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const MetalTypeAdminScreen()),
            ),
          ),
          _QuickLink(
            icon: Icons.category_outlined,
            label: 'Metal Forms',
            subtitle: 'Add, rename or deactivate metal forms',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const MetalFormAdminScreen()),
            ),
          ),
          _QuickLink(
            icon: Icons.palette_outlined,
            label: 'Design Tokens',
            subtitle: 'Manage colours, typography and spacing per theme',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const DesignTokensScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Count Quick Link ─────────────────────────────────────────────────────────

class _CountQuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final AsyncValue<int> countAsync;
  final VoidCallback onTap;

  const _CountQuickLink({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.countAsync,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: cs.primary, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: tt.titleSmall),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              countAsync.maybeWhen(
                data: (count) => count > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.lossRed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$count',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      )
                    : Icon(Icons.chevron_right,
                        color: cs.onSurfaceVariant, size: 20),
                orElse: () =>
                    Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quick Link ───────────────────────────────────────────────────────────────

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickLink({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: cs.primary, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: tt.titleSmall),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: tt.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
