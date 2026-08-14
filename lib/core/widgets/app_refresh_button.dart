// lib/core/widgets/app_refresh_button.dart

import 'package:flutter/material.dart';

/// Standard refresh icon button used across all screens.
///
/// Renders an [Icons.refresh] button in [cs.onSurfaceVariant] colour.
/// Use via [AppScaffold.onRefresh] or place standalone where needed.
class AppRefreshButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double size;

  const AppRefreshButton({
    super.key,
    this.onPressed,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: Icon(Icons.refresh, size: size, color: cs.onSurfaceVariant),
      tooltip: 'Refresh',
      onPressed: onPressed,
    );
  }
}
