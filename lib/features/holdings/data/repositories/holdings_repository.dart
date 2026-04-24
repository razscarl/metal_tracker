// lib/features/holdings/data/repositories/holdings_repository.dart: Holdings Repository
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:metal_tracker/core/utils/time_service.dart';
import '../models/holding_model.dart';

class HoldingsRepository {
  final SupabaseClient _supabase;

  HoldingsRepository(this._supabase);

  // Get current user ID for RLS compliance
  String get _userId => _supabase.auth.currentUser!.id;

  // ==========================================
  // HOLDINGS FETCHING
  // ==========================================

  Future<List<Holding>> getHoldings({bool includeProfile = true}) async {
    final response = await _supabase
        .from('holdings')
        .select(includeProfile ? '*, product_profiles(*)' : '*')
        .eq('user_id', _userId)
        .eq('is_sold', false)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Holding.fromJson(json)).toList();
  }

  Future<List<Holding>> getSoldHoldings() async {
    final response = await _supabase
        .from('holdings')
        .select('*, product_profiles(*)')
        .eq('user_id', _userId)
        .eq('is_sold', true)
        .order('sold_date', ascending: false);

    return (response as List).map((json) => Holding.fromJson(json)).toList();
  }

  // ==========================================
  // HOLDINGS ACTIONS
  // ==========================================

  Future<Holding> createHolding({
    required String productName,
    required String productProfileId,
    String? retailerId,
    required DateTime purchaseDate,
    required double purchasePrice,
  }) async {
    final response = await _supabase
        .from('holdings')
        .insert({
          'user_id': _userId,
          'product_name': productName,
          'product_profile_id': productProfileId,
          'retailer_id': retailerId,
          'purchase_date': TimeService.toLocalDateString(purchaseDate),
          'purchase_price': purchasePrice,
          'is_sold': false,
          'created_at': TimeService.toUtcString(DateTime.now()),
          'updated_at': TimeService.toUtcString(DateTime.now()),
        })
        .select('*, product_profiles(*)')
        .single();

    return Holding.fromJson(response);
  }

  Future<Holding> updateHolding({
    required String id,
    String? productName,
    DateTime? purchaseDate,
    double? purchasePrice,
    String? retailerId,
    String? productProfileId,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': TimeService.toUtcString(DateTime.now()),
    };

    if (productName != null) updates['product_name'] = productName;
    if (purchaseDate != null) {
      updates['purchase_date'] = TimeService.toLocalDateString(purchaseDate);
    }
    if (purchasePrice != null) updates['purchase_price'] = purchasePrice;
    if (retailerId != null) updates['retailer_id'] = retailerId;
    if (productProfileId != null) updates['product_profile_id'] = productProfileId;

    final response = await _supabase
        .from('holdings')
        .update(updates)
        .eq('id', id)
        .eq('user_id', _userId)
        .select('*, product_profiles(*)')
        .single();

    return Holding.fromJson(response);
  }

  Future<Holding> sellHolding({
    required String id,
    required DateTime soldDate,
    required double soldPrice,
  }) async {
    final response = await _supabase
        .from('holdings')
        .update({
          'is_sold': true,
          'sold_date': TimeService.toLocalDateString(soldDate),
          'sold_price': soldPrice,
          'updated_at': TimeService.toUtcString(DateTime.now()),
        })
        .eq('id', id)
        .eq('user_id', _userId)
        .select('*, product_profiles(*)')
        .single();

    return Holding.fromJson(response);
  }

  Future<void> deleteHolding(String id) async {
    await _supabase
        .from('holdings')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
