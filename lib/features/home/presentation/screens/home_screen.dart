// lib/features/home/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      // The drawer automatically adds the hamburger icon to the AppBar
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Metal Tracker'),
        centerTitle: true,
        backgroundColor: AppColors.backgroundCard,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryGold),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Your body content (Dashboard widgets) will go here next
            Center(
              child: Text(
                'Welcome to Metal Tracker',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
