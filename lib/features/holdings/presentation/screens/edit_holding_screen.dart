// lib/features/holdings/presentation/screens/edit_holding_screen.dart:Edit Holding Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/holding_model.dart';
import '../providers/holdings_providers.dart';

class EditHoldingScreen extends ConsumerStatefulWidget {
  final Holding holding;

  const EditHoldingScreen({
    super.key,
    required this.holding,
  });

  @override
  ConsumerState<EditHoldingScreen> createState() => _EditHoldingScreenState();
}

class _EditHoldingScreenState extends ConsumerState<EditHoldingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _productNameController;
  late final TextEditingController _purchasePriceController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _productNameController =
        TextEditingController(text: widget.holding.productName);
    _purchasePriceController = TextEditingController(
      text: widget.holding.purchasePrice.toStringAsFixed(2),
    );
    _selectedDate = widget.holding.purchaseDate;
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _purchasePriceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: AppConstants.minPurchaseDate,
      lastDate: AppConstants.maxPurchaseDate,
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(updateHoldingProvider.notifier).run({
      'id': widget.holding.id,
      'productName': _productNameController.text.trim(),
      'purchaseDate': _selectedDate,
      'purchasePrice': double.parse(_purchasePriceController.text),
      'retailerId': null,
    });

    final state = ref.read(updateHoldingProvider);
    if (mounted && !state.hasError) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Holding updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(updateHoldingProvider);

    // Listen for errors
    ref.listen(updateHoldingProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${next.error}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Holding'),
        backgroundColor: AppColors.backgroundCard,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(AppConstants.cardBorderRadius),
                border: Border.all(
                  color: AppColors.primaryGold.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primaryGold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You can only edit the product name, purchase date, and purchase price. To change the product type, create a new holding.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Product Name
            TextFormField(
              controller: _productNameController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter product name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Purchase Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Purchase Date'),
              subtitle: Text(
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              ),
              trailing: const Icon(Icons.edit),
              onTap: _selectDate,
            ),
            const SizedBox(height: 16),

            // Purchase Price
            TextFormField(
              controller: _purchasePriceController,
              decoration: const InputDecoration(
                labelText: 'Purchase Price (AUD)',
                prefixIcon: Icon(Icons.attach_money),
                prefixText: '\$',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter purchase price';
                }
                final price = double.tryParse(value);
                if (price == null) {
                  return 'Invalid price';
                }
                if (price < AppConstants.minPrice ||
                    price > AppConstants.maxPrice) {
                  return 'Price out of range';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              height: AppConstants.buttonHeight,
              child: ElevatedButton(
                onPressed: updateState.isLoading ? null : _saveChanges,
                child: updateState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textDark,
                        ),
                      )
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
