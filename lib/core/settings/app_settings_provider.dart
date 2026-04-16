import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_settings.dart';

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>(
  (ref) => AppSettingsNotifier()..load(),
);

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(const AppSettings.defaults());

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.passcode),
  );

  static const _biometricKey = 'settings_biometric_unlock';
  static const _clipboardKey = 'settings_auto_clear_clipboard';
  static const _notificationsKey = 'settings_notifications';
  static const _themeModeKey = 'settings_theme_mode';
  static const _autoLockKey = 'settings_auto_lock_seconds';
  static const _clipboardSecondsKey = 'settings_clipboard_clear_seconds';

  Future<void> load() async {
    final biometricValue = await _storage.read(key: _biometricKey);
    final clipboardValue = await _storage.read(key: _clipboardKey);
    final notificationsValue = await _storage.read(key: _notificationsKey);
    final themeModeValue = await _storage.read(key: _themeModeKey);
    final autoLockValue = await _storage.read(key: _autoLockKey);
    final clipboardSecondsValue =
        await _storage.read(key: _clipboardSecondsKey);

    state = state.copyWith(
      biometricUnlockEnabled:
          _parseBool(biometricValue, state.biometricUnlockEnabled),
      autoClearClipboardEnabled:
          _parseBool(clipboardValue, state.autoClearClipboardEnabled),
      notificationsEnabled:
          _parseBool(notificationsValue, state.notificationsEnabled),
      themeMode: _parseThemeMode(themeModeValue, state.themeMode),
      autoLockSeconds: _parseInt(autoLockValue, state.autoLockSeconds),
      clipboardClearSeconds:
          _parseInt(clipboardSecondsValue, state.clipboardClearSeconds),
    );
  }

  Future<void> setBiometricUnlockEnabled(bool value) async {
    state = state.copyWith(biometricUnlockEnabled: value);
    await _storage.write(key: _biometricKey, value: value.toString());
  }

  Future<void> setAutoClearClipboardEnabled(bool value) async {
    state = state.copyWith(autoClearClipboardEnabled: value);
    await _storage.write(key: _clipboardKey, value: value.toString());
  }

  Future<void> setNotificationsEnabled(bool value) async {
    state = state.copyWith(notificationsEnabled: value);
    await _storage.write(key: _notificationsKey, value: value.toString());
  }

  Future<void> setThemeMode(ThemeMode value) async {
    state = state.copyWith(themeMode: value);
    await _storage.write(key: _themeModeKey, value: value.name);
  }

  Future<void> setAutoLockSeconds(int value) async {
    state = state.copyWith(autoLockSeconds: value);
    await _storage.write(key: _autoLockKey, value: value.toString());
  }

  Future<void> setClipboardClearSeconds(int value) async {
    state = state.copyWith(clipboardClearSeconds: value);
    await _storage.write(key: _clipboardSecondsKey, value: value.toString());
  }

  bool _parseBool(String? value, bool fallback) {
    if (value == null) {
      return fallback;
    }
    return value.toLowerCase() == 'true';
  }

  int _parseInt(String? value, int fallback) {
    final parsed = int.tryParse(value ?? '');
    return parsed ?? fallback;
  }

  ThemeMode _parseThemeMode(String? value, ThemeMode fallback) {
    for (final mode in ThemeMode.values) {
      if (mode.name == value) {
        return mode;
      }
    }
    return fallback;
  }
}
