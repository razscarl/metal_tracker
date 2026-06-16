// lib/core/widgets/movement_arrow.dart
//
// Standard movement direction indicator used throughout the app.
// Size inherits from the surrounding DefaultTextStyle unless overridden.
// Null movementUp = no data yet → renders nothing (SizedBox.shrink).

import 'package:flutter/material.dart';

class MovementArrow extends StatelessWidget {
  final bool? movementUp;
  final Color color;

  /// Explicit size override. When omitted the widget inherits the font size
  /// from DefaultTextStyle so the arrow scales with the surrounding text.
  final double? size;

  const MovementArrow({
    super.key,
    required this.movementUp,
    required this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (movementUp == null) return const SizedBox.shrink();
    final iconSize = size ?? DefaultTextStyle.of(context).style.fontSize ?? 14.0;
    return Icon(
      movementUp! ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
      size: iconSize,
      color: color,
    );
  }
}
