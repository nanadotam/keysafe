import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../domain/vault_entry.dart';
import '../providers/vault_provider.dart';
import '../../../core/constants/routes.dart';
import '../../../core/services/clipboard_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/settings/app_settings_provider.dart';
import '../../../core/widgets/category_icon.dart';
import '../../../core/widgets/strength_badge.dart';
import '../../../crypto/crypto_service.dart';
import '../../../crypto/key_store.dart';

class PasswordDetailScreen extends ConsumerStatefulWidget {
  final VaultEntry entry;
  const PasswordDetailScreen({super.key, required this.entry});

  @override
  ConsumerState<PasswordDetailScreen> createState() =>
      _PasswordDetailScreenState();
}

class _PasswordDetailScreenState
    extends ConsumerState<PasswordDetailScreen> {
  bool _passwordVisible = false;
  String? _decryptedPassword;
  final _localAuth = LocalAuthentication();

  Future<void> _revealPassword() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      bool authenticated = true;
      if (canCheck) {
        authenticated = await _localAuth.authenticate(
          localizedReason: 'Reveal password',
        );
        if (authenticated) HapticFeedback.mediumImpact();
      }
      if (!authenticated) return;

      final key = await KeyStore.getAesKey();
      if (key == null || !mounted) return;
      final plain = CryptoService.decrypt(widget.entry.encryptedPassword, key);
      setState(() {
        _decryptedPassword = plain;
        _passwordVisible = true;
      });
    } catch (_) {}
  }

  Future<void> _copyPassword() async {
    if (_decryptedPassword == null) {
      await _revealPassword();
      if (_decryptedPassword == null) return;
    }
    final settings = ref.read(appSettingsProvider);
    if (settings.autoClearClipboardEnabled) {
      await ClipboardService.copyAndScheduleClear(
        _decryptedPassword!,
        durationSeconds: settings.clipboardClearSeconds,
        onCleared: () async {
          if (ref.read(appSettingsProvider).notificationsEnabled) {
            await NotificationService.show(
              id: 77,
              title: 'Clipboard cleared',
              body: 'Your copied password was removed from the clipboard.',
            );
          }
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Copied — clipboard clears in ${settings.clipboardClearSeconds}s',
            ),
          ),
        );
      }
    } else {
      await Clipboard.setData(ClipboardData(text: _decryptedPassword!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password copied')),
        );
      }
    }
    HapticFeedback.lightImpact();
  }

  Future<void> _copyUsername() async {
    await Clipboard.setData(ClipboardData(text: widget.entry.username));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Username copied')));
    }
    HapticFeedback.lightImpact();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Password'),
        content: Text('Delete "${widget.entry.name}"? This cannot be undone.'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      HapticFeedback.heavyImpact();
      await ref.read(vaultProvider.notifier).delete(widget.entry.id);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('MMM d, yyyy');
    final entry = widget.entry;

    return Scaffold(
      appBar: AppBar(
        title: Text(entry.name),
        actions: [
          IconButton(
            icon: const Icon(Symbols.edit),
            onPressed: () => context.push(Routes.editPassword, extra: entry),
          ),
          IconButton(
            icon: Icon(Symbols.delete, color: theme.colorScheme.error),
            onPressed: _delete,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Center(child: CategoryIcon(category: entry.category, size: 64)),
              const SizedBox(height: 8),
              Text(entry.name, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              StrengthBadge.fromScore(entry.strengthScore),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Symbols.person),
                      title: const Text('Username'),
                      subtitle: Text(entry.username),
                      trailing: IconButton(
                        icon: const Icon(Symbols.content_copy),
                        onPressed: _copyUsername,
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Symbols.lock),
                      title: const Text('Password'),
                      subtitle: _passwordVisible && _decryptedPassword != null
                          ? Text(
                              _decryptedPassword!,
                              style: GoogleFonts.jetBrainsMono(),
                            )
                          : const Text('••••••••••••'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _passwordVisible
                                  ? Symbols.visibility_off
                                  : Symbols.visibility,
                            ),
                            onPressed: _passwordVisible
                                ? () => setState(() {
                                      _passwordVisible = false;
                                      _decryptedPassword = null;
                                    })
                                : _revealPassword,
                          ),
                          IconButton(
                            icon: const Icon(Symbols.content_copy),
                            onPressed: _copyPassword,
                          ),
                        ],
                      ),
                    ),
                    if (entry.url.isNotEmpty) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Symbols.link),
                        title: const Text('Website'),
                        subtitle: Text(entry.url),
                        trailing: IconButton(
                          icon: const Icon(Symbols.open_in_new),
                          onPressed: () async {
                            final uri = Uri.tryParse(entry.url);
                            if (uri != null) await launchUrl(uri);
                          },
                        ),
                      ),
                    ],
                    if (entry.notes.isNotEmpty) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Symbols.notes),
                        title: const Text('Notes'),
                        subtitle: Text(entry.notes),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Symbols.schedule),
                      title: const Text('Created'),
                      subtitle: Text(fmt.format(entry.createdAt)),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Symbols.update),
                      title: const Text('Modified'),
                      subtitle: Text(fmt.format(entry.updatedAt)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () =>
                          context.push(Routes.qrShare, extra: entry),
                      child: const Text('Share via QR'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                      ),
                      onPressed: _delete,
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
