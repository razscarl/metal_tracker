// lib/features/holdings/presentation/screens/add_holding_screen.dart:Add Holding Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/constants/app_constants.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/core/utils/weight_converter.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/core/widgets/app_drawer.dart';
import 'package:metal_tracker/features/holdings/presentation/providers/holdings_providers.dart';
import 'package:metal_tracker/features/product_profiles/data/models/product_profile_model.dart';
import 'package:metal_tracker/features/retailers/data/models/retailers_model.dart';
import 'package:metal_tracker/features/product_profiles/presentation/screens/add_product_profile_screen.dart';
import 'package:metal_tracker/features/retailers/presentation/providers/retailers_providers.dart';

class AddHoldingScreen extends ConsumerStatefulWidget {
  final String? prefillProductName;
  final String? prefillProfileId;
  final String? prefillRetailerId;
  final double? prefillPrice;

  const AddHoldingScreen({
    super.key,
    this.prefillProductName,
    this.prefillProfileId,
    this.prefillRetailerId,
    this.prefillPrice,
  });

  @override
  ConsumerState<AddHoldingScreen> createState() => _AddHoldingScreenState();
}

class _AddHoldingScreenState extends ConsumerState<AddHoldingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _purchasePriceController = TextEditingController();

  MetalType _selectedMetalType = MetalType.gold;
  Retailer? _selectedRetailer;
  ProductProfile? _selectedProfile;
  DateTime _selectedDate = DateTime.now();
  bool _prefillApplied = false;

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

  Future<void> _createHolding() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product profile'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    await ref.read(createHoldingProvider.notifier).run({
      'productName': _productNameController.text.trim(),
      'productProfileId': _selectedProfile!.id,
      'retailerId': _selectedRetailer?.id,
      'purchaseDate': _selectedDate,
      'purchasePrice': double.parse(_purchasePriceController.text),
    });

    // Check state after run() completes — if no error, pop and notify
    final state = ref.read(createHoldingProvider);
    if (mounted && !state.hasError) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Holding added successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
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

  Future<void> _navigateToCreateProfile() async {
    final result = await Navigator.push<ProductProfile>(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductProfileScreen(
          metalType: _selectedMetalType,
        ),
      ),
    );

    if (result != null) {
      setState(() => _selectedProfile = result);
    }
  }

  void _applyPrefill(List<ProductProfile> profiles, List<Retailer> retailers) {
    if (_prefillApplied) return;
    _prefillApplied = true;
    if (widget.prefillProductName != null) {
      _productNameController.text = widget.prefillProductName!;
    }
    if (widget.prefillPrice != null) {
      _purchasePriceController.text =
          widget.prefillPrice!.toStringAsFixed(2);
    }
    if (widget.prefillProfileId != null) {
      final match = profiles.where((p) => p.id == widget.prefillProfileId);
      if (match.isNotEmpty) setState(() => _selectedProfile = match.first);
    }
    if (widget.prefillRetailerId != null) {
      final match =
          retailers.where((r) => r.id == widget.prefillRetailerId);
      if (match.isNotEmpty) setState(() => _selectedRetailer = match.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final retailersAsync = ref.watch(retailersProvider);
    final profilesAsync = ref.watch(productProfilesProvider);
    final createState = ref.watch(createHoldingProvider);

    // Listen for errors
    ref.listen(createHoldingProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${next.error}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    // Apply prefill once profiles and retailers are loaded
    if (profilesAsync.hasValue && retailersAsync.hasValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyPrefill(profilesAsync.value!, retailersAsync.value!);
      });
    }

    return AppScaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Add Holding'),
        backgroundColor: AppColors.backgroundCard,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Step 1: Metal Type
            Text(
              'Step 1: Select Metal Type',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
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
                          _selectedProfile = null;
                        });
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Step 2: Retailer
            Text(
              'Step 2: Select Retailer (Optional)',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            retailersAsync.when(
              data: (retailers) {
                return DropdownButtonFormField<Retailer>(
                  initialValue: _selectedRetailer,
                  decoration: const InputDecoration(
                    labelText: 'Retailer',
                    prefixIcon: Icon(Icons.store),
                  ),
                  items: [
                    const DropdownMenuItem<Retailer>(
                      value: null,
                      child: Text('None / Unknown'),
                    ),
                    ...retailers.map((retailer) {
                      return DropdownMenuItem(
                        value: retailer,
                        child: Text(retailer.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedRetailer = value);
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error loading retailers'),
            ),
            const SizedBox(height: 24),

            // Step 3: Product Profile
            Text(
              'Step 3: Select Product Profile',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            profilesAsync.when(
              data: (profiles) {
                final filteredProfiles = _sortProfiles(
                  profiles
                      .where(
                          (p) => p.metalType == _selectedMetalType.displayName)
                      .toList(),
                );

                return Column(
                  children: [
                    if (_selectedProfile != null)
                      Card(
                        color: AppColors.primaryGold.withValues(alpha: 0.1),
                        child: ListTile(
                          leading: const Icon(Icons.check_circle,
                              color: AppColors.success),
                          title: Text(_selectedProfile!.profileName),
                          subtitle: Text(
                            '${_selectedProfile!.weightDisplay}${_selectedProfile!.weightUnit} • ${_selectedProfile!.purity}%',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() => _selectedProfile = null);
                            },
                          ),
                        ),
                      ),
                    if (_selectedProfile == null) ...[
                      if (filteredProfiles.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No ${_selectedMetalType.displayName} product profiles yet',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        )
                      else
                        ...filteredProfiles.map((profile) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(profile.profileName),
                              subtitle: Text(
                                '${profile.weightDisplay}${profile.weightUnit} • ${profile.purity}%',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                setState(() => _selectedProfile = profile);
                              },
                            ),
                          );
                        }),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _navigateToCreateProfile,
                        icon: const Icon(Icons.add),
                        label: const Text('Create New Product Profile'),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error loading profiles'),
            ),
            const SizedBox(height: 24),

            // Step 4: Purchase Details
            if (_selectedProfile != null) ...[
              Text(
                'Step 4: Purchase Details',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _productNameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  prefixIcon: Icon(Icons.label),
                  helperText: 'e.g., 2023 Gold Maple Leaf',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
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
              SizedBox(
                height: AppConstants.buttonHeight,
                child: ElevatedButton(
                  onPressed: createState.isLoading ? null : _createHolding,
                  child: createState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textDark,
                          ),
                        )
                      : const Text('Add Holding'),
                ),
              ),
            ],
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Image.asset(
                MetalColorHelper.getAssetPathForMetal(metalType),
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 8),
              Text(
                metalType.displayName,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
