import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../providers/auth_provider.dart';
import '../domain/auth_state.dart';
import '../../../core/constants/routes.dart';
import '../../../core/settings/app_settings_provider.dart';
import '../../../crypto/key_store.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  String _version       = '';
  bool   _onboardingSeen = false;
  GoRouter? _router;
  late final AnimationController _animCtrl;
  late final Animation<double>   _opacity;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opacity = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
    _init();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _onboardingSeen = await KeyStore.getOnboardingSeen();
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = 'v${info.version}');
    await ref.read(authProvider.notifier).checkAuth();
  }

  @override
  Widget build(BuildContext context) {
    _router = GoRouter.of(context); // cache router here (always sync)
    final biometricEnabled =
        ref.watch(appSettingsProvider).biometricUnlockEnabled;

    ref.listen<AuthState>(authProvider, (_, state) {
      state.when(
        initial:       () {},
        loading:       () {},
        authenticated: (_, __) {
          // Already authenticated — if biometric is enabled, lock first.
          if (biometricEnabled) {
            ref.read(authProvider.notifier).lock();
            context.go(Routes.lock);
            return;
          }
          context.go(Routes.home);
        },
        locked:         () => context.go(Routes.lock),
        unauthenticated: () {
          final router = _router;
          if (router == null || !mounted) return;
          router.go(_onboardingSeen ? Routes.login : Routes.onboarding);
        },
        error: (_) => context.go(Routes.login),
      );
    });

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: FadeTransition(
                opacity: _opacity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 84,
                        height: 84,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'KeySafe',
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ZERO-KNOWLEDGE VAULT',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 48),
                    child: LinearProgressIndicator(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _version,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'by Nana Kwaku Amoako',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
