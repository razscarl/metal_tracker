// lib/features/product_profiles/presentation/screens/product_profile_mapping_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_profile_providers.dart';
import 'package:metal_tracker/features/holdings/presentation/providers/holdings_providers.dart';
import 'package:metal_tracker/features/live_prices/data/models/live_price_model.dart';
import 'package:metal_tracker/features/live_prices/presentation/providers/live_prices_providers.dart';
import 'package:metal_tracker/features/product_listings/data/models/product_listing_model.dart';
import 'package:metal_tracker/features/product_listings/presentation/providers/product_listings_providers.dart';
import 'package:metal_tracker/core/widgets/profile_search_field.dart';
import 'package:metal_tracker/features/product_profiles/data/models/product_profile_model.dart';
import 'package:metal_tracker/features/product_profiles/presentation/screens/add_product_profile_screen.dart';

class ProductProfileMappingScreen extends ConsumerWidget {
  final String? initialListingId;

  const ProductProfileMappingScreen({super.key, this.initialListingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    final profilesAsync = ref.watch(productProfilesProvider);

    if (!isAdmin) {
      return AppScaffold(
        title: 'Profile Mapping',
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.lock_outline, size: 48, color: AppColors.textSecondary),
                SizedBox(height: 16),
                Text(
                  'Profile mapping is managed by administrators.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      initialIndex: initialListingId != null ? 1 : 0,
      child: AppScaffold(
        title: 'Profile Mapping',
        tabBar: const TabBar(
          indicatorColor: AppColors.primaryGold,
          labelColor: AppColors.primaryGold,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: 'Live Prices'),
            Tab(text: 'Listings'),
          ],
        ),
        actions: [
          profilesAsync.when(
            data: (profiles) => IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Add Product Profile',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddProductProfileScreen(),
                  ),
                );
                ref.invalidate(productProfilesProvider);
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
        body: profilesAsync.when(
          data: (profiles) => TabBarView(
            children: [
              _LivePricesTab(profiles: profiles),
              _ListingsTab(
                profiles: profiles,
                initialListingId: initialListingId,
              ),
            ],
          ),
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold)),
          error: (e, _) => Center(
            child: Text('Error loading profiles: $e',
                style: const TextStyle(color: AppColors.error)),
          ),
        ),
      ),
    );
  }
}

// ─── Live Prices Tab ──────────────────────────────────────────────────────────

class _LivePricesTab extends ConsumerWidget {
  final List<ProductProfile> profiles;

  const _LivePricesTab({required this.profiles});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unmappedAsync = ref.watch(unmappedLivePricesProvider);

    return RefreshIndicator(
      color: AppColors.primaryGold,
      onRefresh: () async {
        ref.invalidate(unmappedLivePricesProvider);
        ref.invalidate(livePricesNotifierProvider);
      },
      child: unmappedAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const _AllMappedState(label: 'live prices');
          }
          return _UnmappedHeader(
            count: items.length,
            label: 'live price',
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              itemCount: items.length,
              itemBuilder: (_, i) => _LivePriceCard(
                livePrice: items[i],
                profiles: profiles,
                onSaved: () {
                  ref.invalidate(unmappedLivePricesProvider);
                  ref.invalidate(livePricesNotifierProvider);
                  ref.invalidate(livePricesProvider);
                  ref.invalidate(portfolioValuationProvider);
                },
              ),
            ),
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGold)),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }
}

// ─── Listings Tab ─────────────────────────────────────────────────────────────

class _ListingsTab extends ConsumerWidget {
  final List<ProductProfile> profiles;
  final String? initialListingId;

  const _ListingsTab({required this.profiles, this.initialListingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unmappedAsync = ref.watch(unmappedProductListingsProvider);

    return RefreshIndicator(
      color: AppColors.primaryGold,
      onRefresh: () async {
        ref.invalidate(unmappedProductListingsProvider);
        ref.invalidate(productListingsNotifierProvider);
      },
      child: unmappedAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const _AllMappedState(label: 'listings');
          }
          // Pin the target listing at the top when arriving from a row tap
          final sorted = initialListingId != null
              ? [
                  ...items.where((l) => l.id == initialListingId),
                  ...items.where((l) => l.id != initialListingId),
                ]
              : items;
          return _UnmappedHeader(
            count: items.length,
            label: 'listing',
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              itemCount: sorted.length,
              itemBuilder: (_, i) => _ListingCard(
                listing: sorted[i],
                profiles: profiles,
                highlighted: sorted[i].id == initialListingId,
                onSaved: () {
                  ref.invalidate(unmappedProductListingsProvider);
                  ref.invalidate(productListingsNotifierProvider);
                },
              ),
            ),
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGold)),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }
}

// ─── Live Price Card ──────────────────────────────────────────────────────────

class _LivePriceCard extends ConsumerStatefulWidget {
  final LivePrice livePrice;
  final List<ProductProfile> profiles;
  final VoidCallback onSaved;

  const _LivePriceCard({
    required this.livePrice,
    required this.profiles,
    required this.onSaved,
  });

  @override
  ConsumerState<_LivePriceCard> createState() => _LivePriceCardState();
}

class _LivePriceCardState extends ConsumerState<_LivePriceCard> {
  ProductProfile? _selectedProfile;
  bool _saving = false;

  Future<void> _save() async {
    if (_selectedProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Select a product profile first'),
        backgroundColor: AppColors.warning,
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(livePricesRepositoryProvider)
          .updateLivePriceMapping(widget.livePrice.id, _selectedProfile!.id);
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _MappingCard(
      title: widget.livePrice.livePriceName ?? '—',
      subtitle: widget.livePrice.retailerName ?? '',
      priceLabel: widget.livePrice.sellPrice != null
          ? '\$${widget.livePrice.sellPrice!.toStringAsFixed(2)}'
          : null,
      profiles: widget.profiles,
      selectedProfile: _selectedProfile,
      saving: _saving,
      onProfileChanged: (v) => setState(() => _selectedProfile = v),
      onSave: _save,
    );
  }
}

// ─── Listing Card ─────────────────────────────────────────────────────────────

class _ListingCard extends ConsumerStatefulWidget {
  final ProductListing listing;
  final List<ProductProfile> profiles;
  final bool highlighted;
  final VoidCallback onSaved;

  const _ListingCard({
    required this.listing,
    required this.profiles,
    this.highlighted = false,
    required this.onSaved,
  });

  @override
  ConsumerState<_ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends ConsumerState<_ListingCard> {
  ProductProfile? _selectedProfile;
  bool _saving = false;

  Future<void> _save() async {
    if (_selectedProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Select a product profile first'),
        backgroundColor: AppColors.warning,
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(productListingsRepositoryProvider)
          .updateListingMapping(widget.listing.id, _selectedProfile!.id);
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _MappingCard(
      title: widget.listing.listingName,
      subtitle: widget.listing.retailerName ?? '',
      priceLabel: '\$${widget.listing.listingSellPrice.toStringAsFixed(2)}',
      profiles: widget.profiles,
      selectedProfile: _selectedProfile,
      saving: _saving,
      highlighted: widget.highlighted,
      onProfileChanged: (v) => setState(() => _selectedProfile = v),
      onSave: _save,
    );
  }
}

// ─── Shared mapping card ──────────────────────────────────────────────────────

class _MappingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? priceLabel;
  final List<ProductProfile> profiles;
  final ProductProfile? selectedProfile;
  final bool saving;
  final bool highlighted;
  final ValueChanged<ProductProfile> onProfileChanged;
  final VoidCallback onSave;

  const _MappingCard({
    required this.title,
    required this.subtitle,
    required this.priceLabel,
    required this.profiles,
    required this.selectedProfile,
    required this.saving,
    this.highlighted = false,
    required this.onProfileChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...profiles]
      ..sort((a, b) => a.profileName.compareTo(b.profileName));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlighted ? AppColors.primaryGold : Colors.white10,
          width: highlighted ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (priceLabel != null)
                Text(
                  priceLabel!,
                  style: const TextStyle(
                    color: AppColors.primaryGold,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ProfileSearchField(
                  profiles: sorted,
                  selected: selectedProfile,
                  onSelected: onProfileChanged,
                  label: 'Type to search profiles…',
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: saving ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: AppColors.textDark,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                ),
                child: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _AllMappedState extends StatelessWidget {
  final String label;

  const _AllMappedState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline,
              size: 56, color: AppColors.gainGreen),
          const SizedBox(height: 12),
          Text(
            'All $label mapped!',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pull down to refresh',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _UnmappedHeader extends StatelessWidget {
  final int count;
  final String label;
  final Widget child;

  const _UnmappedHeader({
    required this.count,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final plural = count == 1 ? label : '${label}s';
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.warning.withValues(alpha: 0.15),
          child: Row(
            children: [
              const Icon(Icons.link_off, color: AppColors.warning, size: 16),
              const SizedBox(width: 8),
              Text(
                '$count unmapped $plural',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
