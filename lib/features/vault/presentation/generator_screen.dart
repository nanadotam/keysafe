import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/services/clipboard_service.dart';
import '../../../core/widgets/strength_badge.dart';
import '../../../crypto/crypto_service.dart';

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  int _length = 16;
  bool _uppercase = true;
  bool _numbers = true;
  bool _symbols = true;
  bool _avoidAmbiguous = false;
  String _generated = '';

  static const _lower = 'abcdefghijklmnopqrstuvwxyz';
  static const _upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const _digits = '0123456789';
  static const _syms = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
  static const _ambiguous = 'Il1O0';

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    var chars = _lower;
    if (_uppercase) chars += _upper;
    if (_numbers) chars += _digits;
    if (_symbols) chars += _syms;
    if (_avoidAmbiguous) {
      chars = chars.split('').where((c) => !_ambiguous.contains(c)).join();
    }
    if (chars.isEmpty) chars = _lower;

    final rng = Random.secure();
    final password = List.generate(
      _length,
      (_) => chars[rng.nextInt(chars.length)],
    ).join();
    setState(() => _generated = password);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strength = CryptoService.calculateStrength(_generated);

    return Scaffold(
      appBar: AppBar(title: const Text('Generator')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      SelectableText(
                        _generated,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: strength / 100,
                        color: strength >= 70
                            ? const Color(0xFF60BA46)
                            : strength >= 40
                                ? const Color(0xFFFFC600)
                                : const Color(0xFFFE5257),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      StrengthBadge.fromScore(strength),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.tonal(
                    onPressed: _generate,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Symbols.refresh),
                        SizedBox(width: 8),
                        Text('Regenerate'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await ClipboardService.copyAndScheduleClear(
                        _generated,
                        durationSeconds: 30,
                      );
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Copied — clears in 30s'),
                          ),
                        );
                      }
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Symbols.content_copy),
                        SizedBox(width: 8),
                        Text('Copy'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        children: [
                          Text('Length: $_length',
                              style: theme.textTheme.bodyLarge),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Symbols.remove),
                            onPressed: _length > 6
                                ? () {
                                    setState(() => _length--);
                                    _generate();
                                  }
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Symbols.add),
                            onPressed: _length < 64
                                ? () {
                                    setState(() => _length++);
                                    _generate();
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Uppercase (A-Z)'),
                      value: _uppercase,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        setState(() => _uppercase = v);
                        _generate();
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Numbers (0-9)'),
                      value: _numbers,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        setState(() => _numbers = v);
                        _generate();
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Symbols (!@#...)'),
                      value: _symbols,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        setState(() => _symbols = v);
                        _generate();
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Avoid Ambiguous (Il1O0)'),
                      value: _avoidAmbiguous,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        setState(() => _avoidAmbiguous = v);
                        _generate();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.pop(_generated),
                child: const Text('Use This Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
