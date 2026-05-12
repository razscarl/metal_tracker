import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/features/metadata/data/models/metadata_models.dart';
import 'package:metal_tracker/features/metadata/presentation/providers/metadata_providers.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_prefs_providers.dart';

/// Embedded settings section for metal form preferences.
/// Uses [metalFormsProvider] for available options and
/// [userMetalformPrefsNotifierProvider] for the user's selections.
/// Saves immediately on each toggle — no Save button required.
class UserMetalformPrefsSection extends ConsumerWidget {
  const UserMetalformPrefsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metalFormsAsync = ref.watch(metalFormsProvider);
    final prefsAsync = ref.watch(userMetalformPrefsNotifierProvider);

    if (metalFormsAsync.isLoading || prefsAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(
              color: AppColors.primaryGold, strokeWidth: 2),
        ),
      );
    }

    if (metalFormsAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error loading metal forms: ${metalFormsAsync.error}',
            style: const TextStyle(color: AppColors.error, fontSize: 13)),
      );
    }

    final metalForms = metalFormsAsync.valueOrNull ?? [];
    final prefs = prefsAsync.valueOrNull ?? [];
    final selectedIds = prefs.map((p) => p.metalFormId).toSet();

    if (metalForms.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No metal forms configured. Ask an administrator to add them.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    }

    return Column(
      children: [
        for (final mf in metalForms)
          _FormToggleRow(
            metalForm: mf,
            selected: selectedIds.contains(mf.id),
            onChanged: (enabled) => _toggle(ref, mf, enabled, selectedIds),
            saving: prefsAsync.isLoading,
          ),
        if (selectedIds.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'No forms selected — all form types are shown.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ),
      ],
    );
  }

  Future<void> _toggle(
    WidgetRef ref,
    MetalFormRecord mf,
    bool enabled,
    Set<String> currentIds,
  ) async {
    final updated = enabled
        ? {...currentIds, mf.id}
        : currentIds.difference({mf.id});
    await ref
        .read(userMetalformPrefsNotifierProvider.notifier)
        .set(updated.toList());
  }
}

class _FormToggleRow extends StatelessWidget {
  final MetalFormRecord metalForm;
  final bool selected;
  final ValueChanged<bool> onChanged;
  final bool saving;

  const _FormToggleRow({
    required this.metalForm,
    required this.selected,
    required this.onChanged,
    required this.saving,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(
        metalForm.name,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      ),
      value: selected,
      onChanged: saving ? null : onChanged,
      activeColor: AppColors.primaryGold,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      dense: true,
    );
  }
}
