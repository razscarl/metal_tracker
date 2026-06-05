// lib/core/widgets/neumorphic_container.dart
//
// DEPRECATED — use Material 3 Card instead.
// This widget exists only for backward compatibility during migration.
// Do not use in new code.

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

@Deprecated('Use Card instead')
class NeumorphicContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool isPressed;

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
        color:        AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isPressed
            ? null
            : [
                BoxShadow(
                  color:      Colors.white.withValues(alpha: 0.05),
                  offset:     const Offset(-5, -5),
                  blurRadius: 10,
                ),
                BoxShadow(
                  color:      Colors.black.withValues(alpha: 0.3),
                  offset:     const Offset(5, 5),
                  blurRadius: 10,
                ),
              ],
      ),
      child: child,
    );
  }
}
