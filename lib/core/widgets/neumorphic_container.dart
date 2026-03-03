// lib/core/widgets/neumorphic_container.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool isPressed; // Indented look

  const NeumorphicContainer({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.padding,
    this.isPressed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isPressed
            ? null // Pressed state usually flips or removes shadows
            : [
                // Top-Left Light Highlight
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.05),
                  offset: const Offset(-5, -5),
                  blurRadius: 10,
                ),
                // Bottom-Right Dark Shadow
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  offset: const Offset(5, 5),
                  blurRadius: 10,
                ),
              ],
      ),
      child: child,
    );
  }
}
