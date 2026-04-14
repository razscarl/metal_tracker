// lib/features/retailers/data/repositories/retailers_repository.dart:Retailers Repository
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:metal_tracker/features/retailers/data/models/retailer_scraper_setting_model.dart';
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

  /// Get active scraper settings for a retailer + scraper type.
  Future<List<RetailerScraperSetting>> getScraperSettingsForType(
    String retailerId,
    String scraperType,
  ) async {
    try {
      final response = await _supabase
          .from('retailer_scraper_settings')
          .select()
          .eq('retailer_id', retailerId)
          .eq('scraper_type', scraperType)
          .eq('is_active', true)
          .order('metal_type');
      return (response as List)
          .map((json) => RetailerScraperSetting.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching scraper settings: $e');
      return [];
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

  // ==========================================
  // SCRAPER SETTINGS
  // ==========================================

  /// Get all scraper settings, optionally filtered by retailer/type/active.
  Future<List<RetailerScraperSetting>> getRetailerScraperSettings({
    String? retailerId,
    String? scraperType,
    bool activeOnly = false,
  }) async {
    try {
      var query = _supabase.from('retailer_scraper_settings').select();
      if (retailerId != null) query = query.eq('retailer_id', retailerId);
      if (scraperType != null) query = query.eq('scraper_type', scraperType);
      if (activeOnly) query = query.eq('is_active', true);
      final response = await query.order('scraper_type').order('metal_type');
      return (response as List)
          .map((json) => RetailerScraperSetting.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching scraper settings: $e');
      return [];
    }
  }

  /// Create a new scraper setting.
  Future<RetailerScraperSetting?> createScraperSetting({
    required String retailerId,
    required String scraperType,
    String? metalType,
    required String searchString,
    String? searchUrl,
    bool isActive = true,
    String? notes,
  }) async {
    try {
      final response = await _supabase
          .from('retailer_scraper_settings')
          .insert({
            'retailer_id': retailerId,
            'scraper_type': scraperType,
            'metal_type': metalType,
            'search_string': searchString,
            'search_url': searchUrl,
            'is_active': isActive,
            'notes': notes,
          })
          .select()
          .single();
      return RetailerScraperSetting.fromJson(response);
    } catch (e) {
      debugPrint('Error creating scraper setting: $e');
      rethrow;
    }
  }

  /// Update an existing scraper setting.
  Future<RetailerScraperSetting?> updateScraperSetting({
    required String settingId,
    String? searchString,
    bool? isActive,
    String? notes,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (searchString != null) updates['search_string'] = searchString;
      if (isActive != null) updates['is_active'] = isActive;
      if (notes != null) updates['notes'] = notes;
      if (updates.isEmpty) return null;
      final response = await _supabase
          .from('retailer_scraper_settings')
          .update(updates)
          .eq('id', settingId)
          .select()
          .single();
      return RetailerScraperSetting.fromJson(response);
    } catch (e) {
      debugPrint('Error updating scraper setting: $e');
      return null;
    }
  }

  /// Delete a scraper setting.
  Future<bool> deleteScraperSetting(String settingId) async {
    try {
      await _supabase
          .from('retailer_scraper_settings')
          .delete()
          .eq('id', settingId);
      return true;
    } catch (e) {
      debugPrint('Error deleting scraper setting: $e');
      return false;
    }
  }
}
