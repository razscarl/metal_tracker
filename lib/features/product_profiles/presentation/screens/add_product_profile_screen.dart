// lib/features/product_profiles/presentation/screens/add_product_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/constants/app_constants.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/features/holdings/presentation/providers/holdings_providers.dart';
import 'package:metal_tracker/features/product_profiles/presentation/providers/product_profiles_providers.dart';

class AddProductProfileScreen extends ConsumerStatefulWidget {
  final MetalType? metalType;

  const AddProductProfileScreen({
    super.key,
    this.metalType,
  });

  @override
  ConsumerState<AddProductProfileScreen> createState() =>
      _AddProductProfileScreenState();
}

class _AddProductProfileScreenState
    extends ConsumerState<AddProductProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _purityController = TextEditingController();
  final _customFormController = TextEditingController();

  late MetalType _selectedMetalType;
  late MetalForm _selectedForm;
  late WeightUnit _selectedUnit;

  @override
  void initState() {
    super.initState();
    _selectedMetalType = widget.metalType ?? MetalType.gold;
    _selectedForm = MetalForm.castBar;
    _selectedUnit = WeightUnit.oz;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _purityController.dispose();
    _customFormController.dispose();
    super.dispose();
  }

  /// Parse weight input - supports fractions (1/4) and decimals (0.25)
  double _parseWeight(String input) {
    input = input.trim();

    // Check if it's a fraction
    if (input.contains('/')) {
      final parts = input.split('/');
      if (parts.length == 2) {
        final numerator = double.tryParse(parts[0].trim());
        final denominator = double.tryParse(parts[1].trim());
        if (numerator != null && denominator != null && denominator != 0) {
          return numerator / denominator;
        }
      }
      throw const FormatException('Invalid fraction format');
    }

    // Otherwise parse as decimal
    final weight = double.tryParse(input);
    if (weight == null) {
      throw const FormatException('Invalid number format');
    }
    return weight;
  }

  /// Format weight for profile code (remove decimals for whole numbers)
  String _formatWeightForCode(double weight) {
    if (weight == weight.roundToDouble()) {
      return weight.toInt().toString();
    }
    return weight.toString().replaceAll('.', '');
  }

  Future<void> _createProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Get purity value using provider
    final purityAsync =
        ref.read(getPurityValueProvider(_purityController.text.trim()));

    purityAsync.when(
      data: (purityValue) async {
        final weightInput = _weightController.text.trim();
        final weight = _parseWeight(weightInput);
        final weightDisplay = weightInput; // Store exactly as user entered

        final formName = _selectedForm == MetalForm.other
            ? _customFormController.text
            : _selectedForm.displayName;

        // Fixed: Use purity with decimals (99.99) not rounded (100)
        final profileCode =
            '${_formatWeightForCode(weight)}${_selectedUnit.displayName.toUpperCase()}-'
            '${_selectedMetalType.displayName.toUpperCase()}-'
            '${purityValue.toString().replaceAll('.', '')}-'
            '${formName.toUpperCase().replaceAll(' ', '')}';

        // Fixed: Remove suffix - just the basic format
        final profileName =
            '$weightDisplay${_selectedUnit.displayName} ${_selectedMetalType.displayName} '
            '${purityValue.toStringAsFixed(2)}% $formName';

        // Use provider to create profile
        final profile =
            await ref.read(createProductProfileProvider.notifier).createProfile(
                  profileName: profileName,
                  profileCode: profileCode,
                  metalType: _selectedMetalType.displayName,
                  metalForm: _selectedForm.displayName,
                  metalFormCustom: _selectedForm == MetalForm.other
                      ? _customFormController.text
                      : null,
                  weight: weight,
                  weightDisplay: weightDisplay,
                  weightUnit: _selectedUnit.displayName,
                  purity: purityValue,
                );

        if (mounted && profile != null) {
          ref.invalidate(productProfilesProvider);
          Navigator.pop(context, profile);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product profile created successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
      loading: () {},
      error: (error, stack) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createProductProfileProvider);

    // Show error if exists
    ref.listen(createProductProfileProvider, (previous, next) {
      if (next.error != null) {
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
        title: const Text('Create Product Profile'),
        backgroundColor: AppColors.backgroundCard,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Metal Type Dropdown
            DropdownButtonFormField<MetalType>(
              initialValue: _selectedMetalType,
              decoration: InputDecoration(
                labelText: 'Metal Type',
                prefixIcon: Icon(
                  MetalColorHelper.getIconForMetal(_selectedMetalType),
                  color: MetalColorHelper.getColorForMetal(_selectedMetalType),
                ),
              ),
              items: MetalType.values.map((metal) {
                return DropdownMenuItem(
                  value: metal,
                  child: Row(
                    children: [
                      Icon(
                        MetalColorHelper.getIconForMetal(metal),
                        color: MetalColorHelper.getColorForMetal(metal),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(metal.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedMetalType = value!);
              },
            ),
            const SizedBox(height: 16),

            // Metal Form Dropdown
            DropdownButtonFormField<MetalForm>(
              initialValue: _selectedForm,
              decoration: const InputDecoration(
                labelText: 'Metal Form',
                prefixIcon: Icon(Icons.category),
              ),
              items: MetalForm.values.map((form) {
                return DropdownMenuItem(
                  value: form,
                  child: Text(form.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedForm = value!);
              },
            ),
            const SizedBox(height: 16),

            // Custom form name
            if (_selectedForm == MetalForm.other) ...[
              TextFormField(
                controller: _customFormController,
                decoration: const InputDecoration(
                  labelText: 'Custom Form Name',
                  prefixIcon: Icon(Icons.edit),
                ),
                validator: (value) {
                  if (_selectedForm == MetalForm.other &&
                      (value == null || value.isEmpty)) {
                    return 'Please enter custom form name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            // Weight Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Weight',
                      helperText: 'e.g., 1, 1/4, 0.25, 2.5',
                      prefixIcon: Icon(Icons.scale),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      try {
                        final weight = _parseWeight(value);
                        if (weight < AppConstants.minWeight ||
                            weight > AppConstants.maxWeight) {
                          return 'Invalid range';
                        }
                      } catch (e) {
                        return 'Invalid format';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<WeightUnit>(
                    initialValue: _selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                    ),
                    items: WeightUnit.values.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedUnit = value!);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Purity
            TextFormField(
              controller: _purityController,
              decoration: const InputDecoration(
                labelText: 'Purity',
                helperText: 'e.g., 99.99, 24k, 925, 0.9999',
                prefixIcon: Icon(Icons.verified),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter purity';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Info box
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
                      'Weight supports fractions (1/4) and decimals (0.25). The app will remember your exact input.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Create button
            SizedBox(
              height: AppConstants.buttonHeight,
              child: ElevatedButton(
                onPressed: createState.isLoading ? null : _createProfile,
                child: createState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textDark,
                        ),
                      )
                    : const Text('Create Product Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
