import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_profile_providers.dart';
import 'package:metal_tracker/features/settings/presentation/screens/admin_settings_screen.dart';
import 'package:metal_tracker/features/settings/presentation/screens/analytics_settings_screen.dart';
import 'package:metal_tracker/features/settings/presentation/screens/global_spot_pref_screen.dart';
import 'package:metal_tracker/features/settings/presentation/screens/user_metaltype_prefs_section.dart';
import 'package:metal_tracker/features/settings/presentation/screens/user_retailer_prefs_section.dart';
import 'package:metal_tracker/features/settings/presentation/screens/profile_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);

    return AppScaffold(
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SettingsSection(
            icon: Icons.person_outline,
            label: 'Profile',
            child: const ProfileSettingsScreen(embedded: true),
          ),
          _SettingsSection(
            icon: Icons.toll_outlined,
            label: 'Metal Preferences',
            description: 'Choose which metals to track across the app',
            child: const UserMetaltypePrefsSection(),
          ),
          _SettingsSection(
            icon: Icons.store_outlined,
            label: 'Retailer Preferences',
            description: 'Choose which retailers to include in prices and analysis',
            child: const UserRetailerPrefsSection(),
          ),
          _SettingsSection(
            icon: Icons.cloud_outlined,
            label: 'Global Spot Provider Settings',
            description: 'Configure your global spot price API providers',
            child: const GlobalSpotPrefScreen(embedded: true),
          ),
          _SettingsSection(
            icon: Icons.analytics_outlined,
            label: 'Analytics',
            description: 'Thresholds and labels used in analytics screens',
            child: const AnalyticsSettingsScreen(embedded: true),
          ),
          if (isAdmin)
            _SettingsSection(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Administration',
              child: const AdminSettingsScreen(embedded: true),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? description;
  final Widget child;

  const _SettingsSection({
    required this.icon,
    required this.label,
    this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.primaryGold, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (description != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            description!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            // Section content
            child,
          ],
        ),
      ),
    );
  }
}
