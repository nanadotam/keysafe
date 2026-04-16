import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/vault_repository.dart';
import '../domain/vault_entry.dart';
import '../../auth/providers/auth_provider.dart';

final vaultRepositoryProvider = Provider<VaultRepository>(
  (ref) => VaultRepository(ref.watch(dioProvider)),
);

class VaultNotifier extends StateNotifier<AsyncValue<List<VaultEntry>>> {
  final VaultRepository _repo;
  String _categoryFilter = 'all';
  String _searchQuery = '';

  VaultNotifier(this._repo) : super(const AsyncValue.loading());

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final entries = await _repo.fetchAll();
      state = AsyncValue.data(entries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async => load();

  Future<void> create({
    required String name,
    required String username,
    required String plainPassword,
    required String url,
    required String notes,
    required String category,
  }) async {
    final current = state.valueOrNull ?? [];
    try {
      final entry = await _repo.create(
        name: name,
        username: username,
        plainPassword: plainPassword,
        url: url,
        notes: notes,
        category: category,
      );
      state = AsyncValue.data([...current, entry]);
    } catch (e, st) {
      state = AsyncValue.data(current);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> update({
    required String id,
    required String name,
    required String username,
    String? plainPassword,
    required String url,
    required String notes,
    required String category,
    required String existingEncrypted,
    required int existingStrength,
    required DateTime existingCreatedAt,
  }) async {
    final current = state.valueOrNull ?? [];
    try {
      final updated = await _repo.update(
        id: id,
        name: name,
        username: username,
        plainPassword: plainPassword,
        url: url,
        notes: notes,
        category: category,
        existingEncrypted: existingEncrypted,
        existingStrength: existingStrength,
        existingCreatedAt: existingCreatedAt,
      );
      state = AsyncValue.data(
        current.map((e) => e.id == id ? updated : e).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.data(current);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> delete(String id) async {
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((e) => e.id != id).toList());
    try {
      await _repo.delete(id);
    } catch (e, st) {
      state = AsyncValue.data(current);
      Error.throwWithStackTrace(e, st);
    }
  }

  void setFilter(String category) {
    _categoryFilter = category;
  }

  void setSearch(String query) {
    _searchQuery = query;
  }

  List<VaultEntry> getFiltered(List<VaultEntry> all) {
    var filtered = all;
    if (_categoryFilter != 'all') {
      filtered = filtered
          .where((e) => e.category == _categoryFilter)
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (e) =>
                e.name.toLowerCase().contains(q) ||
                e.username.toLowerCase().contains(q),
          )
          .toList();
    }
    return filtered;
  }

  Future<void> flushPendingOps() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) return;
    await _repo.flushPendingOps();
  }
}

final vaultProvider =
    StateNotifierProvider<VaultNotifier, AsyncValue<List<VaultEntry>>>(
  (ref) => VaultNotifier(ref.watch(vaultRepositoryProvider)),
);
