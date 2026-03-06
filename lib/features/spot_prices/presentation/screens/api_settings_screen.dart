// lib/features/spot_prices/presentation/screens/api_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/features/spot_prices/data/models/global_spot_price_api_setting_model.dart';
import 'package:metal_tracker/features/spot_prices/data/services/global_spot_price_service_factory.dart';
import 'package:metal_tracker/features/spot_prices/presentation/providers/spot_prices_providers.dart';
import 'package:metal_tracker/features/spot_prices/presentation/screens/add_edit_api_setting_screen.dart';

class ApiSettingsScreen extends ConsumerWidget {
  const ApiSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(apiSettingsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('API Settings'),
        backgroundColor: AppColors.backgroundCard,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add API setting',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddEditApiSettingScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: settingsAsync.when(
        data: (settings) {
          if (settings.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.key_off,
                      size: 56, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  const Text(
                    'No API settings configured',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddEditApiSettingScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add API Setting'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: settings.length,
            itemBuilder: (context, index) {
              return _ApiSettingCard(setting: settings[index]);
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}

class _ApiSettingCard extends ConsumerWidget {
  final GlobalSpotPriceApiSetting setting;

  const _ApiSettingCard({required this.setting});

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text('Delete API Setting'),
        content: const Text(
          'Are you sure you want to delete this API setting? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(apiSettingsNotifierProvider.notifier).delete(setting.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API setting deleted'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maskedKey = setting.apiKey.length > 8
        ? '${setting.apiKey.substring(0, 4)}••••${setting.apiKey.substring(setting.apiKey.length - 4)}'
        : '••••••••';

    return Card(
      color: AppColors.backgroundCard,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: setting.isActive
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.textSecondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    setting.isActive ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(
                      color: setting.isActive
                          ? AppColors.success
                          : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                // Edit
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  color: AppColors.primaryGold,
                  tooltip: 'Edit',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddEditApiSettingScreen(setting: setting),
                      ),
                    );
                  },
                ),
                // Delete
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppColors.error,
                  tooltip: 'Delete',
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Service type
            _InfoRow(
              icon: Icons.api,
              label: 'Service',
              value: GlobalSpotPriceServiceFactory.displayNameFor(
                  setting.serviceType),
            ),
            const SizedBox(height: 8),

            // API Key (masked)
            _InfoRow(
              icon: Icons.key,
              label: 'API Key',
              value: maskedKey,
            ),

            // Config key/value pairs
            if (setting.config.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: setting.config.entries
                    .map(
                      (e) => Expanded(
                        child: _InfoRow(
                          icon: Icons.tune,
                          label: e.key,
                          value: e.value,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],

            if (setting.updatedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Updated: ${_fmt(setting.updatedAt!)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
