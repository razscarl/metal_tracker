// lib/core/widgets/app_logo_title.dart
import 'package:flutter/material.dart';

/// Shared AppBar title widget — shows the Metal Tracker logo to the left of
/// the screen title. Used by all top-level navigation screens.
class AppLogoTitle extends StatelessWidget {
  final String title;

  const AppLogoTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/logo.png',
          height: 28,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
