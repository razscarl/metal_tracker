import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/features/admin/data/models/change_request_model.dart';
import 'package:metal_tracker/features/admin/presentation/providers/admin_providers.dart';

/// Shows a modal bottom sheet for submitting a change request.
///
/// [requestType]       — one of the [ChangeRequestType] constants.
/// [prefillSubject]    — optional initial text for the subject field.
/// [prefillDescription]— optional initial text for the description field.
Future<void> showChangeRequestDialog(
  BuildContext context, {
  required String requestType,
  String? prefillSubject,
  String? prefillDescription,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.backgroundCard,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _ChangeRequestSheet(
      requestType: requestType,
      prefillSubject: prefillSubject,
      prefillDescription: prefillDescription,
    ),
  );
}

class _ChangeRequestSheet extends ConsumerStatefulWidget {
  final String requestType;
  final String? prefillSubject;
  final String? prefillDescription;

  const _ChangeRequestSheet({
    required this.requestType,
    this.prefillSubject,
    this.prefillDescription,
  });

  @override
  ConsumerState<_ChangeRequestSheet> createState() =>
      _ChangeRequestSheetState();
}

class _ChangeRequestSheetState extends ConsumerState<_ChangeRequestSheet> {
  late final TextEditingController _subjectController;
  late final TextEditingController _descriptionController;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _subjectController =
        TextEditingController(text: widget.prefillSubject ?? '');
    _descriptionController =
        TextEditingController(text: widget.prefillDescription ?? '');
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final subject = _subjectController.text.trim();
    if (subject.isEmpty) {
      setState(() => _error = 'Please enter a subject.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final repo = ref.read(changeRequestRepositoryProvider);
      await repo.submitRequest(
        requestType: widget.requestType,
        subject: subject,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );
      // Invalidate pending count badge
      ref.invalidate(pendingRequestCountProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request submitted — an admin will review it soon.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = 'Could not submit request. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            ChangeRequestType.displayName(widget.requestType),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your request will be reviewed by an administrator.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _subjectController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Subject *',
              prefixIcon: Icon(Icons.subject),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Details (optional)',
              prefixIcon: Icon(Icons.notes),
              alignLabelWithHint: true,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textDark,
                    ),
                  )
                : const Text('Submit Request'),
          ),
        ],
      ),
    );
  }
}
