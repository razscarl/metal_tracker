// lib/core/widgets/scraper_selector_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/features/retailers/data/models/retailers_model.dart';

class ScraperSelectorSheet extends ConsumerStatefulWidget {
  final String scraperType;
  final String title;

  const ScraperSelectorSheet({
    required this.scraperType,
    required this.title,
    super.key,
  });

  static Future<List<String>?> show(
    BuildContext context, {
    required String scraperType,
    required String title,
  }) {
    return showModalBottomSheet<List<String>?>(
      context:            context,
      isScrollControlled: true,
      builder: (_) => ScraperSelectorSheet(
        scraperType: scraperType,
        title:       title,
      ),
    );
  }

  @override
  ConsumerState<ScraperSelectorSheet> createState() =>
      _ScraperSelectorSheetState();
}

class _ScraperSelectorSheetState extends ConsumerState<ScraperSelectorSheet> {
  List<Retailer> _retailers = [];
  Set<String>    _selected  = {};
  bool           _loading   = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(retailerRepositoryProvider);
      final all  = await repo.getRetailers(includeInactive: false);
      final withSettings = <Retailer>[];
      for (final r in all) {
        final settings =
            await repo.getScraperSettingsForType(r.id, widget.scraperType);
        if (settings.any((s) => s.isActive)) withSettings.add(r);
      }
      if (mounted) {
        setState(() {
          _retailers = withSettings;
          _selected  = withSettings.map((r) => r.id).toSet();
          _loading   = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize:      MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width:  40,
                height: 4,
                decoration: BoxDecoration(
                  color:        cs.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(widget.title, style: tt.titleMedium),
            const SizedBox(height: 4),
            Text(
              'All retailers are pre-selected. Deselect any you want to skip.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),

            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child:   Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_retailers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No retailers configured for this scrape type.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              )
            else
              for (final r in _retailers)
                CheckboxListTile(
                  title: Text(r.name),
                  subtitle: r.retailerAbbr != null
                      ? Text(r.retailerAbbr!,
                          style: tt.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant))
                      : null,
                  value:            _selected.contains(r.id),
                  controlAffinity:  ListTileControlAffinity.leading,
                  contentPadding:   EdgeInsets.zero,
                  dense:            true,
                  onChanged: (_) => setState(() {
                    if (_selected.contains(r.id)) {
                      _selected.remove(r.id);
                    } else {
                      _selected.add(r.id);
                    }
                  }),
                ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, null),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () => Navigator.pop(context, _selected.toList()),
                    child: const Text('Scrape'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
