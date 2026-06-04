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

  // Admin: fetch text styles with resolved values + token IDs for editing.
  Future<List<Map<String, dynamic>>> fetchTextStylesAdmin(String themeId) async {
    final resolved = await _supabase.rpc(
      'resolve_text_styles',
      params: {'p_theme_id': themeId},
    ) as List<dynamic>;

    final rows = await _supabase
        .from('design_text_styles')
        .select(
            'id, style_name, color_token_id, font_size_token_id, font_weight_token_id, font_family_token_id')
        .eq('theme_id', themeId) as List<dynamic>;

    final rowMap = <String, Map<String, dynamic>>{
      for (final r in rows.cast<Map<String, dynamic>>())
        r['style_name'] as String: r
    };

    return resolved.cast<Map<String, dynamic>>().map((r) {
      final row = rowMap[r['style_name'] as String];
      return <String, dynamic>{
        ...r,
        'id':                   row?['id'],
        'color_token_id':       row?['color_token_id'],
        'font_size_token_id':   row?['font_size_token_id'],
        'font_weight_token_id': row?['font_weight_token_id'],
        'font_family_token_id': row?['font_family_token_id'],
      };
    }).toList();
  }

  // Admin: update one or more token assignments on a text style.
  Future<void> updateTextStyleToken({
    required String textStyleId,
    String? colorTokenId,
    String? fontSizeTokenId,
    String? fontWeightTokenId,
    String? fontFamilyTokenId,
  }) async {
    final update = <String, dynamic>{};
    if (colorTokenId       != null) update['color_token_id']        = colorTokenId;
    if (fontSizeTokenId    != null) update['font_size_token_id']    = fontSizeTokenId;
    if (fontWeightTokenId  != null) update['font_weight_token_id']  = fontWeightTokenId;
    if (fontFamilyTokenId  != null) update['font_family_token_id']  = fontFamilyTokenId;
    await _supabase.from('design_text_styles').update(update).eq('id', textStyleId);
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

  // Admin: fetch primitive tokens with their resolved values for a theme.
  // Used by visual pickers (colour swatches, size selectors, etc.).
  Future<List<Map<String, dynamic>>> fetchPrimitiveTokensWithValues(
    String tokenType,
    String themeId,
  ) async {
    final response = await _supabase
        .from('design_tokens')
        .select('''
          id, token_name, reserved_for,
          design_token_values!design_token_values_token_id_fkey(value)
        ''')
        .eq('tier', 'primitive')
        .eq('token_type', tokenType)
        .eq('design_token_values.theme_id', themeId)
        .order('sort_order') as List<dynamic>;

    return response.cast<Map<String, dynamic>>().map((t) {
      final vals = t['design_token_values'] as List?;
      final value = vals?.isNotEmpty == true
          ? (vals!.first as Map<String, dynamic>)['value'] as String?
          : null;
      return <String, dynamic>{...t, 'value': value};
    }).toList();
  }

  // Admin: fetch semantic tokens with their resolved values and edit metadata.
  // Merges the resolve_design_tokens RPC result with design_tokens metadata.
  Future<List<Map<String, dynamic>>> fetchSemanticTokensResolved(
      String themeId) async {
    // Step 1: resolved values from RPC
    final resolved = await _supabase.rpc(
      'resolve_design_tokens',
      params: {'p_theme_id': themeId},
    ) as List<dynamic>;
    final resolvedMap = <String, String?>{
      for (final r in resolved.cast<Map<String, dynamic>>())
        r['token_name'] as String: r['resolved_value'] as String?
    };

    // Step 2: semantic token metadata
    final metadata = await _supabase
        .from('design_tokens')
        .select('id, token_name, token_type, group_name, reserved_for, sort_order')
        .eq('tier', 'semantic')
        .order('token_type')
        .order('sort_order') as List<dynamic>;

    // Step 3: value row IDs + references (needed for editing)
    final valueRows = await _supabase
        .from('design_token_values')
        .select('token_id, id, references_token_id')
        .eq('theme_id', themeId) as List<dynamic>;
    final valueByTokenId = <String, Map<String, dynamic>>{
      for (final v in valueRows.cast<Map<String, dynamic>>())
        v['token_id'] as String: v
    };

    // Step 4: merge
    return metadata.cast<Map<String, dynamic>>().map((m) {
      final name = m['token_name'] as String;
      final id   = m['id'] as String;
      final vRow = valueByTokenId[id];
      return <String, dynamic>{
        ...m,
        'resolved_value':       resolvedMap[name],
        'value_id':             vRow?['id'],
        'references_token_id':  vRow?['references_token_id'],
      };
    }).toList();
  }
}
