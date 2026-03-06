// lib/features/retailers/data/repositories/retailers_repository.dart:Retailers Repository
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/retailers_model.dart';

class RetailerRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  String get _userId => _supabase.auth.currentUser!.id;

  // ==========================================
  // READ
  // ==========================================

  /// Get all retailers for the current user
  Future<List<Retailer>> getRetailers({bool includeInactive = false}) async {
    try {
      var query = _supabase.from('retailers').select();

      if (!includeInactive) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('name');

      return (response as List).map((json) => Retailer.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching retailers: $e');
      return [];
    }
  }

  /// Get a single retailer by ID
  Future<Retailer?> getRetailer(String retailerId) async {
    try {
      final response = await _supabase
          .from('retailers')
          .select()
          .eq('id', retailerId)
          .single();

      return Retailer.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching retailer: $e');
      return null;
    }
  }

  // ==========================================
  // CREATE
  // ==========================================

  /// Create a new retailer
  Future<Retailer?> createRetailer({
    required String name,
    String? retailerAbbr,
    String? baseUrl,
    bool isActive = true,
  }) async {
    try {
      final response = await _supabase
          .from('retailers')
          .insert({
            'user_id': _userId,
            'name': name,
            'retailer_abbr': retailerAbbr,
            'base_url': baseUrl,
            'is_active': isActive,
          })
          .select()
          .single();

      return Retailer.fromJson(response);
    } catch (e) {
      debugPrint('Error creating retailer: $e');
      return null;
    }
  }

  // ==========================================
  // UPDATE
  // ==========================================

  /// Update an existing retailer
  Future<Retailer?> updateRetailer({
    required String retailerId,
    String? name,
    String? retailerAbbr,
    String? baseUrl,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (name != null) updates['name'] = name;
      if (retailerAbbr != null) updates['retailer_abbr'] = retailerAbbr;
      if (baseUrl != null) updates['base_url'] = baseUrl;
      if (isActive != null) updates['is_active'] = isActive;

      if (updates.isEmpty) return null;

      final response = await _supabase
          .from('retailers')
          .update(updates)
          .eq('id', retailerId)
          .eq('user_id', _userId)
          .select()
          .single();

      return Retailer.fromJson(response);
    } catch (e) {
      debugPrint('Error updating retailer: $e');
      return null;
    }
  }

  // ==========================================
  // DELETE
  // ==========================================

  /// Soft delete a retailer (set is_active = false)
  Future<bool> softDeleteRetailer(String retailerId) async {
    try {
      await _supabase
          .from('retailers')
          .update({'is_active': false})
          .eq('id', retailerId)
          .eq('user_id', _userId);
      return true;
    } catch (e) {
      debugPrint('Error deleting retailer: $e');
      return false;
    }
  }
}
