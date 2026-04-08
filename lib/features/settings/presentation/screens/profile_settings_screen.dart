import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/features/auth/presentation/providers/auth_providers.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_profile_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Profile & account settings screen.
///
/// Set [embedded] = true when shown inside settings_screen (no AppScaffold).
/// Set [embedded] = false (default) when opened as a standalone screen.
class ProfileSettingsScreen extends ConsumerWidget {
  final bool embedded;

  const ProfileSettingsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final body = _buildBody(context, ref);
    if (embedded) return body;
    return AppScaffold(title: 'Profile', body: body);
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAuthUserProvider);
    final profileAsync = ref.watch(userProfileNotifierProvider);
    final profile = profileAsync.valueOrNull;
    final isOAuthUser = user?.isOAuthUser ?? false;
    final timeoutMinutes =
        ref.watch(sessionTimeoutProvider).valueOrNull ?? 15;

    final providerLabel = switch (user?.provider) {
      'google' => 'Google',
      'apple' => 'Apple',
      _ => 'Email & Password',
    };

    return Column(
      children: [
        // ── Metal Tracker profile fields ──────────────────────────────────
        _tile(
          icon: Icons.badge_outlined,
          label: 'User Name',
          value: profile?.username ?? user?.displayName ?? 'Not set',
          onTap: () => _showEditUsernameDialog(
              context, ref, profile?.username ?? user?.displayName),
        ),
        _tile(
          icon: Icons.phone_outlined,
          label: 'Phone',
          value: profile?.phone ?? 'Not set',
          onTap: () =>
              _showEditPhoneDialog(context, ref, profile?.phone),
        ),
        const Divider(color: Colors.white10, height: 1),

        // ── Auth account fields ───────────────────────────────────────────
        _tile(
          icon: Icons.email_outlined,
          label: 'Email',
          value: user?.email ?? '—',
          onTap: isOAuthUser
              ? null
              : () => _showEditEmailDialog(context, ref, user?.email),
        ),
        if (!isOAuthUser)
          _tile(
            icon: Icons.lock_outline,
            label: 'Change Password',
            value: '••••••••',
            onTap: () => _showChangePasswordDialog(context, ref),
          ),
        const Divider(color: Colors.white10, height: 1),

        // ── Session Preferences ───────────────────────────────────────────
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'Session Preferences',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        _tile(
          icon: Icons.verified_user_outlined,
          label: 'Signed in with',
          value: providerLabel,
          onTap: null,
        ),
        _tile(
          icon: Icons.timer_outlined,
          label: 'Session Timeout',
          value: _timeoutLabel(timeoutMinutes),
          onTap: () => _showTimeoutPicker(context, ref, timeoutMinutes),
        ),
        const Divider(color: Colors.white10, height: 1),

        // ── Admin request ─────────────────────────────────────────────────
        ListTile(
          leading: const Icon(Icons.admin_panel_settings_outlined,
              color: AppColors.textSecondary, size: 22),
          title: const Text(
            'Request Admin Access',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          trailing: const Icon(Icons.chevron_right,
              size: 18, color: AppColors.textSecondary),
          onTap: () => _showAdminRequestDialog(context, ref),
        ),
      ],
    );
  }

  static Widget _tile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryGold, size: 22),
      title: Text(label,
          style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 15)),
      subtitle: Text(value,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 13)),
      trailing: onTap != null
          ? const Icon(Icons.edit_outlined,
              size: 16, color: AppColors.textSecondary)
          : null,
      onTap: onTap,
    );
  }

  String _timeoutLabel(int minutes) => switch (minutes) {
        0 => 'Never',
        1 => '1 minute',
        _ => '$minutes minutes',
      };

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showEditUsernameDialog(
      BuildContext context, WidgetRef ref, String? current) {
    final ctrl = TextEditingController(text: current ?? '');
    bool loading = false;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: const Text('User Name',
              style: TextStyle(color: AppColors.textPrimary)),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      setState(() => loading = true);
                      try {
                        await ref
                            .read(userProfileNotifierProvider.notifier)
                            .saveProfile(username: ctrl.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppColors.error),
                          );
                        }
                      } finally {
                        setState(() => loading = false);
                      }
                    },
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.textDark))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPhoneDialog(
      BuildContext context, WidgetRef ref, String? current) {
    final ctrl = TextEditingController(text: current ?? '');
    bool loading = false;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: const Text('Phone Number',
              style: TextStyle(color: AppColors.textPrimary)),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Phone (optional)',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      setState(() => loading = true);
                      try {
                        await ref
                            .read(userProfileNotifierProvider.notifier)
                            .saveProfile(
                                phone: ctrl.text.trim().isEmpty
                                    ? null
                                    : ctrl.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppColors.error),
                          );
                        }
                      } finally {
                        setState(() => loading = false);
                      }
                    },
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.textDark))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditEmailDialog(
      BuildContext context, WidgetRef ref, String? current) {
    final ctrl = TextEditingController(text: current ?? '');
    bool loading = false;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: const Text('Change Email',
              style: TextStyle(color: AppColors.textPrimary)),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'New email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      setState(() => loading = true);
                      try {
                        await Supabase.instance.client.auth.updateUser(
                          UserAttributes(email: ctrl.text.trim()),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Confirm via email sent to new address'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppColors.error),
                          );
                        }
                      } finally {
                        setState(() => loading = false);
                      }
                    },
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.textDark))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool loading = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: const Text('Change Password',
              style: TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newCtrl,
                obscureText: obscureNew,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'New password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureNew
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => obscureNew = !obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmCtrl,
                obscureText: obscureConfirm,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Confirm password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => obscureConfirm = !obscureConfirm),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      final newPwd = newCtrl.text;
                      if (newPwd.length < 8) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Password must be at least 8 characters'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }
                      if (newPwd != confirmCtrl.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Passwords do not match'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }
                      setState(() => loading = true);
                      try {
                        await Supabase.instance.client.auth.updateUser(
                          UserAttributes(password: newPwd),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Password updated successfully'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppColors.error),
                          );
                        }
                      } finally {
                        setState(() => loading = false);
                      }
                    },
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.textDark))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimeoutPicker(
      BuildContext context, WidgetRef ref, int current) {
    const options = [0, 5, 15, 30, 60];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Session Timeout',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...options.map((minutes) {
              final label = minutes == 0
                  ? 'Never'
                  : minutes == 1
                      ? '1 minute'
                      : '$minutes minutes';
              final selected = minutes == current;
              return ListTile(
                leading: Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected
                      ? AppColors.primaryGold
                      : AppColors.textSecondary,
                  size: 22,
                ),
                title: Text(label,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    )),
                onTap: () {
                  ref
                      .read(sessionTimeoutProvider.notifier)
                      .setMinutes(minutes);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showAdminRequestDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        title: const Text('Request Admin Access',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Submit a request for administrator privileges. An existing admin '
          'will review your request.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // TODO (Phase 6): Use ChangeRequestDialog widget
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Request submitted — coming in next phase'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }
}
