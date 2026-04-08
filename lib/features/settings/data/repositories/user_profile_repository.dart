import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:metal_tracker/features/settings/data/models/user_profile_model.dart';

class UserProfileRepository {
  final SupabaseClient _supabase;

  UserProfileRepository(this._supabase);

  String get _userId => _supabase.auth.currentUser!.id;

  /// Returns true if a profile row exists for the current user.
  Future<bool> profileExists() async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('id')
          .eq('id', _userId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      debugPrint('Error checking profile existence: $e');
      return false;
    }
  }

  /// Fetches the current user's profile. Returns null if not found.
  Future<UserProfile?> getProfile() async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', _userId)
          .maybeSingle();
      if (response == null) return null;
      return UserProfile.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  /// Creates or updates the current user's profile.
  Future<UserProfile?> upsertProfile({
    required String username,
    String? phone,
  }) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .upsert({
            'id': _userId,
            'username': username,
            'phone': phone,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      return UserProfile.fromJson(response);
    } catch (e) {
      debugPrint('Error upserting user profile: $e');
      rethrow;
    }
  }

  /// Updates mutable profile fields. Does not touch is_admin or status.
  Future<UserProfile?> updateProfile({
    String? username,
    String? phone,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (username != null) updates['username'] = username;
      if (phone != null) updates['phone'] = phone;

      final response = await _supabase
          .from('user_profiles')
          .update(updates)
          .eq('id', _userId)
          .select()
          .single();
      return UserProfile.fromJson(response);
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  // ── Admin methods ────────────────────────────────────────────────────────────

  /// Returns all user profiles with the given status. Admin only.
  Future<List<UserProfile>> getUsersByStatus(String status) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('status', status)
          .order('created_at');
      return (response as List).map((e) => UserProfile.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching users by status: $e');
      rethrow;
    }
  }

  /// Updates a user's approval status. Admin only.
  Future<void> updateUserStatus(String userId, String status) async {
    try {
      await _supabase
          .from('user_profiles')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      debugPrint('Error updating user status: $e');
      rethrow;
    }
  }
}
