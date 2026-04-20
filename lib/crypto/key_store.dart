import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KeyStore {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.passcode),
  );

  static const _aesKeyKey             = 'vault_aes_key';
  static const _accessTokenKey        = 'access_token';
  static const _refreshTokenKey       = 'refresh_token';
  static const _userIdKey             = 'user_id';
  static const _userEmailKey          = 'user_email';
  static const _displayNameKey        = 'display_name';
  static const _firstNameKey          = 'first_name';
  static const _lastNameKey           = 'last_name';
  static const _hashedPasswordKey     = 'hashed_master_password';
  static const _biometricEnabledKey   = 'biometric_enabled';
  static const _onboardingSeenKey     = 'onboarding_seen';

  // ── AES Key ──────────────────────────────────────────────────────────────
  static Future<void> storeAesKey(Uint8List key) async {
    await _storage.write(key: _aesKeyKey, value: base64Encode(key));
  }

  static Future<Uint8List?> getAesKey() async {
    final val = await _storage.read(key: _aesKeyKey);
    if (val == null) return null;
    return base64Decode(val);
  }

  // ── Tokens ────────────────────────────────────────────────────────────────
  static Future<void> storeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  static Future<String?> getAccessToken() =>
      _storage.read(key: _accessTokenKey);

  static Future<String?> getRefreshToken() =>
      _storage.read(key: _refreshTokenKey);

  // ── User Info ─────────────────────────────────────────────────────────────
  static Future<void> storeUserInfo({
    required String userId,
    required String email,
    String? displayName,
    String? firstName,
    String? lastName,
  }) async {
    final ops = [
      _storage.write(key: _userIdKey, value: userId),
      _storage.write(key: _userEmailKey, value: email),
    ];
    if (displayName != null) {
      ops.add(_storage.write(key: _displayNameKey, value: displayName));
    }
    if (firstName != null) {
      ops.add(_storage.write(key: _firstNameKey, value: firstName));
    }
    if (lastName != null) {
      ops.add(_storage.write(key: _lastNameKey, value: lastName));
    }
    await Future.wait(ops);
  }

  static Future<String?> getUserId()    => _storage.read(key: _userIdKey);
  static Future<String?> getUserEmail() => _storage.read(key: _userEmailKey);
  static Future<String?> getDisplayName() =>
      _storage.read(key: _displayNameKey);
  static Future<String?> getFirstName() => _storage.read(key: _firstNameKey);
  static Future<String?> getLastName()  => _storage.read(key: _lastNameKey);

  static Future<void> storeDisplayName(String name) =>
      _storage.write(key: _displayNameKey, value: name);

  // ── Master-password hash (for offline "remember me" unlock) ───────────────
  /// Store an AES-key-derived hash so the lock screen can verify the master
  /// password locally without hitting the network.
  static Future<void> storeMasterPasswordHash(String hash) =>
      _storage.write(key: _hashedPasswordKey, value: hash);

  static Future<String?> getMasterPasswordHash() =>
      _storage.read(key: _hashedPasswordKey);

  // ── Biometric flag ────────────────────────────────────────────────────────
  static Future<void> setBiometricEnabled(bool value) =>
      _storage.write(key: _biometricEnabledKey, value: value.toString());

  static Future<bool> getBiometricEnabled() async {
    final v = await _storage.read(key: _biometricEnabledKey);
    return v == 'true';
  }

  // ── Onboarding flag ───────────────────────────────────────────────────────
  static Future<void> setOnboardingSeen(bool value) =>
      _storage.write(key: _onboardingSeenKey, value: value.toString());

  static Future<bool> getOnboardingSeen() async {
    final v = await _storage.read(key: _onboardingSeenKey);
    return v == 'true';
  }

  // ── Wipe ──────────────────────────────────────────────────────────────────
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  static Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _aesKeyKey),
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }
}
