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

// ── Semantic tokens with resolved values for a theme ─────────────────────────

@riverpod
Future<List<Map<String, dynamic>>> semanticTokensResolved(
  SemanticTokensResolvedRef ref,
  String themeId,
) async {
  return ref
      .watch(designTokensRepositoryProvider)
      .fetchSemanticTokensResolved(themeId);
}

// ── Text styles with resolved values + token IDs ──────────────────────────────

@riverpod
Future<List<Map<String, dynamic>>> textStylesAdmin(
  TextStylesAdminRef ref,
  String themeId,
) async {
  return ref
      .watch(designTokensRepositoryProvider)
      .fetchTextStylesAdmin(themeId);
}

// ── Primitive tokens with values for a type + theme (pickers) ─────────────────

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

// ── Semantic colour tokens (for text style colour picker) ─────────────────────

@riverpod
Future<List<Map<String, dynamic>>> semanticColorTokens(
  SemanticColorTokensRef ref,
  String themeId,
) async {
  final all = await ref
      .watch(designTokensRepositoryProvider)
      .fetchSemanticTokensResolved(themeId);
  return all.where((t) => t['token_type'] == 'color').toList();
}

// ── Semantic tokens of a given type (for text style pickers) ──────────────────

@riverpod
Future<List<Map<String, dynamic>>> semanticTokensByType(
  SemanticTokensByTypeRef ref,
  String tokenType,
  String themeId,
) async {
  final all = await ref
      .watch(designTokensRepositoryProvider)
      .fetchSemanticTokensResolved(themeId);
  return all.where((t) => t['token_type'] == tokenType).toList();
}

// ── Token value editor (semantic → primitive reference) ───────────────────────

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

// ── Text style editor ─────────────────────────────────────────────────────────

@riverpod
class TextStyleEditor extends _$TextStyleEditor {
  @override
  FutureOr<void> build() {}

  Future<void> updateToken({
    required String textStyleId,
    required String themeId,
    String? colorTokenId,
    String? fontSizeTokenId,
    String? fontWeightTokenId,
    String? fontFamilyTokenId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(designTokensRepositoryProvider).updateTextStyleToken(
            textStyleId:       textStyleId,
            colorTokenId:      colorTokenId,
            fontSizeTokenId:   fontSizeTokenId,
            fontWeightTokenId: fontWeightTokenId,
            fontFamilyTokenId: fontFamilyTokenId,
          );
      ref.invalidate(textStylesAdminProvider(themeId));
      ref.invalidate(designTokensProvider);
    });
  }
}
