// lib/features/product_profiles/presentation/screens/product_profiles_screen.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/constants/app_constants.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/core/utils/sort_config.dart';
import 'package:metal_tracker/core/widgets/filter_sheet.dart';
import 'package:metal_tracker/features/product_profiles/data/models/product_profile_model.dart';
import 'package:metal_tracker/features/product_profiles/presentation/providers/product_profiles_providers.dart';
import 'package:metal_tracker/features/admin/data/models/change_request_model.dart';
import 'package:metal_tracker/features/admin/presentation/widgets/change_request_dialog.dart';
import 'package:metal_tracker/features/product_profiles/presentation/screens/add_product_profile_screen.dart';
import 'package:metal_tracker/features/product_profiles/presentation/screens/edit_product_profile_screen.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_profile_providers.dart';

// Flex weights — kept in sync between header and row
const _kMetalFlex  = 10;
const _kNameFlex   = 28;
const _kFormFlex   = 18;
const _kWeightFlex = 17;
const _kPurityFlex = 13;
const _kNormFlex   = 14;

enum _SortColumn { metal, name, form, weight, purity, normOz }

/// Straight weight-unit conversion to troy oz (no purity applied).
double _toNormOz(double weight, String weightUnit) {
  switch (weightUnit) {
    case 'kg':
      return weight * 32.1507;
    case 'g':
      return weight * 0.03215;
    default: // 'oz'
      return weight;
  }
}

class ProductProfilesScreen extends ConsumerStatefulWidget {
  const ProductProfilesScreen({super.key});

  @override
  ConsumerState<ProductProfilesScreen> createState() =>
      _ProductProfilesScreenState();
}

class _ProductProfilesScreenState
    extends ConsumerState<ProductProfilesScreen> {
  // Filters
  String? _metalFilter;
  String? _formFilter;
  double? _weightMin, _weightMax;
  double? _purityMin, _purityMax;
  double? _normOzMin, _normOzMax;

  // Cache of all loaded profiles (used for slider bounds)
  List<ProductProfile> _allProfiles = [];

  // Sort
  SortConfig<_SortColumn> _sortConfig =
      SortConfig.initial(_SortColumn.normOz, ascending: true);

  int get _activeFilterCount =>
      (_metalFilter != null ? 1 : 0) +
      (_formFilter != null ? 1 : 0) +
      (_weightMin != null ? 1 : 0) +
      (_purityMin != null ? 1 : 0) +
      (_normOzMin != null ? 1 : 0);

  // ─── Filter sheet ──────────────────────────────────────────────────────────

  void _showFilterSheet(BuildContext context) {
    final weightHi = _allProfiles.isEmpty
        ? 0.0
        : (_allProfiles.map((p) => p.weight).reduce(math.max) * 1.01)
            .ceilToDouble();
    final normHi = _allProfiles.isEmpty
        ? 0.0
        : (_allProfiles
                    .map((p) => _toNormOz(p.weight, p.weightUnit))
                    .reduce(math.max) *
                1.01)
            .ceilToDouble();

    FilterSheet.show(
      context: context,
      title: 'Filter',
      initialSize: 0.55,
      maxSize: 0.85,
      onReset: () => setState(() {
        _metalFilter = null;
        _formFilter = null;
        _weightMin = null;
        _weightMax = null;
        _purityMin = null;
        _purityMax = null;
        _normOzMin = null;
        _normOzMax = null;
      }),
      builder: (setSheet) {
        void update(VoidCallback fn) {
          setSheet(fn);
          setState(fn);
        }

        return [
          FilterSection(
            label: 'Metal',
            child: FilterChipGroup<String>(
              options: MetalType.values
                  .map((m) => FilterChipOption(
                      value: m.displayName, label: m.displayName))
                  .toList(),
              selected: _metalFilter,
              onChanged: (v) => update(() => _metalFilter = v),
            ),
          ),
          FilterSection(
            label: 'Form',
            child: FilterChipGroup<String>(
              options: MetalForm.values
                  .map((f) => FilterChipOption(
                      value: f.displayName, label: f.displayName))
                  .toList(),
              selected: _formFilter,
              onChanged: (v) => update(() => _formFilter = v),
            ),
          ),
          if (_allProfiles.isNotEmpty)
            FilterSection(
              label: 'Weight (raw)',
              child: FilterRangeSlider(
                min: 0,
                max: weightHi,
                currentMin: _weightMin ?? 0,
                currentMax: _weightMax ?? weightHi,
                format: (v) => v.toStringAsFixed(1),
                onChanged: (r) => update(() {
                  _weightMin = r.start <= 0 ? null : r.start;
                  _weightMax = r.end >= weightHi ? null : r.end;
                }),
              ),
            ),
          FilterSection(
            label: 'Purity (%)',
            child: FilterRangeSlider(
              min: 0,
              max: 100,
              currentMin: _purityMin ?? 0,
              currentMax: _purityMax ?? 100,
              format: (v) => '${v.toStringAsFixed(0)}%',
              onChanged: (r) => update(() {
                _purityMin = r.start <= 0 ? null : r.start;
                _purityMax = r.end >= 100 ? null : r.end;
              }),
            ),
          ),
          if (_allProfiles.isNotEmpty)
            FilterSection(
              label: 'Norm oz',
              child: FilterRangeSlider(
                min: 0,
                max: normHi,
                currentMin: _normOzMin ?? 0,
                currentMax: _normOzMax ?? normHi,
                format: (v) => v.toStringAsFixed(2),
                onChanged: (r) => update(() {
                  _normOzMin = r.start <= 0 ? null : r.start;
                  _normOzMax = r.end >= normHi ? null : r.end;
                }),
              ),
            ),
        ];
      },
    );
  }

  // ─── Sort ─────────────────────────────────────────────────────────────────

  void _onHeaderTap(_SortColumn col) {
    setState(() {
      _sortConfig = _sortConfig.tap(col, defaultAscending: (_) => true);
    });
  }

  List<ProductProfile> _sortProfiles(List<ProductProfile> profiles) {
    final result = List<ProductProfile>.from(profiles);
    _sortConfig.sortList(result, (a, b, col) {
      switch (col) {
        case _SortColumn.metal:
          return a.metalType.compareTo(b.metalType);
        case _SortColumn.name:
          return a.profileName.compareTo(b.profileName);
        case _SortColumn.form:
          return a.metalForm.compareTo(b.metalForm);
        case _SortColumn.weight:
          return a.weight.compareTo(b.weight);
        case _SortColumn.purity:
          return a.purity.compareTo(b.purity);
        case _SortColumn.normOz:
          return _toNormOz(a.weight, a.weightUnit)
              .compareTo(_toNormOz(b.weight, b.weightUnit));
      }
    });
    return result;
  }

  // ─── Filter ───────────────────────────────────────────────────────────────

  List<ProductProfile> _filterProfiles(List<ProductProfile> profiles) {
    return profiles.where((p) {
      if (_metalFilter != null && p.metalType != _metalFilter) return false;
      if (_formFilter != null && p.metalForm != _formFilter) return false;
      if (_weightMin != null && p.weight < _weightMin!) return false;
      if (_weightMax != null && p.weight > _weightMax!) return false;
      if (_purityMin != null && p.purity < _purityMin!) return false;
      if (_purityMax != null && p.purity > _purityMax!) return false;
      final normOz = _toNormOz(p.weight, p.weightUnit);
      if (_normOzMin != null && normOz < _normOzMin!) return false;
      if (_normOzMax != null && normOz > _normOzMax!) return false;
      return true;
    }).toList();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(productProfilesNotifierProvider);

    return AppScaffold(
      title: 'Product Profiles',
      onRefresh: () => ref.invalidate(productProfilesNotifierProvider),
      actions: [
        // Filter button with badge
        Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'Filter',
              onPressed: () => _showFilterSheet(context),
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
        // Add button
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Add Profile',
          onPressed: () async {
            final result = await Navigator.push<dynamic>(
              context,
              MaterialPageRoute(
                  builder: (_) => const AddProductProfileScreen()),
            );
            if (result != null) {
              ref.invalidate(productProfilesNotifierProvider);
            }
          },
        ),
      ],
      body: profilesAsync.when(
        data: _buildContent,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }

  Widget _buildContent(List<ProductProfile> allProfiles) {
    _allProfiles = allProfiles;
    final filtered = _sortProfiles(_filterProfiles(allProfiles));

    if (filtered.isEmpty) {
      return _EmptyState(hasFilters: _activeFilterCount > 0);
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
            itemBuilder: (ctx, i) => _TableRow(
              profile: filtered[i],
              onTap: () => _onRowTap(filtered[i]),
              onLongPress: () => _onRowLongPress(filtered[i]),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onRowTap(ProductProfile profile) async {
    if (ref.read(isAdminProvider)) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
            builder: (_) => EditProductProfileScreen(profile: profile)),
      );
      if (result == true) {
        ref.invalidate(productProfilesNotifierProvider);
      }
    } else {
      if (!mounted) return;
      await showChangeRequestDialog(
        context,
        requestType: ChangeRequestType.changeProductProfile,
        prefillSubject: 'Change profile: ${profile.profileName}',
      );
    }
  }

  Future<void> _onRowLongPress(ProductProfile profile) async {
    if (!ref.read(isAdminProvider)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text('Delete Profile'),
        content: Text(
          'Delete "${profile.profileName}"? This cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(productProfilesNotifierProvider.notifier)
          .deleteProfile(profile.id);
    }
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
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
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
    final metalPrimary   = config.isPrimary(_SortColumn.metal);
    final metalSecondary = config.isSecondary(_SortColumn.metal);
    final metalActive    = metalPrimary || metalSecondary;
    final metalColor = metalPrimary
        ? AppColors.primaryGold
        : metalSecondary
            ? AppColors.primaryGold.withAlpha(160)
            : AppColors.textSecondary;
    return Container(
      color: AppColors.backgroundCard,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Metal column header — icon only, tappable
          Expanded(
            flex: _kMetalFlex,
            child: GestureDetector(
              onTap: () => onTap(_SortColumn.metal),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bar_chart, size: 14, color: metalColor),
                    if (metalActive) ...[
                      const SizedBox(width: 2),
                      Icon(
                        config.isAscending(_SortColumn.metal)
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: metalPrimary ? 11 : 9,
                        color: metalColor,
                      ),
                      if (metalSecondary) ...[
                        const SizedBox(width: 1),
                        Text('2', style: TextStyle(color: metalColor, fontSize: 8, fontWeight: FontWeight.w700)),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
          _cell('Name', _SortColumn.name, _kNameFlex),
          _cell('Form', _SortColumn.form, _kFormFlex),
          _cell('Weight', _SortColumn.weight, _kWeightFlex),
          _cell('Purity', _SortColumn.purity, _kPurityFlex),
          _cell('Norm oz', _SortColumn.normOz, _kNormFlex),
        ],
      ),
    );
  }
}

// ─── Table Row ────────────────────────────────────────────────────────────────

class _TableRow extends StatelessWidget {
  final ProductProfile profile;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _TableRow({
    required this.profile,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final metalColor =
        MetalColorHelper.getColorForMetalString(profile.metalType);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white10)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Metal icon
            Expanded(
              flex: _kMetalFlex,
              child: Image.asset(
                MetalColorHelper.getAssetPathForMetalString(profile.metalType),
                width: 22,
                height: 22,
                fit: BoxFit.contain,
              ),
            ),
            // Name
            Expanded(
              flex: _kNameFlex,
              child: Text(
                profile.profileName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: metalColor,
                  fontSize: 12,
                ),
              ),
            ),
            // Form
            Expanded(
              flex: _kFormFlex,
              child: Text(
                profile.metalForm,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
            // Weight
            Expanded(
              flex: _kWeightFlex,
              child: Text(
                '${profile.weightDisplay}${profile.weightUnit}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
            // Purity
            Expanded(
              flex: _kPurityFlex,
              child: Text(
                '${profile.purity.toStringAsFixed(2)}%',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
            // Norm oz
            Expanded(
              flex: _kNormFlex,
              child: Text(
                _toNormOz(profile.weight, profile.weightUnit)
                    .toStringAsFixed(2),
                style: const TextStyle(
                  color: AppColors.textSecondary,
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


// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  const _EmptyState({required this.hasFilters});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.category_outlined,
              size: 56, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'No profiles match the filter' : 'No product profiles yet',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          if (!hasFilters)
            const Text(
              'Tap + to create your first product profile.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}
