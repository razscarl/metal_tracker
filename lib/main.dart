// lib/main.dart:Main Entry Point
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: MetalTrackerApp(),
    ),
  );
}

class MetalTrackerApp extends StatelessWidget {
  const MetalTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Metal Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthWrapper(),
    );
  }
}
