import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/features/metadata/data/models/metadata_models.dart';
import 'package:metal_tracker/features/metadata/presentation/providers/metadata_providers.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_prefs_providers.dart';

class UserMetaltypePrefsSection extends ConsumerWidget {
  const UserMetaltypePrefsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs              = Theme.of(context).colorScheme;
    final tt              = Theme.of(context).textTheme;
    final metalTypesAsync = ref.watch(metalTypesProvider);
    final prefsAsync      = ref.watch(userMetaltypePrefsNotifierProvider);

    if (metalTypesAsync.isLoading || prefsAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (metalTypesAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          'Error loading metal types: ${metalTypesAsync.error}',
          style: TextStyle(color: cs.error, fontSize: 13),
        ),
      );
    }

    final metalTypes  = metalTypesAsync.valueOrNull ?? [];
    final prefs       = prefsAsync.valueOrNull ?? [];
    final selectedIds = prefs.map((p) => p.metalTypeId).toSet();

    if (metalTypes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No metal types configured. Ask an administrator to add them.',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      );
    }

    return Column(
      children: [
        for (final mt in metalTypes)
          SwitchListTile.adaptive(
            title: Text(
              mt.name.isEmpty ? mt.name
                  : mt.name[0].toUpperCase() + mt.name.substring(1),
              style: tt.bodyMedium,
            ),
            value: selectedIds.contains(mt.id),
            onChanged: prefsAsync.isLoading ? null : (enabled) => _toggle(
              ref, mt, enabled, selectedIds),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            dense: true,
          ),
        if (selectedIds.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'No metals selected — all metal data is shown.',
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
      ],
    );
  }

  Future<void> _toggle(
    WidgetRef ref, MetalTypeRecord mt, bool enabled, Set<String> currentIds,
  ) async {
    final updated = enabled
        ? {...currentIds, mt.id}
        : currentIds.difference({mt.id});
    await ref.read(userMetaltypePrefsNotifierProvider.notifier).set(updated.toList());
  }
}
