import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../providers/vault_provider.dart';
import '../domain/vault_entry.dart';
import '../../../core/constants/routes.dart';
import '../../../core/widgets/category_icon.dart';
import '../../../core/widgets/strength_badge.dart';
import '../../../core/widgets/cat_filter_chip.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedCategory = 'all';
  String _searchQuery = '';
  final _searchController = SearchController();
  static const _categories = [
    'all',
    'social',
    'finance',
    'email',
    'shopping',
    'apps',
    'personal',
    'wifi',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vaultProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<VaultEntry> _filtered(List<VaultEntry> all) {
    var list = all;
    if (_selectedCategory != 'all') {
      list = list.where((e) => e.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (e) =>
                e.name.toLowerCase().contains(q) ||
                e.username.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vaultState = ref.watch(vaultProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(vaultProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: const Text('KeySafe'),
              actions: [
                IconButton(
                  icon: const Icon(Symbols.person),
                  onPressed: () => context.push(Routes.profile),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Search passwords...',
                  leading: const Icon(Symbols.search),
                  trailing: [
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Symbols.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                  ],
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: vaultState.when(
                data: (entries) => _StatsRow(entries: entries),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final cat = _categories[i];
                    return CatFilterChip(
                      category: cat,
                      selected: _selectedCategory == cat,
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedCategory = cat);
                      },
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            vaultState.when(
              data: (entries) {
                final filtered = _filtered(entries);
                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Symbols.lock_open,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            entries.isEmpty
                                ? 'No passwords yet'
                                : 'No results found',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          if (entries.isEmpty)
                            FilledButton.icon(
                              onPressed: () => context.push(Routes.addPassword),
                              icon: const Icon(Symbols.add),
                              label: const Text('Add Password'),
                            ),
                        ],
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _VaultListTile(entry: filtered[i]),
                      childCount: filtered.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Symbols.error, color: theme.colorScheme.error),
                        const SizedBox(height: 8),
                        Text(e.toString()),
                        const SizedBox(height: 16),
                        FilledButton.tonal(
                          onPressed: () =>
                              ref.read(vaultProvider.notifier).load(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          context.push(Routes.addPassword);
        },
        child: const Icon(Symbols.add),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final List<VaultEntry> entries;
  const _StatsRow({required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weakCount = entries
        .where((e) => e.strengthScore < 40)
        .length;
    final score = entries.isEmpty
        ? 100
        : (100 - weakCount * 5).clamp(0, 100);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${entries.length}',
                        style: theme.textTheme.displaySmall),
                    Text('Passwords',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$score',
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: score > 70
                              ? const Color(0xFF60BA46)
                              : score > 40
                                  ? const Color(0xFFFFC600)
                                  : const Color(0xFFFE5257),
                        )),
                    Text('Security Score',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VaultListTile extends StatelessWidget {
  final VaultEntry entry;
  const _VaultListTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CategoryIcon(category: entry.category),
      title: Text(entry.name),
      subtitle: Text(
        entry.username,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StrengthBadge.fromScore(entry.strengthScore),
          const SizedBox(width: 4),
          const Icon(Symbols.chevron_right),
        ],
      ),
      onTap: () => context.push(Routes.detail, extra: entry),
    );
  }
}
