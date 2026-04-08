import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/features/settings/data/models/user_prefs_models.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_prefs_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// User preference screen for configuring Global Spot Price API providers.
/// Supports multiple providers (one row per user+provider).
///
/// Set [embedded] = true when shown inside settings_screen (no AppScaffold).
/// Set [embedded] = false (default) when opened as a standalone screen.
class GlobalSpotPrefScreen extends ConsumerWidget {
  final bool embedded;

  const GlobalSpotPrefScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final body = _buildBody(context, ref);
    if (embedded) return body;
    return AppScaffold(title: 'Global Spot Provider Settings', body: body);
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(userGlobalSpotPrefNotifierProvider);
    final providersAsync = ref.watch(globalSpotProvidersProvider());

    if (prefsAsync.isLoading || providersAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
            child: CircularProgressIndicator(color: AppColors.primaryGold)),
      );
    }

    if (providersAsync.hasError) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error loading providers: ${providersAsync.error}',
            style: const TextStyle(color: AppColors.error, fontSize: 13)),
      );
    }

    final configured = prefsAsync.valueOrNull ?? [];
    final allProviders = providersAsync.valueOrNull ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Info banner
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: const Text(
            'Global spot price captures are shared across the platform and '
            'visible to all users. You need an API key from a supported provider.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 8),

        if (configured.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              'No providers configured. Add one below.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          )
        else
          ...configured.map((pref) => _ProviderRow(
                pref: pref,
                providerName: allProviders
                    .firstWhere(
                      (p) => p.providerKey == pref.providerKey,
                      orElse: () => allProviders.isEmpty
                          ? throw StateError('no providers')
                          : allProviders.first,
                    )
                    .name,
              )),

        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Provider'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primaryGold),
              foregroundColor: AppColors.primaryGold,
            ),
            onPressed: allProviders.isEmpty
                ? null
                : () => _showAddSheet(context, ref, configured, allProviders),
          ),
        ),
      ],
    );
  }

  void _showAddSheet(
    BuildContext context,
    WidgetRef ref,
    List<UserGlobalSpotPref> existing,
    List<dynamic> allProviders,
  ) {
    // Exclude providers already configured
    final configuredKeys = existing.map((p) => p.providerKey).toSet();
    final available =
        allProviders.where((p) => !configuredKeys.contains(p.providerKey)).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All available providers are already configured.'),
          backgroundColor: AppColors.backgroundCard,
        ),
      );
      return;
    }

    String? selectedKey = available.first.providerKey as String;
    final apiKeyController = TextEditingController();
    bool saving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add Provider',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedKey,
                decoration: const InputDecoration(
                  labelText: 'Provider',
                  prefixIcon: Icon(Icons.cloud_outlined),
                ),
                dropdownColor: AppColors.backgroundCard,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14),
                items: available
                    .map((p) => DropdownMenuItem<String>(
                          value: p.providerKey as String,
                          child: Text(p.name as String),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => selectedKey = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  prefixIcon: Icon(Icons.vpn_key_outlined),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: (saving ||
                        selectedKey == null ||
                        apiKeyController.text.trim().isEmpty)
                    ? null
                    : () async {
                        setState(() => saving = true);
                        try {
                          final userId = Supabase
                              .instance.client.auth.currentUser!.id;
                          await ref
                              .read(userGlobalSpotPrefNotifierProvider.notifier)
                              .upsert(UserGlobalSpotPref(
                                userId: userId,
                                providerKey: selectedKey!,
                                apiKey: apiKeyController.text.trim(),
                              ));
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Provider added'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        } finally {
                          if (ctx.mounted) setState(() => saving = false);
                        }
                      },
                child: saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.textDark),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Provider Row ───────────────────────────────────────────────────────────────

class _ProviderRow extends ConsumerStatefulWidget {
  final UserGlobalSpotPref pref;
  final String providerName;

  const _ProviderRow({required this.pref, required this.providerName});

  @override
  ConsumerState<_ProviderRow> createState() => _ProviderRowState();
}

class _ProviderRowState extends ConsumerState<_ProviderRow> {
  bool _deleting = false;
  bool _toggling = false;

  String _maskKey(String key) {
    if (key.length <= 8) return '••••••••';
    return '${key.substring(0, 4)}${'•' * (key.length - 8)}${key.substring(key.length - 4)}';
  }

  void _showEditSheet(BuildContext context) {
    final apiKeyController = TextEditingController(text: widget.pref.apiKey);
    bool saving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit ${widget.providerName}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  prefixIcon: Icon(Icons.vpn_key_outlined),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: (saving || apiKeyController.text.trim().isEmpty)
                    ? null
                    : () async {
                        setState(() => saving = true);
                        try {
                          await ref
                              .read(userGlobalSpotPrefNotifierProvider.notifier)
                              .upsert(UserGlobalSpotPref(
                                id: widget.pref.id,
                                userId: widget.pref.userId,
                                providerKey: widget.pref.providerKey,
                                apiKey: apiKeyController.text.trim(),
                              ));
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('API key updated'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        } finally {
                          if (ctx.mounted) setState(() => saving = false);
                        }
                      },
                child: saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.textDark),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleActive() async {
    setState(() => _toggling = true);
    try {
      await ref.read(userGlobalSpotPrefNotifierProvider.notifier).upsert(
            UserGlobalSpotPref(
              id: widget.pref.id,
              userId: widget.pref.userId,
              providerKey: widget.pref.providerKey,
              apiKey: widget.pref.apiKey,
              isActive: !widget.pref.isActive,
            ),
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.providerName,
                  style: TextStyle(
                    color: widget.pref.isActive
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _maskKey(widget.pref.apiKey),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          if (_deleting || _toggling)
            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primaryGold),
            )
          else ...[
            InkWell(
              onTap: _toggleActive,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  widget.pref.isActive
                      ? Icons.toggle_on_outlined
                      : Icons.toggle_off_outlined,
                  size: 18,
                  color: widget.pref.isActive
                      ? AppColors.primaryGold
                      : AppColors.textSecondary,
                ),
              ),
            ),
            InkWell(
              onTap: () => _showEditSheet(context),
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.textSecondary),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.backgroundCard,
                    title: const Text('Remove Provider',
                        style: TextStyle(color: AppColors.textPrimary)),
                    content: Text(
                      'Remove ${widget.providerName}?',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel',
                            style:
                                TextStyle(color: AppColors.textSecondary)),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true || !mounted) return;
                setState(() => _deleting = true);
                try {
                  await ref
                      .read(userGlobalSpotPrefNotifierProvider.notifier)
                      .delete(widget.pref.id!);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Provider removed'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _deleting = false);
                }
              },
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.delete_outline,
                    size: 18, color: AppColors.error),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
