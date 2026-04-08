// lib/features/live_prices/presentation/screens/live_prices_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/constants/app_constants.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/core/utils/weight_converter.dart';
import 'package:metal_tracker/core/widgets/app_drawer.dart';
import 'package:metal_tracker/core/widgets/app_logo_title.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/core/widgets/filter_sheet.dart';
import 'package:metal_tracker/features/holdings/presentation/providers/holdings_providers.dart';
import 'package:metal_tracker/features/live_prices/data/models/live_price_model.dart';
import 'package:metal_tracker/features/live_prices/presentation/providers/live_prices_providers.dart';
import 'package:metal_tracker/features/live_prices/presentation/screens/live_price_mapping_screen.dart';
import 'package:metal_tracker/features/live_prices/presentation/screens/manual_live_price_entry_screen.dart';
import 'package:metal_tracker/features/product_profiles/data/models/product_profile_model.dart';

class LivePricesScreen extends ConsumerStatefulWidget {
  const LivePricesScreen({super.key});

  @override
  ConsumerState<LivePricesScreen> createState() => _LivePricesScreenState();
}

class _LivePricesScreenState extends ConsumerState<LivePricesScreen> {
  bool _scraping = false;

  // Filters
  String _nameSearch = '';
  double? _minSell;
  double? _maxSell;
  double? _minBuyback;
  double? _maxBuyback;

  int get _activeFilterCount =>
      (_nameSearch.isNotEmpty ? 1 : 0) +
      (_minSell != null || _maxSell != null ? 1 : 0) +
      (_minBuyback != null || _maxBuyback != null ? 1 : 0);

  void _showFilterSheet() {
    String localSearch = _nameSearch;
    double? localMinSell = _minSell;
    double? localMaxSell = _maxSell;
    double? localMinBuyback = _minBuyback;
    double? localMaxBuyback = _maxBuyback;

    FilterSheet.show(
      context: context,
      title: 'Filter Live Prices',
      onReset: () => setState(() {
        _nameSearch = '';
        _minSell = _maxSell = _minBuyback = _maxBuyback = null;
      }),
      builder: (setSheetState) => [
        FilterSection(
          label: 'Product Name',
          child: FilterSearchField(
            hint: 'Search name...',
            value: localSearch,
            onChanged: (v) {
              localSearch = v;
              setState(() => _nameSearch = v);
            },
          ),
        ),
        FilterSection(
          label: 'Sell Price (\$)',
          child: FilterRangeSlider(
            min: 0,
            max: 5000,
            currentMin: localMinSell ?? 0,
            currentMax: localMaxSell ?? 5000,
            format: (v) => '\$${v.toStringAsFixed(0)}',
            onChanged: (range) {
              localMinSell = range.start > 0 ? range.start : null;
              localMaxSell = range.end < 5000 ? range.end : null;
              setState(() {
                _minSell = localMinSell;
                _maxSell = localMaxSell;
              });
              setSheetState(() {});
            },
          ),
        ),
        FilterSection(
          label: 'Buyback Price (\$)',
          child: FilterRangeSlider(
            min: 0,
            max: 5000,
            currentMin: localMinBuyback ?? 0,
            currentMax: localMaxBuyback ?? 5000,
            format: (v) => '\$${v.toStringAsFixed(0)}',
            onChanged: (range) {
              localMinBuyback = range.start > 0 ? range.start : null;
              localMaxBuyback = range.end < 5000 ? range.end : null;
              setState(() {
                _minBuyback = localMinBuyback;
                _maxBuyback = localMaxBuyback;
              });
              setSheetState(() {});
            },
          ),
        ),
      ],
    );
  }

  List<LivePrice> _applyFilters(List<LivePrice> prices) {
    return prices.where((p) {
      if (_nameSearch.isNotEmpty) {
        final name = (p.livePriceName ?? '').toLowerCase();
        if (!name.contains(_nameSearch.toLowerCase())) return false;
      }
      if (_minSell != null && (p.sellPrice ?? 0) < _minSell!) return false;
      if (_maxSell != null && (p.sellPrice ?? 0) > _maxSell!) return false;
      if (_minBuyback != null && (p.buybackPrice ?? 0) < _minBuyback!) {
        return false;
      }
      if (_maxBuyback != null && (p.buybackPrice ?? 0) > _maxBuyback!) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _scrapeAll() async {
    setState(() => _scraping = true);
    try {
      final summary =
          await ref.read(livePricesNotifierProvider.notifier).scrapeAll();
      ref.invalidate(portfolioValuationProvider);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Scrape Results'),
            content: Text(summary),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK')),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _scraping = false);
    }
  }

  Future<void> _editPrice(LivePrice price) async {
    final sellCtrl = TextEditingController(
        text: price.sellPrice?.toStringAsFixed(2) ?? '');
    final buyCtrl = TextEditingController(
        text: price.buybackPrice?.toStringAsFixed(2) ?? '');
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Edit Live Price'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: sellCtrl,
                decoration: const InputDecoration(
                  labelText: 'Sell Price',
                  prefixText: '\$',
                  prefixIcon: Icon(Icons.trending_up),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: buyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Buyback Price',
                  prefixText: '\$',
                  prefixIcon: Icon(Icons.trending_down),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save')),
          ],
        ),
      );
      if (ok == true && mounted) {
        final sell =
            sellCtrl.text.isNotEmpty ? double.tryParse(sellCtrl.text) : null;
        final buyback =
            buyCtrl.text.isNotEmpty ? double.tryParse(buyCtrl.text) : null;
        await ref.read(livePricesNotifierProvider.notifier).updatePrice(
              id: price.id,
              sellPrice: sell,
              buybackPrice: buyback,
            );
        ref.invalidate(portfolioValuationProvider);
      }
    } finally {
      sellCtrl.dispose();
      buyCtrl.dispose();
    }
  }

  Future<void> _deletePrice(LivePrice price) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Live Price'),
        content: const Text(
            'This will permanently delete this live price entry.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.textPrimary),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref.read(livePricesNotifierProvider.notifier).deletePrice(price.id);
      ref.invalidate(portfolioValuationProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final livePricesAsync = ref.watch(livePricesNotifierProvider);
    final profilesAsync = ref.watch(productProfilesProvider);

    return AppScaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const AppLogoTitle('Live Prices'),
        backgroundColor: AppColors.backgroundCard,
        actions: [
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
          ref.watch(unmappedLivePricesProvider).when(
                data: (unmapped) => Badge(
                  label: Text('${unmapped.length}'),
                  isLabelVisible: unmapped.isNotEmpty,
                  child: IconButton(
                    icon: const Icon(Icons.link),
                    tooltip: 'Map prices to profiles',
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LivePriceMappingScreen(),
                        ),
                      );
                      ref.invalidate(livePricesNotifierProvider);
                    },
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
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
        foregroundColor: AppColors.textDark,
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
                      'Tap + to add prices manually, or use the sync button to scrape retailers.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Apply filters
          final filtered = _applyFilters(livePrices);

          if (filtered.isEmpty && livePrices.isNotEmpty) {
            return const Center(
              child: Text('No results match your filters.',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }

          // Group by date descending
          final pricesByDate = <String, List<LivePrice>>{};
          for (final price in filtered) {
            final key = price.captureDate.toIso8601String().split('T')[0];
            pricesByDate.putIfAbsent(key, () => []).add(price);
          }
          final sortedDates = pricesByDate.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return profilesAsync.when(
            data: (profiles) {
              final profileMap = {for (var p in profiles) p.id: p};
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
                            onEdit: () => _editPrice(price),
                            onDelete: () => _deletePrice(price),
                          )),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LivePriceCard({
    required this.livePrice,
    required this.profile,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final priceColor = profile != null
        ? MetalColorHelper.getColorForMetal(profile!.metalTypeEnum)
        : AppColors.textPrimary;

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
                  Image.asset(
                    MetalColorHelper.getAssetPathForMetal(profile!.metalTypeEnum),
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
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
                      Text(
                        livePrice.retailerAbbr != null
                            ? '${livePrice.retailerAbbr} · ${livePrice.retailerName ?? ''}'
                            : livePrice.retailerName ?? 'Unknown Retailer',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (profile == null)
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
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
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      color: AppColors.textSecondary, size: 20),
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete,
                            size: 18, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Delete',
                            style: TextStyle(color: AppColors.error)),
                      ]),
                    ),
                  ],
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
                                  color: priceColor),
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
                                  color: priceColor),
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
