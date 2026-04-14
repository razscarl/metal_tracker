// lib/core/widgets/app_logo_title.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';

/// Shared AppBar title widget — shows the Metal Tracker logo to the left of
/// the screen title. Used by all top-level navigation screens.
class AppLogoTitle extends ConsumerWidget {
  final String title;

  const AppLogoTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionProvider).valueOrNull ?? '';
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
        if (version.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(
            'v$version',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ],
    );
  }
}
