// lib/features/product_profiles/presentation/screens/edit_product_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/constants/app_constants.dart';
import 'package:metal_tracker/core/utils/metal_color_helper.dart';
import 'package:metal_tracker/features/product_profiles/data/models/product_profile_model.dart';
import 'package:metal_tracker/features/product_profiles/presentation/providers/product_profiles_providers.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/core/widgets/app_drawer.dart';

class EditProductProfileScreen extends ConsumerStatefulWidget {
  final ProductProfile profile;

  const EditProductProfileScreen({super.key, required this.profile});

  @override
  ConsumerState<EditProductProfileScreen> createState() =>
      _EditProductProfileScreenState();
}

class _EditProductProfileScreenState
    extends ConsumerState<EditProductProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _purityController = TextEditingController();
  final _customFormController = TextEditingController();

  late MetalType _selectedMetalType;
  late MetalForm _selectedForm;
  late WeightUnit _selectedUnit;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _selectedMetalType = p.metalTypeEnum;
    _selectedForm = MetalForm.fromString(p.metalForm);
    _selectedUnit = p.weightUnitEnum;
    _weightController.text = p.weightDisplay;
    _purityController.text = p.purity.toStringAsFixed(2);
    _customFormController.text = p.metalFormCustom ?? '';
  }

  @override
  void dispose() {
    _weightController.dispose();
    _purityController.dispose();
    _customFormController.dispose();
    super.dispose();
  }

  double _parseWeight(String input) {
    input = input.trim();
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
    final weight = double.tryParse(input);
    if (weight == null) throw const FormatException('Invalid number format');
    return weight;
  }

  String _formatWeightForCode(double weight) {
    if (weight == weight.roundToDouble()) return weight.toInt().toString();
    return weight.toString().replaceAll('.', '');
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final purityValue = await ref.read(
          getPurityValueProvider(_purityController.text.trim()).future);

      final weightInput = _weightController.text.trim();
      final weight = _parseWeight(weightInput);
      final weightDisplay = weightInput;

      final formName = _selectedForm == MetalForm.other
          ? _customFormController.text
          : _selectedForm.displayName;

      final profileCode =
          '${_formatWeightForCode(weight)}${_selectedUnit.displayName.toUpperCase()}-'
          '${_selectedMetalType.displayName.toUpperCase()}-'
          '${purityValue.toString().replaceAll('.', '')}-'
          '${formName.toUpperCase().replaceAll(' ', '')}';

      final profileName =
          '$weightDisplay${_selectedUnit.displayName} ${_selectedMetalType.displayName} '
          '${purityValue.toStringAsFixed(2)}% $formName';

      await ref
          .read(productProfilesNotifierProvider.notifier)
          .updateProfile(
            widget.profile.id,
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

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product profile updated'),
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
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Edit Product Profile'),
        backgroundColor: AppColors.backgroundCard,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Metal Type
            DropdownButtonFormField<MetalType>(
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
                      Text(metal.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) =>
                  setState(() => _selectedMetalType = value!),
            ),
            const SizedBox(height: 16),

            // Metal Form
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
              onChanged: (value) => setState(() => _selectedForm = value!),
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
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      labelText: 'Weight',
                      helperText: 'e.g., 1, 1/4, 0.25, 2.5',
                      prefixIcon: Icon(Icons.scale),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      try {
                        final w = _parseWeight(value);
                        if (w < AppConstants.minWeight ||
                            w > AppConstants.maxWeight) {
                          return 'Invalid range';
                        }
                      } catch (_) {
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
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: WeightUnit.values.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit.displayName),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedUnit = value!),
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

            // Save button
            SizedBox(
              height: AppConstants.buttonHeight,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
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
