// lib/features/spot_prices/presentation/screens/add_edit_api_setting_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/features/spot_prices/data/models/global_spot_price_api_setting_model.dart';
import 'package:metal_tracker/features/spot_prices/data/services/base_global_spot_price_service.dart';
import 'package:metal_tracker/features/spot_prices/data/services/global_spot_price_service_factory.dart';
import 'package:metal_tracker/features/spot_prices/presentation/providers/spot_prices_providers.dart';

class AddEditApiSettingScreen extends ConsumerStatefulWidget {
  final GlobalSpotPriceApiSetting? setting;

  const AddEditApiSettingScreen({super.key, this.setting});

  @override
  ConsumerState<AddEditApiSettingScreen> createState() =>
      _AddEditApiSettingScreenState();
}

class _AddEditApiSettingScreenState
    extends ConsumerState<AddEditApiSettingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _apiKeyController;
  late String _selectedServiceType;
  late Map<String, TextEditingController> _configControllers;
  late bool _isActive;
  bool _isSaving = false;
  bool _obscureKey = true;

  bool get _isEditMode => widget.setting != null;

  BaseGlobalSpotPriceService get _selectedService =>
      GlobalSpotPriceServiceFactory.forType(_selectedServiceType);

  @override
  void initState() {
    super.initState();
    _apiKeyController =
        TextEditingController(text: widget.setting?.apiKey ?? '');
    _selectedServiceType = widget.setting?.serviceType ??
        GlobalSpotPriceServiceFactory.all.first.serviceType;
    _isActive = widget.setting?.isActive ?? true;
    _configControllers = _buildConfigControllers(
      _selectedService,
      widget.setting?.config ?? {},
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    for (final c in _configControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, TextEditingController> _buildConfigControllers(
    BaseGlobalSpotPriceService service,
    Map<String, String> existingConfig,
  ) {
    return {
      for (final field in service.configSchema)
        field.key: TextEditingController(
          text: existingConfig[field.key] ?? field.defaultValue ?? '',
        ),
    };
  }

  void _onServiceChanged(String? newType) {
    if (newType == null || newType == _selectedServiceType) return;
    for (final c in _configControllers.values) {
      c.dispose();
    }
    setState(() {
      _selectedServiceType = newType;
      _configControllers = _buildConfigControllers(
        GlobalSpotPriceServiceFactory.forType(newType),
        {},
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final config = {
        for (final entry in _configControllers.entries)
          entry.key: entry.value.text.trim().toUpperCase(),
      };

      final notifier = ref.read(apiSettingsNotifierProvider.notifier);
      if (_isEditMode) {
        await notifier.updateSetting(
          id: widget.setting!.id,
          apiKey: _apiKeyController.text.trim(),
          serviceType: _selectedServiceType,
          config: config,
          isActive: _isActive,
        );
      } else {
        await notifier.create(
          apiKey: _apiKeyController.text.trim(),
          serviceType: _selectedServiceType,
          config: config,
          isActive: _isActive,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode
                ? 'API setting updated'
                : 'API setting created'),
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = GlobalSpotPriceServiceFactory.all;
    final service = _selectedService;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit API Setting' : 'Add API Setting'),
        backgroundColor: AppColors.backgroundCard,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Service dropdown
            DropdownButtonFormField<String>(
              key: ValueKey(_selectedServiceType),
              initialValue: _selectedServiceType,
              decoration: const InputDecoration(
                labelText: 'API Service',
                border: OutlineInputBorder(),
              ),
              dropdownColor: AppColors.backgroundCard,
              items: services
                  .map((s) => DropdownMenuItem(
                        value: s.serviceType,
                        child: Text(s.displayName),
                      ))
                  .toList(),
              onChanged: _onServiceChanged,
            ),
            const SizedBox(height: 16),

            // Info banner (per-service text)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.primaryGold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.primaryGold, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      service.infoBannerText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                ],
              ),
            ),

            // API Key (always shown, always masked)
            TextFormField(
              controller: _apiKeyController,
              obscureText: _obscureKey,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: 'Enter your API key',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscureKey ? Icons.visibility : Icons.visibility_off),
                  onPressed: () =>
                      setState(() => _obscureKey = !_obscureKey),
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'API key is required' : null,
            ),
            const SizedBox(height: 16),

            // Dynamic config fields from service schema
            ...service.configSchema.map((field) {
              final controller = _configControllers[field.key]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: field.label,
                    hintText: field.hint,
                    border: const OutlineInputBorder(),
                  ),
                  validator: field.isRequired
                      ? (v) => (v == null || v.trim().isEmpty)
                          ? '${field.label} is required'
                          : null
                      : null,
                ),
              );
            }),

            // Active toggle
            Card(
              color: AppColors.backgroundCard,
              child: SwitchListTile(
                title: const Text('Active'),
                subtitle: Text(
                  _isActive
                      ? 'This setting will be used for fetching'
                      : 'This setting is inactive',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                activeTrackColor: AppColors.success,
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
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
