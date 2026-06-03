// lib/features/admin/presentation/providers/design_tokens_admin_providers.dart

import 'package:metal_tracker/core/theme/design_tokens_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'design_tokens_admin_providers.g.dart';

// ── All themes (admin — includes unavailable) ─────────────────────────────────

@riverpod
Future<List<Map<String, dynamic>>> allDesignThemes(
    AllDesignThemesRef ref) async {
  return ref.watch(designTokensRepositoryProvider).fetchAllThemes();
}

// ── All tokens with values for a given theme ──────────────────────────────────

@riverpod
Future<List<Map<String, dynamic>>> designTokensAdmin(
  DesignTokensAdminRef ref,
  String themeId,
) async {
  return ref.watch(designTokensRepositoryProvider).fetchAllTokensAdmin(themeId);
}

// ── Primitive tokens by type (for semantic reference picker) ──────────────────

@riverpod
Future<List<Map<String, dynamic>>> primitiveTokensByType(
  PrimitiveTokensByTypeRef ref,
  String tokenType,
) async {
  return ref
      .watch(designTokensRepositoryProvider)
      .fetchPrimitiveTokens(tokenType);
}

// ── Token value editor notifier ───────────────────────────────────────────────

@riverpod
class TokenValueEditor extends _$TokenValueEditor {
  @override
  FutureOr<void> build() {}

  Future<void> updatePrimitive({
    required String tokenValueId,
    required String value,
    required String themeId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(designTokensRepositoryProvider)
          .updatePrimitiveValue(tokenValueId: tokenValueId, value: value);
      ref.invalidate(designTokensAdminProvider(themeId));
      ref.invalidate(designTokensProvider);
    });
  }

  Future<void> updateReference({
    required String tokenValueId,
    required String referencesTokenId,
    required String themeId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(designTokensRepositoryProvider)
          .updateSemanticReference(
            tokenValueId: tokenValueId,
            referencesTokenId: referencesTokenId,
          );
      ref.invalidate(designTokensAdminProvider(themeId));
      ref.invalidate(designTokensProvider);
    });
  }
}
