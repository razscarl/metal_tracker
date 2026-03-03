// lib/features/live_prices/presentation/screens/manual_live_price_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../product_profiles/data/models/product_profile_model.dart';
import '../../../retailers/data/models/retailers_model.dart';
import '../../../holdings/presentation/providers/holdings_providers.dart';
import '../../../retailers/presentation/providers/retailers_providers.dart';
import '../providers/live_prices_providers.dart';

class ManualLivePriceEntryScreen extends ConsumerStatefulWidget {
  const ManualLivePriceEntryScreen({super.key});

  @override
  ConsumerState<ManualLivePriceEntryScreen> createState() =>
      _ManualLivePriceEntryScreenState();
}

class _ManualLivePriceEntryScreenState
    extends ConsumerState<ManualLivePriceEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sellPriceController = TextEditingController();
  final _buybackPriceController = TextEditingController();

  ProductProfile? _selectedProfile;
  Retailer? _selectedRetailer;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _sellPriceController.dispose();
    _buybackPriceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: AppConstants.minPurchaseDate,
      lastDate: AppConstants.maxPurchaseDate,
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _saveLivePrice() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a product profile'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    if (_selectedRetailer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a retailer'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    final sellPrice = _sellPriceController.text.isNotEmpty
        ? double.tryParse(_sellPriceController.text)
        : null;
    final buybackPrice = _buybackPriceController.text.isNotEmpty
        ? double.tryParse(_buybackPriceController.text)
        : null;

    if (sellPrice == null && buybackPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter at least one price'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    await ref.read(livePricesNotifierProvider.notifier).addManualPrice(
          productProfileId: _selectedProfile!.id,
          retailerId: _selectedRetailer!.id,
          captureDate: _selectedDate,
          sellPrice: sellPrice,
          buybackPrice: buybackPrice,
        );

    final state = ref.read(livePricesNotifierProvider);
    if (!mounted || state.hasError) return;

    // Capture local copies before async gap
    final profileName = _selectedProfile!.profileName;
    final retailerName = _selectedRetailer!.name;

    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Live Price Saved'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 48),
            const SizedBox(height: 16),
            Text('Price saved for $profileName',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text('Retailer: $retailerName',
                style: Theme.of(context).textTheme.bodyMedium),
            if (sellPrice != null)
              Text('Sell Price: \$${sellPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium),
            if (buybackPrice != null)
              Text('Buyback Price: \$${buybackPrice.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Done'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add Another Price'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (shouldContinue == true) {
      setState(() {
        _selectedProfile = null;
        _selectedRetailer = null;
        _sellPriceController.clear();
        _buybackPriceController.clear();
        _selectedDate = DateTime.now();
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(productProfilesProvider);
    final retailersAsync = ref.watch(retailersProvider);
    final createState = ref.watch(livePricesNotifierProvider);

    ref.listen(livePricesNotifierProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${next.error}'),
          backgroundColor: AppColors.error,
        ));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Live Price Entry'),
        backgroundColor: AppColors.backgroundCard,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(AppConstants.cardBorderRadius),
                border: Border.all(
                    color: AppColors.primaryGold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primaryGold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Enter current prices from retailers. These will be used to calculate your portfolio value.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Product Profile',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            profilesAsync.when(
              data: (profiles) => DropdownButtonFormField<ProductProfile>(
                value: _selectedProfile,
                decoration: const InputDecoration(
                  labelText: 'Select Product Profile',
                  prefixIcon: Icon(Icons.inventory_2),
                ),
                items: profiles
                    .map((p) =>
                        DropdownMenuItem(value: p, child: Text(p.profileName)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedProfile = v),
                validator: (v) =>
                    v == null ? 'Please select a product profile' : null,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error loading product profiles'),
            ),
            const SizedBox(height: 24),
            Text('Retailer', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            retailersAsync.when(
              data: (retailers) => DropdownButtonFormField<Retailer>(
                value: _selectedRetailer,
                decoration: const InputDecoration(
                  labelText: 'Select Retailer',
                  prefixIcon: Icon(Icons.store),
                ),
                items: retailers
                    .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedRetailer = v),
                validator: (v) => v == null ? 'Please select a retailer' : null,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error loading retailers'),
            ),
            const SizedBox(height: 24),
            Text('Prices', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _sellPriceController,
              decoration: const InputDecoration(
                labelText: 'Sell Price (what retailer sells for)',
                prefixIcon: Icon(Icons.trending_up),
                prefixText: '\$',
                helperText: 'Optional',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final price = double.tryParse(value);
                  if (price == null || price < 0) return 'Invalid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _buybackPriceController,
              decoration: const InputDecoration(
                labelText: 'Buyback Price (what retailer buys from you)',
                prefixIcon: Icon(Icons.trending_down),
                prefixText: '\$',
                helperText: 'Optional - but needed for portfolio valuation',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final price = double.tryParse(value);
                  if (price == null || price < 0) return 'Invalid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Capture Date'),
              subtitle: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
              trailing: const Icon(Icons.edit),
              onTap: _selectDate,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: AppConstants.buttonHeight,
              child: ElevatedButton(
                onPressed: createState.isLoading ? null : _saveLivePrice,
                child: createState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.textDark))
                    : const Text('Save Live Price'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
