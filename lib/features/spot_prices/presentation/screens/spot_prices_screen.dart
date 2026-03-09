// lib/features/spot_prices/presentation/screens/spot_prices_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/core/widgets/app_drawer.dart';
import 'package:metal_tracker/core/widgets/app_logo_title.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/features/spot_prices/data/models/spot_price_model.dart';
import 'package:metal_tracker/features/spot_prices/presentation/providers/spot_prices_providers.dart';
import 'package:metal_tracker/features/spot_prices/presentation/screens/api_settings_screen.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';

final _currencyFmt = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
final _dateFmt = DateFormat('d/M/y');
final _timeFmt = DateFormat('HH:mm');

// Flex weights — must stay in sync between header and row widgets
const _kDateFlex   = 13;
const _kTimeFlex   = 10;
const _kSourceFlex = 20;
const _kTypeFlex   = 11;
const _kGoldFlex   = 15;
const _kSilverFlex = 15;
const _kPlatFlex   = 16;

enum _SortColumn { date, time, source, type, gold, silver, platinum }

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
  String? _sourceFilter;
  final Set<String> _requiredMetals = {};

  // Sort
  _SortColumn _sortColumn = _SortColumn.date;
  bool _sortAscending = false;

  // Fetch
  bool _isFetching = false;
  bool _isLocalFetching = false;

  int get _activeFilterCount =>
      (_datePreset != null ? 1 : 0) +
      (_sourceTypeFilter != null ? 1 : 0) +
      (_sourceFilter != null ? 1 : 0) +
      _requiredMetals.length;

  // ─── Filter sheet ─────────────────────────────────────────────────────────

  void _showFilterSheet(
      BuildContext context, List<String> contextualSources) {
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
            initialChildSize: 0.65,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            builder: (ctx, scrollCtrl) => Column(
              children: [
                // Handle + title bar
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
                            _datePreset = null;
                            _sourceTypeFilter = null;
                            _sourceFilter = null;
                            _requiredMetals.clear();
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

                // Scrollable filter content
                Expanded(
                  child: ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    children: [
                      // ── Date ──────────────────────────────────────────
                      _SheetSection(
                        label: 'Date',
                        child: _RadioGroup<String?>(
                          options: const [
                            (label: 'All time',    value: null),
                            (label: 'Today',       value: 'today'),
                            (label: 'Yesterday',   value: 'ytd'),
                            (label: 'Last 7 days', value: 'week'),
                            (label: 'Last 30 days',value: 'month'),
                          ],
                          current: _datePreset,
                          onChanged: (v) =>
                              update(() => _datePreset = v),
                        ),
                      ),

                      // ── Type ──────────────────────────────────────────
                      _SheetSection(
                        label: 'Type',
                        child: _RadioGroup<String?>(
                          options: const [
                            (label: 'All',    value: null),
                            (label: 'Global', value: 'global_api'),
                            (label: 'Local',  value: 'local_scraper'),
                          ],
                          current: _sourceTypeFilter,
                          onChanged: (v) => update(() {
                            _sourceTypeFilter = v;
                            _sourceFilter = null;
                          }),
                        ),
                      ),

                      // ── Has metals ────────────────────────────────────
                      _SheetSection(
                        label: 'Has metal',
                        child: Column(
                          children: [
                            for (final m in [
                              (key: 'gold',     label: 'Gold'),
                              (key: 'silver',   label: 'Silver'),
                              (key: 'platinum', label: 'Platinum'),
                            ])
                              _CheckRow(
                                label: m.label,
                                color: MetalColorHelper
                                    .getColorForMetalString(m.key),
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

                      // ── Source ────────────────────────────────────────
                      if (contextualSources.length > 1)
                        _SheetSection(
                          label: 'Source',
                          child: _RadioGroup<String?>(
                            options: [
                              (label: 'All', value: null),
                              ...contextualSources.map(
                                  (s) => (label: s, value: s as String?)),
                            ],
                            current: _sourceFilter,
                            onChanged: (v) =>
                                update(() => _sourceFilter = v),
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

  // ─── Fetch ───────────────────────────────────────────────────────────────

  Future<void> _onFetchTapped() async {
    final setting =
        await ref.read(spotPricesRepositoryProvider).getActiveApiSetting();
    if (!mounted) return;

    if (setting == null) {
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const ApiSettingsScreen()));
      return;
    }

    setState(() => _isFetching = true);
    try {
      final usageResult = await ref
          .read(spotPricesNotifierProvider.notifier)
          .checkUsage(
              setting.apiKey, setting.serviceType, setting.config);
      if (!mounted) return;

      if (usageResult != null && !usageResult.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Usage check failed: ${usageResult.errorMessage}'),
          backgroundColor: AppColors.error,
        ));
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: const Text('Fetch Global Spot Prices'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (usageResult != null) ...[
                if (usageResult.plan != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      const Icon(Icons.credit_card,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text('Plan: ${usageResult.plan}',
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13)),
                    ]),
                  ),
                Row(children: [
                  const Icon(Icons.data_usage,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${usageResult.remaining} / ${usageResult.total} '
                      'requests remaining this month',
                      style:
                          const TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
              ],
              Text(
                'Fetch spot prices for Gold, Silver and Platinum?',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: AppColors.textDark,
              ),
              child: const Text('Fetch'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      final result = await ref
          .read(spotPricesNotifierProvider.notifier)
          .fetchAndSave(
            apiKey: setting.apiKey,
            serviceType: setting.serviceType,
            config: setting.config,
          );
      if (!mounted) return;

      if (result.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Fetch failed: ${result.error}'),
          backgroundColor: AppColors.error,
        ));
      } else if (result.savedCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Already up to date'),
          backgroundColor: AppColors.backgroundCard,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${result.savedCount} price(s) updated'),
          backgroundColor: AppColors.success,
        ));
      }
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  // ─── Local Fetch ─────────────────────────────────────────────────────────

  Future<void> _onLocalFetchTapped() async {
    setState(() => _isLocalFetching = true);
    try {
      final result = await ref
          .read(spotPricesNotifierProvider.notifier)
          .fetchLocalSpotPrices();
      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: Row(
            children: [
              Icon(
                result.savedCount > 0 ? Icons.check_circle : Icons.info_outline,
                color: result.savedCount > 0
                    ? AppColors.success
                    : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                result.savedCount > 0
                    ? '${result.savedCount} price(s) saved'
                    : 'Local Spot Results',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: result.details.map((line) {
                final isError = line.contains('✗') || line.contains('no ') || line.contains('check');
                final isOk = line.contains('✓');
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    line,
                    style: TextStyle(
                      fontSize: 13,
                      color: isError
                          ? AppColors.error
                          : isOk
                              ? AppColors.success
                              : AppColors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _isLocalFetching = false);
    }
  }

  // ─── Sort ────────────────────────────────────────────────────────────────

  void _onHeaderTap(_SortColumn col) {
    setState(() {
      if (_sortColumn == col) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = col;
        _sortAscending =
            col == _SortColumn.source || col == _SortColumn.type;
      }
    });
  }

  List<_Session> _sortSessions(List<_Session> sessions) {
    int compare(_Session a, _Session b) {
      switch (_sortColumn) {
        case _SortColumn.date:
          return a.fetchTimestamp.compareTo(b.fetchTimestamp);
        case _SortColumn.time:
          final aMin =
              a.fetchTimestamp.hour * 60 + a.fetchTimestamp.minute;
          final bMin =
              b.fetchTimestamp.hour * 60 + b.fetchTimestamp.minute;
          return aMin.compareTo(bMin);
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
    }

    final sorted = List<_Session>.from(sessions)..sort(compare);
    return _sortAscending ? sorted : sorted.reversed.toList();
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
    return AppScaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const AppLogoTitle('Spot Prices'),
        backgroundColor: AppColors.backgroundCard,
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
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'API Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ApiSettingsScreen()),
            ),
          ),
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
              icon: const Icon(Icons.cloud_download),
              tooltip: 'Fetch Spot Prices',
              onPressed: _onFetchTapped,
            ),
        ],
      ),
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
          p.sourceType != _sourceTypeFilter) { return false; }
      if (_sourceFilter != null && p.source != _sourceFilter) return false;
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
          sortColumn: _sortColumn,
          sortAscending: _sortAscending,
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
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primaryGold.withValues(alpha: 0.15)
                  : AppColors.backgroundDark,
              border: Border.all(
                color: selected
                    ? AppColors.primaryGold
                    : Colors.white12,
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
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String label;
  final Color color;
  final bool checked;
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
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color:
                    checked ? color.withValues(alpha: 0.15) : Colors.transparent,
                border: Border.all(
                  color: checked ? color : Colors.white24,
                  width: checked ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: checked
                  ? Icon(Icons.check, size: 14, color: color)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: checked ? color : AppColors.textPrimary,
                fontSize: 14,
                fontWeight:
                    checked ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
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
                  color: active
                      ? AppColors.primaryGold
                      : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (active) ...[
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
          _cell('Date',   _SortColumn.date,   _kDateFlex),
          _cell('Time',   _SortColumn.time,   _kTimeFlex),
          _cell('Source', _SortColumn.source, _kSourceFlex),
          _cell('Type',   _SortColumn.type,   _kTypeFlex),
          ..._metalCols.map((m) {
            final active = sortColumn == m.col;
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
                        MetalColorHelper.getAssetPathForMetalString(
                            m.key),
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
                              color: active
                                  ? AppColors.primaryGold
                                  : MetalColorHelper
                                      .getColorForMetalString(m.key),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (active) ...[
                            const SizedBox(width: 1),
                            Icon(
                              sortAscending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 9,
                              color: AppColors.primaryGold,
                            ),
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
            flex: _kDateFlex,
            child: Text(
              _dateFmt.format(session.fetchTimestamp),
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11),
            ),
          ),
          Expanded(
            flex: _kTimeFlex,
            child: Text(
              _timeFmt.format(session.fetchTimestamp),
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
