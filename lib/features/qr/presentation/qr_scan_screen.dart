import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/routes.dart';

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  final _controller = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(String raw) {
    if (_scanned) return;
    setState(() => _scanned = true);

    // Try to parse as a keysafe:// URI
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.scheme == 'keysafe' && uri.host == 'import') {
      final service  = uri.queryParameters['service']  ?? '';
      final username = uri.queryParameters['username'] ?? '';
      final url      = uri.queryParameters['url']      ?? '';
      final enc      = uri.queryParameters['enc']      ?? '';
      _showKeysafeImportDialog(
        service: service,
        username: username,
        url: url,
        enc: enc,
      );
    } else {
      // Generic QR — show text and offer copy
      _showGenericDialog(raw);
    }
  }

  void _showGenericDialog(String raw) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('QR Code Scanned'),
        content: SelectableText(raw),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: raw));
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('Copy & Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop(raw);
            },
            child: const Text('Use'),
          ),
        ],
      ),
    ).then((_) { if (mounted) setState(() => _scanned = false); });
  }

  void _showKeysafeImportDialog({
    required String service,
    required String username,
    required String url,
    required String enc,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Password?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.label_outline),
              title: const Text('Service'),
              subtitle: Text(service.isEmpty ? '—' : service),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline),
              title: const Text('Username'),
              subtitle: Text(username.isEmpty ? '—' : username),
            ),
            if (url.isNotEmpty)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.link),
                title: const Text('URL'),
                subtitle: Text(url),
              ),
            const Divider(),
            Text(
              'The password is encrypted. It will be stored in your vault '
              'and decrypted with your vault key.',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (mounted) setState(() => _scanned = false);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Navigate to add-password with pre-filled fields
              if (mounted) {
                context.pop();
                context.push(
                  Routes.addPassword,
                  extra: {
                    'name': service,
                    'username': username,
                    'url': url,
                    'enc': enc,
                  },
                );
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcode = capture.barcodes.firstOrNull;
              if (barcode?.rawValue != null) {
                _onDetect(barcode!.rawValue!);
              }
            },
          ),
          Center(
            child: CustomPaint(
              size: const Size(250, 250),
              painter: _ScanWindowPainter(color: theme.colorScheme.primary),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Point at a KeySafe QR code',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanWindowPainter extends CustomPainter {
  final Color color;
  _ScanWindowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    const len = 30.0;
    final w = size.width;
    final h = size.height;
    // Corners
    final corners = [
      [Offset(0, len), Offset.zero, Offset(len, 0)],
      [Offset(w - len, 0), Offset(w, 0), Offset(w, len)],
      [Offset(w, h - len), Offset(w, h), Offset(w - len, h)],
      [Offset(len, h), Offset(0, h), Offset(0, h - len)],
    ];
    for (final pts in corners) {
      final path = Path()
        ..moveTo(pts[0].dx, pts[0].dy)
        ..lineTo(pts[1].dx, pts[1].dy)
        ..lineTo(pts[2].dx, pts[2].dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
