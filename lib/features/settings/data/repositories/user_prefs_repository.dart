import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:metal_tracker/core/utils/time_service.dart';
import 'package:metal_tracker/features/settings/data/models/user_prefs_models.dart';
import 'package:metal_tracker/features/settings/data/models/user_analytics_settings_model.dart';
import 'package:metal_tracker/features/settings/data/models/user_retailer_model.dart';

class UserPrefsRepository {
  final SupabaseClient _supabase;

  UserPrefsRepository(this._supabase);

  String get _userId => _supabase.auth.currentUser!.id;

  // ── Live Price Prefs ────────────────────────────────────────────────────────

  Future<List<UserLivePricePref>> getLivePricePrefs() async {
    try {
      final response = await _supabase
          .from('user_live_price_prefs')
          .select()
          .eq('user_id', _userId)
          .eq('is_active', true)
          .order('retailer_id');
      return (response as List)
          .map((json) => UserLivePricePref.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching live price prefs: $e');
      return [];
    }
  }

  /// Replaces all live price prefs for the current user.
  Future<void> setLivePricePrefs(List<UserLivePricePref> prefs) async {
    try {
      await _supabase
          .from('user_live_price_prefs')
          .delete()
          .eq('user_id', _userId);

      if (prefs.isEmpty) return;

      await _supabase.from('user_live_price_prefs').insert(
            prefs.map((p) => p.toJson()).toList(),
          );
    } catch (e) {
      debugPrint('Error setting live price prefs: $e');
      rethrow;
    }
  }

  // ── Local Spot Prefs ────────────────────────────────────────────────────────

  Future<List<UserLocalSpotPref>> getLocalSpotPrefs() async {
    try {
      final response = await _supabase
          .from('user_local_spot_prefs')
          .select()
          .eq('user_id', _userId)
          .eq('is_active', true)
          .order('retailer_id');
      return (response as List)
          .map((json) => UserLocalSpotPref.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching local spot prefs: $e');
      return [];
    }
  }

  /// Replaces all local spot prefs for the current user.
  Future<void> setLocalSpotPrefs(List<UserLocalSpotPref> prefs) async {
    try {
      await _supabase
          .from('user_local_spot_prefs')
          .delete()
          .eq('user_id', _userId);

      if (prefs.isEmpty) return;

      await _supabase.from('user_local_spot_prefs').insert(
            prefs.map((p) => p.toJson()).toList(),
          );
    } catch (e) {
      debugPrint('Error setting local spot prefs: $e');
      rethrow;
    }
  }

  // ── Global Spot Prefs ───────────────────────────────────────────────────────

  Future<List<UserGlobalSpotPref>> getGlobalSpotPrefs() async {
    try {
      final response = await _supabase
          .from('user_global_spot_prefs')
          .select()
          .eq('user_id', _userId)
          .order('created_at');
      return (response as List)
          .map((json) => UserGlobalSpotPref.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching global spot prefs: $e');
      return [];
    }
  }

  /// Returns the single active global spot pref for the current user, or null.
  Future<UserGlobalSpotPref?> getActiveGlobalSpotPref() async {
    try {
      final response = await _supabase
          .from('user_global_spot_prefs')
          .select()
          .eq('user_id', _userId)
          .eq('is_active', true)
          .order('created_at')
          .limit(1)
          .maybeSingle();
      if (response == null) return null;
      return UserGlobalSpotPref.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching active global spot pref: $e');
      return null;
    }
  }

  Future<UserGlobalSpotPref?> upsertGlobalSpotPref(
    UserGlobalSpotPref pref,
  ) async {
    try {
      final data = pref.toJson()
        ..['updated_at'] = TimeService.toUtcString(DateTime.now());
      final response = await _supabase
          .from('user_global_spot_prefs')
          .upsert(data)
          .select()
          .single();
      return UserGlobalSpotPref.fromJson(response);
    } catch (e) {
      debugPrint('Error upserting global spot pref: $e');
      rethrow;
    }
  }

  Future<void> deleteGlobalSpotPref(String id) async {
    try {
      await _supabase
          .from('user_global_spot_prefs')
          .delete()
          .eq('id', id)
          .eq('user_id', _userId);
    } catch (e) {
      debugPrint('Error deleting global spot pref: $e');
      rethrow;
    }
  }

  // ── User Metal Types ────────────────────────────────────────────────────────

  Future<List<String>> getUserMetalTypes() async {
    try {
      final response = await _supabase
          .from('user_metal_types')
          .select('metal_type')
          .eq('user_id', _userId);
      return (response as List)
          .map((row) => row['metal_type'] as String)
          .toList();
    } catch (e) {
      debugPrint('Error fetching user metal types: $e');
      return [];
    }
  }

  Future<void> setUserMetalTypes(List<String> metals) async {
    try {
      await _supabase
          .from('user_metal_types')
          .delete()
          .eq('user_id', _userId);
      if (metals.isEmpty) return;
      await _supabase.from('user_metal_types').insert(
            metals
                .map((m) => {'user_id': _userId, 'metal_type': m})
                .toList(),
          );
    } catch (e) {
      debugPrint('Error setting user metal types: $e');
      rethrow;
    }
  }

  // ── User Retailers ──────────────────────────────────────────────────────────

  Future<List<UserRetailer>> getUserRetailers() async {
    try {
      final response = await _supabase
          .from('user_retailers')
          .select('*, retailers(name)')
          .eq('user_id', _userId)
          .order('created_at');
      return (response as List)
          .map((json) => UserRetailer.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching user retailers: $e');
      return [];
    }
  }

  Future<void> setUserRetailers(List<String> retailerIds) async {
    try {
      await _supabase
          .from('user_retailers')
          .delete()
          .eq('user_id', _userId);
      if (retailerIds.isEmpty) return;
      await _supabase.from('user_retailers').insert(
            retailerIds
                .map((id) => {'user_id': _userId, 'retailer_id': id})
                .toList(),
          );
    } catch (e) {
      debugPrint('Error setting user retailers: $e');
      rethrow;
    }
  }

  // ── Analytics Settings ──────────────────────────────────────────────────────

  Future<UserAnalyticsSettings> getAnalyticsSettings() async {
    try {
      final response = await _supabase
          .from('user_analytics_settings')
          .select()
          .eq('user_id', _userId)
          .maybeSingle();
      if (response == null) return UserAnalyticsSettings.defaults(_userId);
      return UserAnalyticsSettings.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching analytics settings: $e');
      return UserAnalyticsSettings.defaults(_userId);
    }
  }

  Future<UserAnalyticsSettings> upsertAnalyticsSettings(
    UserAnalyticsSettings settings,
  ) async {
    try {
      final response = await _supabase
          .from('user_analytics_settings')
          .upsert(settings.toJson())
          .select()
          .single();
      return UserAnalyticsSettings.fromJson(response);
    } catch (e) {
      debugPrint('Error upserting analytics settings: $e');
      rethrow;
    }
  }
}
