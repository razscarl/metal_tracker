import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/features/retailers/data/models/retailers_model.dart';

/// Bottom sheet shown before any admin-triggered scrape.
/// Loads retailers that have active settings for the given [scraperType],
/// presents all pre-selected, and returns the confirmed selection.
/// Returns null if the admin cancels.
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
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ScraperSelectorSheet(
        scraperType: scraperType,
        title: title,
      ),
    );
  }

  @override
  ConsumerState<ScraperSelectorSheet> createState() =>
      _ScraperSelectorSheetState();
}

class _ScraperSelectorSheetState extends ConsumerState<ScraperSelectorSheet> {
  List<Retailer> _retailers = [];
  Set<String> _selected = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(retailerRepositoryProvider);
      final all = await repo.getRetailers(includeInactive: false);

      final withSettings = <Retailer>[];
      for (final r in all) {
        final settings =
            await repo.getScraperSettingsForType(r.id, widget.scraperType);
        if (settings.any((s) => s.isActive)) withSettings.add(r);
      }

      if (mounted) {
        setState(() {
          _retailers = withSettings;
          _selected = withSettings.map((r) => r.id).toSet();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'All retailers are pre-selected. Deselect any you want to skip.',
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primaryGold, strokeWidth: 2),
                ),
              )
            else if (_retailers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No retailers configured for this scrape type.',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              )
            else
              for (final r in _retailers)
                CheckboxListTile(
                  title: Text(
                    r.name,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14),
                  ),
                  subtitle: r.retailerAbbr != null
                      ? Text(r.retailerAbbr!,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12))
                      : null,
                  value: _selected.contains(r.id),
                  onChanged: (_) => setState(() {
                    if (_selected.contains(r.id)) {
                      _selected.remove(r.id);
                    } else {
                      _selected.add(r.id);
                    }
                  }),
                  activeColor: AppColors.primaryGold,
                  checkColor: Colors.black,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, null),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () => Navigator.pop(context, _selected.toList()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.white12,
                    ),
                    child: const Text(
                      'Scrape',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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
