// lib/features/product_profiles/data/repositories/product_profiles_repository.dart: Product Profiles Repository
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_profile_model.dart';
import '../../../live_prices/data/models/live_price_model.dart';

class ProductProfilesRepository {
  final SupabaseClient _supabase;

  ProductProfilesRepository(this._supabase);

  String get _userId => _supabase.auth.currentUser!.id;

  // ==========================================
  // PRODUCT PROFILES
  // ==========================================

  Future<List<ProductProfile>> getProductProfiles() async {
    final response = await _supabase
        .from('product_profiles')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ProductProfile.fromJson(json))
        .toList();
  }

  Future<ProductProfile> getProductProfile(String id) async {
    final response = await _supabase
        .from('product_profiles')
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .single();

    return ProductProfile.fromJson(response);
  }

  Future<ProductProfile?> createProductProfile({
    required String profileName,
    required String profileCode,
    required String metalType,
    required String metalForm,
    String? metalFormCustom,
    required double weight,
    required String weightDisplay,
    required String weightUnit,
    required double purity,
  }) async {
    try {
      final response = await _supabase
          .from('product_profiles')
          .insert({
            'user_id': _userId,
            'profile_name': profileName,
            'profile_code': profileCode,
            'metal_type': metalType,
            'metal_form': metalForm,
            'metal_form_custom': metalFormCustom,
            'weight': weight,
            'weight_display': weightDisplay,
            'weight_unit': weightUnit,
            'purity': purity,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return ProductProfile.fromJson(response);
    } catch (e) {
      debugPrint('Error creating product profile: $e');
      return null;
    }
  }

  Future<void> deleteProductProfile(String id) async {
    await _supabase
        .from('product_profiles')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  // ==========================================
  // LIVE PRICE MAPPING
  // ==========================================

  /// Links an unmapped live price to a product profile.
  /// Moved here from scraper_repository — this is a product profile concern,
  /// not a scraper concern.
  Future<LivePrice?> updateLivePriceMapping(
    String livePriceId,
    String productProfileId,
  ) async {
    try {
      final response = await _supabase
          .from('live_prices')
          .update({'product_profile_id': productProfileId})
          .eq('id', livePriceId)
          .eq('user_id', _userId)
          .select()
          .single();

      return LivePrice.fromJson(response);
    } catch (e) {
      debugPrint('Error updating live price mapping: $e');
      return null;
    }
  }
}
