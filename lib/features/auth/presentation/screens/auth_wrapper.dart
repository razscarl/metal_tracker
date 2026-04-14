// lib/features/auth/presentation/screens/auth_wrapper.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/features/admin/presentation/providers/admin_providers.dart';
import 'package:metal_tracker/features/auth/presentation/providers/auth_providers.dart';
import 'package:metal_tracker/features/auth/presentation/screens/auth_screen.dart';
import 'package:metal_tracker/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:metal_tracker/features/auth/presentation/screens/pending_approval_screen.dart';
import 'package:metal_tracker/features/auth/presentation/widgets/lock_screen_overlay.dart';
import 'package:metal_tracker/features/home/presentation/screens/home_screen.dart';
import 'package:metal_tracker/features/holdings/presentation/providers/holdings_providers.dart';
import 'package:metal_tracker/features/live_prices/presentation/providers/live_prices_providers.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_prefs_providers.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_profile_providers.dart';
import 'package:metal_tracker/features/spot_prices/presentation/providers/spot_prices_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper>
    with WidgetsBindingObserver {
  bool _authenticated = false;
  bool _locked = false;
  bool _appStarted = false;
  bool _profileChecked = false;
  bool _needsOnboarding = false;
  bool _pendingApproval = false;
  bool _rejected = false;
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appStarted = true;
    });
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _clearUserProviders() {
    ref.invalidate(userProfileNotifierProvider);
    ref.invalidate(userMetalTypesNotifierProvider);
    ref.invalidate(userRetailersNotifierProvider);
    ref.invalidate(userGlobalSpotPrefNotifierProvider);
    ref.invalidate(userAnalyticsSettingsNotifierProvider);
    ref.invalidate(livePricesNotifierProvider);
    ref.invalidate(spotPricesNotifierProvider);
    ref.invalidate(globalSpotProvidersProvider());
    ref.invalidate(holdingsProvider);
    ref.invalidate(productProfilesProvider);
    ref.invalidate(pendingUsersNotifierProvider);
    ref.invalidate(pendingUserCountProvider);
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    final minutes = ref.read(sessionTimeoutProvider).valueOrNull ?? 15;
    if (minutes == 0) return;
    _idleTimer = Timer(Duration(minutes: minutes), _lockSession);
  }

  void _lockSession() {
    if (mounted && _authenticated) setState(() => _locked = true);
  }

  Future<void> _checkProfileAndStatus() async {
    _clearUserProviders();
    final repo = ref.read(userProfileRepositoryProvider);
    final profile = await repo.getProfile();
    if (!mounted) return;
    setState(() {
      _authenticated = true;
      _profileChecked = true;
      _needsOnboarding = profile == null;
      _pendingApproval = profile?.isPending ?? false;
      _rejected = profile?.isRejected ?? false;
    });
    if (profile?.isApproved ?? false) _resetIdleTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_appStarted) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _lockSession();
    } else if (state == AppLifecycleState.resumed) {
      if (!_locked && _authenticated) _resetIdleTimer();
    } else if (state == AppLifecycleState.detached) {
      _idleTimer?.cancel();
      Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final event = snapshot.data!.event;
          if (event == AuthChangeEvent.signedIn &&
              snapshot.data!.session != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (!mounted || _authenticated) return;
              await _checkProfileAndStatus();
            });
          } else if (event == AuthChangeEvent.signedOut) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _clearUserProviders();
                _idleTimer?.cancel();
                setState(() {
                  _authenticated = false;
                  _locked = false;
                  _profileChecked = false;
                  _needsOnboarding = false;
                  _pendingApproval = false;
                  _rejected = false;
                });
              }
            });
          }
        }

        if (!_authenticated) return const AuthScreen();

        if (!_profileChecked) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundDark,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold),
            ),
          );
        }

        if (_needsOnboarding) {
          return OnboardingScreen(
            onComplete: () async {
              _clearUserProviders();
              final repo = ref.read(userProfileRepositoryProvider);
              final profile = await repo.getProfile();
              if (!mounted) return;
              setState(() {
                _needsOnboarding = false;
                _locked = false;
                _pendingApproval = profile?.isPending ?? false;
                _rejected = profile?.isRejected ?? false;
              });
              if (profile?.isApproved ?? false) _resetIdleTimer();
            },
          );
        }

        if (_rejected) {
          return _RejectedScreen(
            onSignOut: () =>
                ref.read(authNotifierProvider.notifier).signOut(),
          );
        }

        if (_pendingApproval) {
          return PendingApprovalScreen(
            onApproved: () {
              setState(() {
                _pendingApproval = false;
                _rejected = false;
              });
              _resetIdleTimer();
            },
            onRejected: () {
              setState(() {
                _pendingApproval = false;
                _rejected = true;
              });
            },
          );
        }

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) {
            if (!_locked) _resetIdleTimer();
          },
          child: Stack(
            children: [
              HomeScreen(
                  key: ValueKey(
                      Supabase.instance.client.auth.currentUser?.id)),
              if (_locked)
                LockScreenOverlay(
                  userEmail:
                      Supabase.instance.client.auth.currentUser?.email,
                  onUnlocked: () {
                    setState(() => _locked = false);
                    _resetIdleTimer();
                  },
                  onSignOut: () => setState(() {
                    _authenticated = false;
                    _locked = false;
                  }),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Rejected screen ───────────────────────────────────────────────────────────

class _RejectedScreen extends StatelessWidget {
  final VoidCallback onSignOut;

  const _RejectedScreen({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
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
                  color: AppColors.backgroundCard,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.lossRed.withOpacity(0.4), width: 2),
                ),
                child: const Icon(Icons.block_rounded,
                    color: AppColors.lossRed, size: 40),
              ),
              const SizedBox(height: 32),
              const Text(
                'Account Not Approved',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your account request was not approved. '
                'Please contact support if you believe this is an error.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onSignOut,
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
