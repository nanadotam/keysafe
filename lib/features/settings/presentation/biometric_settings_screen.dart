// lib/features/settings/presentation/biometric_settings_screen.dart
//
// Adapted from hostel_hub's BiometricSettingsScreen, but:
//   • No Firebase — uses KeyStore (FlutterSecureStorage / AndroidKeystore)
//   • Re-authentication = verify master password hash stored in KeyStore
//   • Enable flow: verify master password → OS biometric prompt → enable flag
//   • Disable flow: directly clears the flag (user is already in-app)

import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/services/biometric_service.dart';
import '../../../core/settings/app_settings_provider.dart';
import '../../../crypto/key_store.dart';

class BiometricSettingsScreen extends ConsumerStatefulWidget {
  const BiometricSettingsScreen({super.key});

  @override
  ConsumerState<BiometricSettingsScreen> createState() =>
      _BiometricSettingsScreenState();
}

class _BiometricSettingsScreenState
    extends ConsumerState<BiometricSettingsScreen> {
  bool _isBusy = false;
  late Future<BiometricStatus> _statusFuture;

  // Kept at class level to avoid the "controller disposed during animation"
  // crash (same pattern as hostel_hub's BiometricSettingsScreen).
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _statusFuture = _loadStatus();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<BiometricStatus> _loadStatus() =>
      ref.read(biometricServiceProvider).getStatus();

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _statusFuture = _loadStatus());
  }

  // ── Enable flow ─────────────────────────────────────────────────────────────

  Future<void> _enable(BiometricStatus status) async {
    if (!status.isSupported) {
      _showSnackBar('Biometric / device lock is not available on this device.');
      return;
    }

    // Step 1 — verify master password locally (re-auth without a network call).
    final verified = await _verifyMasterPassword();
    if (!mounted) return;
    if (!verified) return;

    // Capture messenger before the OS prompt suspends Flutter.
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isBusy = true);

    try {
      // Step 2 — trigger the OS biometric / device-lock prompt.
      final authenticated = await ref
          .read(biometricServiceProvider)
          .authenticate(
            localizedReason:
                'Confirm your identity to enable biometric unlock for KeySafe',
          );
      if (!mounted) return;

      if (!authenticated) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Biometric confirmation was cancelled.'),
          ),
        );
        return;
      }

      // Step 3 — persist the flag in KeyStore and AppSettings.
      await ref.read(biometricServiceProvider).enable();
      await ref
          .read(appSettingsProvider.notifier)
          .setBiometricUnlockEnabled(true);
      await KeyStore.setBiometricEnabled(true);
      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Biometric unlock is now enabled.'),
          backgroundColor: Color(0xFF60BA46),
        ),
      );
      await _refresh();
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  // ── Disable flow ────────────────────────────────────────────────────────────

  Future<void> _disable() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isBusy = true);
    try {
      await ref.read(biometricServiceProvider).disable();
      await ref
          .read(appSettingsProvider.notifier)
          .setBiometricUnlockEnabled(false);
      await KeyStore.setBiometricEnabled(false);
      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(content: Text('Biometric unlock has been turned off.')),
      );
      await _refresh();
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  // ── Test prompt ─────────────────────────────────────────────────────────────

  Future<void> _test(BiometricStatus status) async {
    if (!status.isSupported) {
      _showSnackBar('Biometric / device lock is not available on this device.');
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isBusy = true);
    try {
      final ok = await ref
          .read(biometricServiceProvider)
          .authenticate(
            localizedReason: 'Testing biometric unlock for KeySafe',
          );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Biometric prompt succeeded ✓'
                : 'Biometric prompt was cancelled.',
          ),
          backgroundColor: ok ? const Color(0xFF60BA46) : null,
        ),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  // ── Master-password re-auth ─────────────────────────────────────────────────

  /// Prompts the user for their master password, then verifies it against
  /// the sha-256 hash stored in KeyStore.  Returns true if verified.
  Future<bool> _verifyMasterPassword() async {
    _passwordController.clear();
    var obscureText = true;

    final typedPassword = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('Confirm Master Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your master password to enable biometric unlock on this device.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: obscureText,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Master Password',
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setDialogState(() => obscureText = !obscureText),
                      icon: Icon(
                        obscureText
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(_passwordController.text.trim()),
              child: const Text('Verify'),
            ),
          ],
        ),
      ),
    );

    if (typedPassword == null || typedPassword.isEmpty) return false;

    // Verify offline using the stored sha-256 hash.
    final userId  = await KeyStore.getUserId() ?? '';
    final stored  = await KeyStore.getMasterPasswordHash();

    if (stored == null) {
      if (mounted) {
        _showSnackBar(
          'No session hash found. Please log in again to enable biometrics.',
        );
      }
      return false;
    }

    final computed = base64Encode(
      crypto.sha256
          .convert(utf8.encode(typedPassword + userId))
          .bytes,
    );

    if (computed != stored) {
      if (mounted) {
        _showSnackBar('Incorrect master password.');
      }
      return false;
    }

    return true;
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings        = ref.watch(appSettingsProvider);
    final biometricEnabled = settings.biometricUnlockEnabled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biometric Unlock'),
        leading: const BackButton(),
      ),
      body: FutureBuilder<BiometricStatus>(
        future: _statusFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final status = snapshot.data!;
          final availabilityText = status.isSupported
              ? _formatBiometricTypes(status.availableBiometrics)
              : 'Unavailable';

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                // ── Status card ───────────────────────────────────────────
                _InfoCard(
                  title: 'Status',
                  children: [
                    _StatusRow(
                      label: 'Device support',
                      value: status.isSupported ? 'Available' : 'Unavailable',
                      valueColor: status.isSupported
                          ? const Color(0xFF60BA46)
                          : null,
                    ),
                    _StatusRow(
                      label: 'Enrolled methods',
                      value: availabilityText,
                    ),
                    _StatusRow(
                      label: 'KeySafe unlock',
                      value: biometricEnabled && status.isEnabled
                          ? 'Enabled'
                          : 'Disabled',
                      valueColor: biometricEnabled && status.isEnabled
                          ? const Color(0xFF60BA46)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── How it works ──────────────────────────────────────────
                _InfoCard(
                  title: 'How it works',
                  children: const [
                    Text(
                      'Enable this on a trusted device after signing in once. '
                      'KeySafe will store a secure hash of your master password '
                      'in the device Keystore (Android) / Keychain (iOS) and '
                      'require the system biometric prompt — or your device PIN — '
                      'before unlocking. Your actual password never leaves the device.',
                      style: TextStyle(height: 1.5),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Enable button ─────────────────────────────────────────
                FilledButton.icon(
                  onPressed: _isBusy ||
                          (biometricEnabled && status.isEnabled)
                      ? null
                      : () => _enable(status),
                  icon: _isBusy && !biometricEnabled
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Symbols.fingerprint),
                  label: Text(
                    biometricEnabled && status.isEnabled
                        ? 'Biometric Unlock Enabled'
                        : 'Enable Biometric Unlock',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Test button ───────────────────────────────────────────
                OutlinedButton.icon(
                  onPressed: _isBusy ? null : () => _test(status),
                  icon: const Icon(Symbols.verified_user),
                  label: const Text('Test Biometric Prompt'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Disable button ────────────────────────────────────────
                OutlinedButton.icon(
                  onPressed:
                      _isBusy || !(biometricEnabled && status.isEnabled)
                          ? null
                          : _disable,
                  icon: const Icon(Symbols.lock_reset),
                  label: const Text('Disable Biometric Unlock'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatBiometricTypes(List<BiometricType> biometrics) {
    if (biometrics.isEmpty) return 'None enrolled (device PIN may still work)';
    final labels = biometrics
        .map(
          (t) => switch (t) {
            BiometricType.face        => 'Face',
            BiometricType.fingerprint => 'Fingerprint',
            BiometricType.strong      => 'Strong biometric',
            BiometricType.weak        => 'Weak biometric',
            BiometricType.iris        => 'Iris',
          },
        )
        .toSet()
        .toList();
    return labels.join(', ');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget helpers (same pattern as hostel_hub's _InfoCard / _StatusRow)
// ─────────────────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String       title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
