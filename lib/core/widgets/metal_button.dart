// lib/core/widgets/metal_button.dart

import 'package:flutter/material.dart';
import 'neumorphic_container.dart';

class MetalButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;

  const MetalButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFFD4AF37), // Default Gold
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
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
