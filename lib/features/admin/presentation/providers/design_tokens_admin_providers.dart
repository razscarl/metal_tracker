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

// ── Semantic tokens with resolved values for a theme (admin display) ──────────

@riverpod
Future<List<Map<String, dynamic>>> semanticTokensResolved(
  SemanticTokensResolvedRef ref,
  String themeId,
) async {
  return ref
      .watch(designTokensRepositoryProvider)
      .fetchSemanticTokensResolved(themeId);
}

// ── Primitive tokens with values for a type + theme (visual pickers) ──────────

@riverpod
Future<List<Map<String, dynamic>>> primitiveTokensWithValues(
  PrimitiveTokensWithValuesRef ref,
  String tokenType,
  String themeId,
) async {
  return ref
      .watch(designTokensRepositoryProvider)
      .fetchPrimitiveTokensWithValues(tokenType, themeId);
}

// ── Token value editor ────────────────────────────────────────────────────────

@riverpod
class TokenValueEditor extends _$TokenValueEditor {
  @override
  FutureOr<void> build() {}

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
      ref.invalidate(semanticTokensResolvedProvider(themeId));
      ref.invalidate(designTokensProvider);
    });
  }
}
