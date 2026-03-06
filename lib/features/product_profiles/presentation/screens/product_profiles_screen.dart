// lib/features/product_profiles/presentation/screens/product_profiles_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/constants/app_constants.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/core/widgets/app_drawer.dart';
import 'package:metal_tracker/core/widgets/app_logo_title.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/features/product_profiles/data/models/product_profile_model.dart';
import 'package:metal_tracker/features/product_profiles/presentation/providers/product_profiles_providers.dart';
import 'package:metal_tracker/features/product_profiles/presentation/screens/add_product_profile_screen.dart';
import 'package:metal_tracker/features/product_profiles/presentation/screens/edit_product_profile_screen.dart';

// Flex weights — kept in sync between header and row
const _kMetalFlex  = 10;
const _kNameFlex   = 35;
const _kFormFlex   = 18;
const _kWeightFlex = 17;
const _kPurityFlex = 15;

enum _SortColumn { metal, name, form, weight, purity }

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

  // Sort
  _SortColumn _sortColumn = _SortColumn.name;
  bool _sortAscending = true;

  int get _activeFilterCount =>
      (_metalFilter != null ? 1 : 0) + (_formFilter != null ? 1 : 0);

  // ─── Filter sheet ──────────────────────────────────────────────────────────

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          void update(VoidCallback fn) {
            setSheet(fn);
            setState(fn);
          }

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.55,
            minChildSize: 0.35,
            maxChildSize: 0.85,
            builder: (ctx, scrollCtrl) => Column(
              children: [
                // Title bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Filter',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (_activeFilterCount > 0)
                        TextButton(
                          onPressed: () => update(() {
                            _metalFilter = null;
                            _formFilter = null;
                          }),
                          child: const Text(
                            'Clear all',
                            style: TextStyle(
                                color: AppColors.error, fontSize: 13),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                Expanded(
                  child: ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    children: [
                      // Metal filter
                      _SheetSection(
                        label: 'Metal',
                        child: _RadioGroup<String?>(
                          options: [
                            (label: 'All', value: null),
                            ...MetalType.values.map(
                              (m) => (label: m.displayName, value: m.displayName),
                            ),
                          ],
                          current: _metalFilter,
                          onChanged: (v) => update(() => _metalFilter = v),
                        ),
                      ),

                      // Form filter
                      _SheetSection(
                        label: 'Form',
                        child: _RadioGroup<String?>(
                          options: [
                            (label: 'All', value: null),
                            ...MetalForm.values.map(
                              (f) => (label: f.displayName, value: f.displayName),
                            ),
                          ],
                          current: _formFilter,
                          onChanged: (v) => update(() => _formFilter = v),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Sort ─────────────────────────────────────────────────────────────────

  void _onHeaderTap(_SortColumn col) {
    setState(() {
      if (_sortColumn == col) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = col;
        _sortAscending = true;
      }
    });
  }

  List<ProductProfile> _sortProfiles(List<ProductProfile> profiles) {
    int compare(ProductProfile a, ProductProfile b) {
      switch (_sortColumn) {
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
      }
    }

    final sorted = List<ProductProfile>.from(profiles)..sort(compare);
    return _sortAscending ? sorted : sorted.reversed.toList();
  }

  // ─── Filter ───────────────────────────────────────────────────────────────

  List<ProductProfile> _filterProfiles(List<ProductProfile> profiles) {
    return profiles.where((p) {
      if (_metalFilter != null && p.metalType != _metalFilter) return false;
      if (_formFilter != null && p.metalForm != _formFilter) return false;
      return true;
    }).toList();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(productProfilesNotifierProvider);

    return AppScaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const AppLogoTitle('Product Profiles'),
        backgroundColor: AppColors.backgroundCard,
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
      ),
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
    final filtered = _sortProfiles(_filterProfiles(allProfiles));

    if (filtered.isEmpty) {
      return _EmptyState(hasFilters: _activeFilterCount > 0);
    }

    return Column(
      children: [
        _TableHeader(
          sortColumn: _sortColumn,
          sortAscending: _sortAscending,
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
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => EditProductProfileScreen(profile: profile)),
    );
    if (result == true) {
      ref.invalidate(productProfilesNotifierProvider);
    }
  }

  Future<void> _onRowLongPress(ProductProfile profile) async {
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
  final _SortColumn sortColumn;
  final bool sortAscending;
  final ValueChanged<_SortColumn> onTap;

  const _TableHeader({
    required this.sortColumn,
    required this.sortAscending,
    required this.onTap,
  });

  Widget _cell(String label, _SortColumn col, int flex) {
    final active = sortColumn == col;
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
                  color:
                      active ? AppColors.primaryGold : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (active) ...[
                const SizedBox(width: 2),
                Icon(
                  sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 11,
                  color: AppColors.primaryGold,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final metalActive = sortColumn == _SortColumn.metal;
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
                    Icon(
                      Icons.bar_chart,
                      size: 14,
                      color: metalActive
                          ? AppColors.primaryGold
                          : AppColors.textSecondary,
                    ),
                    if (metalActive) ...[
                      const SizedBox(width: 2),
                      Icon(
                        sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 11,
                        color: AppColors.primaryGold,
                      ),
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
          ],
        ),
      ),
    );
  }
}

// ─── Filter sheet sub-widgets ─────────────────────────────────────────────────

class _SheetSection extends StatelessWidget {
  final String label;
  final Widget child;
  const _SheetSection({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _RadioGroup<T> extends StatelessWidget {
  final List<({String label, T value})> options;
  final T current;
  final ValueChanged<T> onChanged;

  const _RadioGroup({
    required this.options,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final selected = opt.value == current;
        return GestureDetector(
          onTap: () => onChanged(opt.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primaryGold.withValues(alpha: 0.15)
                  : AppColors.backgroundDark,
              border: Border.all(
                color: selected ? AppColors.primaryGold : Colors.white12,
                width: selected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              opt.label,
              style: TextStyle(
                color: selected
                    ? AppColors.primaryGold
                    : AppColors.textSecondary,
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
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
