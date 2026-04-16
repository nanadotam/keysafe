import 'dart:math';

import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../auth/providers/auth_provider.dart';
import '../../vault/providers/vault_provider.dart';
import '../../../core/constants/routes.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/settings/app_settings_provider.dart';
import '../../../crypto/key_store.dart';
import '../data/vault_export_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(appSettingsProvider);
    final biometric = settings.biometricUnlockEnabled;
    final clipboardClear = settings.autoClearClipboardEnabled;
    final darkMode = settings.themeMode == ThemeMode.dark;
    final notifications = settings.notificationsEnabled;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionHeader(context, 'Security'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Symbols.fingerprint),
                    title: const Text('Biometric Unlock'),
                    subtitle: const Text('Use fingerprint or face to unlock'),
                    value: biometric,
                    onChanged: (v) async {
                      HapticFeedback.selectionClick();
                      await ref
                          .read(appSettingsProvider.notifier)
                          .setBiometricUnlockEnabled(v);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Symbols.content_paste_off),
                    title: const Text('Auto-clear Clipboard'),
                    subtitle: const Text('Clear clipboard after 30 seconds'),
                    value: clipboardClear,
                    onChanged: (v) async {
                      HapticFeedback.selectionClick();
                      await ref
                          .read(appSettingsProvider.notifier)
                          .setAutoClearClipboardEnabled(v);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Symbols.notifications),
                    title: const Text('Notifications'),
                    subtitle:
                        const Text('Show security and clipboard notifications'),
                    value: notifications,
                    onChanged: (v) async {
                      HapticFeedback.selectionClick();
                      if (v) {
                        final granted =
                            await NotificationService.requestPermissions();
                        if (!granted && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notification permission denied'),
                            ),
                          );
                          return;
                        }
                      }
                      await ref
                          .read(appSettingsProvider.notifier)
                          .setNotificationsEnabled(v);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Symbols.timer),
                    title: const Text('Auto-lock Delay'),
                    subtitle: Text(_labelForAutoLock(settings.autoLockSeconds)),
                    trailing: const Icon(Symbols.chevron_right),
                    onTap: () =>
                        _showAutoLockDialog(context, ref, settings.autoLockSeconds),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Symbols.content_paste_go),
                    title: const Text('Clipboard Clear Delay'),
                    subtitle: Text(
                      '${settings.clipboardClearSeconds} seconds',
                    ),
                    trailing: const Icon(Symbols.chevron_right),
                    onTap: () => _showClipboardDialog(
                      context,
                      ref,
                      settings.clipboardClearSeconds,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionHeader(context, 'Appearance'),
            Card(
              child: SwitchListTile(
                secondary: const Icon(Symbols.dark_mode),
                title: const Text('Dark Mode'),
                value: darkMode,
                onChanged: (v) async {
                  HapticFeedback.selectionClick();
                  await ref
                      .read(appSettingsProvider.notifier)
                      .setThemeMode(v ? ThemeMode.dark : ThemeMode.light);
                },
              ),
            ),
            const SizedBox(height: 16),
            _sectionHeader(context, 'Account'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Symbols.lock_reset),
                    title: const Text('Change Master Password'),
                    trailing: const Icon(Symbols.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Symbols.download),
                    title: const Text('Export Vault'),
                    trailing: const Icon(Symbols.chevron_right),
                    onTap: () => _startExportFlow(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionHeader(
              context,
              'Danger Zone',
              color: theme.colorScheme.error,
            ),
            Card(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Symbols.delete_forever,
                        color: theme.colorScheme.error),
                    title: Text(
                      'Wipe Vault',
                      style:
                          TextStyle(color: theme.colorScheme.error),
                    ),
                    onTap: () => _startWipeVaultFlow(context, ref),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading:
                        Icon(Symbols.logout, color: theme.colorScheme.error),
                    title: Text(
                      'Log Out',
                      style:
                          TextStyle(color: theme.colorScheme.error),
                    ),
                    onTap: () => _confirmDanger(
                      context,
                      ref,
                      'Log Out',
                      'You will need your master password to unlock again.',
                      onConfirm: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) context.go(Routes.login);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, {Color? color}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color ?? theme.colorScheme.primary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  String _labelForAutoLock(int seconds) {
    return switch (seconds) {
      30 => '30 seconds',
      60 => '1 minute',
      300 => '5 minutes',
      _ => 'Never',
    };
  }

  void _showAutoLockDialog(
    BuildContext context,
    WidgetRef ref,
    int currentSeconds,
  ) {
    final options = const {
      '30 seconds': 30,
      '1 minute': 60,
      '5 minutes': 300,
      'Never': 0,
    };
    showDialog(
      context: context,
      builder: (ctx) => _AutoLockDialog(
        currentSeconds: currentSeconds,
        options: options,
        onSelected: (seconds) => ref
            .read(appSettingsProvider.notifier)
            .setAutoLockSeconds(seconds),
      ),
    );
  }

  void _showClipboardDialog(
    BuildContext context,
    WidgetRef ref,
    int currentSeconds,
  ) {
    final options = const {
      '15 seconds': 15,
      '30 seconds': 30,
      '60 seconds': 60,
    };
    showDialog(
      context: context,
      builder: (ctx) => _AutoLockDialog(
        title: 'Clipboard Clear Delay',
        currentSeconds: currentSeconds,
        options: options,
        onSelected: (seconds) => ref
            .read(appSettingsProvider.notifier)
            .setClipboardClearSeconds(seconds),
      ),
    );
  }

  Future<void> _confirmDanger(
    BuildContext context,
    WidgetRef ref,
    String title,
    String message, {
    required VoidCallback onConfirm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
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
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      HapticFeedback.heavyImpact();
      onConfirm();
    }
  }

  Future<void> _startExportFlow(BuildContext context, WidgetRef ref) async {
    final password = await _promptForSecret(
      context,
      title: 'Protect Export',
      message:
          'Choose a password for the ZIP file that will be emailed to your account.',
      confirmLabel: 'Create Export',
    );
    if (password == null || password.isEmpty) {
      return;
    }

    try {
      await ref.read(vaultExportServiceProvider).emailProtectedExport(password);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Export ready in your email composer. Send it to your account to finish.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  Future<void> _startWipeVaultFlow(BuildContext context, WidgetRef ref) async {
    final entries = ref.read(vaultProvider).valueOrNull ?? const [];
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your vault is already empty.')),
      );
      return;
    }

    final email = await KeyStore.getUserEmail();
    if (email == null || email.isEmpty) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No account email found. Log in again.')),
      );
      return;
    }

    final otp = _generateOtp();
    try {
      await FlutterEmailSender.send(
        Email(
          recipients: [email],
          subject: 'KeySafe Vault Wipe OTP',
          body:
              'Use this OTP to confirm your vault wipe request: $otp\n\nIf you did not request this, ignore the email draft.',
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open email composer: $error')),
      );
      return;
    }

    if (!context.mounted) {
      return;
    }

    final typedOtp = await _promptForSecret(
      context,
      title: 'Confirm OTP',
      message:
          'Send the drafted email to yourself, then enter the OTP you received.',
      confirmLabel: 'Verify OTP',
      obscureText: false,
    );
    if (typedOtp == null || typedOtp.trim() != otp) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP verification failed.')),
        );
      }
      return;
    }

    if (!context.mounted) {
      return;
    }

    final phrase = await _promptForSecret(
      context,
      title: 'Final Confirmation',
      message: 'Type DELETE PASSWORDS to permanently wipe your vault.',
      confirmLabel: 'Wipe Vault',
      obscureText: false,
    );
    if (phrase?.trim() != 'DELETE PASSWORDS') {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vault wipe cancelled.')),
        );
      }
      return;
    }

    try {
      final notifier = ref.read(vaultProvider.notifier);
      for (final entry in List.of(entries)) {
        await notifier.delete(entry.id);
      }

      if (!context.mounted) {
        return;
      }

      if (ref.read(appSettingsProvider).notificationsEnabled) {
        await NotificationService.show(
          id: 102,
          title: 'Vault wiped',
          body: 'All vault entries were deleted from this account.',
        );
      }

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vault wiped successfully.')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vault wipe failed: $error')),
      );
    }
  }

  String _generateOtp() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<String?> _promptForSecret(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    bool obscureText = true,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => _SecretPromptDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        obscureText: obscureText,
      ),
    );
  }
}

class _SecretPromptDialog extends StatefulWidget {
  const _SecretPromptDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.obscureText,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final bool obscureText;

  @override
  State<_SecretPromptDialog> createState() => _SecretPromptDialogState();
}

class _SecretPromptDialogState extends State<_SecretPromptDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.message),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: widget.obscureText,
            autofocus: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

class _AutoLockDialog extends StatefulWidget {
  final Map<String, int> options;
  final int currentSeconds;
  final Future<void> Function(int seconds) onSelected;
  final String title;

  const _AutoLockDialog({
    this.title = 'Auto-lock Delay',
    required this.options,
    required this.currentSeconds,
    required this.onSelected,
  });

  @override
  State<_AutoLockDialog> createState() => _AutoLockDialogState();
}

class _AutoLockDialogState extends State<_AutoLockDialog> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.options.entries
            .firstWhere(
              (entry) => entry.value == widget.currentSeconds,
              orElse: () => const MapEntry('1 minute', 60),
            )
            .key;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: RadioGroup<String>(
        groupValue: _selected,
        onChanged: (v) {
          if (v != null) {
            setState(() => _selected = v);
            widget.onSelected(widget.options[v] ?? 60);
            Navigator.pop(context);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.options.keys
              .map((o) => RadioListTile<String>(value: o, title: Text(o)))
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
