import 'package:metal_tracker/core/utils/time_service.dart';

class AutomationJob {
  final String id;
  final String jobType;
  final String? retailerId;
  final String? retailerName;
  final DateTime scheduledAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String status;
  final int attemptNumber;
  final String? parentJobId;
  final String triggeredBy;
  final Map<String, dynamic>? errorLog;
  final Map<String, dynamic>? resultSummary;
  final DateTime? createdAt;

  const AutomationJob({
    required this.id,
    required this.jobType,
    this.retailerId,
    this.retailerName,
    required this.scheduledAt,
    this.startedAt,
    this.completedAt,
    required this.status,
    this.attemptNumber = 1,
    this.parentJobId,
    required this.triggeredBy,
    this.errorLog,
    this.resultSummary,
    this.createdAt,
  });

  factory AutomationJob.fromJson(Map<String, dynamic> json) {
    return AutomationJob(
      id: json['id'] as String,
      jobType: json['job_type'] as String,
      retailerId: json['retailer_id'] as String?,
      retailerName: json['retailer_name'] as String?,
      scheduledAt: TimeService.parseTimestamp(json['scheduled_at'] as String),
      startedAt: json['started_at'] != null
          ? TimeService.parseTimestamp(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? TimeService.parseTimestamp(json['completed_at'] as String)
          : null,
      status: json['status'] as String? ?? 'pending',
      attemptNumber: json['attempt_number'] as int? ?? 1,
      parentJobId: json['parent_job_id'] as String?,
      triggeredBy: json['triggered_by'] as String? ?? 'scheduler',
      errorLog: json['error_log'] as Map<String, dynamic>?,
      resultSummary: json['result_summary'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? TimeService.parseTimestamp(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'job_type': jobType,
        if (retailerId != null) 'retailer_id': retailerId,
        if (retailerName != null) 'retailer_name': retailerName,
        'scheduled_at': TimeService.toUtcString(scheduledAt),
        if (startedAt != null) 'started_at': TimeService.toUtcString(startedAt!),
        if (completedAt != null) 'completed_at': TimeService.toUtcString(completedAt!),
        'status': status,
        'attempt_number': attemptNumber,
        if (parentJobId != null) 'parent_job_id': parentJobId,
        'triggered_by': triggeredBy,
        if (errorLog != null) 'error_log': errorLog,
        if (resultSummary != null) 'result_summary': resultSummary,
      };
}

// Strongly-typed status constants
abstract class JobStatus {
  static const pending = 'pending';
  static const running = 'running';
  static const success = 'success';
  static const failed = 'failed';
}

// Strongly-typed triggered_by constants
abstract class JobTrigger {
  static const scheduler = 'scheduler';
  static const retry = 'retry';
  static const manual = 'manual';
}
