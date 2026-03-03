// lib/features/scrapers/presentation/screens/live_price_mapping_screen.dart:Live Price Mapping Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../holdings/presentation/providers/holdings_providers.dart';
import '../../../product_profiles/presentation/screens/add_product_profile_screen.dart';
import '../../../scrapers/presentation/providers/scraper_providers.dart';
import '../../data/models/live_price_model.dart';
import '../../../product_profiles/data/models/product_profile_model.dart';
import '../../../retailers/presentation/providers/retailers_providers.dart';

class LivePriceMappingScreen extends ConsumerWidget {
  const LivePriceMappingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unmappedAsync = ref.watch(unmappedLivePricesProvider);
    final profilesAsync = ref.watch(productProfilesProvider);
    final retailersAsync = ref.watch(retailersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Live Prices'),
        backgroundColor: AppColors.backgroundCard,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(unmappedLivePricesProvider);
              ref.invalidate(productProfilesProvider);
            },
          ),
        ],
      ),
      body: unmappedAsync.when(
        data: (unmappedPrices) {
          if (unmappedPrices.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'All Live Prices Mapped!',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'All your live prices are linked to product profiles.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // Header banner
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.warning.withValues(alpha: 0.2),
                child: Row(
                  children: [
                    const Icon(Icons.link_off, color: AppColors.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${unmappedPrices.length} live ${unmappedPrices.length == 1 ? 'price needs' : 'prices need'} mapping to product profiles',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),

              // Unmapped prices list
              Expanded(
                child: profilesAsync.when(
                  data: (profiles) => retailersAsync.when(
                    data: (retailers) {
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: unmappedPrices.length,
                        itemBuilder: (context, index) {
                          final livePrice = unmappedPrices[index];
                          final retailer = retailers.firstWhere(
                            (r) => r.id == livePrice.retailerId,
                            orElse: () => retailers.first,
                          );

                          return _LivePriceMappingCard(
                            livePrice: livePrice,
                            retailerName: retailer.name,
                            profiles: profiles,
                            onMapped: () {
                              ref.invalidate(unmappedLivePricesProvider);
                              ref.invalidate(livePricesProvider);
                              ref.invalidate(portfolioValuationProvider);
                            },
                            onCreateProfile: () async {
                              // Try to detect metal type from live price name
                              final metalType =
                                  _detectMetalType(livePrice.livePriceName);

                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddProductProfileScreen(
                                      metalType: metalType),
                                ),
                              );
                              ref.invalidate(productProfilesProvider);
                            },
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Center(
                      child: Text('Error loading retailers'),
                    ),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(
                    child: Text('Error loading product profiles'),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Error loading unmapped prices: $error',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ),
      ),
    );
  }

  /// Detect metal type from live price name
  static MetalType _detectMetalType(String? livePriceName) {
    if (livePriceName == null) return MetalType.gold;

    final nameLower = livePriceName.toLowerCase();

    if (nameLower.contains('silver')) {
      return MetalType.silver;
    } else if (nameLower.contains('platinum')) {
      return MetalType.platinum;
    } else if (nameLower.contains('gold')) {
      return MetalType.gold;
    }

    // Default to gold if can't detect
    return MetalType.gold;
  }
}

class _LivePriceMappingCard extends ConsumerStatefulWidget {
  final LivePrice livePrice;
  final String retailerName;
  final List<ProductProfile> profiles;
  final VoidCallback onMapped;
  final VoidCallback onCreateProfile;

  const _LivePriceMappingCard({
    required this.livePrice,
    required this.retailerName,
    required this.profiles,
    required this.onMapped,
    required this.onCreateProfile,
  });

  @override
  ConsumerState<_LivePriceMappingCard> createState() =>
      _LivePriceMappingCardState();
}

class _LivePriceMappingCardState extends ConsumerState<_LivePriceMappingCard> {
  String? _selectedProfileId;
  bool _isSaving = false;

  Future<void> _saveMapping() async {
    if (_selectedProfileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product profile'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(scraperRepositoryProvider);
      await repository.updateLivePriceMapping(
        widget.livePrice.id,
        _selectedProfileId!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mapping saved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onMapped();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving mapping: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live price info
            Row(
              children: [
                const Icon(
                  Icons.price_change,
                  color: AppColors.primaryGold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.livePrice.livePriceName ?? 'Unknown',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        widget.retailerName,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Prices
            Row(
              children: [
                if (widget.livePrice.sellPrice != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sell',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '\$${widget.livePrice.sellPrice!.toStringAsFixed(2)}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.error,
                                  ),
                        ),
                      ],
                    ),
                  ),
                if (widget.livePrice.buybackPrice != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buyback',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '\$${widget.livePrice.buybackPrice!.toStringAsFixed(2)}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Profile selection
            Text(
              'Link to Product Profile:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              initialValue: _selectedProfileId,
              decoration: const InputDecoration(
                labelText: 'Select Product Profile',
                prefixIcon: Icon(Icons.inventory_2),
              ),
              items: widget.profiles.map<DropdownMenuItem<String>>((profile) {
                return DropdownMenuItem<String>(
                  value: profile.id,
                  child: Text(
                    '${profile.profileName}',
                  ),
                );
              }).toList(),
              onChanged: _isSaving
                  ? null
                  : (value) {
                      setState(() => _selectedProfileId = value);
                    },
            ),
            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : widget.onCreateProfile,
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Profile'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveMapping,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.link),
                    label: Text(_isSaving ? 'Saving...' : 'Save Mapping'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
