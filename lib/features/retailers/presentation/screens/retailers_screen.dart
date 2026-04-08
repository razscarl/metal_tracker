// lib/features/retailers/presentation/screens/retailers_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/constants/scraper_constants.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/widgets/app_drawer.dart';
import 'package:metal_tracker/core/widgets/app_logo_title.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/features/retailers/data/models/retailer_scraper_setting_model.dart';
import 'package:metal_tracker/features/retailers/data/models/retailers_model.dart';
import 'package:metal_tracker/features/retailers/presentation/providers/retailers_providers.dart';
import 'package:metal_tracker/features/retailers/presentation/screens/add_edit_retailer_screen.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/features/retailers/presentation/screens/add_edit_scraper_setting_screen.dart';

class RetailersScreen extends ConsumerWidget {
  const RetailersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final retailersAsync = ref.watch(retailersProvider);

    return AppScaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const AppLogoTitle('Retailers'),
        backgroundColor: AppColors.backgroundCard,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const AddEditRetailerScreen(retailer: null),
                ),
              );
              if (result == true) {
                ref.invalidate(retailersProvider);
              }
            },
          ),
        ],
      ),
      body: retailersAsync.when(
        data: (retailers) {
          final activeRetailers = retailers.where((r) => r.isActive).toList();

          if (activeRetailers.isEmpty) {
            return const Center(child: Text('No active retailers'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeRetailers.length,
            itemBuilder: (context, index) {
              return RetailerCard(retailer: activeRetailers[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

// ─── Retailer Card ────────────────────────────────────────────────────────────

class RetailerCard extends ConsumerWidget {
  final Retailer retailer;

  const RetailerCard({super.key, required this.retailer});

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
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddEditRetailerScreen(retailer: retailer),
                      ),
                    );
                    if (result == true) {
                      ref.invalidate(retailersProvider);
                    }
                  },
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
                    onAdd: () => _navigateToAdd(
                        context, ref, ScraperType.livePrice),
                    onEdit: (s) => _navigateToEdit(context, ref, s),
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
                    onAdd: () => _navigateToAdd(
                        context, ref, ScraperType.localSpot),
                    onEdit: (s) => _navigateToEdit(context, ref, s),
                  ),
                  const SizedBox(height: 12),
                  _ScraperSection(
                    label: 'Product Listing',
                    icon: Icons.shopping_cart_outlined,
                    scraperType: ScraperType.productListing,
                    retailerId: retailer.id,
                    settings: const [],
                    comingSoon: true,
                    onAdd: null,
                    onEdit: (s) => _navigateToEdit(context, ref, s),
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
  final bool comingSoon;
  final VoidCallback? onAdd;
  final void Function(RetailerScraperSetting) onEdit;

  const _ScraperSection({
    required this.label,
    required this.icon,
    required this.scraperType,
    required this.retailerId,
    required this.settings,
    required this.onAdd,
    required this.onEdit,
    this.comingSoon = false,
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
                if (comingSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Coming soon',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 10),
                    ),
                  )
                else
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
          if (!comingSoon) ...[
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
                    onEdit: () => onEdit(s),
                  )),
          ],
        ],
      ),
    );
  }
}

// ─── Setting Row ──────────────────────────────────────────────────────────────

class _SettingRow extends ConsumerStatefulWidget {
  final RetailerScraperSetting setting;
  final String retailerId;
  final VoidCallback onEdit;

  const _SettingRow({
    required this.setting,
    required this.retailerId,
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
          // Active toggle
          GestureDetector(
            onTap: _toggling ? null : _toggleActive,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: _toggling
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    )
                  : Tooltip(
                      message: s.isActive ? 'Active — tap to disable' : 'Inactive — tap to enable',
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
