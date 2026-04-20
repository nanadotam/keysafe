import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/vault_repository.dart';
import '../domain/vault_entry.dart';
import '../data/vault_local_db.dart';
import '../../auth/providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Offline-first vault provider
//
// Load strategy (mirrors the user's spec):
//
//  1. IMMEDIATELY serve from SQLite local cache (fast, works offline).
//  2. If device is online → fetch from server in the background and update
//     the in-memory state + refresh local cache.
//  3. On reconnect after being offline → auto-flush pending ops then refresh.
//
// The AES key (from Android Keystore / iOS Keychain) is in memory after login,
// so decryption always works offline without any extra prompts.
// ─────────────────────────────────────────────────────────────────────────────

final vaultRepositoryProvider = Provider<VaultRepository>(
  (ref) => VaultRepository(ref.watch(dioProvider)),
);

class VaultNotifier extends StateNotifier<AsyncValue<List<VaultEntry>>> {
  VaultNotifier(this._repo) : super(const AsyncValue.loading()) {
    // Start connectivity listener for auto-flush + background refresh.
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen(_onConnectivityChanged);
  }

  final VaultRepository _repo;
  String _categoryFilter = 'all';
  String _searchQuery    = '';
  bool   _backgrounding  = false;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  // ── Load (offline-first) ──────────────────────────────────────────────────

  /// Loads the vault using a two-phase strategy:
  ///   Phase 1: Immediately serve from the local SQLite cache (instant UX).
  ///   Phase 2: Refresh from server in the background if online.
  Future<void> load() async {
    // Phase 1 — show cached data immediately (no network, no wait).
    final cached = await VaultLocalDb.getAll();
    if (cached.isNotEmpty) {
      state = AsyncValue.data(cached);
    } else {
      state = const AsyncValue.loading();
    }

    // Phase 2 — background refresh from server.
    await _refreshFromServer(showLoadingIfEmpty: cached.isEmpty);
  }

  /// Silent background refresh — does NOT set loading state, just quietly
  /// updates if new data arrives.  Called by load() and connectivity events.
  Future<void> _refreshFromServer({bool showLoadingIfEmpty = false}) async {
    if (_backgrounding) return;
    _backgrounding = true;

    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) return;

      // Flush any pending offline ops before downloading fresh data.
      try {
        await _repo.flushPendingOps();
      } catch (_) {}

      final fresh = await _repo.fetchAll();
      if (mounted) {
        state = AsyncValue.data(fresh);
      }
    } catch (e, st) {
      // Only surface the error if we have nothing cached to show.
      if (state.valueOrNull?.isEmpty ?? true) {
        if (mounted) state = AsyncValue.error(e, st);
      }
      // Otherwise silently swallow — user still sees their cached data.
    } finally {
      _backgrounding = false;
    }
  }

  Future<void> refresh() async => _refreshFromServer();

  // ── Connectivity auto-refresh ─────────────────────────────────────────────

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final isOnline = !results.contains(ConnectivityResult.none);
    if (isOnline) {
      // Came back online — flush pending ops and pull fresh data.
      _refreshFromServer();
    }
  }

  // ── CRUD (unchanged, already offline-first in VaultRepository) ───────────

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
        name:          name,
        username:      username,
        plainPassword: plainPassword,
        url:           url,
        notes:         notes,
        category:      category,
      );
      if (mounted) state = AsyncValue.data([...current, entry]);
    } catch (e, st) {
      if (mounted) state = AsyncValue.data(current);
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
        id:                  id,
        name:                name,
        username:            username,
        plainPassword:       plainPassword,
        url:                 url,
        notes:               notes,
        category:            category,
        existingEncrypted:   existingEncrypted,
        existingStrength:    existingStrength,
        existingCreatedAt:   existingCreatedAt,
      );
      if (mounted) {
        state = AsyncValue.data(
          current.map((e) => e.id == id ? updated : e).toList(),
        );
      }
    } catch (e, st) {
      if (mounted) state = AsyncValue.data(current);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> delete(String id) async {
    final current = state.valueOrNull ?? [];
    if (mounted) {
      state = AsyncValue.data(current.where((e) => e.id != id).toList());
    }
    try {
      // Soft-delete locally first; the server delete is best-effort.
      await VaultLocalDb.softDelete(id);
      await _repo.delete(id);
    } catch (e, st) {
      if (mounted) state = AsyncValue.data(current);
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Permanently delete from trash (no server call needed — already deleted).
  Future<void> permanentlyDelete(String id) async {
    await VaultLocalDb.permanentlyDelete(id);
  }

  /// Restore an entry from the trash back to the active vault.
  Future<void> restore(String id) async {
    await VaultLocalDb.restore(id);
    await reloadFromLocal();
  }

  Future<void> reloadFromLocal() async {
    final entries = await VaultLocalDb.getAll();
    if (mounted) state = AsyncValue.data(entries);
  }

  /// Returns all soft-deleted entries.
  Future<List<({VaultEntry entry, DateTime deletedAt})>>
      getDeletedEntries() => VaultLocalDb.getDeleted();

  // ── Filtering / search (in-memory, no re-fetch) ───────────────────────────

  void setFilter(String category) => _categoryFilter = category;
  void setSearch(String query)    => _searchQuery    = query;

  List<VaultEntry> getFiltered(List<VaultEntry> all) {
    var filtered = all;
    if (_categoryFilter != 'all') {
      filtered = filtered.where((e) => e.category == _categoryFilter).toList();
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

  /// Manually flush pending operations (called from Settings).
  Future<void> flushPendingOps() => _repo.flushPendingOps();
}

final vaultProvider =
    StateNotifierProvider<VaultNotifier, AsyncValue<List<VaultEntry>>>(
  (ref) {
    final notifier = VaultNotifier(ref.watch(vaultRepositoryProvider));
    // Auto-load as soon as the provider is created.
    notifier.load();
    return notifier;
  },
);
