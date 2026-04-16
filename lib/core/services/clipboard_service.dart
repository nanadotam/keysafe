import 'dart:async';
import 'package:flutter/services.dart';

class ClipboardService {
  static Timer? _clearTimer;

  static Future<void> copyAndScheduleClear(
    String text, {
    int durationSeconds = 30,
    void Function(int remaining)? onTick,
    void Function()? onCleared,
  }) async {
    _clearTimer?.cancel();
    await Clipboard.setData(ClipboardData(text: text));

    var remaining = durationSeconds;
    _clearTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;
      onTick?.call(remaining);
      if (remaining <= 0) {
        timer.cancel();
        Clipboard.setData(const ClipboardData(text: ''));
        _clearTimer = null;
        onCleared?.call();
      }
    });
  }

  static void cancelClear() {
    _clearTimer?.cancel();
    _clearTimer = null;
  }
}
