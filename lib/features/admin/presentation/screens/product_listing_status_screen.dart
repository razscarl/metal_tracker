// lib/features/admin/presentation/screens/product_listing_status_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/core/widgets/app_scaffold.dart';
import 'package:metal_tracker/features/admin/presentation/providers/admin_providers.dart';
import 'package:metal_tracker/features/product_listings/data/models/product_listing_status_model.dart';

class ProductListingStatusScreen extends ConsumerWidget {
  const ProductListingStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusesAsync =
        ref.watch(productListingStatusesNotifierProvider);

    return AppScaffold(
      title: 'Listing Statuses',
      actions: [
        IconButton(
          icon: const Icon(Icons.add, color: AppColors.primaryGold),
          onPressed: () => _showAddSheet(context, ref),
          tooltip: 'Add status rule',
        ),
      ],
      body: statusesAsync.when(
        data: (statuses) {
          if (statuses.isEmpty) {
            return const Center(
              child: Text(
                'No status rules defined.\nTap + to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: statuses.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.backgroundDark),
            itemBuilder: (context, index) =>
                _StatusRuleRow(rule: statuses[index]),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGold),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style:
                  const TextStyle(color: AppColors.lossRed, fontSize: 13)),
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _AddRuleSheet(ref: ref),
    );
  }
}

// ── Status rule row ────────────────────────────────────────────────────────────

class _StatusRuleRow extends ConsumerWidget {
  final ProductListingStatus rule;

  const _StatusRuleRow({required this.rule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(rule.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.lossRed,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.backgroundCard,
            title: const Text('Delete rule?',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 15)),
            content: Text(
              'Remove mapping for "${rule.capturedStatus}"?',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete',
                    style: TextStyle(color: AppColors.lossRed)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref
            .read(productListingStatusesNotifierProvider.notifier)
            .deleteRule(rule.id);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: AppColors.backgroundCard,
        child: Row(
          children: [
            // Active toggle
            Switch(
              value: rule.isActive,
              onChanged: (val) => ref
                  .read(productListingStatusesNotifierProvider.notifier)
                  .toggleRule(rule.id, val),
              activeColor: AppColors.primaryGold,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          rule.capturedStatus,
                          style: TextStyle(
                            color: rule.isActive
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        rule.storedStatus,
                        style: const TextStyle(
                          color: AppColors.primaryGold,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rule.displayLabel,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add rule bottom sheet ──────────────────────────────────────────────────────

class _AddRuleSheet extends StatefulWidget {
  final WidgetRef ref;

  const _AddRuleSheet({required this.ref});

  @override
  State<_AddRuleSheet> createState() => _AddRuleSheetState();
}

class _AddRuleSheetState extends State<_AddRuleSheet> {
  final _capturedCtrl = TextEditingController();
  final _storedCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _capturedCtrl.dispose();
    _storedCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final captured = _capturedCtrl.text.trim();
    final stored = _storedCtrl.text.trim();
    final label = _labelCtrl.text.trim();
    if (captured.isEmpty || stored.isEmpty || label.isEmpty) return;

    setState(() => _saving = true);
    try {
      await widget.ref
          .read(productListingStatusesNotifierProvider.notifier)
          .addRule(
            capturedStatus: captured,
            storedStatus: stored,
            displayLabel: label,
          );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Status Rule',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _field(_capturedCtrl, 'Captured status (raw, e.g. "out of stock")'),
          const SizedBox(height: 10),
          _field(_storedCtrl, 'Stored status (e.g. "out_of_stock")'),
          const SizedBox(height: 10),
          _field(_labelCtrl, 'Display label (e.g. "Out of Stock")'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: AppColors.textDark,
              ),
              child: _saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        filled: true,
        fillColor: AppColors.backgroundDark,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
