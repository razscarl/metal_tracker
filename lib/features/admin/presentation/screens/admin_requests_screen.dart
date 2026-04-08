import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/features/admin/data/models/change_request_model.dart';
import 'package:metal_tracker/features/admin/presentation/providers/admin_providers.dart';

final _dateFmt = DateFormat('d MMM y HH:mm');

// ─── Status colours & labels ──────────────────────────────────────────────────

Color _statusColor(String status) {
  switch (status) {
    case 'pending':     return AppColors.primaryGold;
    case 'in_progress': return AppColors.accentPlatinum;
    case 'completed':   return AppColors.gainGreen;
    case 'rejected':    return AppColors.lossRed;
    default:            return AppColors.textSecondary;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'pending':     return 'Pending';
    case 'in_progress': return 'In Progress';
    case 'completed':   return 'Completed';
    case 'rejected':    return 'Rejected';
    default:            return status;
  }
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class AdminRequestsScreen extends ConsumerStatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  ConsumerState<AdminRequestsScreen> createState() =>
      _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends ConsumerState<AdminRequestsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    (label: 'All',         status: null),
    (label: 'Pending',     status: 'pending'),
    (label: 'In Progress', status: 'in_progress'),
    (label: 'Completed',   status: 'completed'),
    (label: 'Rejected',    status: 'rejected'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Change Requests',
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: AppColors.primaryGold,
            labelColor: AppColors.primaryGold,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs
                  .map((t) => _RequestList(statusFilter: t.status))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Request list per tab ─────────────────────────────────────────────────────

class _RequestList extends ConsumerWidget {
  final String? statusFilter;
  const _RequestList({this.statusFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync =
        ref.watch(adminChangeRequestsNotifierProvider(status: statusFilter));

    return RefreshIndicator(
      color: AppColors.primaryGold,
      onRefresh: () async => ref.invalidate(
          adminChangeRequestsNotifierProvider(status: statusFilter)),
      child: requestsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGold),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.error)),
        ),
        data: (requests) {
          if (requests.isEmpty) {
            return const Center(
              child: Text(
                'No requests',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) => _RequestCard(request: requests[i]),
          );
        },
      ),
    );
  }
}

// ─── Request card ─────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final ChangeRequest request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _RequestDetailScreen(request: request),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Type badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    ChangeRequestType.displayName(request.requestType),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ),
                const Spacer(),
                // Status pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        _statusColor(request.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _statusLabel(request.status),
                    style: TextStyle(
                      color: _statusColor(request.status),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              request.subject,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (request.description != null &&
                request.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                request.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              request.createdAt != null
                  ? _dateFmt.format(request.createdAt!)
                  : '',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Request detail screen ───────────────────────────────────────────────────

class _RequestDetailScreen extends ConsumerStatefulWidget {
  final ChangeRequest request;
  const _RequestDetailScreen({required this.request});

  @override
  ConsumerState<_RequestDetailScreen> createState() =>
      _RequestDetailScreenState();
}

class _RequestDetailScreenState
    extends ConsumerState<_RequestDetailScreen> {
  late String _status;
  late final TextEditingController _notesController;
  bool _saving = false;

  static const _statuses = [
    'pending',
    'in_progress',
    'completed',
    'rejected',
  ];

  @override
  void initState() {
    super.initState();
    _status = widget.request.status;
    _notesController =
        TextEditingController(text: widget.request.adminNotes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(adminChangeRequestsNotifierProvider().notifier)
          .updateRequest(
            id: widget.request.id!,
            status: _status,
            adminNotes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request updated'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    return AppScaffold(
      title: 'Request Detail',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Type & date
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDark,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    ChangeRequestType.displayName(req.requestType),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  req.createdAt != null ? _dateFmt.format(req.createdAt!) : '',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Subject
            Text(
              req.subject,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (req.description != null && req.description!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                req.description!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),
            // Status dropdown
            const Text(
              'STATUS',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _status,
              dropdownColor: AppColors.backgroundCard,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              items: _statuses
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(
                          _statusLabel(s),
                          style: TextStyle(color: _statusColor(s)),
                        ),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _status = v);
              },
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.flag_outlined),
              ),
            ),
            const SizedBox(height: 16),
            // Admin notes
            const Text(
              'ADMIN NOTES',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Optional notes for the requester...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textDark,
                      ),
                    )
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
