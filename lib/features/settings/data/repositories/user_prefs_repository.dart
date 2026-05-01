import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:metal_tracker/core/utils/time_service.dart';
import 'package:metal_tracker/features/settings/data/models/user_prefs_models.dart';
import 'package:metal_tracker/features/settings/data/models/user_analytics_settings_model.dart';
import 'package:metal_tracker/features/settings/data/models/user_retailer_pref_model.dart';
import 'package:metal_tracker/features/settings/data/models/user_metaltype_pref_model.dart';

class UserPrefsRepository {
  final SupabaseClient _supabase;

  UserPrefsRepository(this._supabase);

  String get _userId => _supabase.auth.currentUser!.id;

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

  // ── User Retailer Prefs ─────────────────────────────────────────────────────

  Future<List<UserRetailerPref>> getUserRetailerPrefs() async {
    try {
      final response = await _supabase
          .from('user_retailer_prefs')
          .select('*, retailers(name, retailer_abbr)')
          .eq('user_id', _userId)
          .order('created_at');
      return (response as List)
          .map((json) => UserRetailerPref.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching user retailer prefs: $e');
      return [];
    }
  }

  Future<void> setUserRetailerPrefs(List<String> retailerIds) async {
    try {
      await _supabase
          .from('user_retailer_prefs')
          .delete()
          .eq('user_id', _userId);
      if (retailerIds.isEmpty) return;
      await _supabase.from('user_retailer_prefs').insert(
            retailerIds
                .map((id) => {'user_id': _userId, 'retailer_id': id})
                .toList(),
          );
    } catch (e) {
      debugPrint('Error setting user retailer prefs: $e');
      rethrow;
    }
  }

  // ── User Metaltype Prefs ────────────────────────────────────────────────────

  Future<List<UserMetaltypePref>> getUserMetaltypePrefs() async {
    try {
      final response = await _supabase
          .from('user_metaltype_prefs')
          .select('*, metal_types(name)')
          .eq('user_id', _userId)
          .order('created_at');
      return (response as List)
          .map((json) => UserMetaltypePref.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching user metaltype prefs: $e');
      return [];
    }
  }

  Future<void> setUserMetaltypePrefs(List<String> metalTypeIds) async {
    try {
      await _supabase
          .from('user_metaltype_prefs')
          .delete()
          .eq('user_id', _userId);
      if (metalTypeIds.isEmpty) return;
      await _supabase.from('user_metaltype_prefs').insert(
            metalTypeIds
                .map((id) => {'user_id': _userId, 'metal_type_id': id})
                .toList(),
          );
    } catch (e) {
      debugPrint('Error setting user metaltype prefs: $e');
      rethrow;
    }
  }

  // ── Analytics Settings ──────────────────────────────────────────────────────

  Future<UserAnalyticsSettings> getAnalyticsSettings() async {
    try {
      final response = await _supabase
          .from('user_analytics_prefs')
          .select()
          .eq('user_id', _userId)
          .maybeSingle();
      if (response == null) return UserAnalyticsSettings.defaults(_userId);
      return UserAnalyticsSettings.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching analytics prefs: $e');
      return UserAnalyticsSettings.defaults(_userId);
    }
  }

  Future<UserAnalyticsSettings> upsertAnalyticsSettings(
    UserAnalyticsSettings settings,
  ) async {
    try {
      final response = await _supabase
          .from('user_analytics_prefs')
          .upsert(settings.toJson())
          .select()
          .single();
      return UserAnalyticsSettings.fromJson(response);
    } catch (e) {
      debugPrint('Error upserting analytics prefs: $e');
      rethrow;
    }
  }
}
