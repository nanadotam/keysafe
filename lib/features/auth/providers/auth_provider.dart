import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../data/auth_repository.dart';
import '../domain/auth_state.dart';
import '../../../crypto/key_store.dart';
import '../../../network/dio_client.dart';

final dioProvider = Provider<Dio>((ref) => createDioClient());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider)),
);

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState.initial());

  Future<void> checkAuth() async {
    state = const AuthState.loading();
    final token = await KeyStore.getAccessToken();
    final aesKey = await KeyStore.getAesKey();
    if (token != null && aesKey != null) {
      final userId = await KeyStore.getUserId() ?? '';
      final email = await KeyStore.getUserEmail() ?? '';
      state = AuthState.authenticated(userId: userId, email: email);
    } else if (token != null) {
      state = const AuthState.locked();
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AuthState.loading();
    try {
      final result = await _repo.login(email: email, password: password);
      state = AuthState.authenticated(
        userId: result.userId,
        email: result.email,
      );
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    state = const AuthState.loading();
    try {
      final result = await _repo.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      state = AuthState.authenticated(
        userId: result.userId,
        email: result.email,
      );
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState.unauthenticated();
  }

  void lock() => state = const AuthState.locked();

  Future<void> unlockWithBiometrics() async {
    final aesKey = await KeyStore.getAesKey();
    if (aesKey != null) {
      final userId = await KeyStore.getUserId() ?? '';
      final email = await KeyStore.getUserEmail() ?? '';
      state = AuthState.authenticated(userId: userId, email: email);
    } else {
      state = const AuthState.unauthenticated();
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(authRepositoryProvider)),
);
