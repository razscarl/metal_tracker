// lib/features/spot_prices/data/repositories/spot_prices_repository.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:metal_tracker/features/spot_prices/data/models/global_spot_price_api_setting_model.dart';
import 'package:metal_tracker/features/spot_prices/data/models/spot_price_model.dart';

class SpotPricesRepository {
  final SupabaseClient _supabase;

  SpotPricesRepository(this._supabase);

  String get _userId => _supabase.auth.currentUser!.id;

  // ─── API Settings ───────────────────────────────────────────────────────────

  /// Returns all API settings for the current user (all rows, not just active).
  Future<List<GlobalSpotPriceApiSetting>> getApiSettings() async {
    try {
      final response = await _supabase
          .from('global_spot_price_api_settings')
          .select()
          .eq('user_id', _userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => GlobalSpotPriceApiSetting.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching API settings: $e');
      return [];
    }
  }

  /// Returns the active API setting, or null if none configured.
  Future<GlobalSpotPriceApiSetting?> getActiveApiSetting() async {
    try {
      final response = await _supabase
          .from('global_spot_price_api_settings')
          .select()
          .eq('user_id', _userId)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return GlobalSpotPriceApiSetting.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching active API setting: $e');
      return null;
    }
  }

  /// Creates a new API setting row.
  Future<GlobalSpotPriceApiSetting?> createApiSetting({
    required String apiKey,
    required String serviceType,
    required Map<String, String> config,
    bool isActive = true,
  }) async {
    try {
      final response = await _supabase
          .from('global_spot_price_api_settings')
          .insert({
            'user_id': _userId,
            'api_key': apiKey,
            'service_type': serviceType,
            'config': config,
            'is_active': isActive,
          })
          .select()
          .single();

      return GlobalSpotPriceApiSetting.fromJson(response);
    } catch (e) {
      debugPrint('Error creating API setting: $e');
      rethrow;
    }
  }

  /// Updates an existing API setting row by id.
  Future<GlobalSpotPriceApiSetting?> updateApiSetting({
    required String id,
    String? apiKey,
    String? serviceType,
    Map<String, String>? config,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (apiKey != null) updates['api_key'] = apiKey;
      if (serviceType != null) updates['service_type'] = serviceType;
      if (config != null) updates['config'] = config;
      if (isActive != null) updates['is_active'] = isActive;

      final response = await _supabase
          .from('global_spot_price_api_settings')
          .update(updates)
          .eq('id', id)
          .eq('user_id', _userId)
          .select()
          .single();

      return GlobalSpotPriceApiSetting.fromJson(response);
    } catch (e) {
      debugPrint('Error updating API setting: $e');
      rethrow;
    }
  }

  /// Deletes an API setting row by id.
  Future<void> deleteApiSetting(String id) async {
    try {
      await _supabase
          .from('global_spot_price_api_settings')
          .delete()
          .eq('id', id)
          .eq('user_id', _userId);
    } catch (e) {
      debugPrint('Error deleting API setting: $e');
      rethrow;
    }
  }

  // ─── Spot Prices ─────────────────────────────────────────────────────────────

  /// Returns all spot prices (global spot data is shared across all users).
  /// Optionally filtered to a specific date.
  Future<List<SpotPrice>> getSpotPrices({DateTime? forDate}) async {
    try {
      var query = _supabase.from('spot_prices').select();

      if (forDate != null) {
        query =
            query.eq('fetch_date', forDate.toIso8601String().split('T')[0]);
      }

      final response =
          await query.order('fetch_timestamp', ascending: false);

      return (response as List)
          .map((json) => SpotPrice.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching spot prices: $e');
      return [];
    }
  }

  /// Saves a single spot price record.
  /// Returns (saved: SpotPrice, wasDuplicate: false) on insert,
  /// or (saved: null, wasDuplicate: true) if an exact duplicate already exists.
  Future<({SpotPrice? saved, bool wasDuplicate})> saveSpotPrice({
    required String metalType,
    required double price,
    required String sourceType,
    required String source,
    String? retailerId,
    String status = 'success',
    String? error,
    DateTime? fetchTimestamp,
  }) async {
    try {
      final now = (fetchTimestamp ?? DateTime.now()).toUtc();
      final today = DateTime.utc(now.year, now.month, now.day);
      final timestampStr = now.toIso8601String();

      // Dedup: skip if an exact duplicate already exists.
      final existing = await _supabase
          .from('spot_prices')
          .select('id')
          .eq('user_id', _userId)
          .eq('metal_type', metalType)
          .eq('price', price)
          .eq('source_type', sourceType)
          .eq('source', source)
          .eq('fetch_timestamp', timestampStr)
          .maybeSingle();

      if (existing != null) return (saved: null, wasDuplicate: true);

      final response = await _supabase
          .from('spot_prices')
          .insert({
            'user_id': _userId,
            'metal_type': metalType,
            'price': price,
            'source_type': sourceType,
            'source': source,
            'retailer_id': retailerId,
            'fetch_date': today.toIso8601String().split('T')[0],
            'fetch_timestamp': timestampStr,
            'status': status,
            'error': error,
          })
          .select()
          .single();

      return (saved: SpotPrice.fromJson(response), wasDuplicate: false);
    } catch (e) {
      debugPrint('Error saving spot price for $metalType: $e');
      rethrow;
    }
  }
}
