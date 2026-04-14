// lib/features/spot_prices/presentation/screens/spot_prices_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/core/utils/sort_config.dart';
import 'package:metal_tracker/core/widgets/filter_sheet.dart';
import 'package:metal_tracker/features/settings/data/models/user_prefs_models.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_prefs_providers.dart';
import 'package:metal_tracker/features/spot_prices/data/models/spot_price_model.dart';
import 'package:metal_tracker/features/spot_prices/data/services/base_global_spot_price_service.dart';
import 'package:metal_tracker/features/spot_prices/data/services/global_spot_price_service_factory.dart';
import 'package:metal_tracker/features/spot_prices/presentation/providers/spot_prices_providers.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_profile_providers.dart';
import 'package:metal_tracker/features/settings/presentation/screens/settings_screen.dart';

final _currencyFmt = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
final _dateTimeFmt = DateFormat('d MMM HH:mm');

// Flex weights — must stay in sync between header and row widgets
const _kDateTimeFlex = 23;
const _kSourceFlex   = 20;
const _kTypeFlex     = 11;
const _kGoldFlex     = 15;
const _kSilverFlex   = 15;
const _kPlatFlex     = 16;

enum _SortColumn { date, source, type, gold, silver, platinum }

// ─── Session model (one row = one fetch session) ──────────────────────────────

class _Session {
  final DateTime fetchTimestamp;
  final String source;
  final String sourceType;
  final double? gold;
  final double? silver;
  final double? platinum;
  final bool hasError;

  const _Session({
    required this.fetchTimestamp,
    required this.source,
    required this.sourceType,
    this.gold,
    this.silver,
    this.platinum,
    this.hasError = false,
  });

  double? priceFor(String metal) {
    switch (metal) {
      case 'gold':     return gold;
      case 'silver':   return silver;
      case 'platinum': return platinum;
      default:         return null;
    }
  }
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class SpotPricesScreen extends ConsumerStatefulWidget {
  const SpotPricesScreen({super.key});

  @override
  ConsumerState<SpotPricesScreen> createState() => _SpotPricesScreenState();
}

class _SpotPricesScreenState extends ConsumerState<SpotPricesScreen> {
  // Filters
  String? _datePreset;
  String? _sourceTypeFilter;
  Set<String> _sourceFilters = {}; // multi-select: source names
  final Set<String> _requiredMetals = {};

  // Sort
  SortConfig<_SortColumn> _sortConfig =
      SortConfig.initial(_SortColumn.date, ascending: false);

  // Fetch
  bool _isFetching = false;
  bool _isLocalFetching = false;

  bool _sourceFilterInited = false;

  int get _activeFilterCount =>
      (_datePreset != null ? 1 : 0) +
      (_sourceTypeFilter != null ? 1 : 0) +
      _sourceFilters.length +
      _requiredMetals.length;

  // ─── Filter sheet ─────────────────────────────────────────────────────────

  void _showFilterSheet(
      BuildContext context, List<String> contextualSources) {
    FilterSheet.show(
      context: context,
      title: 'Filter',
      onReset: () => setState(() {
        _datePreset = null;
        _sourceTypeFilter = null;
        _sourceFilters = {};
        _requiredMetals.clear();
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
            label: 'Type',
            child: FilterChipGroup<String>(
              options: const [
                FilterChipOption(value: 'global_api', label: 'Global'),
                FilterChipOption(value: 'local_scraper', label: 'Local'),
              ],
              selected: _sourceTypeFilter,
              onChanged: (v) => update(() {
                _sourceTypeFilter = v;
                _sourceFilters = {};
              }),
            ),
          ),
          FilterSection(
            label: 'Has metal',
            child: Column(
              children: [
                for (final m in [
                  (key: 'gold', label: 'Gold'),
                  (key: 'silver', label: 'Silver'),
                  (key: 'platinum', label: 'Platinum'),
                ])
                  FilterCheckRow(
                    label: m.label,
                    color: MetalColorHelper.getColorForMetalString(m.key),
                    checked: _requiredMetals.contains(m.key),
                    onChanged: (v) => update(() {
                      v
                          ? _requiredMetals.add(m.key)
                          : _requiredMetals.remove(m.key);
                    }),
                  ),
              ],
            ),
          ),
          if (contextualSources.length > 1)
            FilterSection(
              label: 'Source',
              child: Column(
                children: contextualSources
                    .map((s) => FilterCheckRow(
                          label: s,
                          color: AppColors.textPrimary,
                          checked: _sourceFilters.contains(s),
                          onChanged: (v) => update(() {
                            v
                                ? _sourceFilters.add(s)
                                : _sourceFilters.remove(s);
                          }),
                        ))
                    .toList(),
              ),
            ),
        ];
      },
    );
  }

  // ─── Fetch ───────────────────────────────────────────────────────────────

  Future<void> _onFetchTapped(List<UserGlobalSpotPref> allPrefs) async {
    final globalPrefs = allPrefs.where((p) => p.isActive).toList();
    if (globalPrefs.isEmpty) {
      _showNoProviderDialog();
      return;
    }

    // Usage check before fetching
    final hasUsageData = await _checkAndShowUsage(globalPrefs);
    if (hasUsageData == false) return; // user cancelled

    setState(() => _isFetching = true);
    try {
      final reports = await ref
          .read(spotPricesNotifierProvider.notifier)
          .fetchGlobalSpotPrices();
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => _SpotScrapeResultsDialog(reports: reports),
      );
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  void _showNoProviderDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text(
          'No Provider Configured',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'You do not have a Global Spot Provider configured. '
          'Would you like to configure one now?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not Now',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const SettingsScreen()),
              );
            },
            child: const Text('Go to Settings'),
          ),
        ],
      ),
    );
  }

  /// Returns true if fetch should proceed, false if user cancelled.
  /// Returns true immediately if no usage data is available.
  Future<bool> _checkAndShowUsage(List<UserGlobalSpotPref> prefs) async {
    final usageResults = <({String name, SpotPriceUsageResult result})>[];

    for (final pref in prefs) {
      try {
        final result = await ref
            .read(spotPricesNotifierProvider.notifier)
            .checkUsage(pref.apiKey, pref.providerKey, {});
        if (result != null && result.isSuccess) {
          final service =
              GlobalSpotPriceServiceFactory.forType(pref.providerKey);
          usageResults.add((name: service.displayName, result: result));
        }
      } catch (_) {
        // If usage check fails, proceed without showing dialog
      }
    }

    if (usageResults.isEmpty) return true; // no usage endpoint — proceed

    if (!mounted) return false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Row(
          children: [
            Icon(Icons.data_usage, color: AppColors.primaryGold, size: 20),
            SizedBox(width: 8),
            Text('API Usage',
                style: TextStyle(
                    color: AppColors.textPrimary, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...usageResults.map((u) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _UsageBar(result: u.result),
                      const SizedBox(height: 4),
                      Text(
                        '${u.result.used} / ${u.result.total} calls used'
                        '  •  ${u.result.remaining} remaining'
                        '${u.result.plan != null ? '  •  ${u.result.plan}' : ''}',
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11),
                      ),
                    ],
                  ),
                )),
            const Text(
              'Fetching will use 1 call per provider.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Fetch'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  // ─── Local Fetch ─────────────────────────────────────────────────────────

  Future<void> _onLocalFetchTapped() async {
    setState(() => _isLocalFetching = true);
    try {
      final reports = await ref
          .read(spotPricesNotifierProvider.notifier)
          .fetchLocalSpotPrices();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => _SpotScrapeResultsDialog(reports: reports),
      );
    } finally {
      if (mounted) setState(() => _isLocalFetching = false);
    }
  }

  // ─── Sort ────────────────────────────────────────────────────────────────

  void _onHeaderTap(_SortColumn col) {
    setState(() {
      _sortConfig = _sortConfig.tap(
        col,
        defaultAscending: (c) =>
            c == _SortColumn.source || c == _SortColumn.type,
      );
    });
  }

  List<_Session> _sortSessions(List<_Session> sessions) {
    final result = List<_Session>.from(sessions);
    _sortConfig.sortList(result, (a, b, col) {
      switch (col) {
        case _SortColumn.date:
          return a.fetchTimestamp.compareTo(b.fetchTimestamp);
        case _SortColumn.source:
          return a.source.compareTo(b.source);
        case _SortColumn.type:
          return a.sourceType.compareTo(b.sourceType);
        case _SortColumn.gold:
          return _cmpNullLast(a.gold, b.gold);
        case _SortColumn.silver:
          return _cmpNullLast(a.silver, b.silver);
        case _SortColumn.platinum:
          return _cmpNullLast(a.platinum, b.platinum);
      }
    });
    return result;
  }

  int _cmpNullLast(double? a, double? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  // ─── Filter helpers ──────────────────────────────────────────────────────

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

  bool _matchesMetals(_Session s) {
    if (_requiredMetals.isEmpty) return true;
    if (_requiredMetals.contains('gold')     && s.gold == null)     return false;
    if (_requiredMetals.contains('silver')   && s.silver == null)   return false;
    if (_requiredMetals.contains('platinum') && s.platinum == null) return false;
    return true;
  }

  // ─── Session builder ─────────────────────────────────────────────────────

  List<_Session> _buildSessions(List<SpotPrice> prices) {
    final map = <String, _Session>{};
    for (final p in prices) {
      final key =
          '${p.fetchTimestamp.millisecondsSinceEpoch}_${p.source}_${p.sourceType}';
      final existing = map[key];
      final metal = p.metalType.toLowerCase();
      map[key] = _Session(
        fetchTimestamp: p.fetchTimestamp,
        source: p.source,
        sourceType: p.sourceType,
        gold:     metal == 'gold'     ? p.price : existing?.gold,
        silver:   metal == 'silver'   ? p.price : existing?.silver,
        platinum: metal == 'platinum' ? p.price : existing?.platinum,
        hasError:
            (existing?.hasError ?? false) || p.status != 'success',
      );
    }
    return map.values.toList();
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pricesAsync = ref.watch(spotPricesNotifierProvider);
    final globalPrefs =
        ref.watch(userGlobalSpotPrefNotifierProvider).valueOrNull ?? [];
    final hasProvider = globalPrefs.any((p) => p.isActive);

    // Pre-populate source filter from user prefs on first load
    if (!_sourceFilterInited) {
      final globalPrefsVal =
          ref.watch(userGlobalSpotPrefNotifierProvider).valueOrNull;
      final retailersVal = ref.watch(userRetailersNotifierProvider).valueOrNull;
      if (globalPrefsVal != null && retailersVal != null) {
        _sourceFilterInited = true;
        for (final pref in globalPrefsVal.where((p) => p.isActive)) {
          final service = GlobalSpotPriceServiceFactory.forType(pref.providerKey);
          _sourceFilters.add(service.displayName);
        }
        for (final r in retailersVal) {
          if (r.retailerName != null) _sourceFilters.add(r.retailerName!);
        }
      }
    }

    // Reactive: rebuild source filter when prefs change
    ref.listen(userGlobalSpotPrefNotifierProvider, (_, next) {
      final prefs = next.valueOrNull ?? [];
      final retailers =
          ref.read(userRetailersNotifierProvider).valueOrNull ?? [];
      if (mounted) {
        setState(() {
          _sourceFilters = {
            for (final p in prefs.where((p) => p.isActive))
              GlobalSpotPriceServiceFactory.forType(p.providerKey).displayName,
            for (final r in retailers)
              if (r.retailerName != null) r.retailerName!,
          };
        });
      }
    });
    ref.listen(userRetailersNotifierProvider, (_, next) {
      final retailers = next.valueOrNull ?? [];
      final prefs =
          ref.read(userGlobalSpotPrefNotifierProvider).valueOrNull ?? [];
      if (mounted) {
        setState(() {
          _sourceFilters = {
            for (final p in prefs.where((p) => p.isActive))
              GlobalSpotPriceServiceFactory.forType(p.providerKey).displayName,
            for (final r in retailers)
              if (r.retailerName != null) r.retailerName!,
          };
        });
      }
    });

    return AppScaffold(
      title: 'Spot Prices',
      onRefresh: () => ref.invalidate(spotPricesNotifierProvider),
      actions: [
        // Filter button with active-count badge
        pricesAsync.when(
          data: (prices) {
            final sources = prices
                .where((p) =>
                    _sourceTypeFilter == null ||
                    p.sourceType == _sourceTypeFilter)
                .map((p) => p.source)
                .toSet()
                .toList()
              ..sort();
            return Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: const Icon(Icons.tune),
                  tooltip: 'Filter',
                  onPressed: () =>
                      _showFilterSheet(context, sources),
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
        // Local fetch — admin only
        if (ref.watch(isAdminProvider)) ...[
          if (_isLocalFetching)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.textSecondary),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.store_outlined),
              tooltip: 'Fetch Local Spot Prices',
              onPressed: _onLocalFetchTapped,
            ),
        ],
        if (_isFetching)
          const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primaryGold),
            ),
          )
        else
          IconButton(
            icon: Icon(
              Icons.cloud_download,
              color: hasProvider
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
            tooltip: hasProvider
                ? 'Fetch Global Spot Prices'
                : 'No provider configured',
            onPressed: () => _onFetchTapped(globalPrefs),
          ),
      ],
      body: pricesAsync.when(
        data: _buildContent,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }

  Widget _buildContent(List<SpotPrice> allPrices) {
    final filtered = allPrices.where((p) {
      if (_sourceTypeFilter != null &&
          p.sourceType != _sourceTypeFilter) return false;
      if (_sourceFilters.isNotEmpty && !_sourceFilters.contains(p.source)) {
        return false;
      }
      if (!_matchesDate(p.fetchTimestamp)) return false;
      return true;
    }).toList();

    final sessions = _sortSessions(
      _buildSessions(filtered).where(_matchesMetals).toList(),
    );

    if (sessions.isEmpty) return const _EmptyState();

    return Column(
      children: [
        _TableHeader(
          config: _sortConfig,
          onTap: _onHeaderTap,
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: sessions.length,
            itemBuilder: (ctx, i) => _TableRow(session: sessions[i]),
          ),
        ),
      ],
    );
  }
}


// ─── Table Header ─────────────────────────────────────────────────────────────

const _metalCols = [
  (key: 'gold',     name: 'Gold',     col: _SortColumn.gold,     flex: _kGoldFlex),
  (key: 'silver',   name: 'Silver',   col: _SortColumn.silver,   flex: _kSilverFlex),
  (key: 'platinum', name: 'Platinum', col: _SortColumn.platinum, flex: _kPlatFlex),
];

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
    return Container(
      color: AppColors.backgroundCard,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _cell('Date', _SortColumn.date, _kDateTimeFlex),
          _cell('Source', _SortColumn.source, _kSourceFlex),
          _cell('Type',   _SortColumn.type,   _kTypeFlex),
          ..._metalCols.map((m) {
            final primary   = config.isPrimary(m.col);
            final secondary = config.isSecondary(m.col);
            final active    = primary || secondary;
            final color = primary
                ? AppColors.primaryGold
                : secondary
                    ? AppColors.primaryGold.withAlpha(160)
                    : MetalColorHelper.getColorForMetalString(m.key);
            return Expanded(
              flex: m.flex,
              child: GestureDetector(
                onTap: () => onTap(m.col),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        MetalColorHelper.getAssetPathForMetalString(m.key),
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            m.name,
                            style: TextStyle(
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (active) ...[
                            const SizedBox(width: 1),
                            Icon(
                              config.isAscending(m.col)
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: primary ? 9 : 8,
                              color: color,
                            ),
                            if (secondary) ...[
                              const SizedBox(width: 1),
                              Text('2', style: TextStyle(color: color, fontSize: 7, fontWeight: FontWeight.w700)),
                            ],
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Table Row ────────────────────────────────────────────────────────────────

class _TableRow extends StatelessWidget {
  final _Session session;
  const _TableRow({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: _kDateTimeFlex,
            child: Text(
              _dateTimeFmt.format(session.fetchTimestamp),
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11),
            ),
          ),
          Expanded(
            flex: _kSourceFlex,
            child: Text(
              session.source,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 11),
            ),
          ),
          Expanded(
            flex: _kTypeFlex,
            child: _TypeBadge(sourceType: session.sourceType),
          ),
          ..._metalCols.map((m) {
            final price = session.priceFor(m.key);
            final color =
                MetalColorHelper.getColorForMetalString(m.key);
            return Expanded(
              flex: m.flex,
              child: Text(
                price != null ? _currencyFmt.format(price) : '—',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: price != null
                      ? color
                      : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String sourceType;
  const _TypeBadge({required this.sourceType});

  @override
  Widget build(BuildContext context) {
    final isGlobal = sourceType == 'global_api';
    final color =
        isGlobal ? AppColors.primaryGold : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isGlobal ? 'Global' : 'Local',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, size: 56, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text('No spot prices yet',
              style: TextStyle(color: AppColors.textSecondary)),
          SizedBox(height: 8),
          Text(
            'Tap the cloud icon to fetch live global spot prices.',
            style:
                TextStyle(color: AppColors.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Usage Bar ────────────────────────────────────────────────────────────────

class _UsageBar extends StatelessWidget {
  final SpotPriceUsageResult result;
  const _UsageBar({required this.result});

  @override
  Widget build(BuildContext context) {
    final pct = result.total > 0 ? result.used / result.total : 0.0;
    final color = pct >= 0.9
        ? AppColors.lossRed
        : pct >= 0.7
            ? AppColors.warning
            : AppColors.success;
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: pct.clamp(0.0, 1.0),
        backgroundColor: Colors.white12,
        color: color,
        minHeight: 6,
      ),
    );
  }
}

// ─── Spot Scrape Results Dialog ───────────────────────────────────────────────

class _SpotScrapeResultsDialog extends StatelessWidget {
  final List<SpotScrapeReport> reports;

  const _SpotScrapeResultsDialog({required this.reports});

  static final _priceFmt =
      NumberFormat.currency(symbol: r'$', decimalDigits: 2);

  Color _statusColor(String status) => switch (status) {
        'success' => AppColors.success,
        'duplicate' => AppColors.textSecondary,
        'partial' => AppColors.warning,
        _ => AppColors.error,
      };

  IconData _statusIcon(String status) => switch (status) {
        'success' => Icons.check_circle_outline,
        'duplicate' => Icons.info_outline,
        'partial' => Icons.warning_amber_outlined,
        _ => Icons.error_outline,
      };

  String _statusLabel(String status) => switch (status) {
        'success' => 'saved',
        'duplicate' => 'up to date',
        'partial' => 'partial',
        'failed' => 'failed',
        _ => 'error',
      };

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
            child: Text('Fetch Results', style: TextStyle(fontSize: 16)),
          ),
          Text(
            '$totalCaptured price${totalCaptured == 1 ? '' : 's'}',
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
                'No results.',
                style: TextStyle(color: AppColors.textSecondary),
              )
            : ListView.separated(
                shrinkWrap: true,
                itemCount: reports.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: Colors.white12, height: 24),
                itemBuilder: (_, i) {
                  final r = reports[i];
                  final statusColor = _statusColor(r.status);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Source header
                      Row(
                        children: [
                          Icon(_statusIcon(r.status),
                              color: statusColor, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              r.sourceName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            _statusLabel(r.status),
                            style: TextStyle(
                                color: statusColor, fontSize: 11),
                          ),
                        ],
                      ),

                      // Captured prices
                      if (r.prices.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 22),
                          child: Row(
                            children: const [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  'Metal',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              Expanded(
                                flex: 5,
                                child: Text(
                                  'Price (AUD/oz)',
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
                        ...r.prices.entries.map((entry) {
                          final metalColor =
                              MetalColorHelper.getColorForMetalString(
                                  entry.key);
                          final label = entry.key[0].toUpperCase() +
                              entry.key.substring(1);
                          return Padding(
                            padding:
                                const EdgeInsets.only(left: 22, top: 3),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                        color: metalColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Expanded(
                                  flex: 5,
                                  child: Text(
                                    _priceFmt.format(entry.value),
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],

                      // Errors
                      if (r.errors.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        ...r.errors.map(
                          (err) => Padding(
                            padding:
                                const EdgeInsets.only(left: 22, top: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.close,
                                    color: AppColors.error, size: 12),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    err,
                                    style: const TextStyle(
                                        color: AppColors.error,
                                        fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
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
