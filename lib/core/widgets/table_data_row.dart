// lib/core/widgets/table_data_row.dart

import 'package:flutter/material.dart';

/// A data row in a card-based table with standard padding and a bottom
/// separator line.
///
/// Wrap the row's cell widgets in a [Row] and pass them as [children].
/// The separator is drawn via a bottom border at 15% opacity of
/// [cs.outlineVariant] — consistent across every table in the app.
class TableDataRow extends StatelessWidget {
  final List<Widget> children;

  const TableDataRow({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(children: children),
    );
  }
}
