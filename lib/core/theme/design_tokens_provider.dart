// lib/core/theme/design_tokens_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/core/theme/design_tokens.dart';
import 'package:metal_tracker/core/theme/design_tokens_repository.dart';
import 'package:metal_tracker/features/settings/presentation/providers/user_profile_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'design_tokens_provider.g.dart';

// ── Repository provider ───────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
DesignTokensRepository designTokensRepository(DesignTokensRepositoryRef ref) {
  return DesignTokensRepository(ref.watch(supabaseClientProvider));
}

// ── Active theme ID ───────────────────────────────────────────────────────────
// Resolves: user preference → default theme

@Riverpod(keepAlive: true)
Future<String> activeThemeId(ActiveThemeIdRef ref) async {
  final repo = ref.watch(designTokensRepositoryProvider);

  // Try user's saved preference first
  final profile = await ref.watch(userProfileNotifierProvider.future);
  if (profile?.themeId != null) return profile!.themeId!;

  // Fall back to the default theme
  final defaultId = await repo.fetchDefaultThemeId();
  if (defaultId != null) return defaultId;

  throw Exception('No default design theme configured in database');
}

// ── Resolved token snapshot ───────────────────────────────────────────────────
// keepAlive: token data is needed throughout the app session.
// Invalidate this provider to trigger a re-fetch (e.g. after theme switch).

@Riverpod(keepAlive: true)
Future<DesignTokens> designTokens(DesignTokensRef ref) async {
  final themeId = await ref.watch(activeThemeIdProvider.future);
  final repo    = ref.watch(designTokensRepositoryProvider);
  final rows    = await repo.fetchTokensForTheme(themeId);
  return DesignTokens.fromRows(rows);
}

// ── Available themes (for theme picker UI) ────────────────────────────────────

@riverpod
Future<List<Map<String, dynamic>>> availableThemes(AvailableThemesRef ref) {
  return ref.watch(designTokensRepositoryProvider).fetchAvailableThemes();
}

// ── Theme switcher ────────────────────────────────────────────────────────────

@riverpod
class ThemeSwitchNotifier extends _$ThemeSwitchNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> switchTheme(String themeId) async {
    final repo    = ref.read(designTokensRepositoryProvider);
    final profile = await ref.read(userProfileNotifierProvider.future);
    if (profile == null) return;

    await repo.setUserTheme(profile.id, themeId);

    // Invalidate both profile and token providers to trigger re-fetch
    ref.invalidate(userProfileNotifierProvider);
    ref.invalidate(activeThemeIdProvider);
    ref.invalidate(designTokensProvider);
  }
}
