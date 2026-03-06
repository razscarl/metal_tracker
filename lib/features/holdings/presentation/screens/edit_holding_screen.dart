// lib/features/holdings/presentation/screens/edit_holding_screen.dart:Edit Holding Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/constants/app_constants.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/core/utils/weight_converter.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/core/widgets/app_drawer.dart';
import 'package:metal_tracker/features/holdings/data/models/holding_model.dart';
import 'package:metal_tracker/features/holdings/presentation/providers/holdings_providers.dart';
import 'package:metal_tracker/features/product_profiles/data/models/product_profile_model.dart';

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
  late MetalType _selectedMetalType;
  ProductProfile? _selectedProfile;

  @override
  void initState() {
    super.initState();
    _productNameController =
        TextEditingController(text: widget.holding.productName);
    _purchasePriceController = TextEditingController(
      text: widget.holding.purchasePrice.toStringAsFixed(2),
    );
    _selectedDate = widget.holding.purchaseDate;
    _selectedProfile = widget.holding.productProfile;
    _selectedMetalType = widget.holding.productProfile?.metalTypeEnum ??
        MetalType.gold;
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _purchasePriceController.dispose();
    super.dispose();
  }

  List<ProductProfile> _sortProfiles(List<ProductProfile> profiles) {
    final sorted = [...profiles];
    sorted.sort((a, b) {
      final mfA = MetalForm.values.indexOf(
        MetalForm.values.firstWhere(
          (e) => e.displayName == a.metalForm,
          orElse: () => MetalForm.other,
        ),
      );
      final mfB = MetalForm.values.indexOf(
        MetalForm.values.firstWhere(
          (e) => e.displayName == b.metalForm,
          orElse: () => MetalForm.other,
        ),
      );
      if (mfA != mfB) return mfA.compareTo(mfB);

      final wA = a.weightUnitEnum.convertTo(a.weight, WeightUnit.oz);
      final wB = b.weightUnitEnum.convertTo(b.weight, WeightUnit.oz);
      if (wA != wB) return wA.compareTo(wB);

      return a.purity.compareTo(b.purity);
    });
    return sorted;
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
      'productProfileId': _selectedProfile?.id,
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
    final profilesAsync = ref.watch(productProfilesProvider);

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

    return AppScaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Edit Holding'),
        backgroundColor: AppColors.backgroundCard,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Product Profile section
            Text(
              'Product Profile',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),

            // Metal type filter
            Row(
              children: MetalType.values.map((metalType) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _MetalTypeCard(
                      metalType: metalType,
                      isSelected: _selectedMetalType == metalType,
                      onTap: () {
                        setState(() {
                          _selectedMetalType = metalType;
                          // Clear selected profile only if it belongs to a different metal type
                          if (_selectedProfile != null &&
                              _selectedProfile!.metalTypeEnum != metalType) {
                            _selectedProfile = null;
                          }
                        });
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Profile list
            profilesAsync.when(
              data: (allProfiles) {
                final filtered = _sortProfiles(
                  allProfiles
                      .where((p) =>
                          p.metalType == _selectedMetalType.displayName)
                      .toList(),
                );

                if (filtered.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No ${_selectedMetalType.displayName} product profiles found',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  );
                }

                return Column(
                  children: filtered.map((profile) {
                    final isSelected = _selectedProfile?.id == profile.id;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isSelected
                          ? AppColors.primaryGold.withValues(alpha: 0.1)
                          : AppColors.backgroundCard,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            AppConstants.cardBorderRadius),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primaryGold
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: ListTile(
                        leading: isSelected
                            ? const Icon(Icons.check_circle,
                                color: AppColors.success)
                            : const Icon(Icons.radio_button_unchecked,
                                color: AppColors.textSecondary),
                        title: Text(profile.profileName),
                        subtitle: Text(
                          '${profile.metalForm} • ${profile.weightDisplay} • ${profile.purity}%',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        onTap: () => setState(() => _selectedProfile = profile),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error loading profiles'),
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

class _MetalTypeCard extends StatelessWidget {
  final MetalType metalType;
  final bool isSelected;
  final VoidCallback onTap;

  const _MetalTypeCard({
    required this.metalType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = MetalColorHelper.getColorForMetal(metalType);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: isSelected
            ? color.withValues(alpha: 0.2)
            : AppColors.backgroundCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          side: BorderSide(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Image.asset(
                MetalColorHelper.getAssetPathForMetal(metalType),
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 4),
              Text(
                metalType.displayName,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
