// lib/core/widgets/metal_button.dart
//
// DEPRECATED — use FilledButton or ElevatedButton from Material 3 instead.
// This widget exists only for backward compatibility during migration.
// Do not use in new code.

import 'package:flutter/material.dart';
import 'neumorphic_container.dart';

@Deprecated('Use FilledButton or ElevatedButton instead')
class MetalButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;

  const MetalButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFFD4AF37),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: NeumorphicContainer(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color:         color,
              fontWeight:    FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
