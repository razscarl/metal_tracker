import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/constants/app_constants.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/core/widgets/filter_sheet.dart';
import 'package:metal_tracker/features/investment_guide/data/models/investment_recommendation.dart';
import 'package:metal_tracker/features/investment_guide/presentation/providers/investment_guide_providers.dart';
import 'package:metal_tracker/features/investment_guide/presentation/widgets/market_context_banner.dart';
import 'package:metal_tracker/features/investment_guide/presentation/widgets/recommendation_card.dart';
import 'package:metal_tracker/features/metadata/presentation/providers/metadata_providers.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_prefs_providers.dart';

// Forms excluded by default — not typically investment-grade products
const _kDefaultExcludedForms = {'Pool Allocation', 'Granule'};

class InvestmentGuideScreen extends ConsumerStatefulWidget {
  const InvestmentGuideScreen({super.key});

  @override
  ConsumerState<InvestmentGuideScreen> createState() =>
      _InvestmentGuideScreenState();
}

class _InvestmentGuideScreenState
    extends ConsumerState<InvestmentGuideScreen> {
  final _budgetCtrl = TextEditingController();

  // Filter state
  Set<String> _metalFilters = {};
  Set<String> _formFilters = {};
  Set<String> _retailerFilters = {};
  bool _filterInited = false;

  bool _oosExpanded = false;

  @override
  void initState() {
    super.initState();
    // Clear any stale results from a previous navigation on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(investmentGuideNotifierProvider);
    });
  }

  @override
  void dispose() {
    _budgetCtrl.dispose();
    super.dispose();
  }

  int get _activeFilterCount =>
      _metalFilters.length + _formFilters.length + _retailerFilters.length;

  void _run() {
    final budget = double.tryParse(_budgetCtrl.text.replaceAll(',', ''));
    if (budget == null || budget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid budget')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    ref.read(investmentGuideNotifierProvider.notifier).runGuide(
          budget: budget,
          metalFilters: _metalFilters,
          formFilters: _formFilters,
          retailerFilters: _retailerFilters,
        );
  }

  void _showFilterSheet(
    BuildContext context,
    List<String> allForms,
    List<String> allRetailers,
  ) {
    FilterSheet.show(
      context: context,
      title: 'Filter',
      initialSize: 0.7,
      maxSize: 0.95,
      onReset: () => setState(() {
        _metalFilters = {};
        _formFilters = {};
        _retailerFilters = {};
      }),
      builder: (setSheet) {
        void update(VoidCallback fn) {
          setSheet(fn);
          setState(fn);
        }

        return [
          FilterSection(
            label: 'Metal Type',
            child: Column(
              children: MetalType.values.map((m) {
                return FilterCheckRow(
                  label: m.displayName,
                  color: MetalColorHelper.getColorForMetal(m),
                  checked: _metalFilters.contains(m.name),
                  onChanged: (v) => update(() {
                    v
                        ? _metalFilters.add(m.name)
                        : _metalFilters.remove(m.name);
                  }),
                );
              }).toList(),
            ),
          ),
          FilterSection(
            label: 'Metal Form',
            child: Column(
              children: allForms.map((name) {
                return FilterCheckRow(
                  label: name,
                  color: AppColors.textPrimary,
                  checked: _formFilters.contains(name),
                  onChanged: (v) => update(() {
                    v
                        ? _formFilters.add(name)
                        : _formFilters.remove(name);
                  }),
                );
              }).toList(),
            ),
          ),
          if (allRetailers.isNotEmpty)
            FilterSection(
              label: 'Retailer',
              child: Column(
                children: allRetailers.map((name) {
                  return FilterCheckRow(
                    label: name,
                    color: AppColors.textPrimary,
                    checked: _retailerFilters.contains(name),
                    onChanged: (v) => update(() {
                      v
                          ? _retailerFilters.add(name)
                          : _retailerFilters.remove(name);
                    }),
                  );
                }).toList(),
              ),
            ),
        ];
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final guideAsync = ref.watch(investmentGuideNotifierProvider);

    // Derive available forms and retailers from loaded data
    final allForms = ref.watch(metalFormsProvider).valueOrNull
            ?.map((r) => r.name)
            .toList() ??
        [];
    final allRetailers = () {
      final names = guideAsync.valueOrNull
              ?.map((r) => r.listing.retailerName)
              .whereType<String>()
              .toSet()
              .toList() ??
          [];
      names.sort();
      return names;
    }();

    // Initialise filters from user prefs on first load
    if (!_filterInited) {
      final metals = ref.watch(userMetaltypePrefsNotifierProvider).valueOrNull;
      final forms = ref.watch(userMetalformPrefsNotifierProvider).valueOrNull;
      final retailers = ref.watch(userRetailerPrefsNotifierProvider).valueOrNull;

      if (metals != null && forms != null && retailers != null) {
        _filterInited = true;

        // Metal: from user prefs
        if (metals.isNotEmpty) {
          _metalFilters = metals.map((m) => m.metalTypeName.toLowerCase()).toSet();
        }

        // Form: from user prefs; always exclude investment-grade exclusions
        if (forms.isNotEmpty) {
          _formFilters = forms
              .map((f) => f.metalFormName)
              .where((n) => !_kDefaultExcludedForms.contains(n))
              .toSet();
        } else {
          // No user form prefs — include all except Pool Allocation and Granule
          _formFilters = allForms
              .where((n) => !_kDefaultExcludedForms.contains(n))
              .toSet();
        }

        // Retailer: from user prefs
        if (retailers.isNotEmpty) {
          _retailerFilters = retailers
              .map((r) => r.retailerName ?? '')
              .where((n) => n.isNotEmpty)
              .toSet();
        }
      }
    }

    return AppScaffold(
      title: 'Investment Guide',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          onPressed: _budgetCtrl.text.trim().isNotEmpty ? _run : null,
        ),
        // Filter badge button
        Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'Filter',
              onPressed: () => _showFilterSheet(context, allForms, allRetailers),
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
      ],
      body: Column(
        children: [
          Expanded(
            child: ListView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                const MarketContextBanner(),
                _BudgetInputCard(
                  budgetCtrl: _budgetCtrl,
                  onRun: _run,
                ),
                ..._buildResults(guideAsync),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildResults(AsyncValue<List<InvestmentRecommendation>> state) {
    return state.when(
      data: (recs) {
        if (recs.isEmpty) return [];

        final available = recs.where((r) => r.isAvailable).toList();
        final oos = recs.where((r) => !r.isAvailable).toList();

        return [
          _ResultsHeader(count: available.length),
          for (final rec in available) RecommendationCard(rec: rec),
          if (oos.isNotEmpty)
            _OosSection(
              recs: oos,
              expanded: _oosExpanded,
              onToggle: () => setState(() => _oosExpanded = !_oosExpanded),
            ),
          const SizedBox(height: 24),
        ];
      },
      loading: () => [
        const Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Analysing listings…',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
      error: (e, _) => [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AppColors.lossRed),
          ),
        ),
      ],
    );
  }
}

// ── Budget input card ──────────────────────────────────────────────────────────

class _BudgetInputCard extends StatelessWidget {
  final TextEditingController budgetCtrl;
  final VoidCallback onRun;

  const _BudgetInputCard({
    required this.budgetCtrl,
    required this.onRun,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryGold.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Enter Your Budget',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                r'$',
                style: TextStyle(
                  color: AppColors.primaryGold,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: budgetCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))
                  ],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: AppColors.primaryGold, width: 2),
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                  ),
                  onSubmitted: (_) => onRun(),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'AUD',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onRun,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Find Recommendations',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Results header ─────────────────────────────────────────────────────────────

class _ResultsHeader extends StatelessWidget {
  final int count;

  const _ResultsHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        '$count match${count == 1 ? '' : 'es'} within budget',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Out of Stock section ───────────────────────────────────────────────────────

class _OosSection extends StatelessWidget {
  final List<InvestmentRecommendation> recs;
  final bool expanded;
  final VoidCallback onToggle;

  const _OosSection(
      {required this.recs, required this.expanded, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Out of Stock (${recs.length})',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          for (final rec in recs)
            Opacity(opacity: 0.55, child: RecommendationCard(rec: rec)),
      ],
    );
  }
}
