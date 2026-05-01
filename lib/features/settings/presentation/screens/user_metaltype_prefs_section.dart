import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/features/metadata/data/models/metadata_models.dart';
import 'package:metal_tracker/features/metadata/presentation/providers/metadata_providers.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_prefs_providers.dart';

/// Embedded settings section for metal type preferences.
/// Uses [metalTypesProvider] for available options and
/// [userMetaltypePrefsNotifierProvider] for the user's selections.
/// Saves immediately on each toggle — no Save button required.
class UserMetaltypePrefsSection extends ConsumerWidget {
  const UserMetaltypePrefsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metalTypesAsync = ref.watch(metalTypesProvider);
    final prefsAsync = ref.watch(userMetaltypePrefsNotifierProvider);

    if (metalTypesAsync.isLoading || prefsAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(
              color: AppColors.primaryGold, strokeWidth: 2),
        ),
      );
    }

    if (metalTypesAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error loading metal types: ${metalTypesAsync.error}',
            style: const TextStyle(color: AppColors.error, fontSize: 13)),
      );
    }

    final metalTypes = metalTypesAsync.valueOrNull ?? [];
    final prefs = prefsAsync.valueOrNull ?? [];
    final selectedIds = prefs.map((p) => p.metalTypeId).toSet();

    if (metalTypes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No metal types configured. Ask an administrator to add them.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    }

    return Column(
      children: [
        for (final mt in metalTypes)
          _MetalToggleRow(
            metalType: mt,
            selected: selectedIds.contains(mt.id),
            onChanged: (enabled) => _toggle(ref, mt, enabled, selectedIds),
            saving: prefsAsync.isLoading,
          ),
        if (selectedIds.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'No metals selected — all metal data is shown.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ),
      ],
    );
  }

  Future<void> _toggle(
    WidgetRef ref,
    MetalTypeRecord mt,
    bool enabled,
    Set<String> currentIds,
  ) async {
    final updated = enabled
        ? {...currentIds, mt.id}
        : currentIds.difference({mt.id});
    await ref
        .read(userMetaltypePrefsNotifierProvider.notifier)
        .set(updated.toList());
  }
}

class _MetalToggleRow extends StatelessWidget {
  final MetalTypeRecord metalType;
  final bool selected;
  final ValueChanged<bool> onChanged;
  final bool saving;

  const _MetalToggleRow({
    required this.metalType,
    required this.selected,
    required this.onChanged,
    required this.saving,
  });

  String get _displayName {
    final n = metalType.name;
    if (n.isEmpty) return n;
    return n[0].toUpperCase() + n.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(
        _displayName,
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
