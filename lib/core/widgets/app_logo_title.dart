// lib/core/widgets/app_logo_title.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';

class AppLogoTitle extends ConsumerWidget {
  final String title;
  const AppLogoTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs      = Theme.of(context).colorScheme;
    final tt      = Theme.of(context).textTheme;
    final version = ref.watch(appVersionProvider).valueOrNull ?? '';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/logo.png', height: 28, fit: BoxFit.contain),
        const SizedBox(width: 8),
        Text(title, style: tt.titleLarge),
        if (version.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(
            'v$version',
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
