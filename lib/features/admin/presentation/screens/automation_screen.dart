// lib/features/admin/presentation/screens/automation_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/utils/time_service.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/features/admin/data/models/automation_job_model.dart';
import 'package:metal_tracker/features/admin/data/models/automation_schedule_model.dart';
import 'package:metal_tracker/features/admin/presentation/providers/admin_providers.dart';

class AutomationScreen extends ConsumerStatefulWidget {
  const AutomationScreen({super.key});

  @override
  ConsumerState<AutomationScreen> createState() => _AutomationScreenState();
}

class _AutomationScreenState extends ConsumerState<AutomationScreen> {
  String? _filterType;
  String? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(automationConfigNotifierProvider);
    final schedulesAsync = ref.watch(automationSchedulesNotifierProvider);
    final jobsAsync = ref.watch(automationJobsNotifierProvider);

    return AppScaffold(
      title: 'Automation',
      actions: [
        IconButton(
          icon: const Icon(Icons.add, color: AppColors.primaryGold),
          tooltip: 'Add scheduled time',
          onPressed: () {
            final schedules =
                ref.read(automationSchedulesNotifierProvider).valueOrNull ?? [];
            if (schedules.isEmpty) return;
            _showAddTimeDialog(context, schedules);
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.primaryGold),
          tooltip: 'Refresh',
          onPressed: () {
            ref.invalidate(automationConfigNotifierProvider);
            ref.invalidate(automationSchedulesNotifierProvider);
            ref.read(automationJobsNotifierProvider.notifier).refresh();
          },
        ),
      ],
      body: RefreshIndicator(
        color: AppColors.primaryGold,
        backgroundColor: AppColors.backgroundCard,
        onRefresh: () async {
          ref.invalidate(automationConfigNotifierProvider);
          ref.invalidate(automationSchedulesNotifierProvider);
          await ref.read(automationJobsNotifierProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Config ───────────────────────────────────────────────────────
            const _SectionHeader(label: 'Configuration'),
            const SizedBox(height: 8),
            configAsync.when(
              data: (config) => config == null
                  ? const _ErrorTile(message: 'No automation config found.')
                  : _ConfigCard(config: config),
              loading: () => const _LoadingTile(),
              error: (e, _) => _ErrorTile(message: e.toString()),
            ),

            const SizedBox(height: 20),

            // ── Schedules ────────────────────────────────────────────────────
            const _SectionHeader(label: 'Schedules'),
            const SizedBox(height: 8),
            schedulesAsync.when(
              data: (schedules) => schedules.isEmpty
                  ? const _ErrorTile(message: 'No schedules configured.')
                  : _SchedulesCard(schedules: schedules),
              loading: () => const _LoadingTile(),
              error: (e, _) => _ErrorTile(message: e.toString()),
            ),

            const SizedBox(height: 20),

            // ── Job History ──────────────────────────────────────────────────
            const _SectionHeader(label: 'Job History'),
            const SizedBox(height: 8),
            _FilterRow(
              selectedType: _filterType,
              selectedStatus: _filterStatus,
              onTypeChanged: (v) => setState(() => _filterType = v),
              onStatusChanged: (v) => setState(() => _filterStatus = v),
            ),
            const SizedBox(height: 8),
            jobsAsync.when(
              data: (jobs) {
                final filtered = _applyFilters(jobs);
                if (filtered.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No jobs match the selected filters.',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  );
                }
                return Column(
                  children: filtered
                      .map((job) => _JobRow(
                            job: job,
                            onTap: () => _showJobDetail(context, job),
                          ))
                      .toList(),
                );
              },
              loading: () => const _LoadingTile(),
              error: (e, _) => _ErrorTile(message: e.toString()),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  List<AutomationJob> _applyFilters(List<AutomationJob> jobs) {
    return jobs.where((j) {
      if (_filterType != null && j.jobType != _filterType) return false;
      if (_filterStatus != null && j.status != _filterStatus) return false;
      return true;
    }).toList();
  }

  void _showJobDetail(BuildContext context, AutomationJob job) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _JobDetailSheet(job: job),
    );
  }

  void _showAddTimeDialog(
      BuildContext context, List<AutomationSchedule> schedules) {
    String selectedType = schedules.first.scrapeType;
    final timeController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: const Text(
            'Add Scheduled Time',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Job type selector
                const Text(
                  'Job Type',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedType,
                      isExpanded: true,
                      dropdownColor: AppColors.backgroundCard,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 13),
                      items: schedules
                          .map((s) => DropdownMenuItem(
                                value: s.scrapeType,
                                child: Text(s.displayName),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedType = val);
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Time input
                const Text(
                  'Time (HH:MM)',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: timeController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d:]')),
                    LengthLimitingTextInputFormatter(5),
                  ],
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '10:00',
                    hintStyle: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                    filled: true,
                    fillColor: AppColors.backgroundDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: AppColors.primaryGold),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  validator: (v) => _validateTime(v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final time = timeController.text.trim();
                final schedule = schedules
                    .firstWhere((s) => s.scrapeType == selectedType);
                if (!schedule.runTimes.contains(time)) {
                  final updated = [...schedule.runTimes, time]..sort();
                  ref
                      .read(automationSchedulesNotifierProvider.notifier)
                      .updateRunTimes(schedule.id, updated);
                }
                Navigator.pop(dialogContext);
              },
              child: const Text('Add',
                  style: TextStyle(
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  static String? _validateTime(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter a time';
    final parts = value.trim().split(':');
    if (parts.length != 2) return 'Use HH:MM format';
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return 'Use HH:MM format';
    if (h < 0 || h > 23) return 'Hour must be 00–23';
    if (m < 0 || m > 59) return 'Minute must be 00–59';
    return null;
  }
}

// ─── Config Card ──────────────────────────────────────────────────────────────

class _ConfigCard extends ConsumerWidget {
  final dynamic config; // AutomationConfig

  const _ConfigCard({required this.config});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_outlined,
                  color: AppColors.primaryGold, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Automated Scraping',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: config.enabled as bool,
                activeThumbColor: AppColors.gainGreen,
                onChanged: (val) => ref
                    .read(automationConfigNotifierProvider.notifier)
                    .toggleEnabled(val),
              ),
            ],
          ),
          const Divider(height: 16, color: Colors.white10),
          Row(
            children: [
              const Icon(Icons.public_outlined,
                  color: AppColors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Timezone: ${config.timezone}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Schedules Card ──────────────────────────────────────────────────────────

class _SchedulesCard extends StatelessWidget {
  final List<AutomationSchedule> schedules;

  const _SchedulesCard({required this.schedules});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          for (int i = 0; i < schedules.length; i++) ...[
            _ScheduleRow(schedule: schedules[i]),
            if (i < schedules.length - 1)
              const Divider(height: 1, color: Colors.white10),
          ],
        ],
      ),
    );
  }
}

// ─── Schedule Row (editable) ──────────────────────────────────────────────────

class _ScheduleRow extends ConsumerStatefulWidget {
  final AutomationSchedule schedule;

  const _ScheduleRow({required this.schedule});

  @override
  ConsumerState<_ScheduleRow> createState() => _ScheduleRowState();
}

class _ScheduleRowState extends ConsumerState<_ScheduleRow> {
  int? _editingIndex;
  late TextEditingController _editController;
  late FocusNode _editFocus;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController();
    _editFocus = FocusNode();
    _editFocus.addListener(() {
      // Cancel edit when focus is lost without confirming
      if (!_editFocus.hasFocus && _editingIndex != null) {
        setState(() => _editingIndex = null);
      }
    });
  }

  @override
  void dispose() {
    _editController.dispose();
    _editFocus.dispose();
    super.dispose();
  }

  void _startEdit(int index) {
    setState(() {
      _editingIndex = index;
      _editController.text = widget.schedule.runTimes[index];
      _editController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _editController.text.length,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _editFocus.requestFocus();
    });
  }

  void _confirmEdit(int index) {
    final raw = _editController.text.trim();
    if (_validateTime(raw) != null) return; // invalid — do nothing
    final times = List<String>.from(widget.schedule.runTimes);
    times[index] = raw;
    times.sort();
    ref
        .read(automationSchedulesNotifierProvider.notifier)
        .updateRunTimes(widget.schedule.id, times);
    setState(() => _editingIndex = null);
  }

  void _deleteTime(int index) {
    final times = List<String>.from(widget.schedule.runTimes)..removeAt(index);
    ref
        .read(automationSchedulesNotifierProvider.notifier)
        .updateRunTimes(widget.schedule.id, times);
    setState(() => _editingIndex = null);
  }

  static String? _validateTime(String value) {
    if (value.isEmpty) return 'required';
    final parts = value.split(':');
    if (parts.length != 2) return 'invalid';
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return 'invalid';
    if (h < 0 || h > 23) return 'invalid';
    if (m < 0 || m > 59) return 'invalid';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final schedule = widget.schedule;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.displayName,
                  style: TextStyle(
                    color: schedule.enabled
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                if (schedule.runTimes.isEmpty)
                  const Text(
                    'No times set — tap + to add one.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  )
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (int i = 0; i < schedule.runTimes.length; i++)
                        _editingIndex == i
                            ? _buildEditChip(i)
                            : _buildDisplayChip(i, schedule),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: schedule.enabled,
            activeThumbColor: AppColors.gainGreen,
            onChanged: (val) => ref
                .read(automationSchedulesNotifierProvider.notifier)
                .toggleSchedule(schedule.id, enabled: val),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayChip(int index, AutomationSchedule schedule) {
    final active = schedule.enabled;
    return Container(
      decoration: BoxDecoration(
        color: active
            ? AppColors.primaryGold.withAlpha(25)
            : Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: active
              ? AppColors.primaryGold.withAlpha(70)
              : Colors.white12,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tappable time text → edit mode
          GestureDetector(
            onTap: () => _startEdit(index),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
              child: Text(
                schedule.runTimes[index],
                style: TextStyle(
                  color: active
                      ? AppColors.primaryGold
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          // Delete button
          GestureDetector(
            onTap: () => _deleteTime(index),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 6, 4),
              child: Icon(
                Icons.delete_outline,
                size: 14,
                color: active
                    ? AppColors.primaryGold.withAlpha(160)
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditChip(int index) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryGold.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primaryGold),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 52,
            child: TextField(
              controller: _editController,
              focusNode: _editFocus,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d:]')),
                LengthLimitingTextInputFormatter(5),
              ],
              style: const TextStyle(
                color: AppColors.primaryGold,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _confirmEdit(index),
            ),
          ),
          // Confirm button
          GestureDetector(
            onTap: () => _confirmEdit(index),
            child: const Padding(
              padding: EdgeInsets.fromLTRB(0, 4, 6, 4),
              child: Icon(
                Icons.check,
                size: 14,
                color: AppColors.gainGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Row ───────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final String? selectedType;
  final String? selectedStatus;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String?> onStatusChanged;

  const _FilterRow({
    required this.selectedType,
    required this.selectedStatus,
    required this.onTypeChanged,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'All Types',
                selected: selectedType == null,
                onTap: () => onTypeChanged(null),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Live Prices',
                selected: selectedType == ScrapeType.livePrices,
                onTap: () => onTypeChanged(ScrapeType.livePrices),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Local Spot',
                selected: selectedType == ScrapeType.localSpot,
                onTap: () => onTypeChanged(ScrapeType.localSpot),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Global Spot',
                selected: selectedType == ScrapeType.globalSpot,
                onTap: () => onTypeChanged(ScrapeType.globalSpot),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Listings',
                selected: selectedType == ScrapeType.productListings,
                onTap: () => onTypeChanged(ScrapeType.productListings),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'All Status',
                selected: selectedStatus == null,
                onTap: () => onStatusChanged(null),
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Success',
                selected: selectedStatus == JobStatus.success,
                onTap: () => onStatusChanged(JobStatus.success),
                color: AppColors.gainGreen,
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Failed',
                selected: selectedStatus == JobStatus.failed,
                onTap: () => onStatusChanged(JobStatus.failed),
                color: AppColors.lossRed,
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Running',
                selected: selectedStatus == JobStatus.running,
                onTap: () => onStatusChanged(JobStatus.running),
                color: AppColors.accentPlatinum,
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Pending',
                selected: selectedStatus == JobStatus.pending,
                onTap: () => onStatusChanged(JobStatus.pending),
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = AppColors.primaryGold,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(40) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ─── Job Row ──────────────────────────────────────────────────────────────────

class _JobRow extends StatelessWidget {
  final AutomationJob job;
  final VoidCallback onTap;

  const _JobRow({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(job.status);
    final statusIcon = _statusIcon(job.status);
    final typeLabel = ScrapeType.displayName(job.jobType);
    final triggerLabel = _triggerLabel(job.triggeredBy);
    final triggerIcon = _triggerIcon(job.triggeredBy);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        typeLabel,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (job.retailerName != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '· ${job.retailerName}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(triggerIcon,
                          size: 11, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        triggerLabel,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      if (job.attemptNumber > 1) ...[
                        const SizedBox(width: 6),
                        Text(
                          'attempt ${job.attemptNumber}',
                          style: const TextStyle(
                            color: AppColors.lossRed,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDate(job.createdAt ?? job.scheduledAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    job.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Color _statusColor(String status) => switch (status) {
        JobStatus.success => AppColors.gainGreen,
        JobStatus.failed => AppColors.lossRed,
        JobStatus.running => AppColors.accentPlatinum,
        _ => AppColors.textSecondary,
      };

  static IconData _statusIcon(String status) => switch (status) {
        JobStatus.success => Icons.check_circle_outline,
        JobStatus.failed => Icons.error_outline,
        JobStatus.running => Icons.sync,
        _ => Icons.schedule_outlined,
      };

  static String _triggerLabel(String trigger) => switch (trigger) {
        JobTrigger.manual => 'Manual',
        JobTrigger.retry => 'Retry',
        _ => 'Scheduler',
      };

  static IconData _triggerIcon(String trigger) => switch (trigger) {
        JobTrigger.manual => Icons.person_outline,
        JobTrigger.retry => Icons.refresh,
        _ => Icons.auto_mode,
      };

  static String _formatDate(DateTime dt) =>
      DateFormat(AppDateFormats.compact).format(dt.toLocal());
}

// ─── Job Detail Sheet ─────────────────────────────────────────────────────────

class _JobDetailSheet extends StatelessWidget {
  final AutomationJob job;

  const _JobDetailSheet({required this.job});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(job.status);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(_statusIcon(job.status), color: statusColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ScrapeType.displayName(job.jobType),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withAlpha(80)),
                  ),
                  child: Text(
                    job.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  _DetailRow(label: 'Retailer', value: job.retailerName ?? '—'),
                  _DetailRow(
                      label: 'Triggered By',
                      value: _triggerLabel(job.triggeredBy)),
                  _DetailRow(
                      label: 'Attempt', value: '#${job.attemptNumber}'),
                  _DetailRow(
                      label: 'Scheduled At',
                      value: _formatFull(job.scheduledAt)),
                  if (job.startedAt != null)
                    _DetailRow(
                        label: 'Started At',
                        value: _formatFull(job.startedAt!)),
                  if (job.completedAt != null)
                    _DetailRow(
                        label: 'Completed At',
                        value: _formatFull(job.completedAt!)),
                  if (job.parentJobId != null)
                    _DetailRow(
                        label: 'Parent Job', value: job.parentJobId!),
                  if (job.resultSummary != null &&
                      job.resultSummary!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Result Summary',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    _JsonBlock(data: job.resultSummary!),
                  ],
                  if (job.errorLog != null &&
                      job.errorLog!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Error Log',
                      style: TextStyle(
                          color: AppColors.lossRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    _JsonBlock(data: job.errorLog!, isError: true),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _statusColor(String status) => switch (status) {
        JobStatus.success => AppColors.gainGreen,
        JobStatus.failed => AppColors.lossRed,
        JobStatus.running => AppColors.accentPlatinum,
        _ => AppColors.textSecondary,
      };

  static IconData _statusIcon(String status) => switch (status) {
        JobStatus.success => Icons.check_circle_outline,
        JobStatus.failed => Icons.error_outline,
        JobStatus.running => Icons.sync,
        _ => Icons.schedule_outlined,
      };

  static String _triggerLabel(String trigger) => switch (trigger) {
        JobTrigger.manual => 'Manual',
        JobTrigger.retry => 'Retry',
        _ => 'Scheduler',
      };

  static String _formatFull(DateTime dt) =>
      DateFormat(AppDateFormats.full).format(dt.toLocal());
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _JsonBlock extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isError;

  const _JsonBlock({required this.data, this.isError = false});

  @override
  Widget build(BuildContext context) {
    final lines =
        data.entries.map((e) => '${e.key}: ${_format(e.value)}').join('\n');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isError
            ? AppColors.lossRed.withAlpha(15)
            : Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isError ? AppColors.lossRed.withAlpha(60) : Colors.white12,
        ),
      ),
      child: Text(
        lines,
        style: TextStyle(
          color: isError ? AppColors.lossRed : AppColors.textSecondary,
          fontSize: 11,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  String _format(dynamic value) {
    if (value is List) return value.join(', ');
    return value.toString();
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _LoadingTile extends StatelessWidget {
  const _LoadingTile();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryGold,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  final String message;

  const _ErrorTile({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lossRed.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.lossRed.withAlpha(60)),
      ),
      child: Text(message,
          style: const TextStyle(color: AppColors.lossRed, fontSize: 12)),
    );
  }
}
