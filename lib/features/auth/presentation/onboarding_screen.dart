import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/constants/routes.dart';
import '../../../crypto/key_store.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  DateTime? _lastBackPress;

  static const _slides = [
    _Slide(
      icon: Symbols.shield,
      title: 'Zero-Knowledge Security',
      body:
          'Your passwords are encrypted on your device before they ever reach our servers. We can never see your data.',
    ),
    _Slide(
      icon: Symbols.key_vertical,
      title: 'One Master Key',
      body:
          'A single master password unlocks your entire vault. It never leaves your device — not even for login.',
    ),
    _Slide(
      icon: Symbols.fingerprint,
      title: 'Biometric Unlock',
      body:
          'Use your fingerprint or face to unlock quickly. Your vault key is secured in the device keychain.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await KeyStore.setOnboardingSeen(true);
      if (mounted) context.go(Routes.register);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPress != null &&
            now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
          final exit = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Exit KeySafe?'),
              content: const Text('Are you sure you want to exit?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Stay'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Exit'),
                ),
              ],
            ),
          );
          if (exit == true) SystemNavigator.pop();
        } else {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _slides.length,
                itemBuilder: (context, i) => _SlideWidget(slide: _slides[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: LinearProgressIndicator(
                value: (_page + 1) / _slides.length,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                children: [
                  if (_page > 0)
                    TextButton(
                      onPressed: () => _controller.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    child: Text(
                      _page == _slides.length - 1 ? 'Get Started' : 'Continue',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                await KeyStore.setOnboardingSeen(true);
                if (context.mounted) context.go(Routes.login);
              },
              child: Text(
                'Already have an account? Sign in',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final String title;
  final String body;
  const _Slide({required this.icon, required this.title, required this.body});
}

class _SlideWidget extends StatelessWidget {
  final _Slide slide;
  const _SlideWidget({required this.slide});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(slide.icon, size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: 32),
          Text(
            slide.title,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            slide.body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
