import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/features/metadata/data/models/metadata_models.dart';
import 'package:metal_tracker/features/metadata/presentation/providers/metadata_providers.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_prefs_providers.dart';

class UserMetalformPrefsSection extends ConsumerWidget {
  const UserMetalformPrefsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs             = Theme.of(context).colorScheme;
    final tt             = Theme.of(context).textTheme;
    final metalFormsAsync = ref.watch(metalFormsProvider);
    final prefsAsync     = ref.watch(userMetalformPrefsNotifierProvider);

    if (metalFormsAsync.isLoading || prefsAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (metalFormsAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          'Error loading metal forms: ${metalFormsAsync.error}',
          style: TextStyle(color: cs.error, fontSize: 13),
        ),
      );
    }

    final metalForms  = metalFormsAsync.valueOrNull ?? [];
    final prefs       = prefsAsync.valueOrNull ?? [];
    final selectedIds = prefs.map((p) => p.metalFormId).toSet();

    if (metalForms.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No metal forms configured. Ask an administrator to add them.',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      );
    }

    return Column(
      children: [
        for (final mf in metalForms)
          SwitchListTile.adaptive(
            title: Text(mf.name, style: tt.bodyMedium),
            value: selectedIds.contains(mf.id),
            onChanged: prefsAsync.isLoading
                ? null
                : (enabled) => _toggle(ref, mf, enabled, selectedIds),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            dense: true,
          ),
        if (selectedIds.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'No forms selected — all form types are shown.',
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
      ],
    );
  }

  Future<void> _toggle(
    WidgetRef ref, MetalFormRecord mf, bool enabled, Set<String> currentIds,
  ) async {
    final updated = enabled
        ? {...currentIds, mf.id}
        : currentIds.difference({mf.id});
    await ref.read(userMetalformPrefsNotifierProvider.notifier).set(updated.toList());
  }
}
