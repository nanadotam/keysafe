import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../providers/vault_provider.dart';
import '../domain/vault_entry.dart';

class RecentlyDeletedScreen extends ConsumerStatefulWidget {
  const RecentlyDeletedScreen({super.key});

  @override
  ConsumerState<RecentlyDeletedScreen> createState() =>
      _RecentlyDeletedScreenState();
}

class _RecentlyDeletedScreenState
    extends ConsumerState<RecentlyDeletedScreen> {
  List<({VaultEntry entry, DateTime deletedAt})> _deleted = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items =
        await ref.read(vaultProvider.notifier).getDeletedEntries();
    if (mounted) setState(() { _deleted = items; _loading = false; });
  }

  Future<void> _restore(String id) async {
    await ref.read(vaultProvider.notifier).restore(id);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password restored to vault.')),
      );
    }
  }

  Future<void> _permanentDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete permanently?'),
        content: const Text(
            'This cannot be undone. The password will be gone forever.'),
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
    if (confirmed != true) return;
    await ref.read(vaultProvider.notifier).permanentlyDelete(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recently Deleted'),
        actions: [
          if (_deleted.isNotEmpty)
            TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete all?'),
                    content: const Text(
                        'All deleted passwords will be permanently removed.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete All'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true) return;
                for (final item in List.of(_deleted)) {
                  await ref
                      .read(vaultProvider.notifier)
                      .permanentlyDelete(item.entry.id);
                }
                await _load();
              },
              child: Text(
                'Delete All',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _deleted.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Symbols.delete_sweep,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text(
                        'No recently deleted passwords',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Deleted items are kept for 30 days',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _deleted.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final item = _deleted[i];
                      final daysLeft = 30 -
                          DateTime.now()
                              .difference(item.deletedAt)
                              .inDays;
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.errorContainer,
                            child: Icon(Symbols.delete,
                                color: theme.colorScheme.error, size: 20),
                          ),
                          title: Text(item.entry.name),
                          subtitle: Text(
                            '${item.entry.username} • Deleted '
                            '${DateFormat.MMMd().format(item.deletedAt)} '
                            '($daysLeft days left)',
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Symbols.restore),
                                tooltip: 'Restore',
                                onPressed: () =>
                                    _restore(item.entry.id),
                              ),
                              IconButton(
                                icon: Icon(Symbols.delete_forever,
                                    color: theme.colorScheme.error),
                                tooltip: 'Delete permanently',
                                onPressed: () =>
                                    _permanentDelete(item.entry.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
