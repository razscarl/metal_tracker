import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:metal_tracker/features/spot_prices/data/models/global_spot_provider_model.dart';

class GlobalSpotProvidersRepository {
  final SupabaseClient _supabase;

  GlobalSpotProvidersRepository(this._supabase);

  Future<List<GlobalSpotProvider>> getProviders({
    bool activeOnly = false,
  }) async {
    try {
      var query = _supabase.from('global_spot_providers').select();
      if (activeOnly) query = query.eq('is_active', true);
      final response = await query.order('name');
      return (response as List)
          .map((json) => GlobalSpotProvider.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching global spot providers: $e');
      return [];
    }
  }

  // Admin-only operations

  Future<GlobalSpotProvider?> createProvider({
    required String name,
    required String providerKey,
    String? baseUrl,
    String? description,
    bool isActive = true,
  }) async {
    try {
      final response = await _supabase
          .from('global_spot_providers')
          .insert({
            'name': name,
            'provider_key': providerKey,
            'base_url': baseUrl,
            'description': description,
            'is_active': isActive,
          })
          .select()
          .single();
      return GlobalSpotProvider.fromJson(response);
    } catch (e) {
      debugPrint('Error creating global spot provider: $e');
      rethrow;
    }
  }

  Future<GlobalSpotProvider?> updateProvider(
    GlobalSpotProvider provider,
  ) async {
    try {
      final response = await _supabase
          .from('global_spot_providers')
          .update({
            'name': provider.name,
            'base_url': provider.baseUrl,
            'description': provider.description,
            'is_active': provider.isActive,
          })
          .eq('id', provider.id)
          .select()
          .single();
      return GlobalSpotProvider.fromJson(response);
    } catch (e) {
      debugPrint('Error updating global spot provider: $e');
      rethrow;
    }
  }

  Future<void> deleteProvider(String id) async {
    try {
      await _supabase.from('global_spot_providers').delete().eq('id', id);
    } catch (e) {
      debugPrint('Error deleting global spot provider: $e');
      rethrow;
    }
  }
}
