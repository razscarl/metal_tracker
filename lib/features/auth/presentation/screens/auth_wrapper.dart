// lib/features/auth/presentation/screens/auth_wrapper.dart:Auth Wrapper
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Check if we have a session
        final session = snapshot.hasData ? snapshot.data!.session : null;

        if (session != null) {
          // User is logged in
          return const HomeScreen();
        } else {
          // User is not logged in
          return const AuthScreen();
        }
      },
    );
  }
}
