import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'core/constants/routes.dart';
import 'core/providers/ambient_theme_provider.dart';
import 'core/settings/app_settings_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/splash_screen.dart';
import 'features/auth/presentation/onboarding_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/auth/presentation/lock_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/vault/domain/vault_entry.dart';
import 'features/vault/presentation/home_screen.dart';
import 'features/vault/presentation/password_detail_screen.dart';
import 'features/vault/presentation/add_password_screen.dart';
import 'features/vault/presentation/edit_password_screen.dart';
import 'features/vault/presentation/generator_screen.dart';
import 'features/security/presentation/security_screen.dart';
import 'features/qr/presentation/qr_scan_screen.dart';
import 'features/qr/presentation/qr_share_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/settings/presentation/biometric_settings_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/wifi/presentation/wifi_screen.dart';
import 'features/vault/presentation/recently_deleted_screen.dart';
import 'features/vault/presentation/import_vault_screen.dart';
import 'features/settings/presentation/ambient_dark_mode_screen.dart';
import 'features/security/presentation/login_history_screen.dart';

final _router = GoRouter(
  initialLocation: Routes.splash,
  routes: [
    // ── Auth / onboarding (no shell) ─────────────────────────────────────────
    GoRoute(path: Routes.splash,     builder: (_, __) => const SplashScreen()),
    GoRoute(path: Routes.onboarding, builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: Routes.login,      builder: (_, __) => const LoginScreen()),
    GoRoute(path: Routes.register,   builder: (_, __) => const RegisterScreen()),
    GoRoute(path: Routes.lock,       builder: (_, __) => const LockScreen()),

    // ── Main shell (bottom nav) ──────────────────────────────────────────────
    // All routes inside ShellRoute share the same Navigator instance.
    // context.go() is used between them; context.push() pushes on top.
    ShellRoute(
      builder: (context, state, child) => _MainShell(child: child),
      routes: [
        GoRoute(path: Routes.home,     builder: (_, __) => const HomeScreen()),
        GoRoute(path: Routes.security, builder: (_, __) => const SecurityScreen()),
        GoRoute(path: Routes.settings, builder: (_, __) => const SettingsScreen()),
        // Profile is now INSIDE the shell so context.push(settings) works.
        GoRoute(path: Routes.profile,  builder: (_, __) => const ProfileScreen()),
      ],
    ),

    // ── Fullscreen routes (no shell, pushed on top) ──────────────────────────
    GoRoute(
      path: Routes.detail,
      builder: (_, state) =>
          PasswordDetailScreen(entry: state.extra as VaultEntry),
    ),
    GoRoute(
      path: Routes.addPassword,
      builder: (_, state) {
        final extra = state.extra as Map<String, String>?;
        return AddPasswordScreen(prefill: extra);
      },
    ),
    GoRoute(
      path: Routes.editPassword,
      builder: (_, state) =>
          EditPasswordScreen(entry: state.extra as VaultEntry),
    ),
    GoRoute(path: Routes.generator,    builder: (_, __) => const GeneratorScreen()),
    GoRoute(path: Routes.qrScan,       builder: (_, __) => const QrScanScreen()),
    GoRoute(
      path: Routes.qrShare,
      builder: (_, state) =>
          QrShareScreen(entry: state.extra as VaultEntry),
    ),
    GoRoute(path: Routes.wifi,              builder: (_, __) => const WifiScreen()),
    GoRoute(path: Routes.biometricSettings, builder: (_, __) => const BiometricSettingsScreen()),
    GoRoute(path: Routes.recentlyDeleted,   builder: (_, __) => const RecentlyDeletedScreen()),
    GoRoute(path: Routes.importVault,       builder: (_, __) => const ImportVaultScreen()),
    GoRoute(path: Routes.ambientDarkMode,   builder: (_, __) => const AmbientDarkModeScreen()),
    GoRoute(path: Routes.loginHistory,      builder: (_, __) => const LoginHistoryScreen()),
  ],
);

class KeySafeApp extends ConsumerStatefulWidget {
  const KeySafeApp({super.key});

  @override
  ConsumerState<KeySafeApp> createState() => _KeySafeAppState();
}

class _KeySafeAppState extends ConsumerState<KeySafeApp>
    with WidgetsBindingObserver {
  Timer? _lockTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lockTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final settings = ref.read(appSettingsProvider);
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _scheduleLock(settings.autoLockDuration, settings.autoLockDisabled);
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _lockTimer?.cancel();
      final isLocked = ref.read(authProvider).maybeWhen(
            locked: () => true,
            orElse: () => false,
          );
      if (isLocked) {
        _router.go(Routes.lock);
      }
      return;
    }

    if (state == AppLifecycleState.detached) {
      _lockTimer?.cancel();
    }
  }

  void _scheduleLock(Duration delay, bool disabled) {
    _lockTimer?.cancel();
    if (disabled) {
      return;
    }
    if (delay <= Duration.zero) {
      _lockNow();
      return;
    }
    _lockTimer = Timer(delay, _lockNow);
  }

  void _lockNow() {
    final isAuthenticated = ref.read(authProvider).maybeWhen(
          authenticated: (_, __) => true,
          orElse: () => false,
        );
    if (!isAuthenticated) {
      return;
    }
    ref.read(authProvider.notifier).lock();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'KeySafe',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}

class _MainShell extends StatefulWidget {
  final Widget child;
  const _MainShell({required this.child});

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  static const _routes = [Routes.home, Routes.security, Routes.settings];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _routes.indexWhere(
      (route) => location == route || location.startsWith('$route/'),
    );

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        backgroundColor: Theme.of(context).colorScheme.surface,
        onDestinationSelected: (i) {
          HapticFeedback.selectionClick();
          context.go(_routes[i]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield),
            label: 'Security',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
