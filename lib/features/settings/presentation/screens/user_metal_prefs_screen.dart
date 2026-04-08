import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_prefs_providers.dart';

/// User preference screen for selecting which metal types to track.
///
/// Set [embedded] = true when shown inside settings_screen (no AppScaffold).
class UserMetalPrefsScreen extends ConsumerStatefulWidget {
  final bool embedded;
  const UserMetalPrefsScreen({super.key, this.embedded = false});

  @override
  ConsumerState<UserMetalPrefsScreen> createState() => _UserMetalPrefsScreenState();
}

class _UserMetalPrefsScreenState extends ConsumerState<UserMetalPrefsScreen> {
  static const _allMetals = [
    (key: 'gold',     label: 'Gold'),
    (key: 'silver',   label: 'Silver'),
    (key: 'platinum', label: 'Platinum'),
  ];

  Set<String> _selected = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final metals = await ref.read(userMetalTypesNotifierProvider.future);
    if (mounted) {
      setState(() {
        _selected = metals.toSet();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(userMetalTypesNotifierProvider.notifier)
          .set(_selected.toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Metal preferences saved'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error saving: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();
    if (widget.embedded) return body;
    return AppScaffold(title: 'Metal Preferences', body: body);
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
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
                    () => _selected = _allMetals.map((m) => m.key).toSet()),
                child: const Text('Select All',
                    style: TextStyle(color: AppColors.primaryGold, fontSize: 13)),
              ),
              TextButton(
                onPressed: () => setState(() => _selected.clear()),
                child: const Text('Clear All',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
            ],
          ),
        ),
        ...(_allMetals.map((m) => CheckboxListTile(
              value: _selected.contains(m.key),
              onChanged: (_) => setState(() {
                if (_selected.contains(m.key)) {
                  _selected.remove(m.key);
                } else {
                  _selected.add(m.key);
                }
              }),
              title: Text(m.label,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
              activeColor: AppColors.primaryGold,
              checkColor: AppColors.textDark,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              dense: true,
            ))),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18, width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textDark))
                : const Text('Save'),
          ),
        ),
      ],
    );
  }
}
