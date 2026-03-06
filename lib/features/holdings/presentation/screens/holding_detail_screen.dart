// lib/features/holdings/presentation/screens/holding_detail_screen.dart:Holding Detail Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/constants/app_constants.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/core/utils/weight_converter.dart';
import 'package:metal_tracker/features/holdings/data/models/holding_model.dart';
import 'package:metal_tracker/features/holdings/presentation/providers/holdings_providers.dart';
import 'package:metal_tracker/features/holdings/presentation/screens/edit_holding_screen.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/core/widgets/app_drawer.dart';

class HoldingDetailScreen extends ConsumerWidget {
  final Holding holding;

  const HoldingDetailScreen({
    super.key,
    required this.holding,
  });

  Future<void> _showDeleteConfirmation(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Holding'),
        content: Text(
          'Are you sure you want to delete "${holding.productName}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textPrimary,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(deleteHoldingProvider.notifier).run(holding.id);

      final state = ref.read(deleteHoldingProvider);
      if (context.mounted && !state.hasError) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Holding deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _showSellDialog(BuildContext context, WidgetRef ref) async {
    final soldPriceController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Sell Holding'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You are selling: ${holding.productName}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Sale Date'),
                subtitle: Text(
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                ),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: holding.purchaseDate,
                    lastDate: AppConstants.maxPurchaseDate,
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: soldPriceController,
                decoration: const InputDecoration(
                  labelText: 'Sale Price (AUD)',
                  prefixIcon: Icon(Icons.attach_money),
                  prefixText: '\$',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final price = double.tryParse(soldPriceController.text);
                if (price != null && price > 0) {
                  Navigator.pop(context, {
                    'date': selectedDate,
                    'price': price,
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid sale price'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              child: const Text('Confirm Sale'),
            ),
          ],
        ),
      ),
    );

    if (result != null && context.mounted) {
      await ref.read(sellHoldingProvider.notifier).run({
        'id': holding.id,
        'soldDate': result['date'],
        'soldPrice': result['price'],
      });

      final state = ref.read(sellHoldingProvider);
      if (context.mounted && !state.hasError) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Holding marked as sold'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = holding.productProfile;
    final valuationAsync = ref.watch(portfolioValuationProvider);

    ref.listen(deleteHoldingProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting: ${next.error}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    ref.listen(sellHoldingProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selling: ${next.error}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return AppScaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Holding Details'),
        backgroundColor: AppColors.backgroundCard,
        actions: [
          if (!holding.isSold) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditHoldingScreen(holding: holding),
                  ),
                );
                ref.invalidate(holdingsProvider);
              },
            ),
            IconButton(
              icon: const Icon(Icons.sell),
              onPressed: () => _showSellDialog(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmation(context, ref),
            ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (profile != null)
                        Image.asset(
                          MetalColorHelper.getAssetPathForMetal(
                              profile.metalTypeEnum),
                          width: 32,
                          height: 32,
                          fit: BoxFit.contain,
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          holding.productName,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                    ],
                  ),
                  if (holding.isSold) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(
                            AppConstants.cardBorderRadius),
                      ),
                      child: const Text(
                        'SOLD',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (profile != null) ...[
            Text(
              'Product Profile',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _DetailRow(
                      label: 'Metal Type',
                      value: profile.metalType,
                    ),
                    _DetailRow(
                      label: 'Metal Form',
                      value: profile.metalForm,
                    ),
                    _DetailRow(
                      label: 'Weight',
                      value: '${profile.weightDisplay} ${profile.weightUnit}',
                    ),
                    _DetailRow(
                      label: 'Purity',
                      value: '${profile.purity}%',
                    ),
                    _DetailRow(
                      label: 'Pure Metal Content',
                      value:
                          '${profile.pureMetalContent.toStringAsFixed(4)} ${profile.weightUnit}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Purchase Details',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Purchase Date',
                    value:
                        '${holding.purchaseDate.day}/${holding.purchaseDate.month}/${holding.purchaseDate.year}',
                  ),
                  _DetailRow(
                    label: 'Purchase Price',
                    value: '\$${holding.purchasePrice.toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Valuation section — active holdings only
          if (!holding.isSold && profile != null) ...[
            Text(
              'Valuation',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            valuationAsync.when(
              data: (valuation) {
                final bestPrice = valuation
                    .metalBreakdown[profile.metalTypeEnum]?.bestPricePerOz;
                if (bestPrice == null) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Text(
                            'No live prices available for ${profile.metalType}',
                            style: const TextStyle(
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final currentValue = WeightCalculations.holdingValue(
                  weight: profile.weight,
                  unit: profile.weightUnitEnum,
                  purity: profile.purity,
                  currentPricePerPureOz: bestPrice,
                );
                final gainLoss = currentValue - holding.purchasePrice;
                final gainLossPercent = holding.purchasePrice > 0
                    ? (gainLoss / holding.purchasePrice) * 100
                    : 0.0;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _DetailRow(
                          label: 'Current Value',
                          value:
                              '\$${currentValue.toStringAsFixed(2)}',
                        ),
                        _DetailRow(
                          label: 'Gain / Loss',
                          value:
                              '${gainLoss >= 0 ? "+" : ""}\$${gainLoss.toStringAsFixed(2)} '
                              '(${gainLossPercent >= 0 ? "+" : ""}${gainLossPercent.toStringAsFixed(2)}%)',
                          valueColor: gainLoss >= 0
                              ? AppColors.gainGreen
                              : AppColors.lossRed,
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
          ],

          if (holding.isSold) ...[
            Text(
              'Sale Details',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _DetailRow(
                      label: 'Sale Date',
                      value: holding.soldDate != null
                          ? '${holding.soldDate!.day}/${holding.soldDate!.month}/${holding.soldDate!.year}'
                          : 'N/A',
                    ),
                    _DetailRow(
                      label: 'Sale Price',
                      value: holding.soldPrice != null
                          ? '\$${holding.soldPrice!.toStringAsFixed(2)}'
                          : 'N/A',
                    ),
                    if (holding.soldPrice != null) ...[
                      const Divider(height: 24),
                      _DetailRow(
                        label: 'Profit/Loss',
                        value:
                            '\$${(holding.soldPrice! - holding.purchasePrice).toStringAsFixed(2)}',
                        valueColor: holding.soldPrice! >= holding.purchasePrice
                            ? AppColors.gainGreen
                            : AppColors.lossRed,
                      ),
                      _DetailRow(
                        label: 'Profit/Loss %',
                        value:
                            '${((holding.soldPrice! - holding.purchasePrice) / holding.purchasePrice * 100).toStringAsFixed(2)}%',
                        valueColor: holding.soldPrice! >= holding.purchasePrice
                            ? AppColors.gainGreen
                            : AppColors.lossRed,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
