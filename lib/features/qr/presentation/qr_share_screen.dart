import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../../vault/domain/vault_entry.dart';

class QrShareScreen extends StatefulWidget {
  final VaultEntry entry;
  const QrShareScreen({super.key, required this.entry});

  @override
  State<QrShareScreen> createState() => _QrShareScreenState();
}

class _QrShareScreenState extends State<QrShareScreen> {
  final _qrKey  = GlobalKey();
  int   _remaining = 60;
  Timer? _timer;
  bool  _sharing   = false;

  // The user can adjust how long before the code expires.
  int _expirySeconds = 60;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _remaining = _expirySeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _remaining--);
      if (_remaining <= 0) {
        t.cancel();
        if (mounted) Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Encode as a URI that KeySafe can scan and import directly.
  // Format: keysafe://import?service=...&username=...&enc=...
  // The `enc` parameter holds the AES-GCM encrypted password (base64).
  // Another KeySafe user scanning this will be prompted to decrypt with
  // their own master key — the encrypted blob can only be read by someone
  // who knows the original vault key.
  String get _qrData {
    final params = Uri(
      scheme: 'keysafe',
      host: 'import',
      queryParameters: {
        'service':  widget.entry.name,
        'username': widget.entry.username,
        'url':      widget.entry.url,
        'enc':      widget.entry.encryptedPassword,
      },
    ).toString();
    return params;
  }

  // ── Capture the QR widget as a PNG and share it as a real image ───────────
  Future<void> _shareAsImage() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    HapticFeedback.lightImpact();

    try {
      // Render the RepaintBoundary to an image.
      final boundary = _qrKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not capture QR code')),
          );
        }
        return;
      }

      final image     = await boundary.toImage(pixelRatio: 3.0);
      final byteData  = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes  = byteData.buffer.asUint8List();
      final tmpDir    = await getTemporaryDirectory();
      final fileName  = 'keysafe_${widget.entry.name.replaceAll(' ', '_')}_qr.png';
      final file      = File('${tmpDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: 'KeySafe – ${widget.entry.name}',
        text:    '${widget.entry.name} credentials QR from KeySafe',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _setExpiry(int seconds) {
    setState(() {
      _expirySeconds = seconds;
    });
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _remaining / _expirySeconds;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share via QR'),
        leading: const BackButton(),
        actions: [
          // Let the user pick a custom expiry time.
          PopupMenuButton<int>(
            icon: const Icon(Symbols.timer),
            tooltip: 'Set expiry time',
            onSelected: _setExpiry,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 30,  child: Text('30 seconds')),
              PopupMenuItem(value: 60,  child: Text('1 minute')),
              PopupMenuItem(value: 120, child: Text('2 minutes')),
              PopupMenuItem(value: 300, child: Text('5 minutes')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── QR card (captured by RepaintBoundary) ──────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      RepaintBoundary(
                        key: _qrKey,
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(12),
                          child: QrImageView(
                            data:            _qrData,
                            version:         QrVersions.auto,
                            size:            220,
                            backgroundColor: Colors.white,
                            errorCorrectionLevel: QrErrorCorrectLevel.M,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.entry.name,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        widget.entry.username,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Security note
                      Text(
                        '⚠️ Scan with KeySafe to import. Password is encrypted — '
                        'only readable with the original vault key.',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Expiry progress ──────────────────────────────────────────
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                borderRadius: BorderRadius.circular(4),
                color: progress < 0.25
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
              const SizedBox(height: 4),
              Text(
                'QR expires in ${_remaining}s — tap the timer icon to extend',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),

              // ── Share button ─────────────────────────────────────────────
              FilledButton.icon(
                onPressed: _sharing ? null : _shareAsImage,
                icon: _sharing
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Symbols.share),
                label: Text(_sharing ? 'Preparing image…' : 'Share QR as Image'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
