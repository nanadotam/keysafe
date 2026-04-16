import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../crypto/crypto_service.dart';
import '../../../crypto/key_store.dart';
import '../../vault/data/vault_local_db.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<({String userId, String email, String name})> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      final userId      = data['user_id'] as String;
      final accessToken  = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String;
      final name         = (data['name'] as String?) ?? email.split('@').first;

      await KeyStore.storeTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      await KeyStore.storeUserInfo(userId: userId, email: email, displayName: name);

      final aesKey = CryptoService.deriveKey(
        masterPassword: password,
        salt: userId,
      );
      await KeyStore.storeAesKey(aesKey);

      // Store a sha-256 hash of the master password so the lock screen
      // can verify the password locally without a network round-trip.
      final hash = base64Encode(
        crypto.sha256.convert(utf8.encode(password + userId)).bytes,
      );
      await KeyStore.storeMasterPasswordHash(hash);
      await KeyStore.setOnboardingSeen(true);

      return (userId: userId, email: email, name: name);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<({String userId, String email, String name})> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.register,
        data: {'email': email, 'password': password, 'name': name},
      );
      final data = response.data as Map<String, dynamic>;
      final userId      = data['user_id'] as String;
      final accessToken  = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String;

      await KeyStore.storeTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      await KeyStore.storeUserInfo(userId: userId, email: email, displayName: name);

      final aesKey = CryptoService.deriveKey(
        masterPassword: password,
        salt: userId,
      );
      await KeyStore.storeAesKey(aesKey);

      final hash = base64Encode(
        crypto.sha256.convert(utf8.encode(password + userId)).bytes,
      );
      await KeyStore.storeMasterPasswordHash(hash);
      await KeyStore.setOnboardingSeen(true);

      return (userId: userId, email: email, name: name);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> logout() async {
    final refreshToken = await KeyStore.getRefreshToken();
    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _dio.post(
          ApiEndpoints.logout,
          data: {'refresh_token': refreshToken},
        );
      }
    } catch (_) {}
    // Wipe all local vault data (SQLite + secure-storage snapshot).
    await VaultLocalDb.clearAll();
    await KeyStore.clearAll();
  }

  String _mapError(DioException e) {
    switch (e.response?.statusCode) {
      case 400:
        return 'Invalid request. Please check your details.';
      case 401:
        return 'Incorrect email or password.';
      case 403:
        return 'Account locked. Try again later.';
      case 409:
        return 'An account with this email already exists.';
      case 429:
        return 'Too many attempts. Please wait before trying again.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          return 'Connection timed out. Check your internet.';
        }
        return 'Something went wrong. Please try again.';
    }
  }
}
