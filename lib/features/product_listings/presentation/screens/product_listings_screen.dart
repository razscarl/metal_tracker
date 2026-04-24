// lib/features/product_listings/presentation/screens/product_listings_screen.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:metal_tracker/core/constants/app_constants.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/utils/time_service.dart';
import 'package:metal_tracker/features/product_profiles/presentation/screens/product_profile_mapping_screen.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/core/utils/weight_converter.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/core/utils/sort_config.dart';
import 'package:metal_tracker/core/widgets/filter_sheet.dart';
import 'package:metal_tracker/features/product_listings/data/models/product_listing_model.dart';
import 'package:metal_tracker/features/product_listings/presentation/providers/product_listings_providers.dart';
import 'package:metal_tracker/features/product_profiles/data/models/product_profile_model.dart';
import 'package:metal_tracker/features/product_profiles/presentation/providers/product_profiles_providers.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_profile_providers.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/core/widgets/profile_search_field.dart';

final _currencyFmt = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
final _dateTimeFmt = DateFormat(AppDateFormats.compact);

// Flex weights — must stay in sync between header and row
const _kDateFlex     = 18;
const _kMetalFlex    = 7;
const _kNameFlex     = 30;
const _kRetailerFlex = 12;
const _kSellFlex     = 16;
const _kNormFlex     = 15;

enum _SortCol { date, name, retailer, sell, norm }

// ─── Screen ───────────────────────────────────────────────────────────────────

class ProductListingsScreen extends ConsumerStatefulWidget {
  const ProductListingsScreen({super.key});

  @override
  ConsumerState<ProductListingsScreen> createState() =>
      _ProductListingsScreenState();
}

class _ProductListingsScreenState
    extends ConsumerState<ProductListingsScreen> {
  // Filters
  Set<String> _metalFilters = {};
  Set<String> _formFilters = {};
  Set<String> _retailerFilters = {};
  String? _mappedFilter; // null | 'mapped' | 'unmapped'
  String? _datePreset;   // null | 'today' | 'week' | 'month' | 'year'
  double? _sellMin, _sellMax;
  double? _normMin, _normMax;

  // Cache for filter range bounds
  List<ProductListing> _allListings = [];
  Map<String, ProductProfile> _profileMap = {};

  // Sort
  SortConfig<_SortCol> _sortConfig =
      SortConfig.initial(_SortCol.date, ascending: false);

  bool _isFetching = false;

  int get _activeFilterCount =>
      _metalFilters.length +
      _formFilters.length +
      _retailerFilters.length +
      (_mappedFilter != null ? 1 : 0) +
      (_datePreset != null ? 1 : 0) +
      (_sellMin != null ? 1 : 0) +
      (_normMin != null ? 1 : 0);

  // ── Filter sheet ────────────────────────────────────────────────────────────

  void _showFilterSheet(BuildContext context, List<String> retailers) {
    final sellHi = _allListings.isEmpty
        ? 0.0
        : (_allListings.map((l) => l.listingSellPrice).reduce(math.max) * 1.01)
            .ceilToDouble();
    final norms = _allListings
        .map((l) => _normPrice(l, _profileMap))
        .whereType<double>()
        .toList();
    final normHi = norms.isEmpty
        ? 0.0
        : (norms.reduce(math.max) * 1.01).ceilToDouble();

    FilterSheet.show(
      context: context,
      title: 'Filter',
      initialSize: 0.6,
      onReset: () => setState(() {
        _metalFilters = {};
        _formFilters = {};
        _retailerFilters = {};
        _mappedFilter = null;
        _datePreset = null;
        _sellMin = null;
        _sellMax = null;
        _normMin = null;
        _normMax = null;
      }),
      builder: (setSheet) {
        void update(VoidCallback fn) {
          setSheet(fn);
          setState(fn);
        }

        return [
          FilterSection(
            label: 'Date',
            child: FilterDatePreset(
              selected: _datePreset,
              onChanged: (v) => update(() => _datePreset = v),
            ),
          ),
          FilterSection(
            label: 'Metal',
            child: Column(
              children: MetalType.values
                  .map((m) => FilterCheckRow(
                        label: m.displayName,
                        color: MetalColorHelper.getColorForMetal(m),
                        checked: _metalFilters.contains(m.name),
                        onChanged: (v) => update(() => v
                            ? _metalFilters.add(m.name)
                            : _metalFilters.remove(m.name)),
                      ))
                  .toList(),
            ),
          ),
          FilterSection(
            label: 'Form',
            child: Column(
              children: MetalForm.values
                  .map((f) => FilterCheckRow(
                        label: f.displayName,
                        color: AppColors.textPrimary,
                        checked: _formFilters.contains(f.displayName),
                        onChanged: (v) => update(() => v
                            ? _formFilters.add(f.displayName)
                            : _formFilters.remove(f.displayName)),
                      ))
                  .toList(),
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
                          onChanged: (v) => update(() => v
                              ? _retailerFilters.add(r)
                              : _retailerFilters.remove(r)),
                        ))
                    .toList(),
              ),
            ),
          if (_allListings.isNotEmpty)
            FilterSection(
              label: 'Sell Price',
              child: FilterRangeSlider(
                min: 0,
                max: sellHi,
                currentMin: _sellMin ?? 0,
                currentMax: _sellMax ?? sellHi,
                format: (v) => '\$${v.toStringAsFixed(0)}',
                onChanged: (r) => update(() {
                  _sellMin = r.start <= 0 ? null : r.start;
                  _sellMax = r.end >= sellHi ? null : r.end;
                }),
              ),
            ),
          if (norms.isNotEmpty)
            FilterSection(
              label: '\$/oz',
              child: FilterRangeSlider(
                min: 0,
                max: normHi,
                currentMin: _normMin ?? 0,
                currentMax: _normMax ?? normHi,
                format: (v) => '\$${v.toStringAsFixed(0)}',
                onChanged: (r) => update(() {
                  _normMin = r.start <= 0 ? null : r.start;
                  _normMax = r.end >= normHi ? null : r.end;
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

  // ── Fetch ───────────────────────────────────────────────────────────────────

  Future<void> _fetchListings() async {
    if (_isFetching) return;
    setState(() => _isFetching = true);
    try {
      final reports =
          await ref.read(productListingsNotifierProvider.notifier).scrapeAll();
      if (mounted) _showResultsDialog(reports);
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  void _showResultsDialog(List<RetailerListingReport> reports) {
    final relevant =
        reports.where((r) => r.status != 'no_settings').toList();
    showDialog<void>(
      context: context,
      builder: (_) => _ScrapeResultsDialog(reports: relevant),
    );
  }

  // ── Mapping ─────────────────────────────────────────────────────────────────

  void _showMappingSheet(
    BuildContext context,
    ProductListing listing,
    List<ProductProfile> profiles,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MappingSheet(
        listing: listing,
        profiles: profiles,
        onSaved: () {
          ref.invalidate(productListingsNotifierProvider);
        },
      ),
    );
  }

  // ── Sort ────────────────────────────────────────────────────────────────────

  void _onHeaderTap(_SortCol col) {
    setState(() {
      _sortConfig = _sortConfig.tap(
        col,
        defaultAscending: (c) =>
            c == _SortCol.name || c == _SortCol.retailer,
      );
    });
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(productListingsNotifierProvider);
    final profilesAsync = ref.watch(productProfilesNotifierProvider);
    final isAdmin = ref.watch(isAdminProvider);

    return AppScaffold(
      title: 'Listings',
      onRefresh: () => ref.invalidate(productListingsNotifierProvider),
      actions: [
        // Map button — admin only
        if (isAdmin)
          IconButton(
            icon: const Icon(Icons.link_rounded),
            tooltip: 'Map to profiles',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ProductProfileMappingScreen()),
            ),
          ),
        // Filter button
        listingsAsync.when(
          data: (listings) {
            final retailers = listings
                .map((l) => l.retailerName ?? 'Unknown')
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
          loading: () =>
              const IconButton(icon: Icon(Icons.tune), onPressed: null),
          error: (_, __) => const SizedBox.shrink(),
        ),
        // Fetch button — admin only
        if (isAdmin) ...[
          if (_isFetching)
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
              tooltip: 'Fetch listings',
              onPressed: _fetchListings,
            ),
        ],
      ],
      body: listingsAsync.when(
        data: (listings) => profilesAsync.when(
          data: (profiles) =>
              _buildContent(context, listings, profiles),
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (_, __) =>
              const Center(child: Text('Error loading profiles')),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGold),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.lossRed, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<ProductListing> allListings,
    List<ProductProfile> profiles,
  ) {
    _allListings = allListings;
    final profileMap = {for (final p in profiles) p.id: p};
    final isAdmin = ref.read(isAdminProvider);
    _profileMap = profileMap;

    final now = DateTime.now();
    final cutoff = _datePreset == null
        ? null
        : _datePreset == 'today'
            ? DateTime(now.year, now.month, now.day)
            : _datePreset == 'week'
                ? now.subtract(const Duration(days: 7))
                : _datePreset == 'month'
                    ? now.subtract(const Duration(days: 30))
                    : now.subtract(const Duration(days: 365));

    // Filter
    final filtered = allListings.where((l) {
      if (cutoff != null && l.scrapeTimestamp.isBefore(cutoff)) return false;
      if (_mappedFilter == 'mapped' && l.productProfileId == null) {
        return false;
      }
      if (_mappedFilter == 'unmapped' && l.productProfileId != null) {
        return false;
      }
      if (_retailerFilters.isNotEmpty &&
          !_retailerFilters.contains(l.retailerName ?? '')) {
        return false;
      }
      if (_metalFilters.isNotEmpty) {
        final profile = profileMap[l.productProfileId];
        if (profile == null ||
            !_metalFilters.contains(profile.metalTypeEnum.name)) {
          return false;
        }
      }
      if (_formFilters.isNotEmpty) {
        final profile = profileMap[l.productProfileId];
        if (profile == null ||
            !_formFilters.contains(profile.metalForm)) {
          return false;
        }
      }
      if (_sellMin != null && l.listingSellPrice < _sellMin!) return false;
      if (_sellMax != null && l.listingSellPrice > _sellMax!) return false;
      final np = _normPrice(l, profileMap);
      if (np != null) {
        if (_normMin != null && np < _normMin!) return false;
        if (_normMax != null && np > _normMax!) return false;
      }
      return true;
    }).toList();

    // Sort
    _sortConfig.sortList(filtered, (a, b, col) {
      switch (col) {
        case _SortCol.date:
          return a.scrapeTimestamp.compareTo(b.scrapeTimestamp);
        case _SortCol.name:
          final aName = profileMap[a.productProfileId]?.profileName ??
              a.listingName;
          final bName = profileMap[b.productProfileId]?.profileName ??
              b.listingName;
          return aName.compareTo(bName);
        case _SortCol.retailer:
          return (a.retailerName ?? '').compareTo(b.retailerName ?? '');
        case _SortCol.sell:
          return a.listingSellPrice.compareTo(b.listingSellPrice);
        case _SortCol.norm:
          return _cmpNullLast(
            _normPrice(a, profileMap),
            _normPrice(b, profileMap),
          );
      }
    });

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          allListings.isEmpty
              ? 'No listings scraped yet.\nTap the sync icon to fetch.'
              : 'No listings match the current filters.',
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      );
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
              final listing = filtered[i];
              final profile = profileMap[listing.productProfileId];
              return _TableRow(
                listing: listing,
                profile: profile,
                normPrice: _normPrice(listing, profileMap),
                onTap: isAdmin
                    ? () {
                        if (listing.productProfileId == null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductProfileMappingScreen(
                                initialListingId: listing.id,
                              ),
                            ),
                          ).then((_) =>
                              ref.invalidate(productListingsNotifierProvider));
                        } else {
                          _showMappingSheet(context, listing, profiles);
                        }
                      }
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  static double? _normPrice(
      ProductListing l, Map<String, ProductProfile> pm) {
    final profile = pm[l.productProfileId];
    if (profile == null) return null;
    return WeightCalculations.pricePerPureOunce(
      totalPrice: l.listingSellPrice,
      weight: profile.weight,
      unit: profile.weightUnitEnum,
      purity: profile.purity,
    );
  }

  static int _cmpNullLast(double? a, double? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }
}

// ─── Mapping bottom sheet ─────────────────────────────────────────────────────

class _MappingSheet extends ConsumerStatefulWidget {
  final ProductListing listing;
  final List<ProductProfile> profiles;
  final VoidCallback onSaved;

  const _MappingSheet({
    required this.listing,
    required this.profiles,
    required this.onSaved,
  });

  @override
  ConsumerState<_MappingSheet> createState() => _MappingSheetState();
}

class _MappingSheetState extends ConsumerState<_MappingSheet> {
  ProductProfile? _selectedProfile;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final id = widget.listing.productProfileId;
    _selectedProfile = id != null
        ? widget.profiles.where((p) => p.id == id).firstOrNull
        : null;
  }

  Future<void> _save() async {
    if (_selectedProfile == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(productListingsRepositoryProvider)
          .updateListingMapping(widget.listing.id, _selectedProfile!.id);
      widget.onSaved();
      if (mounted) Navigator.pop(context);
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

  Future<void> _removeMapping() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(productListingsRepositoryProvider)
          .updateListingMapping(widget.listing.id, null);
      widget.onSaved();
      if (mounted) Navigator.pop(context);
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
    final isMapped = widget.listing.productProfileId != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Listing info
          Text(
            widget.listing.listingName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                widget.listing.retailerName ?? '',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(width: 12),
              Text(
                _currencyFmt.format(widget.listing.listingSellPrice),
                style: const TextStyle(
                    color: AppColors.primaryGold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // Profile picker
          ProfileSearchField(
            profiles: [...widget.profiles]
              ..sort((a, b) => a.profileName.compareTo(b.profileName)),
            selected: _selectedProfile,
            onSelected: _saving
                ? (_) {}
                : (p) => setState(() => _selectedProfile = p),
            label: 'Type to search profiles…',
          ),
          const SizedBox(height: 16),
          // Buttons
          Row(
            children: [
              if (isMapped)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _removeMapping,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: const Text('Remove'),
                  ),
                ),
              if (isMapped) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_saving || _selectedProfile == null)
                      ? null
                      : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: AppColors.textDark,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Table Header ─────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  final SortConfig<_SortCol> config;
  final ValueChanged<_SortCol> onTap;

  const _TableHeader({
    required this.config,
    required this.onTap,
  });

  Widget _cell(String label, _SortCol col, int flex) {
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
                  Text('2', style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w700)),
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
          _cell('Date', _SortCol.date, _kDateFlex),
          const Expanded(flex: _kMetalFlex, child: SizedBox.shrink()),
          _cell('Product', _SortCol.name, _kNameFlex),
          _cell('Retailer', _SortCol.retailer, _kRetailerFlex),
          _cell('Sell', _SortCol.sell, _kSellFlex),
          _cell(r'$/oz', _SortCol.norm, _kNormFlex),
        ],
      ),
    );
  }
}

// ─── Table Row ────────────────────────────────────────────────────────────────

class _TableRow extends StatelessWidget {
  final ProductListing listing;
  final ProductProfile? profile;
  final double? normPrice;
  final VoidCallback? onTap;

  const _TableRow({
    required this.listing,
    required this.profile,
    required this.normPrice,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final metalColor = profile != null
        ? MetalColorHelper.getColorForMetal(profile!.metalTypeEnum)
        : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white10)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Date
            Expanded(
              flex: _kDateFlex,
              child: Text(
                _dateTimeFmt.format(listing.scrapeTimestamp),
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
                profile?.profileName ?? listing.listingName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: metalColor, fontSize: 11),
              ),
            ),
            // Retailer
            Expanded(
              flex: _kRetailerFlex,
              child: Text(
                listing.retailerAbbr ?? listing.retailerName ?? '—',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11),
              ),
            ),
            // Sell price
            Expanded(
              flex: _kSellFlex,
              child: Text(
                _currencyFmt.format(listing.listingSellPrice),
                style: TextStyle(
                  color: metalColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // $/oz
            Expanded(
              flex: _kNormFlex,
              child: Text(
                normPrice != null
                    ? _currencyFmt.format(normPrice)
                    : '—',
                style: TextStyle(
                  color: normPrice != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ─── Scrape results dialog ────────────────────────────────────────────────────

class _ScrapeResultsDialog extends StatelessWidget {
  final List<RetailerListingReport> reports;

  const _ScrapeResultsDialog({required this.reports});

  @override
  Widget build(BuildContext context) {
    final totalScraped =
        reports.fold<int>(0, (sum, r) => sum + r.scrapedCount);
    final totalSaved = reports.fold<int>(0, (sum, r) => sum + r.savedCount);

    return AlertDialog(
      backgroundColor: AppColors.backgroundCard,
      title: const Text('Fetch Results',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scraped: $totalScraped  ·  Saved: $totalSaved',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: reports.map((r) => _ReportRow(report: r)).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK',
              style: TextStyle(color: AppColors.primaryGold)),
        ),
      ],
    );
  }
}

class _ReportRow extends StatelessWidget {
  final RetailerListingReport report;

  const _ReportRow({required this.report});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (report.status) {
      'success' => (Icons.check_circle_outline, AppColors.gainGreen),
      'partial' => (Icons.warning_amber_rounded, AppColors.warning),
      'failed' => (Icons.cancel_outlined, AppColors.lossRed),
      _ => (Icons.error_outline, AppColors.lossRed),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  report.retailerName,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                '${report.scrapedCount} scraped / ${report.savedCount} saved',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
          ...report.errors.map((e) => Padding(
                padding: const EdgeInsets.only(left: 22, top: 2),
                child: Text(
                  e,
                  style: const TextStyle(
                      color: AppColors.lossRed, fontSize: 10),
                ),
              )),
        ],
      ),
    );
  }
}
