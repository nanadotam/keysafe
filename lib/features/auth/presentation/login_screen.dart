import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../providers/auth_provider.dart';
import '../domain/auth_state.dart';
import '../../../core/constants/routes.dart';
import '../../../crypto/key_store.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  bool  _obscure     = true;
  int   _attempts    = 0;
  bool  _lockedOut   = false;
  int   _lockoutRemaining = 0;
  Timer? _lockoutTimer;

  // "Remember me" state ──────────────────────────────────────────────────────
  bool    _isReturningUser = false;
  String? _storedDisplayName;
  String? _storedEmail;

  static const _maxAttempts     = 5;
  static const _lockoutDuration = 60;

  @override
  void initState() {
    super.initState();
    _checkReturningUser();
  }

  /// If the user has previously logged in, read their name + email from the
  /// KeyStore and pre-populate the email field.  The password hash is also
  /// stored so on-device verification works on the lock screen, but on the
  /// login screen we always do a full server login to get fresh tokens.
  Future<void> _checkReturningUser() async {
    final token   = await KeyStore.getAccessToken();
    final email   = await KeyStore.getUserEmail();
    final name    = await KeyStore.getDisplayName();
    final onboarded = await KeyStore.getOnboardingSeen();

    if (token != null && email != null && onboarded) {
      // There's an existing session — the lock screen should handle this.
      // But if we arrive here anyway (e.g. manual sign-out), pre-fill email.
      if (mounted) {
        _emailCtrl.text = email;
        setState(() {
          _isReturningUser    = true;
          _storedDisplayName  = name ?? email.split('@').first;
          _storedEmail        = email;
        });
      }
    } else if (email != null && onboarded) {
      // Seen onboarding, has email stored, but no token (signed out).
      if (mounted) {
        _emailCtrl.text = email;
        setState(() {
          _isReturningUser    = true;
          _storedDisplayName  = name ?? email.split('@').first;
          _storedEmail        = email;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  void _startLockout() {
    setState(() {
      _lockedOut         = true;
      _lockoutRemaining  = _lockoutDuration;
    });
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _lockoutRemaining--);
      if (_lockoutRemaining <= 0) {
        t.cancel();
        setState(() {
          _lockedOut = false;
          _attempts  = 0;
        });
      }
    });
  }

  Future<void> _submit() async {
    if (_lockedOut || !_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    await ref.read(authProvider.notifier).login(
          email:    _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
  }

  Future<void> _switchAccount() async {
    // Clear the remembered session and show full login form.
    setState(() {
      _isReturningUser   = false;
      _storedDisplayName = null;
      _storedEmail       = null;
    });
    _emailCtrl.clear();
    _passCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (_, state) {
      state.when(
        initial:         () {},
        loading:         () {},
        authenticated:   (_, __) => context.go(Routes.home),
        locked:          () => context.go(Routes.lock),
        unauthenticated: () {},
        error: (msg) {
          _attempts++;
          if (_attempts >= _maxAttempts) _startLockout();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          HapticFeedback.heavyImpact();
        },
      );
    });

    final theme     = Theme.of(context);
    final isLoading = ref
        .watch(authProvider)
        .maybeWhen(loading: () => true, orElse: () => false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        leading: Navigator.canPop(context)
            ? const BackButton()
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Returning-user greeting ───────────────────────────────
                if (_isReturningUser && _storedDisplayName != null) ...[
                  Card(
                    color: theme.colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: theme.colorScheme.primary,
                                child: Text(
                                  _storedDisplayName![0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Signed in as',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onPrimaryContainer
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                    Text(
                                      _storedDisplayName!,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: theme.colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (_storedEmail != null)
                                      Text(
                                        _storedEmail!,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onPrimaryContainer
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Enter your master password to continue',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  // Zero-knowledge info card for fresh logins.
                  Card(
                    color: theme.colorScheme.tertiaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Symbols.info, color: theme.colorScheme.tertiary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your master password never leaves your device.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Email field — only shown for non-returning users.
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Symbols.email),
                    ),
                    validator: (v) =>
                        v == null || !v.contains('@') ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Master password ───────────────────────────────────────
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: 'Master Password',
                    prefixIcon: const Icon(Symbols.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Symbols.visibility : Symbols.visibility_off,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter your password' : null,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 8),

                // ── Lockout indicator ─────────────────────────────────────
                if (_lockedOut)
                  Column(
                    children: [
                      LinearProgressIndicator(
                        value: _lockoutRemaining / _lockoutDuration,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Too many attempts. Try again in ${_lockoutRemaining}s',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                if (_attempts > 0 && !_lockedOut)
                  Text(
                    '$_attempts / $_maxAttempts attempts',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                const SizedBox(height: 24),

                // ── Submit ────────────────────────────────────────────────
                FilledButton(
                  onPressed: isLoading || _lockedOut ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Unlock Vault'),
                ),
                const SizedBox(height: 16),

                // ── Switch account or go to register ──────────────────────
                if (_isReturningUser)
                  TextButton(
                    onPressed: _switchAccount,
                    child: const Text('Not you? Use a different account'),
                  )
                else
                  TextButton(
                    onPressed: () => context.go(Routes.register),
                    child: const Text("Don't have an account? Register"),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
