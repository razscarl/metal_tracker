// lib/features/retailers/presentation/screens/add_edit_scraper_setting_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/constants/scraper_constants.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/features/retailers/data/models/retailer_scraper_setting_model.dart';
import 'package:metal_tracker/features/retailers/presentation/providers/retailers_providers.dart';

class AddEditScraperSettingScreen extends ConsumerStatefulWidget {
  final String retailerId;
  final RetailerScraperSetting? setting;

  const AddEditScraperSettingScreen({
    super.key,
    required this.retailerId,
    this.setting,
  });

  @override
  ConsumerState<AddEditScraperSettingScreen> createState() =>
      _AddEditScraperSettingScreenState();
}

class _AddEditScraperSettingScreenState
    extends ConsumerState<AddEditScraperSettingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _searchStringController;
  late TextEditingController _searchUrlController;

  String? _selectedScraperType;
  String? _selectedMetalType;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _searchStringController =
        TextEditingController(text: widget.setting?.searchString ?? '');
    _searchUrlController =
        TextEditingController(text: widget.setting?.searchUrl ?? '');
    _selectedScraperType = widget.setting?.scraperType;
    _selectedMetalType = widget.setting?.metalType;
    _isActive = widget.setting?.isActive ?? true;
  }

  @override
  void dispose() {
    _searchStringController.dispose();
    _searchUrlController.dispose();
    super.dispose();
  }

  bool get _isEditMode => widget.setting != null;

  Future<void> _saveSetting() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(scraperRepositoryProvider);

      if (_isEditMode) {
        // Update existing setting
        await repository.updateScraperSetting(
          settingId: widget.setting!.id,
          searchString: _searchStringController.text.trim(),
          isActive: _isActive,
        );
      } else {
        // Create new setting
        await repository.createScraperSetting(
          retailerId: widget.retailerId,
          scraperType: _selectedScraperType!,
          metalType: _selectedMetalType,
          searchString: _searchStringController.text.trim(),
          searchUrl: _searchUrlController.text.trim().isEmpty
              ? null
              : _searchUrlController.text.trim(),
          isActive: _isActive,
        );
      }

      // Invalidate provider to refresh the list
      ref.invalidate(retailerScraperSettingsProvider(widget.retailerId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode
                ? 'Scraper setting updated successfully'
                : 'Scraper setting created successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
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
    return Scaffold(
      appBar: AppBar(
        title:
            Text(_isEditMode ? 'Edit Scraper Setting' : 'Add Scraper Setting'),
        backgroundColor: AppColors.backgroundCard,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Scraper Type Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedScraperType,
              decoration: const InputDecoration(
                labelText: 'Scraper Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: ScraperType.livePrice,
                  child: Text(ScraperType.livePrice),
                ),
                DropdownMenuItem(
                  value: ScraperType.productListing,
                  child: Text(ScraperType.productListing),
                ),
                DropdownMenuItem(
                  value: ScraperType.localSpot,
                  child: Text(ScraperType.localSpot),
                ),
              ],
              onChanged: _isEditMode
                  ? null
                  : (value) {
                      setState(() => _selectedScraperType = value);
                    },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Scraper type is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Metal Type Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedMetalType,
              decoration: const InputDecoration(
                labelText: 'Metal Type (Optional)',
                border: OutlineInputBorder(),
                helperText: 'Leave empty for non-metal-specific scrapers',
              ),
              items: const [
                DropdownMenuItem(
                  value: null,
                  child: Text('None'),
                ),
                DropdownMenuItem(
                  value: 'Gold',
                  child: Text('Gold'),
                ),
                DropdownMenuItem(
                  value: 'Silver',
                  child: Text('Silver'),
                ),
                DropdownMenuItem(
                  value: 'Platinum',
                  child: Text('Platinum'),
                ),
              ],
              onChanged: _isEditMode
                  ? null
                  : (value) {
                      setState(() => _selectedMetalType = value);
                    },
            ),
            const SizedBox(height: 16),

            // Search String
            TextFormField(
              controller: _searchStringController,
              decoration: const InputDecoration(
                labelText: 'Search String',
                hintText: 'e.g., 1 oz Gold Cast Bar',
                border: OutlineInputBorder(),
                helperText: 'Text to search for in scraper results',
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Search string is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Search URL
            TextFormField(
              controller: _searchUrlController,
              decoration: InputDecoration(
                labelText: 'Search URL (Optional)',
                hintText: 'e.g., https://example.com/live-prices',
                border: const OutlineInputBorder(),
                helperText: _searchUrlController.text.trim().isEmpty
                    ? '⚠️ Warning: Search URL is recommended'
                    : null,
                helperStyle: TextStyle(
                  color: _searchUrlController.text.trim().isEmpty
                      ? AppColors.warning
                      : null,
                ),
              ),
              keyboardType: TextInputType.url,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            // Is Active Toggle
            Card(
              child: SwitchListTile(
                title: const Text('Active'),
                subtitle: Text(
                  _isActive
                      ? 'Setting is active and will be used'
                      : 'Setting is inactive and will be ignored',
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
              onPressed: _isSaving ? null : _saveSetting,
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
                  : Text(_isEditMode ? 'Update Setting' : 'Create Setting'),
            ),
          ],
        ),
      ),
    );
  }
}
