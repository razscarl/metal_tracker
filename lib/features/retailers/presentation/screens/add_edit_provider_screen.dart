// lib/features/retailers/presentation/screens/add_edit_provider_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/features/spot_prices/data/models/global_spot_provider_model.dart';

class AddEditProviderScreen extends ConsumerStatefulWidget {
  final GlobalSpotProvider? provider; // null = add mode

  const AddEditProviderScreen({super.key, this.provider});

  @override
  ConsumerState<AddEditProviderScreen> createState() =>
      _AddEditProviderScreenState();
}

class _AddEditProviderScreenState
    extends ConsumerState<AddEditProviderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _keyController;
  late TextEditingController _urlController;
  late TextEditingController _descController;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.provider?.name ?? '');
    _keyController =
        TextEditingController(text: widget.provider?.providerKey ?? '');
    _urlController =
        TextEditingController(text: widget.provider?.baseUrl ?? '');
    _descController =
        TextEditingController(text: widget.provider?.description ?? '');
    _isActive = widget.provider?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _keyController.dispose();
    _urlController.dispose();
    _descController.dispose();
    super.dispose();
  }

  bool get _isEditMode => widget.provider != null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(globalSpotProvidersRepositoryProvider);
      if (_isEditMode) {
        final updated = GlobalSpotProvider(
          id: widget.provider!.id,
          name: _nameController.text.trim(),
          providerKey: widget.provider!.providerKey,
          baseUrl: _urlController.text.trim().isEmpty
              ? null
              : _urlController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          isActive: _isActive,
          createdAt: widget.provider!.createdAt,
        );
        await repo.updateProvider(updated);
      } else {
        final key = _keyController.text
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'\s+'), '_');
        await repo.createProvider(
          name: _nameController.text.trim(),
          providerKey: key,
          baseUrl: _urlController.text.trim().isEmpty
              ? null
              : _urlController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          isActive: _isActive,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isEditMode ? 'Edit Provider' : 'Add Provider',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name *',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            if (!_isEditMode) ...[
              TextFormField(
                controller: _keyController,
                decoration: const InputDecoration(
                  labelText: 'Provider Key *',
                  helperText: 'Unique identifier (e.g. metals_dev)',
                  prefixIcon: Icon(Icons.key_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Base URL (optional)',
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              title: const Text('Active',
                  style: TextStyle(color: AppColors.textPrimary)),
              activeColor: AppColors.gainGreen,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.textDark),
                    )
                  : Text(_isEditMode ? 'Save Changes' : 'Add Provider'),
            ),
          ],
        ),
      ),
    );
  }
}
