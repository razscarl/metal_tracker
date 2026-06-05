import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/features/auth/presentation/providers/auth_providers.dart';

class PendingApprovalScreen extends ConsumerStatefulWidget {
  final VoidCallback onApproved;
  final VoidCallback onRejected;

  const PendingApprovalScreen({
    super.key,
    required this.onApproved,
    required this.onRejected,
  });

  @override
  ConsumerState<PendingApprovalScreen> createState() =>
      _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends ConsumerState<PendingApprovalScreen> {
  bool _checking = false;

  Future<void> _checkStatus() async {
    setState(() => _checking = true);
    try {
      final profile =
          await ref.read(userProfileRepositoryProvider).getProfile();
      if (!mounted) return;
      if (profile == null) return;
      if (profile.isApproved) {
        widget.onApproved();
      } else if (profile.isRejected) {
        widget.onRejected();
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authNotifierProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color:  cs.surfaceContainerLow,
                  shape:  BoxShape.circle,
                  border: Border.all(
                      color: cs.primary.withValues(alpha: 0.4), width: 2),
                ),
                child: Icon(Icons.hourglass_top_rounded,
                    color: cs.primary, size: 40),
              ),
              const SizedBox(height: 32),
              Text(
                'Account Pending Approval',
                textAlign: TextAlign.center,
                style: tt.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                'Your account has been created and is awaiting admin approval. '
                'You will be notified once your account has been reviewed.',
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _checking ? null : _checkStatus,
                  icon: _checking
                      ? SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: cs.onPrimary))
                      : const Icon(Icons.refresh),
                  label: Text(_checking ? 'Checking...' : 'Check Status'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _signOut,
                  child: const Text('Sign Out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
