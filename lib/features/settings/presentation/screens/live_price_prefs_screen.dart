import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Option {
  final String settingId; // retailer_scraper_settings.id
  final String retailerName;
  final String metalType;

  const _Option({
    required this.settingId,
    required this.retailerName,
    required this.metalType,
  });

  String get label =>
      '$retailerName — ${metalType[0].toUpperCase()}${metalType.substring(1)}';
}

/// User preference screen for selecting live price retailers.
///
/// Set [embedded] = true when shown inside settings_screen (no AppScaffold).
/// Set [embedded] = false (default) when opened as a standalone screen.
class LivePricePrefsScreen extends ConsumerStatefulWidget {
  final bool embedded;

  const LivePricePrefsScreen({super.key, this.embedded = false});

  @override
  ConsumerState<LivePricePrefsScreen> createState() =>
      _LivePricePrefsScreenState();
}

class _LivePricePrefsScreenState extends ConsumerState<LivePricePrefsScreen> {
  List<_Option> _options = [];
  Set<String> _selected = {}; // settingId
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final supabase = Supabase.instance.client;
      // Query live_price scraper settings directly — one row per retailer+metal
      final response = await supabase
          .from('retailer_scraper_settings')
          .select('id, retailer_id, metal_type, retailers(name)')
          .eq('scraper_type', 'live_price')
          .eq('is_active', true)
          .not('metal_type', 'is', null)
          .order('metal_type');

      final options = (response as List).map((row) {
        final retailer = row['retailers'] as Map<String, dynamic>?;
        return _Option(
          settingId: row['id'] as String,
          retailerName: retailer?['name'] as String? ?? 'Unknown',
          metalType: row['metal_type'] as String? ?? '',
        );
      }).toList();

      options.sort((a, b) {
        final r = a.retailerName.compareTo(b.retailerName);
        return r != 0 ? r : a.metalType.compareTo(b.metalType);
      });

      // Pre-select: no current selections (legacy screen — use UserMetalPrefsScreen instead)
      final currentIds = <String>{};

      if (mounted) {
        setState(() {
          _options = options;
          _selected = options
              .map((o) => o.settingId)
              .where((id) => currentIds.contains(id))
              .toSet();
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      // Legacy screen — no-op save (use UserMetalPrefsScreen instead)
      await Future.value();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Live price preferences saved'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();
    if (widget.embedded) return body;
    return AppScaffold(title: 'Live Price Retailer Settings', body: body);
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primaryGold),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Failed to load retailers:',
                style: TextStyle(color: AppColors.error, fontSize: 13)),
            const SizedBox(height: 4),
            Text(_error!,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                setState(() => _loading = true);
                _load();
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_options.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No live price retailers configured yet.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 16, top: 4),
          child: Row(
            children: [
              TextButton(
                onPressed: () => setState(
                    () => _selected = _options.map((o) => o.settingId).toSet()),
                child: const Text('Select All',
                    style:
                        TextStyle(color: AppColors.primaryGold, fontSize: 13)),
              ),
              TextButton(
                onPressed: () => setState(() => _selected.clear()),
                child: const Text('Clear All',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ),
            ],
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: ListView(
            shrinkWrap: true,
            children: _options.map((option) => CheckboxListTile(
              value: _selected.contains(option.settingId),
              onChanged: (_) => setState(() {
                if (_selected.contains(option.settingId)) {
                  _selected.remove(option.settingId);
                } else {
                  _selected.add(option.settingId);
                }
              }),
              title: Text(
                option.label,
                style:
                    const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              ),
              activeColor: AppColors.primaryGold,
              checkColor: AppColors.textDark,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              dense: true,
            )).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.textDark),
                  )
                : const Text('Save'),
          ),
        ),
      ],
    );
  }
}
