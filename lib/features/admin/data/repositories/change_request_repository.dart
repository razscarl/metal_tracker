import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:metal_tracker/features/admin/data/models/change_request_model.dart';

class ChangeRequestRepository {
  final SupabaseClient _supabase;

  ChangeRequestRepository(this._supabase);

  String get _userId => _supabase.auth.currentUser!.id;

  // ── User operations ─────────────────────────────────────────────────────────

  Future<ChangeRequest?> submitRequest({
    required String requestType,
    required String subject,
    String? description,
  }) async {
    try {
      final response = await _supabase
          .from('change_requests')
          .insert({
            'user_id': _userId,
            'request_type': requestType,
            'subject': subject,
            'description': description,
            'status': 'pending',
          })
          .select()
          .single();
      return ChangeRequest.fromJson(response);
    } catch (e) {
      debugPrint('Error submitting change request: $e');
      rethrow;
    }
  }

  Future<List<ChangeRequest>> getMyRequests() async {
    try {
      final response = await _supabase
          .from('change_requests')
          .select()
          .eq('user_id', _userId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((json) => ChangeRequest.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching my change requests: $e');
      return [];
    }
  }

  // ── Admin operations ────────────────────────────────────────────────────────

  Future<List<ChangeRequest>> getAllRequests({String? status}) async {
    try {
      var query = _supabase.from('change_requests').select();
      if (status != null) query = query.eq('status', status);
      final response =
          await query.order('created_at', ascending: false);
      return (response as List)
          .map((json) => ChangeRequest.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching all change requests: $e');
      return [];
    }
  }

  Future<int> getPendingCount() async {
    try {
      final response = await _supabase
          .from('change_requests')
          .select()
          .eq('status', 'pending');
      return (response as List).length;
    } catch (e) {
      debugPrint('Error fetching pending count: $e');
      return 0;
    }
  }

  Future<ChangeRequest?> updateRequest({
    required String id,
    required String status,
    String? adminNotes,
  }) async {
    try {
      final response = await _supabase
          .from('change_requests')
          .update({
            'status': status,
            'admin_notes': adminNotes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();
      return ChangeRequest.fromJson(response);
    } catch (e) {
      debugPrint('Error updating change request: $e');
      rethrow;
    }
  }
}
