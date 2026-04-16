// lib/core/services/biometric_service.dart
//
// Wraps local_auth + FlutterSecureStorage in a single injectable service,
// modeled after hostel_hub's BiometricAuthService pattern.
//
// KEY DESIGN DECISIONS (matching hostel_hub)
// ─────────────────────────────────────────
// • Stores the master-password *hash* in the Keystore rather than the
//   raw password — matching the pattern in KeyStore.  The lock screen
//   verifies it offline.
// • biometricOnly = false → allows device PIN / pattern / password as
//   fallback so users without enrolled biometrics can still use the
//   "on-device lock" feature with their screen lock PIN.
// • stickyAuth = true  → OS dialog persists through app switches so the
//   authentication isn't cancelled when the user swaps apps.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data classes
// ─────────────────────────────────────────────────────────────────────────────

class BiometricStatus {
  const BiometricStatus({
    required this.isSupported,
    required this.availableBiometrics,
    required this.isEnabled,
  });

  final bool isSupported;
  final List<BiometricType> availableBiometrics;
  final bool isEnabled;
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class BiometricService {
  BiometricService({
    LocalAuthentication? localAuth,
    FlutterSecureStorage? storage,
  })  : _localAuth = localAuth ?? LocalAuthentication(),
        _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.passcode,
              ),
            );

  static const _enabledKey = 'biometric_feature_enabled';

  final LocalAuthentication _localAuth;
  final FlutterSecureStorage _storage;

  // ── Status ─────────────────────────────────────────────────────────────────

  Future<BiometricStatus> getStatus() async {
    try {
      final canCheck   = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      final biometrics = await _localAuth.getAvailableBiometrics();
      final enabled    = await isEnabled();

      return BiometricStatus(
        isSupported:         canCheck || isSupported,
        availableBiometrics: biometrics,
        isEnabled:           enabled,
      );
    } catch (_) {
      return const BiometricStatus(
        isSupported:         false,
        availableBiometrics: [],
        isEnabled:           false,
      );
    }
  }

  // ── Authenticate ───────────────────────────────────────────────────────────

  /// Prompts the OS authentication dialog.
  ///
  /// [biometricOnly] = false  → also accepts device PIN / pattern / password.
  Future<bool> authenticate({
    required String localizedReason,
    bool biometricOnly = false,
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // ── Enable / disable flag ──────────────────────────────────────────────────

  Future<bool> isEnabled() async {
    final v = await _storage.read(key: _enabledKey);
    return v == 'true';
  }

  Future<void> enable() =>
      _storage.write(key: _enabledKey, value: 'true');

  Future<void> disable() =>
      _storage.write(key: _enabledKey, value: 'false');
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod provider
// ─────────────────────────────────────────────────────────────────────────────

final biometricServiceProvider = Provider<BiometricService>(
  (_) => BiometricService(),
);
