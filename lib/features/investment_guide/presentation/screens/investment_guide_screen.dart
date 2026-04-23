import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/features/investment_guide/data/models/investment_recommendation.dart';
import 'package:metal_tracker/features/investment_guide/presentation/providers/investment_guide_providers.dart';
import 'package:metal_tracker/features/investment_guide/presentation/widgets/market_context_banner.dart';
import 'package:metal_tracker/features/investment_guide/presentation/widgets/recommendation_card.dart';

class InvestmentGuideScreen extends ConsumerStatefulWidget {
  const InvestmentGuideScreen({super.key});

  @override
  ConsumerState<InvestmentGuideScreen> createState() =>
      _InvestmentGuideScreenState();
}

class _InvestmentGuideScreenState
    extends ConsumerState<InvestmentGuideScreen> {
  final _budgetCtrl = TextEditingController();
  String? _metalFilter; // null = All
  bool _oosExpanded = false;

  @override
  void dispose() {
    _budgetCtrl.dispose();
    super.dispose();
  }

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
          metalFilter: _metalFilter,
        );
  }

  @override
  Widget build(BuildContext context) {
    final guideAsync = ref.watch(investmentGuideNotifierProvider);

    return AppScaffold(
      title: 'Investment Guide',
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
                  metalFilter: _metalFilter,
                  onMetalChanged: (v) => setState(() => _metalFilter = v),
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
          if (oos.isNotEmpty) _OosSection(recs: oos, expanded: _oosExpanded,
            onToggle: () => setState(() => _oosExpanded = !_oosExpanded)),
          const SizedBox(height: 24),
        ];
      },
      loading: () => [
        const Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                CircularProgressIndicator(color: AppColors.primaryGold),
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
  final String? metalFilter;
  final ValueChanged<String?> onMetalChanged;
  final VoidCallback onRun;

  const _BudgetInputCard({
    required this.budgetCtrl,
    required this.metalFilter,
    required this.onMetalChanged,
    required this.onRun,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Budget field
          TextField(
            controller: budgetCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))
            ],
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 18),
            decoration: InputDecoration(
              prefixText: r'$',
              prefixStyle: const TextStyle(
                color: AppColors.primaryGold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              hintText: 'Budget (AUD)',
              hintStyle: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 15),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide:
                    BorderSide(color: AppColors.primaryGold, width: 2),
              ),
            ),
            onSubmitted: (_) => onRun(),
          ),
          const SizedBox(height: 14),

          // Metal filter chips
          Row(
            children: [
              for (final opt in [
                (label: 'All', value: null as String?),
                (label: 'Gold', value: 'gold'),
                (label: 'Silver', value: 'silver'),
                (label: 'Platinum', value: 'platinum'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _MetalChip(
                    label: opt.label,
                    selected: metalFilter == opt.value,
                    onTap: () => onMetalChanged(opt.value),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Run button
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

class _MetalChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MetalChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryGold.withAlpha(40)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryGold : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primaryGold : AppColors.textSecondary,
            fontSize: 13,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
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
                  expanded
                      ? Icons.expand_less
                      : Icons.expand_more,
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
