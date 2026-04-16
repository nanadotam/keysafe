import 'package:flutter/material.dart';

class AppSettings {
  final bool biometricUnlockEnabled;
  final bool autoClearClipboardEnabled;
  final bool notificationsEnabled;
  final ThemeMode themeMode;
  final int autoLockSeconds;
  final int clipboardClearSeconds;

  const AppSettings({
    required this.biometricUnlockEnabled,
    required this.autoClearClipboardEnabled,
    required this.notificationsEnabled,
    required this.themeMode,
    required this.autoLockSeconds,
    required this.clipboardClearSeconds,
  });

  const AppSettings.defaults()
      : biometricUnlockEnabled = true,
        autoClearClipboardEnabled = true,
        notificationsEnabled = true,
        themeMode = ThemeMode.dark,
        autoLockSeconds = 60,
        clipboardClearSeconds = 30;

  bool get autoLockDisabled => autoLockSeconds <= 0;

  Duration get autoLockDuration => Duration(seconds: autoLockSeconds);

  AppSettings copyWith({
    bool? biometricUnlockEnabled,
    bool? autoClearClipboardEnabled,
    bool? notificationsEnabled,
    ThemeMode? themeMode,
    int? autoLockSeconds,
    int? clipboardClearSeconds,
  }) {
    return AppSettings(
      biometricUnlockEnabled:
          biometricUnlockEnabled ?? this.biometricUnlockEnabled,
      autoClearClipboardEnabled:
          autoClearClipboardEnabled ?? this.autoClearClipboardEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      themeMode: themeMode ?? this.themeMode,
      autoLockSeconds: autoLockSeconds ?? this.autoLockSeconds,
      clipboardClearSeconds: clipboardClearSeconds ?? this.clipboardClearSeconds,
    );
  }
}
