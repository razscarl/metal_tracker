// lib/features/retailers/presentation/screens/retailers_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/features/retailers/data/models/retailers_model.dart';
import 'package:metal_tracker/features/retailers/presentation/providers/retailers_providers.dart';
import 'package:metal_tracker/features/retailers/presentation/screens/add_edit_retailer_screen.dart';

class RetailersScreen extends ConsumerWidget {
  const RetailersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final retailersAsync = ref.watch(retailersProvider);

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Retailers'),
        backgroundColor: AppColors.backgroundCard,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const AddEditRetailerScreen(retailer: null),
                ),
              );
              if (result == true) {
                ref.invalidate(retailersProvider);
              }
            },
          ),
        ],
      ),
      body: retailersAsync.when(
        data: (retailers) {
          final activeRetailers = retailers.where((r) => r.isActive).toList();

          if (activeRetailers.isEmpty) {
            return const Center(
              child: Text('No active retailers'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeRetailers.length,
            itemBuilder: (context, index) {
              return RetailerCard(retailer: activeRetailers[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}

class RetailerCard extends ConsumerWidget {
  final Retailer retailer;

  const RetailerCard({super.key, required this.retailer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch scraper settings for this retailer
    final settingsAsync = ref.watch(
      retailerScraperSettingsProvider(retailer.id),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Retailer header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        retailer.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (retailer.retailerAbbr != null)
                        Text(
                          retailer.retailerAbbr!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEditRetailerScreen(
                          retailer: retailer,
                        ),
                      ),
                    );
                    if (result == true) {
                      ref.invalidate(retailersProvider);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (retailer.baseUrl != null)
              Text(
                retailer.baseUrl!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primaryGold,
                    ),
              ),
            const Divider(height: 24),

            // Scraper settings section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Scraper Settings',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.primaryGold,
                  onPressed: () {
                    // TODO: Navigate to Add Scraper Setting screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Add Scraper Setting - Coming soon')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Scraper settings list
            settingsAsync.when(
              data: (settings) {
                if (settings.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No scraper settings configured'),
                  );
                }

                return Column(
                  children: settings.map((setting) {
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        _getIconForScraperType(setting.scraperType),
                        color: setting.isActive
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                      title: Text(
                        '${setting.scraperType} - ${setting.metalType ?? "All"}',
                      ),
                      subtitle: Text(
                        setting.searchString,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () {
                          // TODO: Navigate to Edit Scraper Setting screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Edit Setting - Coming soon')),
                          );
                        },
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(),
              ),
              error: (_, __) => const Text('Error loading settings'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForScraperType(String scraperType) {
    switch (scraperType) {
      case 'live_price':
        return Icons.monetization_on;
      case 'product_listing':
        return Icons.shopping_cart;
      case 'local_spot':
        return Icons.show_chart;
      default:
        return Icons.settings;
    }
  }
}
