// lib/features/home/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:metal_tracker/core/constants/app_constants.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/utils/time_service.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/features/home/presentation/providers/home_providers.dart';
import 'package:metal_tracker/features/holdings/presentation/providers/holdings_providers.dart';
import 'package:metal_tracker/features/holdings/presentation/widgets/portfolio_valuation_card.dart';
import 'package:metal_tracker/features/live_prices/data/models/live_price_model.dart';
import 'package:metal_tracker/features/retailers/presentation/providers/retailers_providers.dart';
import 'package:metal_tracker/features/settings/data/models/user_retailer_pref_model.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_prefs_providers.dart';
import 'package:metal_tracker/features/settings/presentation/screens/settings_screen.dart';
import 'package:metal_tracker/features/spot_prices/data/models/spot_price_model.dart';

final _currencyFmt = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
final _dtFmt       = DateFormat(AppDateFormats.compact);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Set<String> _metalFilter    = {};
  Set<String> _retailerFilter = {};
  bool        _filterInited   = false;

  @override
  Widget build(BuildContext context) {
    final cs       = Theme.of(context).colorScheme;
    final metals   = ref.watch(userMetaltypePrefsNotifierProvider).valueOrNull ?? [];
    final retailers = ref.watch(userRetailerPrefsNotifierProvider).valueOrNull ?? [];
    final hasPrefs = metals.isNotEmpty || retailers.isNotEmpty;

    ref.listen(userMetaltypePrefsNotifierProvider, (_, next) {
      final m = next.valueOrNull ?? [];
      if (!_filterInited && m.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {
            _metalFilter  = m.map((x) => x.metalTypeName.toLowerCase()).toSet();
            _filterInited = true;
          });
        });
      }
    });
    ref.listen(userRetailerPrefsNotifierProvider, (_, next) {
      final r = next.valueOrNull ?? [];
      if (!_filterInited && r.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {
            _retailerFilter = r.map((x) => x.retailerId).toSet();
            _filterInited   = true;
          });
        });
      }
    });
    if (!_filterInited && hasPrefs) {
      _filterInited   = true;
      _metalFilter    = metals.map((m) => m.metalTypeName.toLowerCase()).toSet();
      _retailerFilter = retailers.map((r) => r.retailerId).toSet();
    }

    final activeFilterCount =
        (_metalFilter.length < 3 && _metalFilter.isNotEmpty ? 1 : 0) +
        (_retailerFilter.isNotEmpty ? 1 : 0);

    void invalidateAll() {
      ref.invalidate(homeBestPricesProvider);
      ref.invalidate(homeRecentLivePricesProvider);
      ref.invalidate(homeGlobalSpotPricesProvider);
      ref.invalidate(homeLocalSpotPricesProvider);
      ref.invalidate(portfolioValuationProvider);
      ref.invalidate(footerTimestampsProvider);
    }

    return AppScaffold(
      title:    'Metal Tracker',
      isHome:   true,
      onRefresh: invalidateAll,
      actions: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon:    const Icon(Icons.tune),
              tooltip: 'Filter',
              onPressed: hasPrefs
                  ? () => _showFilterSheet(
                      context,
                      metals.map((m) => m.metalTypeName).toList(),
                      retailers)
                  : null,
            ),
            if (activeFilterCount > 0)
              Positioned(
                top:   8,
                right: 8,
                child: Container(
                  width:  16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$activeFilterCount',
                      style: TextStyle(
                        color:      cs.onPrimary,
                        fontSize:   9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
      body: !hasPrefs
          ? _buildNoPrefsState(context)
          : RefreshIndicator(
              onRefresh: () async => invalidateAll(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PortfolioSection(
                      metalFilter:    _metalFilter,
                      retailerFilter: _retailerFilter,
                    ),
                    const SizedBox(height: 16),
                    _LivePricesSection(
                      metalFilter:    _metalFilter,
                      retailerFilter: _retailerFilter,
                    ),
                    const SizedBox(height: 16),
                    _GlobalSpotSection(metalFilter: _metalFilter),
                    const SizedBox(height: 16),
                    _LocalSpotSection(
                      metalFilter:    _metalFilter,
                      retailerFilter: _retailerFilter,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNoPrefsState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune, size: 56, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('Set your preferences', style: tt.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Select the metals and retailers you track to personalise your dashboard.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon:     const Icon(Icons.settings_outlined, size: 18),
              label:    const Text('Go to Settings'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(
    BuildContext context,
    List<String> allMetals,
    List<UserRetailerPref> allRetailers,
  ) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final cs = Theme.of(ctx).colorScheme;
          final tt = Theme.of(ctx).textTheme;
          void update(VoidCallback fn) {
            setSheet(fn);
            setState(fn);
          }

          return DraggableScrollableSheet(
            expand:          false,
            initialChildSize: 0.55,
            minChildSize:    0.4,
            maxChildSize:    0.85,
            builder: (ctx, scrollCtrl) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                  child: Row(
                    children: [
                      Expanded(child: Text('Filter', style: tt.titleMedium)),
                      TextButton(
                        onPressed: () => update(() {
                          _metalFilter    = allMetals.toSet();
                          _retailerFilter =
                              allRetailers.map((r) => r.retailerId).toSet();
                        }),
                        child: const Text('Reset'),
                      ),
                      IconButton(
                        icon:     const Icon(Icons.close),
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
                      _SheetSection(
                        label: 'Metals',
                        child: Column(
                          children: [
                            for (final m in ['gold', 'silver', 'platinum'])
                              if (allMetals.contains(m))
                                _CheckRow(
                                  label:   m[0].toUpperCase() + m.substring(1),
                                  color:   MetalColorHelper.getColorForMetalString(m),
                                  checked: _metalFilter.contains(m),
                                  onChanged: (v) => update(() {
                                    v ? _metalFilter.add(m) : _metalFilter.remove(m);
                                  }),
                                ),
                          ],
                        ),
                      ),
                      if (allRetailers.isNotEmpty)
                        _SheetSection(
                          label: 'Retailers',
                          child: Column(
                            children: [
                              for (final r in allRetailers)
                                _CheckRow(
                                  label:   r.retailerName ?? r.retailerId,
                                  color:   cs.onSurface,
                                  checked: _retailerFilter.contains(r.retailerId),
                                  onChanged: (v) => update(() {
                                    v
                                        ? _retailerFilter.add(r.retailerId)
                                        : _retailerFilter.remove(r.retailerId);
                                  }),
                                ),
                            ],
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
}

// ── Sheet helpers ─────────────────────────────────────────────────────────────

class _SheetSection extends StatelessWidget {
  final String label;
  final Widget child;
  const _SheetSection({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: tt.labelSmall?.copyWith(
              color:         cs.onSurfaceVariant,
              fontWeight:    FontWeight.w600,
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

class _CheckRow extends StatelessWidget {
  final String             label;
  final Color              color;
  final bool               checked;
  final ValueChanged<bool> onChanged;
  const _CheckRow({
    required this.label,
    required this.color,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!checked),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Checkbox(
              value:               checked,
              onChanged:           (v) => onChanged(v ?? false),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity:       VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String  title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: cs.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: tt.titleMedium?.copyWith(color: cs.primary),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            message,
            style:     Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// ── Portfolio section ─────────────────────────────────────────────────────────

class _PortfolioSection extends StatelessWidget {
  final Set<String> metalFilter;
  final Set<String> retailerFilter;
  const _PortfolioSection({required this.metalFilter, required this.retailerFilter});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: 'Portfolio Overview', icon: Icons.account_balance_wallet),
        PortfolioValuationCard(),
      ],
    );
  }
}

// ── Live Prices section ───────────────────────────────────────────────────────

class _LivePricesSection extends ConsumerWidget {
  final Set<String> metalFilter;
  final Set<String> retailerFilter;
  const _LivePricesSection({required this.metalFilter, required this.retailerFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async        = ref.watch(homeRecentLivePricesProvider);
    final profilesAsync = ref.watch(productProfilesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(title: 'Recent Live Prices', icon: Icons.show_chart),
        async.when(
          data: (prices) {
            final filtered = prices.where((p) {
              if (retailerFilter.isNotEmpty &&
                  !retailerFilter.contains(p.retailerId)) return false;
              if (metalFilter.isNotEmpty &&
                  !metalFilter.contains(p.metalType?.toLowerCase())) return false;
              return true;
            }).toList();

            if (filtered.isEmpty) {
              return const _EmptyState(message: 'No live prices recorded yet.');
            }
            if (profilesAsync.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final profiles    = profilesAsync.valueOrNull ?? [];
            final profileMap  = {for (final p in profiles) p.id: p.profileName};
            final colorMap    = {for (final p in profiles)
              p.id: MetalColorHelper.getTextColorForMetal(context, p.metalTypeEnum)};
            final assetMap    = {for (final p in profiles)
              p.id: MetalColorHelper.getAssetPathForMetal(p.metalTypeEnum)};

            final byRetailer = <String, List<LivePrice>>{};
            for (final p in filtered) {
              byRetailer.putIfAbsent(p.retailerId, () => []).add(p);
            }
            return Column(
              children: byRetailer.entries.map((entry) => _RetailerLivePricesCard(
                retailerLabel: entry.value.first.retailerName ?? 'Unknown Retailer',
                prices:        entry.value,
                profileMap:    profileMap,
                colorMap:      colorMap,
                assetMap:      assetMap,
              )).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error:   (e, _) => _EmptyState(message: 'Could not load live prices: $e'),
        ),
      ],
    );
  }
}

class _RetailerLivePricesCard extends StatelessWidget {
  final String            retailerLabel;
  final List<LivePrice>   prices;
  final Map<String, String> profileMap;
  final Map<String, Color>  colorMap;
  final Map<String, String> assetMap;

  const _RetailerLivePricesCard({
    required this.retailerLabel,
    required this.prices,
    required this.profileMap,
    required this.colorMap,
    required this.assetMap,
  });

  @override
  Widget build(BuildContext context) {
    final cs     = Theme.of(context).colorScheme;
    final tt     = Theme.of(context).textTheme;
    final latest = prices
        .map((p) => p.captureTimestamp)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(retailerLabel, style: tt.titleSmall),
                Text(_dtFmt.format(latest),
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
            const Divider(height: 12),
            ...prices.map((p) => _LivePriceRow(
                  price:              p,
                  latestForRetailer:  latest,
                  profileMap:         profileMap,
                  colorMap:           colorMap,
                  assetMap:           assetMap,
                )),
          ],
        ),
      ),
    );
  }
}

class _LivePriceRow extends StatelessWidget {
  final LivePrice           price;
  final DateTime            latestForRetailer;
  final Map<String, String> profileMap;
  final Map<String, Color>  colorMap;
  final Map<String, String> assetMap;

  const _LivePriceRow({
    required this.price,
    required this.latestForRetailer,
    required this.profileMap,
    required this.colorMap,
    required this.assetMap,
  });

  @override
  Widget build(BuildContext context) {
    final cs         = Theme.of(context).colorScheme;
    final name       = (price.productProfileId != null
            ? profileMap[price.productProfileId]
            : null) ??
        price.livePriceName ?? 'Unknown';
    final sell       = price.sellPrice;
    final buy        = price.buybackPrice;
    final priceColor = (price.productProfileId != null
            ? colorMap[price.productProfileId]
            : null) ??
        cs.onSurfaceVariant;
    final assetPath  = price.productProfileId != null
        ? assetMap[price.productProfileId]
        : null;
    final ageDiff    = latestForRetailer.difference(price.captureTimestamp).inHours;
    final isStale    = ageDiff > 2;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Opacity(
        opacity: isStale ? 0.55 : 1.0,
        child: Row(
          children: [
            if (assetPath != null) ...[
              Image.asset(assetPath, width: 16, height: 16, fit: BoxFit.contain),
              const SizedBox(width: 6),
            ] else
              const SizedBox(width: 22),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(color: priceColor, fontSize: 12)),
                  if (isStale)
                    Text(
                      _dtFmt.format(price.captureTimestamp),
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 9),
                    ),
                ],
              ),
            ),
            if (sell != null) _priceTag(context, 'Sell', sell, priceColor),
            if (buy != null) ...[
              const SizedBox(width: 8),
              _priceTag(context, 'Buy', buy, priceColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _priceTag(BuildContext context, String label, double value, Color color) {
    final cs = Theme.of(context).colorScheme;
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text:  '$label ',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10),
          ),
          TextSpan(
            text:  _currencyFmt.format(value),
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Global Spot Prices section ────────────────────────────────────────────────

class _GlobalSpotSection extends ConsumerWidget {
  final Set<String> metalFilter;
  const _GlobalSpotSection({required this.metalFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(homeGlobalSpotPricesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(title: 'Global Spot Prices', icon: Icons.public),
        async.when(
          data: (spots) {
            final filtered = metalFilter.isEmpty
                ? spots
                : spots
                    .where((s) =>
                        metalFilter.contains(s.metalType.toLowerCase()))
                    .toList();
            if (filtered.isEmpty) {
              return const _EmptyState(
                  message: 'No global spot prices recorded yet.');
            }
            return _GlobalSpotCard(spots: filtered);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error:   (e, _) =>
              _EmptyState(message: 'Could not load spot prices: $e'),
        ),
      ],
    );
  }
}

class _GlobalSpotCard extends StatelessWidget {
  final List<SpotPrice> spots;
  const _GlobalSpotCard({required this.spots});

  static const _metals = [
    (key: 'gold',     name: 'Gold'),
    (key: 'silver',   name: 'Silver'),
    (key: 'platinum', name: 'Platinum'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final bySource        = <String, Map<String, SpotPrice>>{};
    final latestBySource  = <String, DateTime>{};
    for (final s in spots) {
      final src = s.source;
      bySource.putIfAbsent(src, () => {})[s.metalType.toLowerCase()] = s;
      final ts = latestBySource[src];
      if (ts == null || s.fetchTimestamp.isAfter(ts)) {
        latestBySource[src] = s.fetchTimestamp;
      }
    }
    final sources = bySource.keys.toList()..sort();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text('Provider',
                      style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6)),
                ),
                ..._metals.map((m) {
                  final color = MetalColorHelper.getColorForMetalString(m.key);
                  return Expanded(
                    flex: 4,
                    child: Text(m.name,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  );
                }),
                Expanded(
                  flex: 4,
                  child: Text('Updated',
                      textAlign: TextAlign.right,
                      style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...sources.map((src) {
            final byMetal = bySource[src]!;
            final ts      = latestBySource[src]!;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(src,
                        overflow: TextOverflow.ellipsis,
                        style: tt.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  ..._metals.map((m) {
                    final spot  = byMetal[m.key];
                    final color = MetalColorHelper.getColorForMetalString(m.key);
                    return Expanded(
                      flex: 4,
                      child: Text(
                        spot != null ? _currencyFmt.format(spot.price) : '—',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: spot != null ? color : cs.onSurfaceVariant,
                          fontSize:   11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }),
                  Expanded(
                    flex: 4,
                    child: Text(
                      _dtFmt.format(ts),
                      textAlign: TextAlign.right,
                      style: tt.labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── Local Spot Prices section ─────────────────────────────────────────────────

class _LocalSpotSection extends ConsumerWidget {
  final Set<String> metalFilter;
  final Set<String> retailerFilter;
  const _LocalSpotSection({required this.metalFilter, required this.retailerFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async         = ref.watch(homeLocalSpotPricesProvider);
    final retailersAsync = ref.watch(retailersProvider);
    final retailerMap   = {
      for (final r in retailersAsync.valueOrNull ?? [])
        r.id: r.retailerAbbr ?? r.name
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(title: 'Local Spot Prices', icon: Icons.store),
        async.when(
          data: (spots) {
            final filtered = spots.where((s) {
              if (metalFilter.isNotEmpty &&
                  !metalFilter.contains(s.metalType.toLowerCase())) return false;
              if (retailerFilter.isNotEmpty &&
                  !retailerFilter.contains(s.retailerId ?? '')) return false;
              return true;
            }).toList();

            if (filtered.isEmpty) {
              return const _EmptyState(
                  message: 'No local spot prices recorded yet.');
            }
            final byRetailer = <String, List<SpotPrice>>{};
            for (final s in filtered) {
              byRetailer.putIfAbsent(s.retailerId ?? s.source, () => []).add(s);
            }
            return Column(
              children: byRetailer.entries.map((entry) => _LocalSpotCard(
                    retailerLabel: retailerMap[entry.key] ??
                        entry.value.first.source,
                    spots: entry.value,
                  )).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error:   (e, _) =>
              _EmptyState(message: 'Could not load local spot prices: $e'),
        ),
      ],
    );
  }
}

class _LocalSpotCard extends StatelessWidget {
  final String         retailerLabel;
  final List<SpotPrice> spots;
  const _LocalSpotCard({required this.retailerLabel, required this.spots});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(retailerLabel, style: tt.titleSmall),
                Text(
                  _dtFmt.format(spots
                      .map((s) => s.fetchTimestamp)
                      .reduce((a, b) => a.isAfter(b) ? a : b)),
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const Divider(height: 12),
            ...spots.map((s) {
              final color = MetalColorHelper.getTextColorForMetalString(context, s.metalType);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Image.asset(
                      MetalColorHelper.getAssetPathForMetalString(s.metalType),
                      width: 18, height: 18, fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(s.metalType,
                          style: TextStyle(color: color, fontSize: 13)),
                    ),
                    Text(
                      _currencyFmt.format(s.price),
                      style: tt.titleSmall,
                    ),
                    const SizedBox(width: 4),
                    Text('/oz',
                        style: tt.labelSmall
                            ?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
