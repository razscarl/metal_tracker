// lib/features/product_listings/presentation/screens/product_listings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:metal_tracker/core/constants/app_constants.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/core/widgets/app_drawer.dart';
import 'package:metal_tracker/core/widgets/app_logo_title.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/core/widgets/filter_sheet.dart';
import 'package:metal_tracker/features/product_listings/data/models/product_listing_model.dart';
import 'package:metal_tracker/features/product_listings/presentation/providers/product_listings_providers.dart';

final _currencyFmt = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
final _dateFmt = DateFormat('d MMM yyyy');

class ProductListingsScreen extends ConsumerStatefulWidget {
  const ProductListingsScreen({super.key});

  @override
  ConsumerState<ProductListingsScreen> createState() =>
      _ProductListingsScreenState();
}

class _ProductListingsScreenState
    extends ConsumerState<ProductListingsScreen> {
  bool _scraping = false;

  // Filters
  String? _metalFilter;    // null = all
  String? _datePreset;     // null | 'today' | 'week' | 'month' | 'year'
  double? _minPrice;
  double? _maxPrice;

  int get _activeFilterCount =>
      (_metalFilter != null ? 1 : 0) +
      (_datePreset != null ? 1 : 0) +
      (_minPrice != null || _maxPrice != null ? 1 : 0);

  DateTime? _dateFrom() {
    final now = DateTime.now();
    return switch (_datePreset) {
      'today' => DateTime(now.year, now.month, now.day),
      'week'  => now.subtract(const Duration(days: 7)),
      'month' => DateTime(now.year, now.month - 1, now.day),
      'year'  => DateTime(now.year - 1, now.month, now.day),
      _       => null,
    };
  }

  List<ProductListing> _applyFilters(List<ProductListing> all) {
    final from = _dateFrom();
    return all.where((l) {
      if (_metalFilter != null &&
          l.metalType?.toLowerCase() != _metalFilter) return false;
      if (from != null && l.scrapeDate.isBefore(from)) return false;
      if (_minPrice != null && l.listingSellPrice < _minPrice!) return false;
      if (_maxPrice != null && l.listingSellPrice > _maxPrice!) return false;
      return true;
    }).toList();
  }

  void _showFilterSheet() {
    String? localMetal = _metalFilter;
    String? localDate = _datePreset;
    double? localMin = _minPrice;
    double? localMax = _maxPrice;

    FilterSheet.show(
      context: context,
      title: 'Filter Listings',
      onReset: () => setState(() {
        _metalFilter = null;
        _datePreset = null;
        _minPrice = _maxPrice = null;
      }),
      builder: (setSheetState) => [
        FilterSection(
          label: 'Metal',
          child: FilterChipGroup<String>(
            options: const [
              FilterChipOption(value: 'gold', label: 'Gold'),
              FilterChipOption(value: 'silver', label: 'Silver'),
              FilterChipOption(value: 'platinum', label: 'Platinum'),
            ],
            selected: localMetal,
            onChanged: (v) {
              localMetal = v;
              setState(() => _metalFilter = v);
              setSheetState(() {});
            },
          ),
        ),
        FilterSection(
          label: 'Date',
          child: FilterDatePreset(
            selected: localDate,
            onChanged: (v) {
              localDate = v;
              setState(() => _datePreset = v);
              setSheetState(() {});
            },
          ),
        ),
        FilterSection(
          label: 'Sell Price (\$)',
          child: FilterRangeSlider(
            min: 0,
            max: 10000,
            currentMin: localMin ?? 0,
            currentMax: localMax ?? 10000,
            format: (v) => '\$${v.toStringAsFixed(0)}',
            onChanged: (range) {
              localMin = range.start > 0 ? range.start : null;
              localMax = range.end < 10000 ? range.end : null;
              setState(() {
                _minPrice = localMin;
                _maxPrice = localMax;
              });
              setSheetState(() {});
            },
          ),
        ),
      ],
    );
  }

  Future<void> _scrapeAll() async {
    setState(() => _scraping = true);
    try {
      final reports =
          await ref.read(productListingsNotifierProvider.notifier).scrapeAll();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: const Text('Scrape Results'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: reports.map((r) {
                final color = r.status == 'success'
                    ? AppColors.gainGreen
                    : r.status == 'partial'
                        ? AppColors.warning
                        : AppColors.lossRed;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: color),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${r.retailerName}: ${r.status} '
                              '(${r.savedCount}/${r.scrapedCount})',
                              style: const TextStyle(
                                  color: AppColors.textPrimary, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      if (r.errors.isNotEmpty)
                        ...r.errors.map((e) => Padding(
                              padding: const EdgeInsets.only(left: 14, top: 2),
                              child: Text(e,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11)),
                            )),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK')),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _scraping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(productListingsNotifierProvider);

    return AppScaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const AppLogoTitle('Listings'),
        backgroundColor: AppColors.backgroundCard,
        actions: [
          // Filter button
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.tune),
                tooltip: 'Filter',
                onPressed: _showFilterSheet,
              ),
              if (_activeFilterCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryGold,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$_activeFilterCount',
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Scrape button
          if (_scraping)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primaryGold),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.cloud_sync),
              tooltip: 'Scrape all retailers',
              onPressed: _scrapeAll,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.invalidate(productListingsNotifierProvider),
          ),
        ],
      ),
      body: listingsAsync.when(
        data: (all) {
          final listings = _applyFilters(all);

          if (all.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.list_alt_outlined,
                        size: 64, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    Text('No Listings Yet',
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the sync button to scrape product listings.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (listings.isEmpty) {
            return const Center(
              child: Text('No results match your filters.',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }

          return RefreshIndicator(
            color: AppColors.primaryGold,
            onRefresh: () =>
                ref.read(productListingsNotifierProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: listings.length,
              itemBuilder: (_, i) => _ListingCard(listing: listings[i]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }
}

// ─── Listing Card ─────────────────────────────────────────────────────────────

class _ListingCard extends StatelessWidget {
  final ProductListing listing;
  const _ListingCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    final metal = listing.metalType?.toLowerCase();
    final color = metal != null
        ? MetalColorHelper.getColorForMetalString(metal)
        : AppColors.textPrimary;
    final iconPath = metal != null
        ? MetalColorHelper.getAssetPathForMetalString(metal)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metal icon / colour bar
          if (iconPath != null)
            Padding(
              padding: const EdgeInsets.only(right: 10, top: 2),
              child: Image.asset(iconPath,
                  width: 20, height: 20, fit: BoxFit.contain),
            )
          else
            Container(
              width: 4,
              height: 40,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: AppColors.textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

          // Name + retailer + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.listingName,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  listing.retailerName ?? 'Unknown Retailer',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  _dateFmt.format(listing.scrapeDate),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ),

          // Price
          Text(
            _currencyFmt.format(listing.listingSellPrice),
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
