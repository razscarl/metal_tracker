// lib/features/product_listings/presentation/screens/product_listings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/widgets/app_drawer.dart';
import 'package:metal_tracker/core/widgets/app_logo_title.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';

class ProductListingsScreen extends ConsumerStatefulWidget {
  const ProductListingsScreen({super.key});

  @override
  ConsumerState<ProductListingsScreen> createState() =>
      _ProductListingsScreenState();
}

class _ProductListingsScreenState extends ConsumerState<ProductListingsScreen> {
  // TODO: Implement product listings when product listing scraper is ready
  // final listingsAsync = ref.watch(productListingsProvider);
  // final retailerFilter = ref.watch(productListingsByRetailerProvider);

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const AppLogoTitle('Product Listings'),
        backgroundColor: AppColors.backgroundCard,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // TODO: Implement refresh when providers are ready
              // ref.invalidate(productListingsProvider);
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.construction,
                size: 64,
                color: AppColors.warning,
              ),
              const SizedBox(height: 16),
              Text(
                'Product Listings',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'This feature is not yet implemented.\nProduct listing scraper coming soon.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* COMMENTED OUT - WILL IMPLEMENT WHEN PRODUCT LISTING SCRAPER IS READY

class _ProductListingsScreenState
    extends ConsumerState<ProductListingsScreen> {
  final listingsAsync = ref.watch(productListingsProvider);
  final retailerFilter = ref.watch(productListingsByRetailerProvider);

  @override
  Widget build(BuildContext context) {
    final scraperState = ref.watch(scraperExecutionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const AppLogoTitle('Product Listings'),
        backgroundColor: AppColors.backgroundCard,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(productListingsProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Scraper controls
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.backgroundCard,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: scraperState.isRunning
                        ? null
                        : () {
                            ref
                                .read(scraperExecutionProvider.notifier)
                                .runScraper('gba_product_listing');
                          },
                    icon: scraperState.isRunning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(scraperState.isRunning
                        ? 'Scraping...'
                        : 'Run Product Listing Scraper'),
                  ),
                ),
                if (scraperState.isRunning) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      ref.read(scraperExecutionProvider.notifier).reset();
                    },
                  ),
                ],
              ],
            ),
          ),

          // Error display
          if (scraperState.errors.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.error.withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: scraperState.errors.map((error) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      error,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Success message
          if (scraperState.successMessage != null && !scraperState.isRunning)
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.success.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      scraperState.successMessage!,
                      style: const TextStyle(color: AppColors.success),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      ref.read(scraperExecutionProvider.notifier).reset();
                    },
                  ),
                ],
              ),
            ),

          // Product listings
          Expanded(
            child: listingsAsync.when(
              data: (listings) {
                if (listings.isEmpty) {
                  return const Center(
                    child: Text('No product listings found'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    final listing = listings[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(listing.listingName ?? 'Unknown'),
                        subtitle: Text(
                          'Price: \$${listing.listingSellPrice?.toStringAsFixed(2) ?? 'N/A'}',
                        ),
                        trailing: listing.productProfileId != null
                            ? const Icon(Icons.check_circle,
                                color: AppColors.success)
                            : const Icon(Icons.link_off,
                                color: AppColors.warning),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

*/
