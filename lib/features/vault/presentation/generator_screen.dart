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

enum _GenMode { random, memorable }

class _GeneratorScreenState extends State<GeneratorScreen> {
  _GenMode _mode = _GenMode.random;
  int _length = 16;
  bool _uppercase = true;
  bool _numbers = true;
  bool _symbols = true;
  bool _avoidAmbiguous = false;
  String _generated = '';

  // Word separator for memorable mode
  static const _separator = '-';

  // Syllable lists for memorable mode
  static const _consonants = ['b','c','d','f','g','h','j','k','l','m',
                               'n','p','r','s','t','v','w','x','z'];
  static const _vowels = ['a','e','i','o','u'];

  static const _lower     = 'abcdefghijklmnopqrstuvwxyz';
  static const _upper     = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const _digits    = '0123456789';
  static const _syms      = r'!@#$%^&*-_=+';
  static const _ambiguous = 'Il1O0';

  @override
  void initState() {
    super.initState();
    _generate();
  }

  // ── Random mode ─────────────────────────────────────────────────────────────
  String _generateRandom() {
    var chars = _lower;
    if (_uppercase) chars += _upper;
    if (_numbers) chars += _digits;
    if (_symbols) chars += _syms;
    if (_avoidAmbiguous) {
      chars = chars.split('').where((c) => !_ambiguous.contains(c)).join();
    }
    if (chars.isEmpty) chars = _lower;

    final rng = Random.secure();

    // Build a list guaranteeing at least one of each enabled character class.
    final mandatory = <String>[];
    if (_numbers) mandatory.add(_digits[rng.nextInt(_digits.length)]);
    if (_symbols) mandatory.add(_syms[rng.nextInt(_syms.length)]);
    if (_uppercase) mandatory.add(_upper[rng.nextInt(_upper.length)]);
    mandatory.add(_lower[rng.nextInt(_lower.length)]);

    final remaining = List.generate(
      (_length - mandatory.length).clamp(0, _length),
      (_) => chars[rng.nextInt(chars.length)],
    );

    final all = [...mandatory, ...remaining]..shuffle(rng);
    return all.take(_length).join();
  }

  // ── Memorable mode ──────────────────────────────────────────────────────────
  // Generates pronounceable groups: e.g. "kobi-3749-wela"
  String _generateMemorable() {
    final rng = Random.secure();

    String syllable() {
      final c = _consonants[rng.nextInt(_consonants.length)];
      final v = _vowels[rng.nextInt(_vowels.length)];
      final c2 = _consonants[rng.nextInt(_consonants.length)];
      return '$c$v$c2';
    }

    final w1 = '${syllable()}${syllable()}';
    final num = (1000 + rng.nextInt(8999)).toString();
    final w2 = '${syllable()}${syllable()}';

    var result = '$w1$_separator$num$_separator$w2';

    if (_uppercase) {
      // Capitalise first letter of each segment
      final parts = result.split(_separator);
      result = parts
          .map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1))
          .join(_separator);
    }
    if (_symbols) {
      final sym = _syms[rng.nextInt(_syms.length)];
      result = '$result$sym';
    }

    return result;
  }

  void _generate() {
    final pw = _mode == _GenMode.memorable
        ? _generateMemorable()
        : _generateRandom();
    setState(() => _generated = pw);
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
              // ── Generated password card ──────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _generate,
                        child: SelectableText(
                          _generated,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: _mode == _GenMode.memorable ? 20 : 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: _mode == _GenMode.memorable ? 1.5 : 0,
                          ),
                          textAlign: TextAlign.center,
                        ),
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
              const SizedBox(height: 12),

              // ── Action row ───────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _generate,
                      icon: const Icon(Symbols.refresh),
                      label: const Text('Regenerate'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
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
                      icon: const Icon(Symbols.content_copy),
                      label: const Text('Copy'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Mode toggle ──────────────────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text('Password Style',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              letterSpacing: 1.2,
                            )),
                      ),
                      SegmentedButton<_GenMode>(
                        segments: const [
                          ButtonSegment(
                            value: _GenMode.random,
                            icon: Icon(Symbols.shuffle),
                            label: Text('Random'),
                          ),
                          ButtonSegment(
                            value: _GenMode.memorable,
                            icon: Icon(Symbols.record_voice_over),
                            label: Text('Memorable'),
                          ),
                        ],
                        selected: {_mode},
                        onSelectionChanged: (s) {
                          setState(() => _mode = s.first);
                          _generate();
                        },
                      ),
                      if (_mode == _GenMode.memorable)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 4),
                          child: Text(
                            'Pronounceable groups separated by dashes — easy to remember, hard to guess.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── Options card ─────────────────────────────────────────────
              Card(
                child: Column(
                  children: [
                    if (_mode == _GenMode.random) ...[
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
                    ],
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
                    if (_mode == _GenMode.random)
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
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Use This Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
