// lib/features/live_prices/presentation/screens/live_prices_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/metal_color_helper.dart';
import '../../../../core/utils/weight_converter.dart';
import '../../data/models/live_price_model.dart';
import '../../../product_profiles/data/models/product_profile_model.dart';
import '../../../retailers/data/models/retailers_model.dart';
import '../../../holdings/presentation/providers/holdings_providers.dart';
import '../../../retailers/presentation/providers/retailers_providers.dart';
import '../providers/live_prices_providers.dart';
import 'manual_live_price_entry_screen.dart';

class LivePricesScreen extends ConsumerWidget {
  const LivePricesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // livePricesNotifierProvider is the generated name from @riverpod class LivePricesNotifier
    final livePricesAsync = ref.watch(livePricesNotifierProvider);
    final profilesAsync = ref.watch(productProfilesProvider);
    final retailersAsync = ref.watch(retailersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Prices'),
        backgroundColor: AppColors.backgroundCard,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(livePricesNotifierProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ManualLivePriceEntryScreen(),
            ),
          );
          ref.invalidate(livePricesNotifierProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Price'),
        backgroundColor: AppColors.primaryGold,
      ),
      body: livePricesAsync.when(
        data: (livePrices) {
          if (livePrices.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.price_change_outlined,
                        size: 64, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    Text('No Live Prices Yet',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the + button to add current market prices',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Group prices by date descending
          final pricesByDate = <String, List<LivePrice>>{};
          for (final price in livePrices) {
            final dateKey = price.captureDate.toIso8601String().split('T')[0];
            pricesByDate.putIfAbsent(dateKey, () => []).add(price);
          }
          final sortedDates = pricesByDate.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return profilesAsync.when(
            data: (profiles) => retailersAsync.when(
              data: (retailers) {
                final profileMap = {for (var p in profiles) p.id: p};
                final retailerMap = {for (var r in retailers) r.id: r};

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedDates.length,
                  itemBuilder: (context, index) {
                    final date = sortedDates[index];
                    final prices = pricesByDate[date]!;
                    final dateObj = DateTime.parse(date);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '${dateObj.day}/${dateObj.month}/${dateObj.year}',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        ...prices.map((price) => _LivePriceCard(
                              livePrice: price,
                              profile: profileMap[price.productProfileId],
                              retailer: retailerMap[price.retailerId],
                            )),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: Text('Error loading retailers')),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                const Center(child: Text('Error loading profiles')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Error loading live prices: $error',
              style: const TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _LivePriceCard extends StatelessWidget {
  final LivePrice livePrice;
  final ProductProfile? profile;
  final Retailer? retailer;

  const _LivePriceCard({
    required this.livePrice,
    this.profile,
    this.retailer,
  });

  @override
  Widget build(BuildContext context) {
    double? pricePerPureOz;
    if (livePrice.buybackPrice != null && profile != null) {
      pricePerPureOz = WeightCalculations.pricePerPureOunce(
        totalPrice: livePrice.buybackPrice!,
        weight: profile!.weight,
        unit: profile!.weightUnitEnum,
        purity: profile!.purity,
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (profile != null)
                  Icon(
                    MetalColorHelper.getIconForMetal(profile!.metalTypeEnum),
                    color: MetalColorHelper.getColorForMetal(
                        profile!.metalTypeEnum),
                    size: 24,
                  )
                else
                  const Icon(Icons.help_outline,
                      color: AppColors.warning, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.profileName ??
                            livePrice.livePriceName ??
                            'Unknown Profile',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(retailer?.name ?? 'Unknown Retailer',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                if (profile == null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('UNMAPPED',
                        style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (livePrice.sellPrice != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sell Price',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text(
                          '\$${livePrice.sellPrice!.toStringAsFixed(2)}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                if (livePrice.buybackPrice != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Buyback Price',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text(
                          '\$${livePrice.buybackPrice!.toStringAsFixed(2)}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (pricePerPureOz != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppConstants.cardBorderRadius),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calculate,
                        size: 16, color: AppColors.primaryGold),
                    const SizedBox(width: 8),
                    Text(
                      'Normalized: \$${pricePerPureOz.toStringAsFixed(2)}/oz pure',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.primaryGold),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
