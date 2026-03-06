// lib/features/retailers/presentation/screens/add_edit_retailer_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/features/retailers/data/models/retailers_model.dart';
import 'package:metal_tracker/features/retailers/presentation/providers/retailers_providers.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/core/widgets/app_drawer.dart';

class AddEditRetailerScreen extends ConsumerStatefulWidget {
  final Retailer? retailer; // null = add mode, not null = edit mode

  const AddEditRetailerScreen({super.key, this.retailer});

  @override
  ConsumerState<AddEditRetailerScreen> createState() =>
      _AddEditRetailerScreenState();
}

class _AddEditRetailerScreenState extends ConsumerState<AddEditRetailerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _abbrController;
  late TextEditingController _urlController;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.retailer?.name ?? '');
    _abbrController =
        TextEditingController(text: widget.retailer?.retailerAbbr ?? '');
    _urlController =
        TextEditingController(text: widget.retailer?.baseUrl ?? '');
    _isActive = widget.retailer?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _abbrController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  bool get _isEditMode => widget.retailer != null;

  Future<void> _saveRetailer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(retailerRepositoryProvider);

      if (_isEditMode) {
        // Update existing retailer
        await repository.updateRetailer(
          retailerId: widget.retailer!.id,
          name: _nameController.text.trim(),
          retailerAbbr: _abbrController.text.trim().toUpperCase(),
          baseUrl: _urlController.text.trim(),
          isActive: _isActive,
        );
      } else {
        // Create new retailer
        await repository.createRetailer(
          name: _nameController.text.trim(),
          retailerAbbr: _abbrController.text.trim().toUpperCase(),
          baseUrl: _urlController.text.trim(),
          isActive: _isActive,
        );
      }

      // Invalidate retailers provider to refresh the list
      ref.invalidate(retailersProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode
                ? 'Retailer updated successfully'
                : 'Retailer created successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
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
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Retailer' : 'Add Retailer'),
        backgroundColor: AppColors.backgroundCard,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Retailer Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Retailer Name',
                hintText: 'e.g., Gold Bullion Australia',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Retailer name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Retailer Abbreviation
            TextFormField(
              controller: _abbrController,
              decoration: const InputDecoration(
                labelText: 'Retailer Abbreviation (Optional)',
                hintText: 'e.g., GBA',
                border: OutlineInputBorder(),
                helperText: 'Will be converted to uppercase',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),

            // Base URL
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Base URL (Optional)',
                hintText: 'e.g., https://example.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),

            // Is Active Toggle
            Card(
              child: SwitchListTile(
                title: const Text('Active'),
                subtitle: Text(
                  _isActive
                      ? 'Retailer is active and visible'
                      : 'Retailer is inactive and hidden',
                ),
                value: _isActive,
                onChanged: (value) {
                  setState(() => _isActive = value);
                },
                activeTrackColor: AppColors.success,
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveRetailer,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primaryGold,
                foregroundColor: AppColors.textDark,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditMode ? 'Update Retailer' : 'Create Retailer'),
            ),
          ],
        ),
      ),
    );
  }
}
