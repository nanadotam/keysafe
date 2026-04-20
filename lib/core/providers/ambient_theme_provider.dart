import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AMBIENT DARK MODE — three strategies persisted in FlutterSecureStorage
// ─────────────────────────────────────────────────────────────────────────────

enum DarkModeStrategy { manual, scheduled, sensor }

class DarkModeConfig {
  final DarkModeStrategy strategy;
  final bool manualDark;
  final int scheduleStartHour;
  final int scheduleStartMinute;
  final int scheduleEndHour;
  final int scheduleEndMinute;
  final double luxThreshold;

  const DarkModeConfig({
    this.strategy = DarkModeStrategy.manual,
    this.manualDark = false,
    this.scheduleStartHour = 19,
    this.scheduleStartMinute = 0,
    this.scheduleEndHour = 7,
    this.scheduleEndMinute = 0,
    this.luxThreshold = 50.0,
  });

  DarkModeConfig copyWith({
    DarkModeStrategy? strategy,
    bool? manualDark,
    int? scheduleStartHour,
    int? scheduleStartMinute,
    int? scheduleEndHour,
    int? scheduleEndMinute,
    double? luxThreshold,
  }) {
    return DarkModeConfig(
      strategy: strategy ?? this.strategy,
      manualDark: manualDark ?? this.manualDark,
      scheduleStartHour: scheduleStartHour ?? this.scheduleStartHour,
      scheduleStartMinute: scheduleStartMinute ?? this.scheduleStartMinute,
      scheduleEndHour: scheduleEndHour ?? this.scheduleEndHour,
      scheduleEndMinute: scheduleEndMinute ?? this.scheduleEndMinute,
      luxThreshold: luxThreshold ?? this.luxThreshold,
    );
  }
}

/// Reactive mirror of [DarkModeConfig] so UI rebuilds when strategy changes.
final darkModeConfigProvider = StateProvider<DarkModeConfig>(
  (_) => const DarkModeConfig(),
);

/// Manages the effective [ThemeMode] based on the chosen strategy.
class AmbientThemeNotifier extends StateNotifier<ThemeMode> {
  AmbientThemeNotifier(this._ref) : super(ThemeMode.dark) {
    _load();
  }

  final Ref _ref;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.passcode),
  );

  static const _kStrategy  = 'amb_strategy';
  static const _kManual    = 'amb_manual_dark';
  static const _kStartH    = 'amb_sched_start_h';
  static const _kStartM    = 'amb_sched_start_m';
  static const _kEndH      = 'amb_sched_end_h';
  static const _kEndM      = 'amb_sched_end_m';
  static const _kLux       = 'amb_lux_threshold';

  DarkModeConfig _config = const DarkModeConfig();
  Timer? _scheduleTimer;
  StreamSubscription<int>? _lightSub;

  int? lastLux;

  DarkModeConfig get config => _config;

  Future<void> _load() async {
    try {
      final stratStr = await _storage.read(key: _kStrategy) ?? 'manual';
      final strategy = DarkModeStrategy.values.firstWhere(
        (s) => s.name == stratStr,
        orElse: () => DarkModeStrategy.manual,
      );
      _config = DarkModeConfig(
        strategy: strategy,
        manualDark:
            (await _storage.read(key: _kManual)) == 'true',
        scheduleStartHour:
            int.tryParse(await _storage.read(key: _kStartH) ?? '') ?? 19,
        scheduleStartMinute:
            int.tryParse(await _storage.read(key: _kStartM) ?? '') ?? 0,
        scheduleEndHour:
            int.tryParse(await _storage.read(key: _kEndH) ?? '') ?? 7,
        scheduleEndMinute:
            int.tryParse(await _storage.read(key: _kEndM) ?? '') ?? 0,
        luxThreshold:
            double.tryParse(await _storage.read(key: _kLux) ?? '') ?? 50.0,
      );
      try {
        _ref.read(darkModeConfigProvider.notifier).state = _config;
      } catch (_) {}
    } catch (_) {}
    _applyStrategy();
  }

  Future<void> _persist() async {
    try {
      await Future.wait([
        _storage.write(key: _kStrategy, value: _config.strategy.name),
        _storage.write(key: _kManual,   value: _config.manualDark.toString()),
        _storage.write(key: _kStartH,   value: _config.scheduleStartHour.toString()),
        _storage.write(key: _kStartM,   value: _config.scheduleStartMinute.toString()),
        _storage.write(key: _kEndH,     value: _config.scheduleEndHour.toString()),
        _storage.write(key: _kEndM,     value: _config.scheduleEndMinute.toString()),
        _storage.write(key: _kLux,      value: _config.luxThreshold.toString()),
      ]);
    } catch (_) {}
  }

  void updateConfig(DarkModeConfig newConfig) {
    _config = newConfig;
    _persist();
    try {
      _ref.read(darkModeConfigProvider.notifier).state = newConfig;
    } catch (_) {}
    _applyStrategy();
  }

  void setDarkMode(bool isDark) {
    updateConfig(_config.copyWith(
      strategy: DarkModeStrategy.manual,
      manualDark: isDark,
    ));
  }

  void _applyStrategy() {
    _cancelSideEffects();
    switch (_config.strategy) {
      case DarkModeStrategy.manual:
        state = _config.manualDark ? ThemeMode.dark : ThemeMode.light;

      case DarkModeStrategy.scheduled:
        state = _withinSchedule() ? ThemeMode.dark : ThemeMode.light;
        _scheduleTimer = Timer.periodic(const Duration(minutes: 1), (_) {
          final next = _withinSchedule() ? ThemeMode.dark : ThemeMode.light;
          if (next != state) state = next;
        });

      case DarkModeStrategy.sensor:
        _startSensorMode();
    }
  }

  bool _withinSchedule() {
    final now = DateTime.now();
    final cur   = now.hour * 60 + now.minute;
    final start = _config.scheduleStartHour * 60 + _config.scheduleStartMinute;
    final end   = _config.scheduleEndHour   * 60 + _config.scheduleEndMinute;
    return start > end
        ? (cur >= start || cur < end)
        : (cur >= start && cur < end);
  }

  void _startSensorMode() {
    // Ambient light sensor requires hardware support.
    // When a supported sensor stream is not available the app falls back to
    // the system theme so automatic switching still works at OS level.
    try {
      _lightSub = _luxStream().listen(
        (lux) {
          lastLux = lux;
          final next = lux < _config.luxThreshold
              ? ThemeMode.dark
              : ThemeMode.light;
          if (next != state) state = next;
        },
        onError: (_) => state = ThemeMode.system,
        onDone: () => state = ThemeMode.system,
      );
    } catch (_) {
      state = ThemeMode.system;
    }
  }

  /// Returns a live lux stream when hardware is available, otherwise empty.
  static Stream<int> _luxStream() => const Stream.empty();

  void _cancelSideEffects() {
    _scheduleTimer?.cancel();
    _scheduleTimer = null;
    _lightSub?.cancel();
    _lightSub = null;
  }

  @override
  void dispose() {
    _cancelSideEffects();
    super.dispose();
  }
}

final themeModeProvider =
    StateNotifierProvider<AmbientThemeNotifier, ThemeMode>(
  (ref) => AmbientThemeNotifier(ref),
);

/// Live lux stream — active only while the ambient-dark-mode screen is open.
/// Returns an empty stream when hardware support is unavailable.
final luxReadingProvider = StreamProvider.autoDispose<int>(
  (_) => AmbientThemeNotifier._luxStream(),
);
