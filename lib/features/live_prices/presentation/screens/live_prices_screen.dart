// lib/features/live_prices/presentation/screens/live_prices_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:metal_tracker/core/constants/app_constants.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/core/utils/time_service.dart';
import 'package:metal_tracker/core/utils/weight_converter.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/core/utils/sort_config.dart';
import 'package:metal_tracker/core/widgets/filter_sheet.dart';
import 'package:metal_tracker/core/widgets/scraper_selector_sheet.dart';
import 'package:metal_tracker/core/constants/scraper_constants.dart';
import 'package:metal_tracker/features/holdings/presentation/providers/holdings_providers.dart';
import 'package:metal_tracker/features/live_prices/data/models/live_price_model.dart';
import 'package:metal_tracker/features/live_prices/presentation/providers/live_prices_providers.dart';
import 'package:metal_tracker/features/product_profiles/data/models/product_profile_model.dart';
import 'package:metal_tracker/features/product_profiles/presentation/providers/product_profiles_providers.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_prefs_providers.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_profile_providers.dart';
import 'package:metal_tracker/features/settings/presentation/screens/settings_screen.dart';
import 'package:metal_tracker/features/product_profiles/presentation/screens/product_profile_mapping_screen.dart';

final _currencyFmt = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
final _dateTimeFmt = DateFormat(AppDateFormats.compact);

// Flex weights — must stay in sync between header and row
const _kDateFlex     = 18;
const _kMetalFlex    = 7;
const _kNameFlex     = 24;
const _kRetailerFlex = 11;
const _kSellFlex     = 15;
const _kBuyFlex      = 15;
const _kNormFlex     = 13;

enum _SortColumn { date, name, retailer, sell, buyback, norm }

// ─── Screen ───────────────────────────────────────────────────────────────────

class LivePricesScreen extends ConsumerStatefulWidget {
  const LivePricesScreen({super.key});

  @override
  ConsumerState<LivePricesScreen> createState() => _LivePricesScreenState();
}

class _LivePricesScreenState extends ConsumerState<LivePricesScreen> {
  // Filters
  String? _datePreset;
  Set<String> _metalFilters = {};    // MetalType.name ('gold', 'silver', 'platinum')
  Set<String> _retailerFilters = {}; // retailer display names
  String? _mappedFilter;             // null | 'mapped' | 'unmapped'
  String _nameFilter = '';
  double? _sellMin, _sellMax, _buyMin, _buyMax;

  // All-prices cache for range bounds
  List<LivePrice> _allPrices = [];

  // Sort
  SortConfig<_SortColumn> _sortConfig =
      SortConfig.initial(_SortColumn.date, ascending: false);

  // Scrape
  bool _scraping = false;

  // Pref pre-population
  bool _filterInited = false;

  int get _activeFilterCount =>
      (_datePreset != null ? 1 : 0) +
      _metalFilters.length +
      _retailerFilters.length +
      (_mappedFilter != null ? 1 : 0) +
      (_nameFilter.isNotEmpty ? 1 : 0) +
      (_sellMin != null || _sellMax != null ? 1 : 0) +
      (_buyMin != null || _buyMax != null ? 1 : 0);

  // ─── Filter sheet ──────────────────────────────────────────────────────────

  void _showFilterSheet(BuildContext context, List<String> retailers) {
    final allSell =
        _allPrices.map((p) => p.sellPrice).whereType<double>().toList();
    final allBuy =
        _allPrices.map((p) => p.buybackPrice).whereType<double>().toList();
    final sellLo = allSell.isEmpty ? 0.0 : allSell.reduce(math.min);
    final sellHi = allSell.isEmpty ? 10000.0 : allSell.reduce(math.max);
    final buyLo = allBuy.isEmpty ? 0.0 : allBuy.reduce(math.min);
    final buyHi = allBuy.isEmpty ? 10000.0 : allBuy.reduce(math.max);

    FilterSheet.show(
      context: context,
      title: 'Filter',
      initialSize: 0.75,
      maxSize: 0.95,
      onReset: () => setState(() {
        _datePreset = null;
        _metalFilters = {};
        _retailerFilters = {};
        _mappedFilter = null;
        _nameFilter = '';
        _sellMin = _sellMax = null;
        _buyMin = _buyMax = null;
      }),
      builder: (setSheet) {
        void update(VoidCallback fn) {
          setSheet(fn);
          setState(fn);
        }

        return [
          FilterSection(
            label: 'Date',
            child: FilterChipGroup<String>(
              options: const [
                FilterChipOption(value: 'today', label: 'Today'),
                FilterChipOption(value: 'ytd', label: 'Yesterday'),
                FilterChipOption(value: 'week', label: 'Last 7 days'),
                FilterChipOption(value: 'month', label: 'Last 30 days'),
              ],
              selected: _datePreset,
              onChanged: (v) => update(() => _datePreset = v),
            ),
          ),
          FilterSection(
            label: 'Product Name',
            child: FilterSearchField(
              hint: 'Search product name…',
              value: _nameFilter,
              onChanged: (v) => update(() => _nameFilter = v),
            ),
          ),
          FilterSection(
            label: 'Metal',
            child: Column(
              children: MetalType.values.map((m) {
                return FilterCheckRow(
                  label: m.displayName,
                  color: MetalColorHelper.getColorForMetal(m),
                  checked: _metalFilters.contains(m.name),
                  onChanged: (v) => update(() {
                    v ? _metalFilters.add(m.name) : _metalFilters.remove(m.name);
                  }),
                );
              }).toList(),
            ),
          ),
          if (retailers.length > 1)
            FilterSection(
              label: 'Retailer',
              child: Column(
                children: retailers
                    .map((r) => FilterCheckRow(
                          label: r,
                          color: AppColors.textPrimary,
                          checked: _retailerFilters.contains(r),
                          onChanged: (v) => update(() {
                            v
                                ? _retailerFilters.add(r)
                                : _retailerFilters.remove(r);
                          }),
                        ))
                    .toList(),
              ),
            ),
          if (sellLo < sellHi)
            FilterSection(
              label: 'Sell Price',
              child: FilterRangeSlider(
                min: sellLo,
                max: sellHi,
                currentMin: _sellMin ?? sellLo,
                currentMax: _sellMax ?? sellHi,
                format: (v) => '\$${v.toStringAsFixed(0)}',
                onChanged: (v) => update(() {
                  _sellMin = v.start == sellLo ? null : v.start;
                  _sellMax = v.end == sellHi ? null : v.end;
                }),
              ),
            ),
          if (buyLo < buyHi)
            FilterSection(
              label: 'Buyback Price',
              child: FilterRangeSlider(
                min: buyLo,
                max: buyHi,
                currentMin: _buyMin ?? buyLo,
                currentMax: _buyMax ?? buyHi,
                format: (v) => '\$${v.toStringAsFixed(0)}',
                onChanged: (v) => update(() {
                  _buyMin = v.start == buyLo ? null : v.start;
                  _buyMax = v.end == buyHi ? null : v.end;
                }),
              ),
            ),
          FilterSection(
            label: 'Mapping',
            child: FilterChipGroup<String>(
              options: const [
                FilterChipOption(value: 'mapped', label: 'Mapped'),
                FilterChipOption(value: 'unmapped', label: 'Unmapped'),
              ],
              selected: _mappedFilter,
              onChanged: (v) => update(() => _mappedFilter = v),
            ),
          ),
        ];
      },
    );
  }

  // ─── Scrape ────────────────────────────────────────────────────────────────

  Future<void> _scrapeAll() async {
    final selected = await ScraperSelectorSheet.show(
      context,
      scraperType: ScraperType.livePrice,
      title: 'Select Retailers to Scrape',
    );
    if (selected == null || !mounted) return;

    setState(() => _scraping = true);
    try {
      final reports = await ref
          .read(livePricesNotifierProvider.notifier)
          .scrapeAll(restrictToRetailerIds: selected);
      ref.invalidate(portfolioValuationProvider);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => _ScrapeResultsDialog(reports: reports),
        );
      }
    } finally {
      if (mounted) setState(() => _scraping = false);
    }
  }

  // ─── Edit ──────────────────────────────────────────────────────────────────

  Future<void> _editPrice(LivePrice price) async {
    final sellCtrl = TextEditingController(
        text: price.sellPrice?.toStringAsFixed(2) ?? '');
    final buyCtrl = TextEditingController(
        text: price.buybackPrice?.toStringAsFixed(2) ?? '');
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.backgroundCard,
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (ok == true && mounted) {
        final sell = sellCtrl.text.isNotEmpty
            ? double.tryParse(sellCtrl.text)
            : null;
        final buyback = buyCtrl.text.isNotEmpty
            ? double.tryParse(buyCtrl.text)
            : null;
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

  // ─── Delete ────────────────────────────────────────────────────────────────

  Future<void> _deletePrice(LivePrice price) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text('Delete Live Price'),
        content: const Text(
            'This will permanently delete this live price entry.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textPrimary,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref
          .read(livePricesNotifierProvider.notifier)
          .deletePrice(price.id);
      ref.invalidate(portfolioValuationProvider);
    }
  }

  // ─── Sort ──────────────────────────────────────────────────────────────────

  void _onHeaderTap(_SortColumn col) {
    setState(() {
      _sortConfig = _sortConfig.tap(
        col,
        defaultAscending: (c) =>
            c == _SortColumn.name || c == _SortColumn.retailer,
      );
    });
  }

  // ─── Filter helpers ────────────────────────────────────────────────────────

  bool _matchesDate(DateTime dt) {
    if (_datePreset == null) return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    switch (_datePreset) {
      case 'today':  return d == today;
      case 'ytd':    return d == today.subtract(const Duration(days: 1));
      case 'week':   return dt.isAfter(today.subtract(const Duration(days: 7)));
      case 'month':  return dt.isAfter(today.subtract(const Duration(days: 30)));
      default:       return true;
    }
  }

  static int _cmpNullLast(double? a, double? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  static double? _normPrice(LivePrice p, Map<String, ProductProfile> pm) {
    final profile = pm[p.productProfileId];
    if (p.buybackPrice == null || profile == null) return null;
    return WeightCalculations.pricePerPureOunce(
      totalPrice: p.buybackPrice!,
      weight: profile.weight,
      unit: profile.weightUnitEnum,
      purity: profile.purity,
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final livePricesAsync = ref.watch(livePricesNotifierProvider);
    final profilesAsync = ref.watch(productProfilesNotifierProvider);

    // Pre-populate filters from user prefs on first load
    if (!_filterInited) {
      final metals = ref.watch(userMetaltypePrefsNotifierProvider).valueOrNull;
      final retailers = ref.watch(userRetailerPrefsNotifierProvider).valueOrNull;
      if (metals != null && retailers != null) {
        _filterInited = true;
        _datePreset = 'month'; // default to last 30 days
        if (metals.isNotEmpty) {
          _metalFilters = metals.map((m) => m.metalTypeName).toSet();
        }
        if (retailers.isNotEmpty) {
          _retailerFilters = retailers
              .map((r) => r.retailerName ?? '')
              .where((n) => n.isNotEmpty)
              .toSet();
        }
      }
    }

    // Reactive updates when prefs change after initial load
    ref.listen(userMetaltypePrefsNotifierProvider, (_, next) {
      final metals = next.valueOrNull ?? [];
      if (metals.isNotEmpty && mounted) {
        setState(() => _metalFilters = metals.map((m) => m.metalTypeName).toSet());
      }
    });
    ref.listen(userRetailerPrefsNotifierProvider, (_, next) {
      final retailers = next.valueOrNull ?? [];
      if (retailers.isNotEmpty && mounted) {
        setState(() => _retailerFilters = retailers
            .map((r) => r.retailerName ?? '')
            .where((n) => n.isNotEmpty)
            .toSet());
      }
    });

    return AppScaffold(
      title: 'Live Prices',
      onRefresh: () => ref.invalidate(livePricesNotifierProvider),
      actions: [
        // Map button
        IconButton(
          icon: const Icon(Icons.link_rounded),
          tooltip: 'Map to profiles',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const ProductProfileMappingScreen()),
          ),
        ),
        // Filter button with active-count badge
        livePricesAsync.when(
          data: (prices) {
            final retailers = prices
                .map((p) => p.retailerName ?? 'Unknown')
                .toSet()
                .toList()
              ..sort();
            return Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: const Icon(Icons.tune),
                  tooltip: 'Filter',
                  onPressed: () => _showFilterSheet(context, retailers),
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
            );
          },
          loading: () => const IconButton(
            icon: Icon(Icons.tune),
            onPressed: null,
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
        // Scrape button — admin only
        if (ref.watch(isAdminProvider)) ...[
          if (_scraping)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryGold,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.cloud_sync),
              tooltip: 'Scrape all retailers',
              onPressed: _scrapeAll,
            ),
        ],
      ],
      body: livePricesAsync.when(
        data: (livePrices) => profilesAsync.when(
          data: (profiles) => _buildContent(livePrices, profiles),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) =>
              const Center(child: Text('Error loading profiles')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }

  Widget _buildContent(
      List<LivePrice> allPrices, List<ProductProfile> profiles) {
    _allPrices = allPrices; // cache for filter-sheet range bounds
    final profileMap = {for (final p in profiles) p.id: p};

    // Filter
    final filtered = allPrices.where((p) {
      if (!_matchesDate(p.captureTimestamp)) return false;
      if (_retailerFilters.isNotEmpty &&
          !_retailerFilters.contains(p.retailerName ?? '')) {
        return false;
      }
      if (_mappedFilter == 'mapped' && p.productProfileId == null) {
        return false;
      }
      if (_mappedFilter == 'unmapped' && p.productProfileId != null) {
        return false;
      }
      if (_metalFilters.isNotEmpty) {
        final profile = profileMap[p.productProfileId];
        if (profile == null ||
            !_metalFilters.contains(profile.metalTypeEnum.name)) {
          return false;
        }
      }
      if (_nameFilter.isNotEmpty) {
        final name = (profileMap[p.productProfileId]?.profileName ??
                p.livePriceName ?? '')
            .toLowerCase();
        if (!name.contains(_nameFilter.toLowerCase())) return false;
      }
      if (_sellMin != null && (p.sellPrice == null || p.sellPrice! < _sellMin!)) {
        return false;
      }
      if (_sellMax != null && (p.sellPrice == null || p.sellPrice! > _sellMax!)) {
        return false;
      }
      if (_buyMin != null && (p.buybackPrice == null || p.buybackPrice! < _buyMin!)) {
        return false;
      }
      if (_buyMax != null && (p.buybackPrice == null || p.buybackPrice! > _buyMax!)) {
        return false;
      }
      return true;
    }).toList();

    // Sort
    _sortConfig.sortList(filtered, (a, b, col) {
      switch (col) {
        case _SortColumn.date:
          return a.captureTimestamp.compareTo(b.captureTimestamp);
        case _SortColumn.name:
          final aName = profileMap[a.productProfileId]?.profileName ??
              a.livePriceName ?? '';
          final bName = profileMap[b.productProfileId]?.profileName ??
              b.livePriceName ?? '';
          return aName.compareTo(bName);
        case _SortColumn.retailer:
          return (a.retailerName ?? '').compareTo(b.retailerName ?? '');
        case _SortColumn.sell:
          return _cmpNullLast(a.sellPrice, b.sellPrice);
        case _SortColumn.buyback:
          return _cmpNullLast(a.buybackPrice, b.buybackPrice);
        case _SortColumn.norm:
          return _cmpNullLast(
            _normPrice(a, profileMap),
            _normPrice(b, profileMap),
          );
      }
    });

    if (filtered.isEmpty) {
      final noPrefs = _metalFilters.isEmpty && _retailerFilters.isEmpty;
      return _EmptyState(hasFilters: _activeFilterCount > 0, noPrefs: noPrefs);
    }

    return Column(
      children: [
        _TableHeader(
          config: _sortConfig,
          onTap: _onHeaderTap,
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final price = filtered[i];
              final profile = profileMap[price.productProfileId];
              return _TableRow(
                price: price,
                profile: profile,
                normPrice: _normPrice(price, profileMap),
                onTap: () => _editPrice(price),
                onLongPress: () => _deletePrice(price),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Table Header ─────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  final SortConfig<_SortColumn> config;
  final ValueChanged<_SortColumn> onTap;

  const _TableHeader({
    required this.config,
    required this.onTap,
  });

  Widget _cell(String label, _SortColumn col, int flex) {
    final primary   = config.isPrimary(col);
    final secondary = config.isSecondary(col);
    final active    = primary || secondary;
    final color = primary
        ? AppColors.primaryGold
        : secondary
            ? AppColors.primaryGold.withAlpha(160)
            : AppColors.textSecondary;
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: () => onTap(col),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (active) ...[
                const SizedBox(width: 2),
                Icon(
                  config.isAscending(col)
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  size: primary ? 11 : 9,
                  color: color,
                ),
                if (secondary) ...[
                  const SizedBox(width: 1),
                  Text(
                    '2',
                    style: TextStyle(
                      color: color,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundCard,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Metal icon column — spacer, no label
          _cell('Date', _SortColumn.date, _kDateFlex),
          const Expanded(flex: _kMetalFlex, child: SizedBox.shrink()),
          _cell('Product', _SortColumn.name, _kNameFlex),
          _cell('Retailer', _SortColumn.retailer, _kRetailerFlex),
          _cell('Sell', _SortColumn.sell, _kSellFlex),
          _cell('Buyback', _SortColumn.buyback, _kBuyFlex),
          _cell(r'BB $/oz', _SortColumn.norm, _kNormFlex),
        ],
      ),
    );
  }
}

// ─── Table Row ────────────────────────────────────────────────────────────────

class _TableRow extends StatelessWidget {
  final LivePrice price;
  final ProductProfile? profile;
  final double? normPrice;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _TableRow({
    required this.price,
    required this.profile,
    required this.normPrice,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final metalColor = profile != null
        ? MetalColorHelper.getColorForMetal(profile!.metalTypeEnum)
        : AppColors.textSecondary;
    final name =
        profile?.profileName ?? price.livePriceName ?? '—';
    final retailer = price.retailerAbbr ?? price.retailerName ?? '—';

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white10)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Date + time (single line)
            Expanded(
              flex: _kDateFlex,
              child: Text(
                _dateTimeFmt.format(price.captureTimestamp),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 10),
              ),
            ),
            // Metal icon
            Expanded(
              flex: _kMetalFlex,
              child: profile != null
                  ? Image.asset(
                      MetalColorHelper.getAssetPathForMetal(
                          profile!.metalTypeEnum),
                      width: 18,
                      height: 18,
                      fit: BoxFit.contain,
                    )
                  : const Icon(Icons.help_outline,
                      size: 16, color: AppColors.warning),
            ),
            // Product name
            Expanded(
              flex: _kNameFlex,
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: metalColor, fontSize: 11),
              ),
            ),
            // Retailer
            Expanded(
              flex: _kRetailerFlex,
              child: Text(
                retailer,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11),
              ),
            ),
            // Sell price
            Expanded(
              flex: _kSellFlex,
              child: Text(
                price.sellPrice != null
                    ? _currencyFmt.format(price.sellPrice)
                    : '—',
                style: TextStyle(
                  color: price.sellPrice != null
                      ? metalColor
                      : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Buyback price
            Expanded(
              flex: _kBuyFlex,
              child: Text(
                price.buybackPrice != null
                    ? _currencyFmt.format(price.buybackPrice)
                    : '—',
                style: TextStyle(
                  color: price.buybackPrice != null
                      ? metalColor
                      : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Normalised price per pure oz
            Expanded(
              flex: _kNormFlex,
              child: Text(
                normPrice != null
                    ? _currencyFmt.format(normPrice)
                    : '—',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: normPrice != null
                      ? metalColor
                      : AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  final bool noPrefs;
  const _EmptyState({required this.hasFilters, this.noPrefs = false});

  @override
  Widget build(BuildContext context) {
    if (noPrefs) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.tune_outlined,
                  size: 56, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              const Text(
                'Set your preferences',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose which metals and retailers to track in Settings.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: const Text('Go to Settings'),
              ),
            ],
          ),
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.price_change_outlined,
              size: 56, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'No prices match the filter' : 'No live prices yet',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if (!hasFilters) ...[
            const SizedBox(height: 8),
            const Text(
              'Use the sync button to scrape retailers.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Scrape Results Dialog ────────────────────────────────────────────────────

class _ScrapeResultsDialog extends StatelessWidget {
  final List<RetailerScrapeReport> reports;

  const _ScrapeResultsDialog({required this.reports});

  static final _priceFmt =
      NumberFormat.currency(symbol: r'$', decimalDigits: 2);

  Color _statusColor(String status) => switch (status) {
        'success' => AppColors.success,
        'partial' => AppColors.warning,
        _ => AppColors.error,
      };

  IconData _statusIcon(String status) => switch (status) {
        'success' => Icons.check_circle_outline,
        'partial' => Icons.warning_amber_outlined,
        _ => Icons.error_outline,
      };

  String _metalLabel(String metalType) =>
      metalType[0].toUpperCase() + metalType.substring(1);

  @override
  Widget build(BuildContext context) {
    final totalCaptured =
        reports.fold<int>(0, (sum, r) => sum + r.prices.length);

    return AlertDialog(
      backgroundColor: AppColors.backgroundCard,
      title: Row(
        children: [
          const Icon(Icons.cloud_sync, color: AppColors.primaryGold, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Scrape Results',
              style: TextStyle(fontSize: 16),
            ),
          ),
          Text(
            '$totalCaptured captured',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: reports.isEmpty
            ? const Text(
                'No scrapers configured.',
                style: TextStyle(color: AppColors.textSecondary),
              )
            : ListView.separated(
                shrinkWrap: true,
                itemCount: reports.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: Colors.white12, height: 24),
                itemBuilder: (_, i) => _RetailerReportTile(
                  report: reports[i],
                  statusColor: _statusColor(reports[i].status),
                  statusIcon: _statusIcon(reports[i].status),
                  metalLabel: _metalLabel,
                  priceFmt: _priceFmt,
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class _RetailerReportTile extends StatelessWidget {
  final RetailerScrapeReport report;
  final Color statusColor;
  final IconData statusIcon;
  final String Function(String) metalLabel;
  final NumberFormat priceFmt;

  const _RetailerReportTile({
    required this.report,
    required this.statusColor,
    required this.statusIcon,
    required this.metalLabel,
    required this.priceFmt,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Retailer header
        Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                report.retailerName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              report.status,
              style: TextStyle(color: statusColor, fontSize: 11),
            ),
          ],
        ),

        // Captured metals
        if (report.prices.isNotEmpty) ...[
          const SizedBox(height: 6),
          // Column headers
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Row(
              children: const [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Metal',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'Sell',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'Buyback',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          ...report.prices.entries.map((entry) {
            final metal = entry.key;
            final sell = entry.value['sell'];
            final buyback = entry.value['buyback'];
            final metalColor =
                MetalColorHelper.getColorForMetalString(metal);
            return Padding(
              padding: const EdgeInsets.only(left: 22, top: 3),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      metalLabel(metal),
                      style: TextStyle(
                          color: metalColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      sell != null ? priceFmt.format(sell) : '—',
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      buyback != null ? priceFmt.format(buyback) : '—',
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],

        // Errors
        if (report.errors.isNotEmpty) ...[
          const SizedBox(height: 6),
          ...report.errors.map(
            (err) => Padding(
              padding: const EdgeInsets.only(left: 22, top: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.close, color: AppColors.error, size: 12),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      err,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
