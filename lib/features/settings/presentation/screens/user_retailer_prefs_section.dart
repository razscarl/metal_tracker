import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/features/retailers/data/models/retailers_model.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_prefs_providers.dart';

class UserRetailerPrefsSection extends ConsumerStatefulWidget {
  const UserRetailerPrefsSection({super.key});

  @override
  ConsumerState<UserRetailerPrefsSection> createState() =>
      _UserRetailerPrefsSectionState();
}

class _UserRetailerPrefsSectionState
    extends ConsumerState<UserRetailerPrefsSection> {
  List<Retailer> _retailers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRetailers();
  }

  Future<void> _loadRetailers() async {
    try {
      final retailers =
          await ref.read(retailerRepositoryProvider).getRetailers();
      retailers.sort((a, b) => a.name.compareTo(b.name));
      if (mounted) setState(() { _retailers = retailers; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(Retailer r, bool enabled, Set<String> currentIds) async {
    final updated = enabled
        ? {...currentIds, r.id}
        : currentIds.difference({r.id});
    await ref.read(userRetailerPrefsNotifierProvider.notifier).set(updated.toList());
  }

  @override
  Widget build(BuildContext context) {
    final cs         = Theme.of(context).colorScheme;
    final tt         = Theme.of(context).textTheme;
    final prefsAsync = ref.watch(userRetailerPrefsNotifierProvider);

    if (_loading || prefsAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_retailers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No retailers found. Ask an administrator to configure them.',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      );
    }

    final prefs       = prefsAsync.valueOrNull ?? [];
    final selectedIds = prefs.map((p) => p.retailerId).toSet();
    final saving      = prefsAsync.isLoading;

    return Column(
      children: [
        for (final r in _retailers)
          SwitchListTile.adaptive(
            title: Text(r.name, style: tt.bodyMedium),
            subtitle: r.retailerAbbr != null
                ? Text(r.retailerAbbr!,
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant))
                : null,
            value: selectedIds.contains(r.id),
            onChanged: saving ? null : (v) => _toggle(r, v, selectedIds),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            dense: true,
          ),
        if (selectedIds.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'No retailers selected — data from all retailers is shown.',
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}
