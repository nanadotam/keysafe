import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../auth/providers/auth_provider.dart';
import '../../vault/domain/vault_entry.dart';
import '../../vault/providers/vault_provider.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/routes.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/settings/app_settings_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../crypto/crypto_service.dart';
import '../../../crypto/key_store.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double>   _scoreAnim;
  bool       _animStarted    = false;
  bool       _checkingBreaches = false;
  Set<String> _compromisedIds = <String>{};
  DateTime?  _lastCheckAt;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scoreAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_animStarted) {
        _animStarted = true;
        _animCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme      = Theme.of(context);
    final vaultState = ref.watch(vaultProvider);

    return vaultState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Security')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.toString()),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => ref.read(vaultProvider.notifier).load(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (entries) => FutureBuilder<_SecuritySnapshot>(
        future: _buildSnapshot(entries),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(title: const Text('Security')),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          final security = snapshot.data!;
          final weakEntries        = entries.where((e) => e.strengthScore < 40).toList();
          final compromisedEntries = entries.where((e) => _compromisedIds.contains(e.id)).toList();
          final reusedEntries      = security.reusedIds.isNotEmpty
              ? entries.where((e) => security.reusedIds.contains(e.id)).toList()
              : <VaultEntry>[];
          final secureEntries = entries
              .where((e) =>
                  !_compromisedIds.contains(e.id) &&
                  e.strengthScore >= 40 &&
                  !security.reusedIds.contains(e.id))
              .toList();

          final weak       = weakEntries.length;
          final compromised = compromisedEntries.length;
          final reused     = reusedEntries.length;
          final secure     = secureEntries.length;
          final score =
              (100 - compromised * 20 - weak * 5 - reused * 3).clamp(0, 100);

          return Scaffold(
            appBar: AppBar(title: const Text('Security')),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ── Score ring ──────────────────────────────────────────
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: AnimatedBuilder(
                          animation: _scoreAnim,
                          builder: (context, _) {
                            final displayScore =
                                (score * _scoreAnim.value).round();
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 140,
                                  height: 140,
                                  child: CircularProgressIndicator(
                                    value: (score / 100) * _scoreAnim.value,
                                    strokeWidth: 10,
                                    color: score >= 70
                                        ? AppColors.strengthStrong
                                        : score >= 40
                                            ? AppColors.strengthFair
                                            : AppColors.strengthWeak,
                                    backgroundColor: theme
                                        .colorScheme.surfaceContainerHighest,
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$displayScore',
                                      style: theme.textTheme.displaySmall,
                                    ),
                                    Text(
                                      'SCORE',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        letterSpacing: 2,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Tappable security rows ───────────────────────────────
                    Card(
                      child: Column(
                        children: [
                          _SecurityRow(
                            icon:      Symbols.dangerous,
                            iconColor: theme.colorScheme.error,
                            label:     'Compromised',
                            count:     compromised,
                            onTap: compromised > 0
                                ? () => _pushFilteredList(
                                      context,
                                      'Compromised Passwords',
                                      compromisedEntries,
                                      theme.colorScheme.error,
                                    )
                                : null,
                          ),
                          const Divider(height: 1),
                          _SecurityRow(
                            icon:      Symbols.warning,
                            iconColor: AppColors.strengthFair,
                            label:     'Weak Passwords',
                            count:     weak,
                            onTap: weak > 0
                                ? () => _pushFilteredList(
                                      context,
                                      'Weak Passwords',
                                      weakEntries,
                                      AppColors.strengthFair,
                                    )
                                : null,
                          ),
                          const Divider(height: 1),
                          _SecurityRow(
                            icon:      Symbols.content_copy,
                            iconColor: theme.colorScheme.primary,
                            label:     'Reused',
                            count:     reused,
                            onTap: reused > 0
                                ? () => _pushFilteredList(
                                      context,
                                      'Reused Passwords',
                                      reusedEntries,
                                      theme.colorScheme.primary,
                                    )
                                : null,
                          ),
                          const Divider(height: 1),
                          _SecurityRow(
                            icon:      Symbols.check_circle,
                            iconColor: AppColors.strengthStrong,
                            label:     'Secure',
                            count:     secure < 0 ? 0 : secure,
                            onTap: secure > 0
                                ? () => _pushFilteredList(
                                      context,
                                      'Secure Passwords',
                                      secureEntries,
                                      AppColors.strengthStrong,
                                    )
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Breach-check button ───────────────────────────────
                    if (_lastCheckAt != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Last breach scan: ${MaterialLocalizations.of(context).formatShortDate(_lastCheckAt!)} ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(_lastCheckAt!))}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    FilledButton.icon(
                      onPressed: _checkingBreaches
                          ? null
                          : () => _runBreachCheck(entries, security),
                      icon: _checkingBreaches
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Symbols.shield),
                      label: Text(
                        _checkingBreaches
                            ? 'Checking breached passwords...'
                            : 'Check for Breaches',
                      ),
                    ),

                    // ── Compromised detail card ───────────────────────────
                    if (_compromisedIds.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Card(
                        color: theme.colorScheme.errorContainer
                            .withValues(alpha: 0.45),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Compromised entries',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              for (final entry in entries.where(
                                (item) => _compromisedIds.contains(item.id),
                              ))
                                InkWell(
                                  onTap: () => context.push(
                                    Routes.detail,
                                    extra: entry,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Symbols.dangerous,
                                          size: 16,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${entry.name} (${entry.username})',
                                          ),
                                        ),
                                        const Icon(Symbols.chevron_right,
                                            size: 16),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _pushFilteredList(
    BuildContext context,
    String title,
    List<VaultEntry> entries,
    Color accentColor,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FilteredVaultScreen(
          title:       title,
          entries:     entries,
          accentColor: accentColor,
        ),
      ),
    );
  }

  Future<_SecuritySnapshot> _buildSnapshot(List<VaultEntry> entries) async {
    final key = await KeyStore.getAesKey();
    if (key == null) {
      return const _SecuritySnapshot(reusedIds: {}, plaintextById: {});
    }

    final plaintextById = <String, String>{};
    for (final entry in entries) {
      try {
        plaintextById[entry.id] =
            CryptoService.decrypt(entry.encryptedPassword, key);
      } catch (_) {}
    }

    // Find reused password IDs.
    final freq = <String, List<String>>{};
    plaintextById.forEach((id, plain) {
      freq.putIfAbsent(plain, () => []).add(id);
    });
    final reusedIds = <String>{};
    freq.forEach((_, ids) {
      if (ids.length > 1) reusedIds.addAll(ids);
    });

    return _SecuritySnapshot(
      reusedIds:     reusedIds,
      plaintextById: plaintextById,
    );
  }

  Future<void> _runBreachCheck(
    List<VaultEntry> entries,
    _SecuritySnapshot snapshot,
  ) async {
    if (_checkingBreaches) return;

    HapticFeedback.lightImpact();
    setState(() => _checkingBreaches = true);
    final dio         = ref.read(dioProvider);
    final compromised = <String>{};
    final prefixCache = <String, Set<String>>{};

    try {
      for (final entry in entries) {
        final plainPassword = snapshot.plaintextById[entry.id];
        if (plainPassword == null || plainPassword.isEmpty) continue;

        final digest = crypto.sha1
            .convert(utf8.encode(plainPassword))
            .toString()
            .toUpperCase();
        final prefix = digest.substring(0, 5);
        final suffix = digest.substring(5);

        final suffixes = prefixCache[prefix] ??
            await _fetchCompromisedSuffixes(dio, prefix);
        prefixCache[prefix] = suffixes;

        if (suffixes.contains(suffix)) compromised.add(entry.id);
      }

      setState(() {
        _compromisedIds = compromised;
        _lastCheckAt    = DateTime.now();
      });

      if (!mounted) return;

      final message = compromised.isEmpty
          ? 'No compromised passwords found.'
          : '${compromised.length} compromised password${compromised.length == 1 ? '' : 's'} found.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

      if (ref.read(appSettingsProvider).notificationsEnabled) {
        await NotificationService.show(
          id:    101,
          title: 'Security scan complete',
          body:  message,
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final responseData = e.response?.data;
      final message      = responseData is Map<String, dynamic>
          ? (responseData['error'] as String?) ?? 'Breach check failed.'
          : 'Breach check failed.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _checkingBreaches = false);
    }
  }

  Future<Set<String>> _fetchCompromisedSuffixes(Dio dio, String prefix) async {
    final response = await dio.post(
      ApiEndpoints.hibpCheck,
      data: {'hash_prefix': prefix},
    );
    final result =
        (response.data as Map<String, dynamic>)['result'] as String? ?? '';
    final suffixes = <String>{};
    for (final line in const LineSplitter().convert(result)) {
      final parts = line.split(':');
      if (parts.isNotEmpty) suffixes.add(parts.first.trim().toUpperCase());
    }
    return suffixes;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filtered vault list screen (Weak / Compromised / Reused / Secure)
// ─────────────────────────────────────────────────────────────────────────────

class _FilteredVaultScreen extends ConsumerWidget {
  const _FilteredVaultScreen({
    required this.title,
    required this.entries,
    required this.accentColor,
  });

  final String          title;
  final List<VaultEntry> entries;
  final Color           accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: const BackButton(),
      ),
      body: entries.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Symbols.check_circle,
                      size: 64, color: AppColors.strengthStrong),
                  const SizedBox(height: 16),
                  Text('No entries in this category',
                      style: theme.textTheme.titleMedium),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final entry = entries[i];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: accentColor.withValues(alpha: 0.15),
                      child: Text(
                        entry.name[0].toUpperCase(),
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      entry.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(entry.username),
                    trailing: const Icon(Symbols.chevron_right),
                    onTap: () =>
                        context.push(Routes.detail, extra: entry),
                  ),
                );
              },
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SecuritySnapshot {
  const _SecuritySnapshot({
    required this.reusedIds,
    required this.plaintextById,
  });

  final Set<String>         reusedIds;
  final Map<String, String> plaintextById;
}

class _SecurityRow extends StatelessWidget {
  const _SecurityRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.count,
    this.onTap,
  });

  final IconData icon;
  final Color    iconColor;
  final String   label;
  final int      count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading:  Icon(icon, color: iconColor),
      title:    Text(label),
      onTap:    onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(
            label: Text('$count'),
            backgroundColor: iconColor.withValues(alpha: 0.12),
            side: BorderSide.none,
          ),
          Icon(
            Symbols.chevron_right,
            color: onTap != null
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
