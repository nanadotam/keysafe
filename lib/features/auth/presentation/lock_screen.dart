import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../providers/auth_provider.dart';
import '../domain/auth_state.dart';
import '../../../core/constants/routes.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/settings/app_settings_provider.dart';
import '../../../crypto/key_store.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen>
    with SingleTickerProviderStateMixin {
  final _passCtrl  = TextEditingController();
  final _formKey   = GlobalKey<FormState>();

  String? _displayName;
  bool    _obscure        = true;
  bool    _showPassField  = false;
  int     _failedAttempts = 0;
  bool    _isVerifying    = false;
  bool    _unlocking      = false;

  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulseAnim;
  int _dotCount = 0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _loadAndUnlock();
  }

  void _startUnlockingAnim() {
    if (!mounted) return;
    setState(() { _unlocking = true; _dotCount = 0; });
    _tickDots();
  }

  void _tickDots() {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted || !_unlocking) return;
      setState(() => _dotCount = (_dotCount + 1) % 4);
      _tickDots();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAndUnlock() async {
    // Load display name so we can greet the user.
    final name = await KeyStore.getDisplayName();
    if (mounted) setState(() => _displayName = name);

    // Auto-trigger biometric on load if enabled.
    final settings = ref.read(appSettingsProvider);
    if (settings.biometricUnlockEnabled) {
      await _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    try {
      final status = await ref.read(biometricServiceProvider).getStatus();
      if (!status.isSupported) {
        // Biometrics unavailable — fall back to password field.
        if (mounted) setState(() => _showPassField = true);
        return;
      }
      final authenticated = await ref
          .read(biometricServiceProvider)
          .authenticate(
            localizedReason: 'Unlock your KeySafe vault',
          );
      if (!mounted) return;
      if (authenticated) {
        HapticFeedback.mediumImpact();
        _startUnlockingAnim();
        await ref.read(authProvider.notifier).unlockWithBiometrics();
      }
    } catch (_) {
      // Silently fall through — user can use master password instead.
    }
  }

  Future<void> _verifyMasterPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isVerifying = true);
    HapticFeedback.lightImpact();

    final password = _passCtrl.text;
    final userId   = await KeyStore.getUserId() ?? '';
    final stored   = await KeyStore.getMasterPasswordHash();

    if (stored == null) {
      // No hash stored (old session) — unlock and re-derive AES key from password.
      // We derive and store the key, then mark authenticated.
      setState(() => _isVerifying = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired — please sign in again.'),
          ),
        );
        await ref.read(authProvider.notifier).logout();
        if (mounted) context.go(Routes.login);
      }
      return;
    }

    final computed = base64Encode(
      crypto.sha256.convert(utf8.encode(password + userId)).bytes,
    );

    if (computed == stored) {
      HapticFeedback.mediumImpact();
      _startUnlockingAnim();
      await ref.read(authProvider.notifier).unlockWithBiometrics();
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _failedAttempts++;
        _isVerifying = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Incorrect password. $_failedAttempts failed attempt${_failedAttempts > 1 ? 's' : ''}.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'This will clear your session and return you to login. Your vault data stays on the server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) context.go(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (_, state) {
      state.whenOrNull(
        authenticated: (_, __) => context.go(Routes.home),
        unauthenticated: ()    => context.go(Routes.login),
      );
    });

    final theme   = Theme.of(context);
    final name    = _displayName ?? 'User';
    final biometricEnabled = ref.watch(appSettingsProvider).biometricUnlockEnabled;

    return Stack(
      children: [
      Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Lock icon ─────────────────────────────────────────────
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Symbols.lock,
                      size: 36,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Greeting ──────────────────────────────────────────────
                  Text(
                    'Welcome back,',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your vault is locked',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white38,
                    ),
                  ),

                  // ── Failed attempts indicator ─────────────────────────────
                  if (_failedAttempts > 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      '$_failedAttempts failed attempt${_failedAttempts > 1 ? 's' : ''}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),

                  // ── Biometric button ──────────────────────────────────────
                  if (biometricEnabled) ...[
                    FilledButton.icon(
                      onPressed: _tryBiometric,
                      icon: const Icon(Symbols.fingerprint),
                      label: const Text('Unlock with Biometrics / Device PIN'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () =>
                          setState(() => _showPassField = !_showPassField),
                      child: Text(
                        _showPassField
                            ? 'Hide password field'
                            : 'Use master password instead',
                        style: TextStyle(color: Colors.white60),
                      ),
                    ),
                  ],

                  // ── Master password fallback ───────────────────────────────
                  if (!biometricEnabled || _showPassField) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Master Password',
                        labelStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Symbols.lock, color: Colors.white54),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Symbols.visibility : Symbols.visibility_off,
                            color: Colors.white54,
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.error,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.error,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Enter your master password' : null,
                      onFieldSubmitted: (_) => _verifyMasterPassword(),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _isVerifying ? null : _verifyMasterPassword,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isVerifying
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Unlock Vault'),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // ── Sign-out ──────────────────────────────────────────────
                  TextButton(
                    onPressed: _signOut,
                    child: Text(
                      'Not $name? Sign out',
                      style: const TextStyle(color: Colors.white38),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),

      // ── Unlocking overlay ─────────────────────────────────────────────────
      if (_unlocking)
        AnimatedOpacity(
          opacity: _unlocking ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            color: Colors.black.withValues(alpha: 0.92),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _pulseAnim,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary.withValues(alpha: 0.18),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.6),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.35),
                            blurRadius: 28,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        Symbols.lock_open,
                        size: 42,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Unlocking your vault${'.' * _dotCount}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 160,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ]);
  }
}
