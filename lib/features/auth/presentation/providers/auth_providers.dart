// lib/features/auth/presentation/providers/auth_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_providers.g.dart';

// ── Auth User Model ────────────────────────────────────────────────────────────

class AuthUser {
  final String id;
  final String? email;
  final String? displayName;
  final String provider;

  const AuthUser({
    required this.id,
    this.email,
    this.displayName,
    required this.provider,
  });

  bool get isOAuthUser => provider != 'email';

  factory AuthUser.fromSupabaseUser(User user) {
    final provider = user.appMetadata['provider'] as String? ?? 'email';
    final displayName = user.userMetadata?['display_name'] as String?;
    return AuthUser(
      id: user.id,
      email: user.email,
      displayName: displayName,
      provider: provider,
    );
  }
}

// ── Current Auth User Provider ─────────────────────────────────────────────────

@riverpod
AuthUser? currentAuthUser(Ref ref) {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;
  return AuthUser.fromSupabaseUser(user);
}

// ── Auth Notifier ──────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  FutureOr<void> build() {}

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      await ref.read(savedEmailProvider.notifier).save(email);
    });
  }

  Future<void> signUp(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _supabase.auth.signUp(email: email, password: password);
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'metaltracker://login-callback',
      );
    });
  }

  Future<void> signInWithApple() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'metaltracker://login-callback',
      );
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _supabase.auth.signOut();
    });
  }

  Future<void> sendPasswordReset(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }
}

// ── Session Timeout Provider ───────────────────────────────────────────────────

const _kSessionTimeoutKey = 'session_timeout_minutes';

@Riverpod(keepAlive: true)
class SessionTimeout extends _$SessionTimeout {
  @override
  Future<int> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kSessionTimeoutKey) ?? 15;
  }

  Future<void> setMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kSessionTimeoutKey, minutes);
    state = AsyncData(minutes);
  }
}

// ── Saved Email Provider ───────────────────────────────────────────────────────

const _kSavedEmailKey = 'auth_saved_email';

@Riverpod(keepAlive: true)
class SavedEmail extends _$SavedEmail {
  @override
  Future<String?> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kSavedEmailKey);
  }

  Future<void> save(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSavedEmailKey, email);
    state = AsyncData(email);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSavedEmailKey);
    state = const AsyncData(null);
  }
}
