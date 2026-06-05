// lib/features/auth/presentation/screens/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/features/auth/presentation/screens/auth_screen.dart';
import 'package:metal_tracker/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:metal_tracker/features/auth/presentation/screens/pending_approval_screen.dart';
import 'package:metal_tracker/features/home/presentation/screens/home_screen.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_profile_providers.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ??
            Supabase.instance.client.auth.currentSession;

        // Not signed in → show auth screen
        if (session == null) {
          return const AuthScreen();
        }

        // Signed in → check profile status
        final profileAsync = ref.watch(userProfileNotifierProvider);

        return profileAsync.when(
          loading: () => const Scaffold(
            backgroundColor: AppColors.backgroundDark,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold),
            ),
          ),
          error: (_, __) => const HomeScreen(),
          data: (profile) {
            // No profile yet — new user, needs onboarding
            if (profile == null) {
              return OnboardingScreen(
                onComplete: () async {
                  ref.invalidate(userProfileNotifierProvider);
                },
              );
            }

            // Profile exists — route by status
            if (profile.isPending) {
              return PendingApprovalScreen(
                onApproved: () => ref.invalidate(userProfileNotifierProvider),
                onRejected: () async {
                  await Supabase.instance.client.auth.signOut();
                },
              );
            }

            // Approved (or any other status) — go to app
            return const HomeScreen();
          },
        );
      },
    );
  }
}
