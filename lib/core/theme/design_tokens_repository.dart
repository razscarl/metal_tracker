// lib/core/theme/design_tokens_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class DesignTokensRepository {
  final SupabaseClient _supabase;

  DesignTokensRepository(this._supabase);

  // Returns all resolved token values for the given theme.
  // Semantic tokens are resolved to their primitive's value via a join.
  // The query returns one row per token with a single `resolved_value` column.
  Future<List<Map<String, dynamic>>> fetchTokensForTheme(String themeId) async {
    // Primitives: join token → value directly
    // Semantics: join token → value → references primitive → primitive value
    // We use a union so the caller gets a flat list.
    final response = await _supabase.rpc(
      'resolve_design_tokens',
      params: {'p_theme_id': themeId},
    ) as List<dynamic>;

    return response.cast<Map<String, dynamic>>();
  }

  // Returns ALL themes — admin view.
  Future<List<Map<String, dynamic>>> fetchAllThemes() async {
    final response = await _supabase
        .from('design_themes')
        .select('id, name, display_name, is_default, is_available, sort_order')
        .order('sort_order');
    return (response as List).cast<Map<String, dynamic>>();
  }

  // Returns all available themes (is_available = true).
  Future<List<Map<String, dynamic>>> fetchAvailableThemes() async {
    final response = await _supabase
        .from('design_themes')
        .select('id, name, display_name, is_default, sort_order')
        .eq('is_available', true)
        .order('sort_order');

    return (response as List).cast<Map<String, dynamic>>();
  }

  // Returns the default theme id.
  Future<String?> fetchDefaultThemeId() async {
    final response = await _supabase
        .from('design_themes')
        .select('id')
        .eq('is_default', true)
        .eq('is_available', true)
        .limit(1)
        .maybeSingle();

    return response?['id'] as String?;
  }

  // Updates the user's selected theme.
  Future<void> setUserTheme(String userId, String themeId) async {
    await _supabase
        .from('user_profiles')
        .update({'theme_id': themeId})
        .eq('id', userId);
  }

  // Admin: fetch all tokens with their values for a given theme.
  Future<List<Map<String, dynamic>>> fetchAllTokensAdmin(String themeId) async {
    // Use FK constraint name to disambiguate — design_token_values has two
    // FKs back to design_tokens (token_id and references_token_id).
    final response = await _supabase
        .from('design_tokens')
        .select('''
          id, token_name, tier, token_type, group_name, reserved_for, sort_order,
          design_token_values!design_token_values_token_id_fkey (
            id, value, references_token_id, theme_id
          )
        ''')
        .eq('design_token_values.theme_id', themeId)
        .order('group_name')
        .order('sort_order');

    return (response as List).cast<Map<String, dynamic>>();
  }

  // Admin: update a primitive token value for a theme.
  Future<void> updatePrimitiveValue({
    required String tokenValueId,
    required String value,
  }) async {
    await _supabase
        .from('design_token_values')
        .update({'value': value})
        .eq('id', tokenValueId);
  }

  // Admin: update a semantic token's primitive reference for a theme.
  Future<void> updateSemanticReference({
    required String tokenValueId,
    required String referencesTokenId,
  }) async {
    await _supabase
        .from('design_token_values')
        .update({'references_token_id': referencesTokenId})
        .eq('id', tokenValueId);
  }

  // Admin: fetch all primitive tokens (for reference picker in admin UI).
  Future<List<Map<String, dynamic>>> fetchPrimitiveTokens(String tokenType) async {
    final response = await _supabase
        .from('design_tokens')
        .select('id, token_name, reserved_for')
        .eq('tier', 'primitive')
        .eq('token_type', tokenType)
        .order('sort_order');

    return (response as List).cast<Map<String, dynamic>>();
  }
}
