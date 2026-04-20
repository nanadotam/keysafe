import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ── Android channels ────────────────────────────────────────────────────────

  static const _generalDetails = AndroidNotificationDetails(
    'keysafe_general',
    'KeySafe',
    channelDescription: 'General vault notifications',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static const _breachDetails = AndroidNotificationDetails(
    'keysafe_breach',
    'Security Alerts',
    channelDescription: 'Password breach and security warnings',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
  );

  static const _syncDetails = AndroidNotificationDetails(
    'keysafe_sync',
    'Sync Status',
    channelDescription: 'Vault cloud synchronisation status',
    importance: Importance.low,
    priority: Priority.low,
    playSound: false,
  );

  static const _locationDetails = AndroidNotificationDetails(
    'keysafe_location',
    'Login Alerts',
    channelDescription: 'Login location security notifications',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
  );

  // ── NotificationDetails wrappers ────────────────────────────────────────────

  static const _general  = NotificationDetails(android: _generalDetails);
  static const _breach   = NotificationDetails(android: _breachDetails);
  static const _sync     = NotificationDetails(android: _syncDetails);
  static const _location = NotificationDetails(android: _locationDetails);

  // ── Stable notification IDs ─────────────────────────────────────────────────

  static const _idClipboard   = 100;
  static const _idBreachScan  = 101;
  static const _idVaultWipe   = 102;
  static const _idNewLocation = 200;
  static const _idSyncStart   = 201;
  static const _idSyncDone    = 202;
  static const _idWeakPasswords = 203;
  static const _idCompromised   = 204;

  // ── Initialisation ──────────────────────────────────────────────────────────

  static Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  static Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    final androidGranted = await android?.requestNotificationsPermission();
    final iosGranted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return (androidGranted ?? true) && (iosGranted ?? true);
  }

  // ── Generic show ────────────────────────────────────────────────────────────

  static Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(id, title, body, _general);
  }

  // ── Security / breach alerts ─────────────────────────────────────────────────

  static Future<void> showBreachScanResult(int compromised) async {
    if (compromised == 0) {
      await _plugin.show(
        _idBreachScan,
        'All Passwords Safe',
        'No compromised passwords were found in the latest scan.',
        _general,
      );
    } else {
      await _plugin.show(
        _idCompromised,
        'Compromised Passwords Found',
        '$compromised password${compromised == 1 ? '' : 's'} appeared in known data breaches. '
            'Open KeySafe to update them.',
        _breach,
      );
    }
  }

  static Future<void> showWeakPasswordAlert(int count) async {
    await _plugin.show(
      _idWeakPasswords,
      'Weak Passwords Detected',
      '$count password${count == 1 ? '' : 's'} in your vault ${count == 1 ? 'is' : 'are'} weak. '
          'Open KeySafe to strengthen them.',
      _breach,
    );
  }

  static Future<void> showVaultWiped() async {
    await _plugin.show(
      _idVaultWipe,
      'Vault Wiped',
      'All vault entries were permanently deleted from this device.',
      _general,
    );
  }

  // ── Sync notifications ──────────────────────────────────────────────────────

  static Future<void> showSyncStarted() async {
    await _plugin.show(
      _idSyncStart,
      'Syncing Vault',
      'Your passwords are being synced to the cloud…',
      _sync,
    );
  }

  static Future<void> showSyncComplete({int count = 0}) async {
    await _plugin.show(
      _idSyncDone,
      'Vault Synced',
      count > 0
          ? '$count change${count == 1 ? '' : 's'} synced to the cloud.'
          : 'Your vault is up to date.',
      _sync,
    );
  }

  // ── Location notifications ──────────────────────────────────────────────────

  static Future<void> showNewLocationLogin(String locationDisplay) async {
    await _plugin.show(
      _idNewLocation,
      'New Login Location',
      'You just signed in from $locationDisplay. '
          'Open KeySafe to mark it as trusted or review your login history.',
      _location,
    );
  }

  static Future<void> showClipboardCleared() async {
    await _plugin.show(
      _idClipboard,
      'Clipboard Cleared',
      'Your copied password has been removed from the clipboard.',
      _general,
    );
  }
}
