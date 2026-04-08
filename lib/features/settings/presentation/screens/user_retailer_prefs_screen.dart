import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/features/retailers/data/models/retailers_model.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_prefs_providers.dart';

/// User preference screen for selecting which retailers to track.
///
/// Set [embedded] = true when shown inside settings_screen (no AppScaffold).
class UserRetailerPrefsScreen extends ConsumerStatefulWidget {
  final bool embedded;
  const UserRetailerPrefsScreen({super.key, this.embedded = false});

  @override
  ConsumerState<UserRetailerPrefsScreen> createState() =>
      _UserRetailerPrefsScreenState();
}

class _UserRetailerPrefsScreenState
    extends ConsumerState<UserRetailerPrefsScreen> {
  List<Retailer> _allRetailers = [];
  Set<String> _selected = {}; // retailer IDs
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final retailers =
          await ref.read(retailerRepositoryProvider).getRetailers();
      final userRetailers =
          await ref.read(userRetailersNotifierProvider.future);
      final selectedIds =
          userRetailers.map((r) => r.retailerId).toSet();

      if (mounted) {
        setState(() {
          _allRetailers = retailers..sort((a, b) => a.name.compareTo(b.name));
          _selected = selectedIds;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(userRetailersNotifierProvider.notifier)
          .set(_selected.toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Retailer preferences saved'),
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
    return AppScaffold(title: 'Retailer Preferences', body: body);
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
      );
    }

    if (_allRetailers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No retailers found.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
                    () => _selected = _allRetailers.map((r) => r.id).toSet()),
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
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: ListView(
            shrinkWrap: true,
            children: _allRetailers
                .map((r) => CheckboxListTile(
                      value: _selected.contains(r.id),
                      onChanged: (_) => setState(() {
                        if (_selected.contains(r.id)) {
                          _selected.remove(r.id);
                        } else {
                          _selected.add(r.id);
                        }
                      }),
                      title: Text(r.name,
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 14)),
                      activeColor: AppColors.primaryGold,
                      checkColor: AppColors.textDark,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      dense: true,
                    ))
                .toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18, width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.textDark))
                : const Text('Save'),
          ),
        ),
      ],
    );
  }
}
