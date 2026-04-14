// lib/features/retailers/presentation/screens/retailers_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/constants/scraper_constants.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/features/admin/data/models/change_request_model.dart';
import 'package:metal_tracker/features/admin/presentation/widgets/change_request_dialog.dart';
import 'package:metal_tracker/features/retailers/data/models/retailer_scraper_setting_model.dart';
import 'package:metal_tracker/features/retailers/data/models/retailers_model.dart';
import 'package:metal_tracker/features/retailers/presentation/providers/retailers_providers.dart';
import 'package:metal_tracker/features/retailers/presentation/screens/add_edit_provider_screen.dart';
import 'package:metal_tracker/features/retailers/presentation/screens/add_edit_retailer_screen.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/features/retailers/presentation/screens/add_edit_scraper_setting_screen.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_prefs_providers.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_profile_providers.dart';
import 'package:metal_tracker/features/spot_prices/data/models/global_spot_provider_model.dart';

class RetailersScreen extends ConsumerStatefulWidget {
  const RetailersScreen({super.key});

  @override
  ConsumerState<RetailersScreen> createState() => _RetailersScreenState();
}

class _RetailersScreenState extends ConsumerState<RetailersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted && !_tabController.indexIsChanging) {
        setState(() => _tab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);

    Widget? actionButton;
    if (_tab == 0 && !isAdmin) {
      actionButton = TextButton.icon(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: const Icon(Icons.add_business_outlined,
            size: 16, color: AppColors.primaryGold),
        label: const Text('Request Retailer',
            style: TextStyle(color: AppColors.primaryGold, fontSize: 12)),
        onPressed: () => showChangeRequestDialog(
          context,
          requestType: ChangeRequestType.newRetailer,
          prefillSubject: 'Add new retailer',
        ),
      );
    } else if (_tab == 1 && isAdmin) {
      actionButton = TextButton.icon(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: const Icon(Icons.add, size: 16, color: AppColors.primaryGold),
        label: const Text('Add Provider',
            style: TextStyle(color: AppColors.primaryGold, fontSize: 12)),
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) => const AddEditProviderScreen()),
          );
          if (result == true) {
            ref.invalidate(
                globalSpotProvidersProvider(activeOnly: false));
          }
        },
      );
    } else if (_tab == 1 && !isAdmin) {
      actionButton = TextButton.icon(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: const Icon(Icons.add_circle_outline,
            size: 16, color: AppColors.primaryGold),
        label: const Text('Request Provider',
            style: TextStyle(color: AppColors.primaryGold, fontSize: 12)),
        onPressed: () => showChangeRequestDialog(
          context,
          requestType: ChangeRequestType.newGlobalSpotProvider,
          prefillSubject: 'Add new global spot provider',
        ),
      );
    }

    return AppScaffold(
      title: 'Retailers & Providers',
      actions: [if (actionButton != null) actionButton],
      tabBar: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primaryGold,
        labelColor: AppColors.primaryGold,
        unselectedLabelColor: AppColors.textSecondary,
        tabs: const [
          Tab(text: 'Retailers'),
          Tab(text: 'Providers'),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _RetailersTab(),
          _ProvidersTab(),
        ],
      ),
    );
  }
}

// ─── Retailers Tab ────────────────────────────────────────────────────────────

class _RetailersTab extends ConsumerWidget {
  const _RetailersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final retailersAsync = ref.watch(retailersProvider);
    final isAdmin = ref.watch(isAdminProvider);

    return RefreshIndicator(
      color: AppColors.primaryGold,
      onRefresh: () async => ref.invalidate(retailersProvider),
      child: retailersAsync.when(
        data: (retailers) {
          final activeRetailers = retailers.where((r) => r.isActive).toList();

          return Stack(
            children: [
              if (activeRetailers.isEmpty)
                const Center(
                  child: Text(
                    'No active retailers',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: activeRetailers.length,
                  itemBuilder: (context, index) {
                    return RetailerCard(
                      retailer: activeRetailers[index],
                      isAdmin: isAdmin,
                    );
                  },
                ),
              if (isAdmin)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    heroTag: 'add_retailer',
                    backgroundColor: AppColors.primaryGold,
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const AddEditRetailerScreen(retailer: null),
                        ),
                      );
                      if (result == true) ref.invalidate(retailersProvider);
                    },
                    child: const Icon(Icons.add, color: AppColors.textDark),
                  ),
                ),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
        error: (error, _) => Center(
          child: Text('Error: $error',
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }
}

// ─── Providers Tab ────────────────────────────────────────────────────────────

class _ProvidersTab extends ConsumerWidget {
  const _ProvidersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersAsync =
        ref.watch(globalSpotProvidersProvider(activeOnly: false));
    final isAdmin = ref.watch(isAdminProvider);

    return RefreshIndicator(
      color: AppColors.primaryGold,
      onRefresh: () async =>
          ref.invalidate(globalSpotProvidersProvider(activeOnly: false)),
      child: providersAsync.when(
        data: (providers) {
          if (providers.isEmpty) {
            return const Center(
              child: Text(
                'No global spot providers',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: providers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _ProviderCard(
              provider: providers[i],
              isAdmin: isAdmin,
              onChanged: () => ref
                  .invalidate(globalSpotProvidersProvider(activeOnly: false)),
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }
}

// ─── Provider Card ────────────────────────────────────────────────────────────

class _ProviderCard extends ConsumerStatefulWidget {
  final GlobalSpotProvider provider;
  final bool isAdmin;
  final VoidCallback onChanged;

  const _ProviderCard({
    required this.provider,
    required this.isAdmin,
    required this.onChanged,
  });

  @override
  ConsumerState<_ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends ConsumerState<_ProviderCard> {
  bool _toggling = false;

  Future<void> _toggleActive() async {
    setState(() => _toggling = true);
    try {
      final updated = GlobalSpotProvider(
        id: widget.provider.id,
        name: widget.provider.name,
        providerKey: widget.provider.providerKey,
        baseUrl: widget.provider.baseUrl,
        description: widget.provider.description,
        isActive: !widget.provider.isActive,
        createdAt: widget.provider.createdAt,
      );
      await ref
          .read(globalSpotProvidersRepositoryProvider)
          .updateProvider(updated);
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _deleteProvider() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text('Delete Provider?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'This will permanently delete "${widget.provider.name}".',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.lossRed)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref
          .read(globalSpotProvidersRepositoryProvider)
          .deleteProvider(widget.provider.id);
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    final activeColor =
        p.isActive ? AppColors.gainGreen : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // Active indicator (admin-toggleable)
          GestureDetector(
            onTap: widget.isAdmin && !_toggling ? _toggleActive : null,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _toggling
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    )
                  : Tooltip(
                      message: widget.isAdmin
                          ? (p.isActive
                              ? 'Active — tap to disable'
                              : 'Inactive — tap to enable')
                          : (p.isActive ? 'Active' : 'Inactive'),
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: activeColor.withValues(alpha: 0.15),
                          border: Border.all(color: activeColor, width: 1.5),
                          shape: BoxShape.circle,
                        ),
                        child: p.isActive
                            ? Icon(Icons.check, size: 10, color: activeColor)
                            : null,
                      ),
                    ),
            ),
          ),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  p.providerKey,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11),
                ),
                if (p.description != null && p.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      p.description!,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),

          // Actions
          if (widget.isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  size: 18, color: AppColors.textSecondary),
              tooltip: 'Edit',
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AddEditProviderScreen(provider: widget.provider),
                  ),
                );
                if (result == true) widget.onChanged();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: AppColors.lossRed),
              tooltip: 'Delete',
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: _deleteProvider,
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.edit_note_outlined,
                  size: 18, color: AppColors.primaryGold),
              tooltip: 'Request change',
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () => showChangeRequestDialog(
                context,
                requestType: ChangeRequestType.changeGlobalSpotProvider,
                prefillSubject: 'Change provider: ${p.name}',
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Retailer Card ────────────────────────────────────────────────────────────

class RetailerCard extends ConsumerWidget {
  final Retailer retailer;
  final bool isAdmin;

  const RetailerCard({
    super.key,
    required this.retailer,
    this.isAdmin = false,
  });

  Future<void> _navigateToAdd(
    BuildContext context,
    WidgetRef ref,
    String scraperType,
  ) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditScraperSettingScreen(
          retailerId: retailer.id,
          initialScraperType: scraperType,
        ),
      ),
    );
    if (result == true) {
      ref.invalidate(retailerScraperSettingsProvider(retailer.id));
    }
  }

  Future<void> _navigateToEdit(
    BuildContext context,
    WidgetRef ref,
    RetailerScraperSetting setting,
  ) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditScraperSettingScreen(
          retailerId: retailer.id,
          setting: setting,
        ),
      ),
    );
    if (result == true) {
      ref.invalidate(retailerScraperSettingsProvider(retailer.id));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(
      retailerScraperSettingsProvider(retailer.id),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Retailer header ──────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        retailer.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (retailer.retailerAbbr != null)
                        Text(
                          retailer.retailerAbbr!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AddEditRetailerScreen(retailer: retailer),
                        ),
                      );
                      if (result == true) ref.invalidate(retailersProvider);
                    },
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.edit_note_outlined,
                        color: AppColors.primaryGold),
                    tooltip: 'Request a change',
                    onPressed: () => showChangeRequestDialog(
                      context,
                      requestType: ChangeRequestType.changeRetailer,
                      prefillSubject: 'Change retailer: ${retailer.name}',
                    ),
                  ),
              ],
            ),
            if (retailer.baseUrl != null) ...[
              const SizedBox(height: 4),
              Text(
                retailer.baseUrl!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.primaryGold),
              ),
            ],
            const Divider(height: 24),

            // ── Scraper settings sections ────────────────────────────────
            settingsAsync.when(
              data: (settings) => Column(
                children: [
                  _ScraperSection(
                    label: 'Live Price',
                    icon: Icons.monetization_on,
                    scraperType: ScraperType.livePrice,
                    retailerId: retailer.id,
                    settings: settings
                        .where((s) => s.scraperType == ScraperType.livePrice)
                        .toList(),
                    isAdmin: isAdmin,
                    onAdd: isAdmin
                        ? () => _navigateToAdd(
                            context, ref, ScraperType.livePrice)
                        : null,
                    onEdit: (s) =>
                        isAdmin ? _navigateToEdit(context, ref, s) : null,
                  ),
                  const SizedBox(height: 12),
                  _ScraperSection(
                    label: 'Local Spot',
                    icon: Icons.store_outlined,
                    scraperType: ScraperType.localSpot,
                    retailerId: retailer.id,
                    settings: settings
                        .where((s) => s.scraperType == ScraperType.localSpot)
                        .toList(),
                    isAdmin: isAdmin,
                    onAdd: isAdmin
                        ? () => _navigateToAdd(
                            context, ref, ScraperType.localSpot)
                        : null,
                    onEdit: (s) =>
                        isAdmin ? _navigateToEdit(context, ref, s) : null,
                  ),
                  const SizedBox(height: 12),
                  _ScraperSection(
                    label: 'Product Listing',
                    icon: Icons.shopping_cart_outlined,
                    scraperType: ScraperType.productListing,
                    retailerId: retailer.id,
                    settings: settings
                        .where((s) =>
                            s.scraperType == ScraperType.productListing)
                        .toList(),
                    isAdmin: isAdmin,
                    onAdd: isAdmin
                        ? () => _navigateToAdd(
                            context, ref, ScraperType.productListing)
                        : null,
                    onEdit: (s) =>
                        isAdmin ? _navigateToEdit(context, ref, s) : null,
                  ),
                ],
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const Text('Error loading settings'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Scraper Section ──────────────────────────────────────────────────────────

class _ScraperSection extends StatelessWidget {
  final String label;
  final IconData icon;
  final String scraperType;
  final String retailerId;
  final List<RetailerScraperSetting> settings;
  final bool isAdmin;
  final VoidCallback? onAdd;
  final void Function(RetailerScraperSetting)? onEdit;

  const _ScraperSection({
    required this.label,
    required this.icon,
    required this.scraperType,
    required this.retailerId,
    required this.settings,
    required this.isAdmin,
    required this.onAdd,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          // Section header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isAdmin)
                  InkWell(
                    onTap: onAdd,
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.add_circle_outline,
                          size: 20, color: AppColors.primaryGold),
                    ),
                  ),
              ],
            ),
          ),

          // Settings list
          const Divider(height: 1, color: Colors.white10),
          if (settings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                'No settings — tap + to add',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            )
          else
            ...settings.map((s) => _SettingRow(
                  setting: s,
                  retailerId: retailerId,
                  isAdmin: isAdmin,
                  onEdit: onEdit != null ? () => onEdit!(s) : null,
                )),
        ],
      ),
    );
  }
}

// ─── Setting Row ──────────────────────────────────────────────────────────────

class _SettingRow extends ConsumerStatefulWidget {
  final RetailerScraperSetting setting;
  final String retailerId;
  final bool isAdmin;
  final VoidCallback? onEdit;

  const _SettingRow({
    required this.setting,
    required this.retailerId,
    required this.isAdmin,
    required this.onEdit,
  });

  @override
  ConsumerState<_SettingRow> createState() => _SettingRowState();
}

class _SettingRowState extends ConsumerState<_SettingRow> {
  bool _toggling = false;

  Future<void> _toggleActive() async {
    setState(() => _toggling = true);
    try {
      await ref.read(retailerRepositoryProvider).updateScraperSetting(
            settingId: widget.setting.id,
            isActive: !widget.setting.isActive,
          );
      ref.invalidate(
          retailerScraperSettingsProvider(widget.retailerId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.setting;
    final metalLabel = s.metalType != null
        ? s.metalType![0].toUpperCase() + s.metalType!.substring(1)
        : 'All';
    final activeColor =
        s.isActive ? AppColors.success : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          // Active toggle (admin-only interactive)
          if (widget.isAdmin)
            GestureDetector(
              onTap: _toggling ? null : _toggleActive,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: _toggling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child:
                            CircularProgressIndicator(strokeWidth: 1.5),
                      )
                    : Tooltip(
                        message: s.isActive
                            ? 'Active — tap to disable'
                            : 'Inactive — tap to enable',
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: activeColor.withValues(alpha: 0.15),
                            border: Border.all(
                                color: activeColor, width: 1.5),
                            shape: BoxShape.circle,
                          ),
                          child: s.isActive
                              ? Icon(Icons.check,
                                  size: 10, color: activeColor)
                              : null,
                        ),
                      ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(6),
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.15),
                  border: Border.all(color: activeColor, width: 1.5),
                  shape: BoxShape.circle,
                ),
                child: s.isActive
                    ? Icon(Icons.check, size: 10, color: activeColor)
                    : null,
              ),
            ),
          const SizedBox(width: 6),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metalLabel,
                  style: TextStyle(
                    color: s.isActive
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  s.searchString,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
                if (s.searchUrl != null)
                  Text(
                    s.searchUrl!,
                    style: const TextStyle(
                        color: AppColors.primaryGold, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (widget.isAdmin)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              color: AppColors.textSecondary,
              onPressed: widget.onEdit,
            ),
        ],
      ),
    );
  }
}
