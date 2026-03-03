// lib/features/holdings/presentation/screens/holdings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/holdings_providers.dart';
import '../../data/models/holding_model.dart';

class HoldingsScreen extends ConsumerWidget {
  const HoldingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final valuationAsync = ref.watch(portfolioValuationProvider);
    final holdingsAsync = ref.watch(holdingsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('My Holdings',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_chart),
            onPressed: () {
              // TODO: Navigate to Add Holding Screen
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(holdingsProvider.future),
        child: Column(
          children: [
            // 1. Summary Header
            valuationAsync.when(
              data: (val) => _buildSummaryHeader(val),
              loading: () => const _HeaderLoading(),
              error: (e, _) => const SizedBox.shrink(),
            ),

            // 2. Holdings List
            Expanded(
              child: holdingsAsync.when(
                data: (holdings) {
                  if (holdings.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: holdings.length,
                    itemBuilder: (context, index) {
                      final holding = holdings[index];
                      return _HoldingCard(holding: holding);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                    child: Text('Error: $err',
                        style: const TextStyle(color: Colors.white))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(PortfolioValuation val) {
    final bool isPositive = val.totalGainLoss >= 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('Total Portfolio Value',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text('\$${val.totalCurrentValue.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                color: isPositive ? Colors.greenAccent : Colors.redAccent,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${isPositive ? "+" : ""}\$${val.totalGainLoss.toStringAsFixed(2)} (${val.totalGainLossPercent.toStringAsFixed(2)}%)',
                style: TextStyle(
                  color: isPositive ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.white24),
          SizedBox(height: 16),
          Text('No holdings yet.',
              style: TextStyle(color: Colors.white54, fontSize: 18)),
        ],
      ),
    );
  }
}

class _HoldingCard extends StatelessWidget {
  final Holding holding;
  const _HoldingCard({required this.holding});

  @override
  Widget build(BuildContext context) {
    final profile = holding.productProfile;
    if (profile == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          // Metal Icon logic
          _buildMetalIndicator(profile.metalTypeEnum),
          const SizedBox(width: 16),

          // Name and weights
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(holding.productName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  '${profile.weightDisplay} ${profile.weightUnit} • ${profile.purity}% Pure',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),

          // Price info
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${holding.purchasePrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500)),
              const Text('Cost Basis',
                  style: TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetalIndicator(MetalType type) {
    Color color;
    switch (type) {
      case MetalType.gold:
        color = const Color(0xFFFFD700);
        break;
      case MetalType.silver:
        color = const Color(0xFFC0C0C0);
        break;
      case MetalType.platinum:
        color = const Color(0xFFE5E4E2);
        break;
      //case MetalType.palladium:
      //  color = const Color(0xFFCED0DD);
      //  break;
    }
    return Container(
      width: 4,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _HeaderLoading extends StatelessWidget {
  const _HeaderLoading();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(32.0),
        child: CircularProgressIndicator(),
      );
}
