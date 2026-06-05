// lib/features/auth/presentation/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metal_tracker/core/providers/repository_providers.dart';
import 'package:metal_tracker/core/theme/app_theme.dart';
import 'package:metal_tracker/features/auth/presentation/providers/auth_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController       = TextEditingController();
  final _passwordController    = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading     = false;
  bool _isSignUp      = false;
  bool _obscurePassword = true;
  bool _obscureConfirm  = true;
  String? _inlineError;
  String? _inlineSuccess;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final saved = ref.read(savedEmailProvider).valueOrNull;
      if (saved != null) _emailController.text = saved;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _friendlyError(Object? error) {
    if (error == null) return 'An unknown error occurred';
    final msg = error.toString();
    if (msg.contains('Unsupported provider') ||
        msg.contains('provider is not enabled')) {
      return 'This sign-in method is not enabled. Contact support.';
    }
    if (error is AuthException) return error.message;
    if (msg.startsWith('{') && msg.contains('"msg"')) {
      final match = RegExp(r'"msg"\s*:\s*"([^"]+)"').firstMatch(msg);
      if (match != null) return match.group(1)!;
    }
    return msg.replaceFirst('Exception: ', '');
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading     = true;
      _inlineError   = null;
      _inlineSuccess = null;
    });
    try {
      if (_isSignUp) {
        await ref.read(authNotifierProvider.notifier).signUp(
              _emailController.text.trim(),
              _passwordController.text,
            );
        final authState = ref.read(authNotifierProvider);
        if (!mounted) return;
        if (authState.hasError) {
          setState(() => _inlineError = _friendlyError(authState.error));
        } else {
          setState(() {
            _inlineSuccess = 'Check your email to confirm your account, then sign in.';
            _isSignUp = false;
            _confirmPasswordController.clear();
          });
        }
      } else {
        await ref.read(authNotifierProvider.notifier).signInWithEmail(
              _emailController.text.trim(),
              _passwordController.text,
            );
        final authState = ref.read(authNotifierProvider);
        if (authState.hasError && mounted) {
          setState(() => _inlineError = _friendlyError(authState.error));
        } else {
          TextInput.finishAutofillContext(shouldSave: true);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _inlineError = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _inlineError = null);
    try {
      await ref.read(authNotifierProvider.notifier).signInWithGoogle();
      final authState = ref.read(authNotifierProvider);
      if (authState.hasError && mounted) {
        setState(() => _inlineError = _friendlyError(authState.error));
      }
    } catch (e) {
      if (mounted) setState(() => _inlineError = _friendlyError(e));
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _inlineError = null);
    try {
      await ref.read(authNotifierProvider.notifier).signInWithApple();
      final authState = ref.read(authNotifierProvider);
      if (authState.hasError && mounted) {
        setState(() => _inlineError = _friendlyError(authState.error));
      }
    } catch (e) {
      if (mounted) setState(() => _inlineError = _friendlyError(e));
    }
  }

  void _showForgotPasswordDialog() {
    final resetController = TextEditingController(text: _emailController.text);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email and we\'ll send a reset link.'),
            const SizedBox(height: 16),
            TextField(
              controller: resetController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final email = resetController.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await ref
                    .read(authNotifierProvider.notifier)
                    .sendPasswordReset(email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Password reset email sent. Check your inbox.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs      = Theme.of(context).colorScheme;
    final version = ref.watch(appVersionProvider).valueOrNull ?? '';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Logo ──────────────────────────────────────────────────
                  Image.asset('assets/logo.png', height: 72, fit: BoxFit.contain),
                  const SizedBox(height: 12),

                  // ── App title + version ───────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Metal Tracker',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (version.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          'v$version',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // ── Sign in / create account subtitle ─────────────────────
                  Text(
                    _isSignUp ? 'Create account' : 'Sign in',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // ── Google sign-in ────────────────────────────────────────
                  OutlinedButton.icon(
                    icon: const Icon(Icons.g_mobiledata, size: 22),
                    label: const Text('Continue with Google'),
                    onPressed: _handleGoogleSignIn,
                  ),
                  const SizedBox(height: 10),

                  // ── Apple sign-in ─────────────────────────────────────────
                  OutlinedButton.icon(
                    icon: const Icon(Icons.apple, size: 22),
                    label: const Text('Continue with Apple'),
                    onPressed: _handleAppleSignIn,
                  ),
                  const SizedBox(height: 20),

                  // ── OR divider ────────────────────────────────────────────
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Email + password fields ───────────────────────────────
                  AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller:        _emailController,
                          keyboardType:      TextInputType.emailAddress,
                          autofillHints:     const [AutofillHints.email],
                          textInputAction:   TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText:  'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Enter your email';
                            if (!v.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller:    _passwordController,
                          obscureText:   _obscurePassword,
                          onChanged:     (_) => setState(() {}),
                          autofillHints: _isSignUp
                              ? const [AutofillHints.newPassword]
                              : const [AutofillHints.password],
                          textInputAction: _isSignUp
                              ? TextInputAction.next
                              : TextInputAction.done,
                          onFieldSubmitted: _isSignUp ? null : (_) => _handleAuth(),
                          decoration: InputDecoration(
                            labelText:  'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Enter your password';
                            if (_isSignUp && v.length < 8) {
                              return 'At least 8 characters required';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  // ── Password requirements (sign-up only) ──────────────────
                  if (_isSignUp) ...[
                    const SizedBox(height: 10),
                    _PasswordRequirements(password: _passwordController.text),
                    const SizedBox(height: 14),
                  ],

                  // ── Confirm password (sign-up only) ───────────────────────
                  if (_isSignUp) ...[
                    TextFormField(
                      controller:      _confirmPasswordController,
                      obscureText:     _obscureConfirm,
                      autofillHints:   const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleAuth(),
                      decoration: InputDecoration(
                        labelText:  'Confirm password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please confirm your password';
                        if (v != _passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── Forgot password (sign-in only) ────────────────────────
                  if (!_isSignUp)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: const Text('Forgot password?'),
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  // ── Inline error ──────────────────────────────────────────
                  if (_inlineError != null) ...[
                    Text(
                      _inlineError!,
                      style: TextStyle(color: cs.error, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                  ],

                  // ── Inline success ────────────────────────────────────────
                  if (_inlineSuccess != null) ...[
                    Text(
                      _inlineSuccess!,
                      style: TextStyle(
                          color: AppColors.gainGreen, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                  ],

                  // ── Primary action button ─────────────────────────────────
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _handleAuth,
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width:  20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.onPrimary,
                              ),
                            )
                          : Text(_isSignUp ? 'Create Account' : 'Sign In'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Toggle sign-in / sign-up ──────────────────────────────
                  TextButton(
                    onPressed: () => setState(() {
                      _isSignUp = !_isSignUp;
                      _emailController.clear();
                      _passwordController.clear();
                      _confirmPasswordController.clear();
                      _inlineError   = null;
                      _inlineSuccess = null;
                    }),
                    child: Text(
                      _isSignUp
                          ? 'Already have one? Sign In'
                          : "Don't have an account? Sign Up",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Password Requirements Checklist ───────────────────────────────────────────

class _PasswordRequirements extends StatelessWidget {
  final String password;
  const _PasswordRequirements({required this.password});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final criteria = [
      (label: '8+ characters',       met: password.length >= 8),
      (label: 'Uppercase letter',     met: password.contains(RegExp(r'[A-Z]'))),
      (label: 'Lowercase letter',     met: password.contains(RegExp(r'[a-z]'))),
      (label: 'Number or symbol',     met: password.contains(RegExp(r'[0-9!@#\$%^&*()\-_=+\[\]{}|;:,.<>?]'))),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: criteria.map((c) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Icon(
                c.met ? Icons.check_circle : Icons.radio_button_unchecked,
                size:  14,
                color: c.met ? AppColors.gainGreen : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                c.label,
                style: TextStyle(
                  fontSize: 12,
                  color: c.met ? AppColors.gainGreen : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
