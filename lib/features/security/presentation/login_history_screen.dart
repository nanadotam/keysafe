import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../data/login_history_repository.dart';
import '../domain/login_event.dart';
import '../../../core/theme/app_colors.dart';

class LoginHistoryScreen extends ConsumerStatefulWidget {
  const LoginHistoryScreen({super.key});

  @override
  ConsumerState<LoginHistoryScreen> createState() => _LoginHistoryScreenState();
}

class _LoginHistoryScreenState extends ConsumerState<LoginHistoryScreen> {
  List<LoginEvent> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo   = ref.read(loginHistoryRepositoryProvider);
    final events = await repo.fetchAll();
    if (mounted) setState(() { _events = events; _loading = false; });
  }

  Future<void> _toggleTrust(LoginEvent event) async {
    if (event.id == null) return;
    try {
      await ref.read(loginHistoryRepositoryProvider)
          .setTrusted(event.id!, trusted: !event.isTrusted);
      await _load();
    } catch (_) {}
  }

  Future<void> _delete(LoginEvent event) async {
    if (event.id == null) return;
    try {
      await ref.read(loginHistoryRepositoryProvider).deleteEntry(event.id!);
      await _load();
    } catch (_) {}
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Delete all login history records?'),
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
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(loginHistoryRepositoryProvider).clearAll();
      } catch (_) {}
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login History'),
        actions: [
          if (_events.isNotEmpty)
            IconButton(
              icon: const Icon(Symbols.delete_sweep),
              tooltip: 'Clear all',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? _EmptyState()
              : Column(
                  children: [
                    _InfoBanner(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _events.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) => _LoginEventCard(
                            event: _events[i],
                            onToggleTrust: () => _toggleTrust(_events[i]),
                            onDelete: () => _delete(_events[i]),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info banner
// ─────────────────────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Symbols.location_on, color: cs.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mark login locations as Trusted to distinguish regular '
              'access from unexpected sign-ins.',
              style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Login event card
// ─────────────────────────────────────────────────────────────────────────────

class _LoginEventCard extends StatelessWidget {
  const _LoginEventCard({
    required this.event,
    required this.onToggleTrust,
    required this.onDelete,
  });

  final LoginEvent    event;
  final VoidCallback  onToggleTrust;
  final VoidCallback  onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs    = theme.colorScheme;
    final df    = DateFormat('dd MMM yyyy  HH:mm');

    final trusted = event.isTrusted;
    final trustColor =
        trusted ? AppColors.strengthStrong : cs.onSurfaceVariant;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  trusted ? Symbols.verified_user : Symbols.location_on,
                  color: trustColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.locationDisplay,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        df.format(event.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Trust badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: trustColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    trusted ? 'Trusted' : 'Unknown',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: trustColor,
                    ),
                  ),
                ),
              ],
            ),
            if (event.hasCoordinates) ...[
              const SizedBox(height: 8),
              Text(
                '${event.latitude!.toStringAsFixed(4)}°, '
                '${event.longitude!.toStringAsFixed(4)}°',
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Symbols.delete, size: 16),
                  label: const Text('Remove'),
                  style: TextButton.styleFrom(
                    foregroundColor: cs.error,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: onToggleTrust,
                  icon: Icon(
                    trusted ? Symbols.remove_moderator : Symbols.verified_user,
                    size: 16,
                  ),
                  label: Text(trusted ? 'Untrust' : 'Mark Trusted'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: trusted
                        ? cs.errorContainer
                        : cs.primaryContainer,
                    foregroundColor: trusted
                        ? cs.onErrorContainer
                        : cs.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Symbols.location_off, size: 64, color: cs.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'No login history yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to start tracking your login locations.',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
