import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:metal_tracker/core/utils/time_service.dart';
import 'package:metal_tracker/features/admin/data/models/automation_config_model.dart';
import 'package:metal_tracker/features/admin/data/models/automation_job_model.dart';
import 'package:metal_tracker/features/admin/data/models/automation_schedule_model.dart';

class AutomationRepository {
  final SupabaseClient _supabase;

  AutomationRepository(this._supabase);

  // ── Config ───────────────────────────────────────────────────────────────

  Future<AutomationConfig?> getConfig() async {
    try {
      final response = await _supabase
          .from('automation_config')
          .select()
          .limit(1)
          .maybeSingle();
      return response != null ? AutomationConfig.fromJson(response) : null;
    } catch (e) {
      debugPrint('Error fetching automation config: $e');
      return null;
    }
  }

  Future<void> updateConfig(String id,
      {String? timezone, bool? enabled}) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': TimeService.toUtcString(DateTime.now()),
        if (timezone != null) 'timezone': timezone,
        if (enabled != null) 'enabled': enabled,
      };
      await _supabase.from('automation_config').update(updates).eq('id', id);
    } catch (e) {
      debugPrint('Error updating automation config: $e');
      rethrow;
    }
  }

  // ── Schedules ────────────────────────────────────────────────────────────

  Future<List<AutomationSchedule>> getSchedules() async {
    try {
      final response = await _supabase
          .from('automation_schedules')
          .select()
          .order('scrape_type');
      return (response as List)
          .map((json) => AutomationSchedule.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching automation schedules: $e');
      return [];
    }
  }

  Future<void> updateSchedule(String id,
      {List<String>? runTimes, bool? enabled}) async {
    try {
      final updates = <String, dynamic>{
        if (runTimes != null) 'run_times': runTimes,
        if (enabled != null) 'enabled': enabled,
      };
      await _supabase
          .from('automation_schedules')
          .update(updates)
          .eq('id', id);
    } catch (e) {
      debugPrint('Error updating automation schedule: $e');
      rethrow;
    }
  }

  // ── Jobs ─────────────────────────────────────────────────────────────────

  Future<List<AutomationJob>> getJobs({
    String? jobType,
    String? status,
    int limit = 100,
  }) async {
    try {
      var query = _supabase.from('automation_jobs').select();
      if (jobType != null) query = query.eq('job_type', jobType);
      if (status != null) query = query.eq('status', status);

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return (response as List)
          .map((json) => AutomationJob.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching automation jobs: $e');
      return [];
    }
  }

  Future<List<AutomationJob>> getFailedJobs({int limit = 50}) async {
    try {
      final response = await _supabase
          .from('automation_jobs')
          .select()
          .eq('status', JobStatus.failed)
          .order('created_at', ascending: false)
          .limit(limit);
      return (response as List)
          .map((json) => AutomationJob.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching failed automation jobs: $e');
      return [];
    }
  }

  /// Inserts a new job record and returns it with the generated id.
  /// Used by Flutter notifiers to log manual scrapes.
  Future<AutomationJob?> insertJob(AutomationJob job) async {
    try {
      final response = await _supabase
          .from('automation_jobs')
          .insert(job.toInsertJson())
          .select()
          .single();
      return AutomationJob.fromJson(response);
    } catch (e) {
      debugPrint('Error inserting automation job: $e');
      return null;
    }
  }

  /// Updates an existing job (e.g. marking running → success/failed).
  /// Used by Flutter notifiers after a manual scrape completes.
  Future<void> updateJob(
    String id, {
    String? status,
    DateTime? startedAt,
    DateTime? completedAt,
    Map<String, dynamic>? errorLog,
    Map<String, dynamic>? resultSummary,
  }) async {
    try {
      final updates = <String, dynamic>{
        if (status != null) 'status': status,
        if (startedAt != null) 'started_at': TimeService.toUtcString(startedAt),
        if (completedAt != null) 'completed_at': TimeService.toUtcString(completedAt),
        if (errorLog != null) 'error_log': errorLog,
        if (resultSummary != null) 'result_summary': resultSummary,
      };
      await _supabase.from('automation_jobs').update(updates).eq('id', id);
    } catch (e) {
      debugPrint('Error updating automation job: $e');
      rethrow;
    }
  }
}
