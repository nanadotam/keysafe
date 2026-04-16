import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/profile_repository.dart';
import '../../../core/constants/routes.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final profileState = ref.watch(profileProvider);

    final email = authState.maybeWhen(
      authenticated: (_, email) => email,
      orElse: () => '',
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(profileProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              profileState.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Card(
                  child: ListTile(
                    leading: Icon(Symbols.error, color: theme.colorScheme.error),
                    title: const Text('Could not load profile'),
                    subtitle: Text(error.toString()),
                    trailing: IconButton(
                      icon: const Icon(Symbols.refresh),
                      onPressed: () => ref.invalidate(profileProvider),
                    ),
                  ),
                ),
                data: (profile) => Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        _displayInitial(profile.name, profile.email, email),
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile.name.isEmpty ? 'KeySafe User' : profile.name,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.email.isEmpty ? email : profile.email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Member since ${DateFormat.yMMMMd().format(profile.memberSince)}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.35,
                      children: [
                        _ProfileStatCard(
                          label: 'Vault Entries',
                          value: '${profile.passwordCount}',
                          icon: Symbols.key,
                        ),
                        _ProfileStatCard(
                          label: 'Wi-Fi Entries',
                          value: '${profile.wifiCount}',
                          icon: Symbols.wifi,
                        ),
                        _ProfileStatCard(
                          label: 'Categories',
                          value: '${profile.categoryCount}',
                          icon: Symbols.category,
                        ),
                        _ProfileStatCard(
                          label: 'Security Score',
                          value: '${profile.securityScore}',
                          icon: Symbols.shield,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Symbols.settings),
                      title: const Text('Settings'),
                      trailing: const Icon(Symbols.chevron_right),
                      // Settings is a shell sibling — use go() not push()
                      onTap: () => context.go(Routes.settings),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Symbols.fingerprint),
                      title: const Text('Biometric Unlock'),
                      trailing: const Icon(Symbols.chevron_right),
                      // biometricSettings is a fullscreen route — push() is fine
                      onTap: () => context.push(Routes.biometricSettings),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Symbols.shield),
                      title: const Text('Security Dashboard'),
                      trailing: const Icon(Symbols.chevron_right),
                      // Security is a shell sibling — use go() not push()
                      onTap: () => context.go(Routes.security),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                ),
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.go(Routes.login);
                  }
                },
                child: const Text('Log Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _displayInitial(String name, String profileEmail, String fallbackEmail) {
    final source = name.isNotEmpty
        ? name
        : profileEmail.isNotEmpty
            ? profileEmail
            : fallbackEmail;
    if (source.isEmpty) {
      return 'K';
    }
    return source.trim().characters.first.toUpperCase();
  }
}

class _ProfileStatCard extends StatelessWidget {
  const _ProfileStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(value, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
