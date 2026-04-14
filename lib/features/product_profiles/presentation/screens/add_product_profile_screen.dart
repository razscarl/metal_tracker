// lib/features/product_profiles/presentation/screens/add_product_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/constants/app_constants.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/features/metadata/presentation/providers/metadata_providers.dart';
import 'package:metal_tracker/features/product_profiles/presentation/providers/product_profiles_providers.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';

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
  String? _selectedFormName; // DB-driven; null until provider loads
  late WeightUnit _selectedUnit;

  @override
  void initState() {
    super.initState();
    _selectedMetalType = widget.metalType ?? MetalType.gold;
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

    try {
      final purityValue = await ref.read(
          getPurityValueProvider(_purityController.text.trim()).future);

      final weightInput = _weightController.text.trim();
      final weight = _parseWeight(weightInput);
      final weightDisplay = weightInput;

      final effectiveForm = _selectedFormName ?? MetalForm.castBar.displayName;
      final formName = effectiveForm == 'Other'
          ? _customFormController.text
          : effectiveForm;

      final profileCode =
          '${_formatWeightForCode(weight)}${_selectedUnit.displayName.toUpperCase()}-'
          '${_selectedMetalType.displayName.toUpperCase()}-'
          '${purityValue.toString().replaceAll('.', '')}-'
          '${formName.toUpperCase().replaceAll(' ', '')}';

      final profileName =
          '$weightDisplay${_selectedUnit.displayName} ${_selectedMetalType.displayName} '
          '${purityValue.toStringAsFixed(2)}% $formName';

      final profile =
          await ref.read(createProductProfileProvider.notifier).createProfile(
                profileName: profileName,
                profileCode: profileCode,
                metalType: _selectedMetalType.displayName,
                metalForm: formName,
                metalFormCustom:
                    effectiveForm == 'Other' ? _customFormController.text : null,
                weight: weight,
                weightDisplay: weightDisplay,
                weightUnit: _selectedUnit.displayName,
                purity: purityValue,
              );

      if (mounted && profile != null) {
        ref.invalidate(productProfilesNotifierProvider);
        Navigator.pop(context, profile);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product profile created successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createProductProfileProvider);
    final metalTypesAsync = ref.watch(metalTypesProvider);
    final metalFormsAsync = ref.watch(metalFormsProvider);

    // Derive the active form list; fall back to enum values if provider fails
    final formNames = metalFormsAsync.valueOrNull?.map((r) => r.name).toList()
        ?? MetalForm.values.map((f) => f.displayName).toList();
    final effectiveForm = (_selectedFormName != null && formNames.contains(_selectedFormName))
        ? _selectedFormName!
        : (formNames.isNotEmpty ? formNames.first : MetalForm.castBar.displayName);

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

    return AppScaffold(
      title: 'Create Product Profile',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Metal Type Dropdown (DB-driven names, enum value)
            DropdownButtonFormField<MetalType>(
              key: ValueKey(_selectedMetalType),
              initialValue: _selectedMetalType,
              decoration: InputDecoration(
                labelText: 'Metal Type',
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(
                    MetalColorHelper.getAssetPathForMetal(_selectedMetalType),
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              items: MetalType.values.map((metal) {
                final dbName = metalTypesAsync.valueOrNull
                        ?.where((r) => r.name == metal.displayName)
                        .map((r) => r.name)
                        .firstOrNull ??
                    metal.displayName;
                return DropdownMenuItem(
                  value: metal,
                  child: Row(
                    children: [
                      Image.asset(
                        MetalColorHelper.getAssetPathForMetal(metal),
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 12),
                      Text(dbName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedMetalType = value!);
              },
            ),
            const SizedBox(height: 16),

            // Metal Form Dropdown (fully DB-driven)
            DropdownButtonFormField<String>(
              key: ValueKey(effectiveForm),
              initialValue: effectiveForm,
              decoration: const InputDecoration(
                labelText: 'Metal Form',
                prefixIcon: Icon(Icons.category),
              ),
              items: formNames.map((name) {
                return DropdownMenuItem<String>(
                  value: name,
                  child: Text(name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedFormName = value);
              },
            ),
            const SizedBox(height: 16),

            // Custom form name (when "Other" is selected)
            if (effectiveForm == 'Other') ...[
              TextFormField(
                controller: _customFormController,
                decoration: const InputDecoration(
                  labelText: 'Custom Form Name',
                  prefixIcon: Icon(Icons.edit),
                ),
                validator: (value) {
                  if (effectiveForm == 'Other' &&
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
                    keyboardType: TextInputType.text,
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
