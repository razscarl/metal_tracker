// lib/features/retailers/presentation/screens/add_edit_scraper_setting_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/constants/scraper_constants.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/features/retailers/data/models/retailer_scraper_setting_model.dart';
import 'package:metal_tracker/features/retailers/presentation/providers/retailers_providers.dart';

class AddEditScraperSettingScreen extends ConsumerStatefulWidget {
  final String retailerId;
  final RetailerScraperSetting? setting;
  /// Pre-selects and locks the scraper type (used when adding from a section).
  final String? initialScraperType;

  const AddEditScraperSettingScreen({
    super.key,
    required this.retailerId,
    this.setting,
    this.initialScraperType,
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

  late String? _selectedScraperType;
  String? _selectedMetalType;
  late bool _isActive;
  bool _isSaving = false;

  bool get _isEditMode => widget.setting != null;

  /// True when the scraper type is locked (edit mode, or pre-set on add).
  bool get _scraperTypeLocked =>
      _isEditMode || widget.initialScraperType != null;

  /// For local_spot scrapers the search string is the metal type key — derived
  /// automatically and shown read-only.
  bool get _searchStringAutoFilled =>
      _selectedScraperType == ScraperType.localSpot &&
      _selectedMetalType != null;

  void _onMetalTypeChanged(String? value) {
    setState(() {
      _selectedMetalType = value;
      // Auto-fill searchString with metal type for local_spot scrapers.
      if (_selectedScraperType == ScraperType.localSpot && value != null) {
        _searchStringController.text = value;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _searchStringController =
        TextEditingController(text: widget.setting?.searchString ?? '');
    _searchUrlController =
        TextEditingController(text: widget.setting?.searchUrl ?? '');
    _selectedScraperType =
        widget.setting?.scraperType ?? widget.initialScraperType;
    _selectedMetalType = widget.setting?.metalType?.toLowerCase();
    _isActive = widget.setting?.isActive ?? true;
  }

  @override
  void dispose() {
    _searchStringController.dispose();
    _searchUrlController.dispose();
    super.dispose();
  }

  String _scraperTypeLabel(String type) {
    switch (type) {
      case ScraperType.livePrice:
        return 'Live Price';
      case ScraperType.localSpot:
        return 'Local Spot';
      case ScraperType.productListing:
        return 'Product Listing';
      default:
        return type;
    }
  }

  Future<void> _saveSetting() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(retailerRepositoryProvider);

      final isProductListing =
          _selectedScraperType == ScraperType.productListing;

      if (_isEditMode) {
        await repository.updateScraperSetting(
          settingId: widget.setting!.id,
          searchString: isProductListing
              ? null // not updated for product_listing
              : _searchStringController.text.trim(),
          isActive: _isActive,
        );
      } else {
        await repository.createScraperSetting(
          retailerId: widget.retailerId,
          scraperType: _selectedScraperType!,
          metalType: _selectedMetalType,
          searchString: isProductListing
              ? (_selectedMetalType ?? 'all') // auto-generated key
              : _searchStringController.text.trim(),
          searchUrl: _searchUrlController.text.trim().isEmpty
              ? null
              : _searchUrlController.text.trim(),
          isActive: _isActive,
        );
      }

      ref.invalidate(retailerScraperSettingsProvider(widget.retailerId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode
                ? 'Setting updated'
                : 'Setting created'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('23505')
            ? 'A setting for this retailer / type / metal already exists.'
            : 'Error: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
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
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Setting' : 'Add Setting'),
        backgroundColor: AppColors.backgroundCard,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Scraper Type ───────────────────────────────────────────
            DropdownButtonFormField<String>(
              initialValue: _selectedScraperType,
              decoration: const InputDecoration(
                labelText: 'Scraper Type',
                border: OutlineInputBorder(),
              ),
              items: [
                ScraperType.livePrice,
                ScraperType.localSpot,
                ScraperType.productListing,
              ].map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(_scraperTypeLabel(t)),
                  )).toList(),
              onChanged: _scraperTypeLocked
                  ? null
                  : (v) => setState(() => _selectedScraperType = v),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // ── Metal Type ─────────────────────────────────────────────
            DropdownButtonFormField<String?>(
              initialValue: _selectedMetalType,
              decoration: InputDecoration(
                labelText: 'Metal Type',
                border: const OutlineInputBorder(),
                helperText: _selectedScraperType == ScraperType.productListing
                    ? 'None = all metals on one page (e.g. IMP shop)'
                    : 'Leave empty for non-metal-specific scrapers',
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('None')),
                DropdownMenuItem(value: 'gold', child: Text('Gold')),
                DropdownMenuItem(value: 'silver', child: Text('Silver')),
                DropdownMenuItem(value: 'platinum', child: Text('Platinum')),
              ],
              onChanged: _isEditMode ? null : _onMetalTypeChanged,
            ),
            const SizedBox(height: 16),

            // ── Search String (hidden for product_listing) ─────────────
            if (_selectedScraperType != ScraperType.productListing) ...[
              TextFormField(
                controller: _searchStringController,
                decoration: InputDecoration(
                  labelText: 'Search String',
                  border: const OutlineInputBorder(),
                  helperText: _searchStringAutoFilled
                      ? 'Auto-filled — edit if needed (e.g. "GOLD PRICE" for IMP)'
                      : _searchStringHint,
                ),
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Search string is required'
                    : null,
              ),
              const SizedBox(height: 16),
            ],

            // ── Search URL ─────────────────────────────────────────────
            TextFormField(
              controller: _searchUrlController,
              decoration: InputDecoration(
                labelText: _selectedScraperType == ScraperType.productListing
                    ? 'Product URL'
                    : 'Search URL (Optional)',
                hintText: _selectedScraperType == ScraperType.productListing
                    ? 'e.g., https://example.com/buy/gold/'
                    : 'e.g., https://example.com/live-prices',
                border: const OutlineInputBorder(),
                helperText: _selectedScraperType == ScraperType.productListing
                    ? (_selectedMetalType == null
                        ? 'URL of the page containing all metals (e.g. /shop/)'
                        : 'Direct URL for ${_selectedMetalType![0].toUpperCase()}${_selectedMetalType!.substring(1)} products')
                    : _searchUrlController.text.trim().isEmpty
                        ? 'Leave blank to use the retailer base URL'
                        : null,
              ),
              keyboardType: TextInputType.url,
              onChanged: (_) => setState(() {}),
              validator: _selectedScraperType == ScraperType.productListing
                  ? (v) => (v == null || v.trim().isEmpty)
                      ? 'Shop URL is required'
                      : null
                  : null,
            ),
            const SizedBox(height: 24),

            // ── Active toggle ──────────────────────────────────────────
            Card(
              child: SwitchListTile(
                title: const Text('Active'),
                subtitle: Text(_isActive
                    ? 'Will be used when scraping'
                    : 'Will be skipped when scraping'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                activeTrackColor: AppColors.success,
              ),
            ),
            const SizedBox(height: 32),

            // ── Save button ────────────────────────────────────────────
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
                  : Text(_isEditMode ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  String? get _searchStringHint {
    switch (_selectedScraperType) {
      case ScraperType.livePrice:
        return 'e.g., 1 oz Gold Cast Bar (table row text)';
      case ScraperType.localSpot:
        return 'e.g., gold-price-tracker (CSS class) or GOLD PRICE (text)';
      default:
        return 'Text or selector used to find the price';
    }
  }
}
