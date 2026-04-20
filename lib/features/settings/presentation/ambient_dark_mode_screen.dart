import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ambient_theme_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Ambient Dark Mode Settings Screen
//
// Lets the user choose between three strategies:
//   Manual    — simple on/off toggle
//   Scheduled — dark mode between two set times (overnight supported)
//   Sensor    — follows the ambient light sensor reading (lux)
// ─────────────────────────────────────────────────────────────────────────────

class AmbientDarkModeScreen extends ConsumerStatefulWidget {
  const AmbientDarkModeScreen({super.key});

  @override
  ConsumerState<AmbientDarkModeScreen> createState() =>
      _AmbientDarkModeScreenState();
}

class _AmbientDarkModeScreenState
    extends ConsumerState<AmbientDarkModeScreen> {
  @override
  Widget build(BuildContext context) {
    final notifier   = ref.read(themeModeProvider.notifier);
    final themeMode  = ref.watch(themeModeProvider);
    final config     = ref.watch(darkModeConfigProvider);
    final isDark     = themeMode == ThemeMode.dark;
    final cs         = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Dark Mode')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Status banner ─────────────────────────────────────────────────
          _StatusBanner(isDark: isDark, strategy: config.strategy),
          const SizedBox(height: 20),

          // ── Mode selector ─────────────────────────────────────────────────
          _SectionLabel(text: 'MODE'),
          _SettingsCard(
            child: Column(
              children: [
                _ModeOption(
                  icon:     Icons.toggle_on_rounded,
                  title:    'Manual',
                  subtitle: 'Turn dark mode on or off yourself',
                  selected: config.strategy == DarkModeStrategy.manual,
                  cs:       cs,
                  onTap: () => notifier.updateConfig(
                    config.copyWith(strategy: DarkModeStrategy.manual),
                  ),
                ),
                const Divider(height: 1),
                _ModeOption(
                  icon:     Icons.schedule_rounded,
                  title:    'Scheduled',
                  subtitle: 'Switch automatically between set times',
                  selected: config.strategy == DarkModeStrategy.scheduled,
                  cs:       cs,
                  onTap: () => notifier.updateConfig(
                    config.copyWith(strategy: DarkModeStrategy.scheduled),
                  ),
                ),
                const Divider(height: 1),
                _ModeOption(
                  icon:     Icons.sensors_rounded,
                  title:    'Ambient Sensor',
                  subtitle: "Responds to the room's light level",
                  selected: config.strategy == DarkModeStrategy.sensor,
                  cs:       cs,
                  onTap: () => notifier.updateConfig(
                    config.copyWith(strategy: DarkModeStrategy.sensor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Strategy-specific settings ────────────────────────────────────
          if (config.strategy == DarkModeStrategy.manual) ...[
            _SectionLabel(text: 'SETTINGS'),
            _SettingsCard(
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: cs.onSurfaceVariant,
                ),
                title: Text(
                  'Dark Mode',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                subtitle: Text(
                  isDark ? 'Currently on' : 'Currently off',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                trailing: Switch(
                  value: config.manualDark,
                  onChanged: (v) => notifier.updateConfig(
                    config.copyWith(manualDark: v),
                  ),
                ),
              ),
            ),
          ] else if (config.strategy == DarkModeStrategy.scheduled) ...[
            _SectionLabel(text: 'SCHEDULE'),
            _ScheduleCard(config: config, notifier: notifier),
          ] else if (config.strategy == DarkModeStrategy.sensor) ...[
            _SectionLabel(text: 'SENSOR SETTINGS'),
            _SensorCard(config: config, notifier: notifier),
          ],

          const SizedBox(height: 24),
          _HintCard(strategy: config.strategy),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Banner
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.isDark, required this.strategy});

  final bool isDark;
  final DarkModeStrategy strategy;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHighest
            : cs.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? cs.outlineVariant : cs.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              key: ValueKey(isDark),
              size: 32,
              color: isDark ? cs.onSurface : cs.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDark ? 'Dark Mode is Active' : 'Light Mode is Active',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? cs.onSurface : cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _strategyLabel(strategy),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? cs.onSurfaceVariant
                        : cs.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _strategyLabel(DarkModeStrategy s) => switch (s) {
        DarkModeStrategy.manual    => 'Controlled manually',
        DarkModeStrategy.scheduled => 'Following your schedule',
        DarkModeStrategy.sensor    => 'Following ambient light sensor',
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Mode Option Row
// ─────────────────────────────────────────────────────────────────────────────

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.cs,
    this.onTap,
  });

  final IconData icon;
  final String   title;
  final String   subtitle;
  final bool     selected;
  final ColorScheme cs;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? cs.primary : cs.onSurfaceVariant;
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
      trailing: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? cs.primary : Colors.grey.shade400,
            width: 2,
          ),
        ),
        child: selected
            ? Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.primary,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Schedule Card
// ─────────────────────────────────────────────────────────────────────────────

class _ScheduleCard extends ConsumerWidget {
  const _ScheduleCard({required this.config, required this.notifier});

  final DarkModeConfig          config;
  final AmbientThemeNotifier    notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startTime = TimeOfDay(
      hour: config.scheduleStartHour,
      minute: config.scheduleStartMinute,
    );
    final endTime = TimeOfDay(
      hour: config.scheduleEndHour,
      minute: config.scheduleEndMinute,
    );
    final cs = Theme.of(context).colorScheme;

    return _SettingsCard(
      child: Column(
        children: [
          _TimeTile(
            icon:  Icons.brightness_2_rounded,
            label: 'Dark from',
            time:  startTime,
            cs:    cs,
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: startTime,
                helpText: 'Dark mode starts at',
              );
              if (picked != null) {
                notifier.updateConfig(config.copyWith(
                  scheduleStartHour:   picked.hour,
                  scheduleStartMinute: picked.minute,
                ));
              }
            },
          ),
          const Divider(height: 1),
          _TimeTile(
            icon:  Icons.wb_sunny_rounded,
            label: 'Until',
            time:  endTime,
            cs:    cs,
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: endTime,
                helpText: 'Dark mode ends at',
              );
              if (picked != null) {
                notifier.updateConfig(config.copyWith(
                  scheduleEndHour:   picked.hour,
                  scheduleEndMinute: picked.minute,
                ));
              }
            },
          ),
        ],
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.icon,
    required this.label,
    required this.time,
    required this.cs,
    required this.onTap,
  });

  final IconData    icon;
  final String      label;
  final TimeOfDay   time;
  final ColorScheme cs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
      leading: Icon(icon, color: cs.onSurfaceVariant, size: 22),
      title: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          time.format(context),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: cs.primary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sensor Card
// Uses local slider state to avoid rebuilding the provider on every drag frame.
// ─────────────────────────────────────────────────────────────────────────────

class _SensorCard extends ConsumerStatefulWidget {
  const _SensorCard({required this.config, required this.notifier});

  final DarkModeConfig       config;
  final AmbientThemeNotifier notifier;

  @override
  ConsumerState<_SensorCard> createState() => _SensorCardState();
}

class _SensorCardState extends ConsumerState<_SensorCard> {
  late double _localThreshold;

  @override
  void initState() {
    super.initState();
    _localThreshold = widget.config.luxThreshold;
  }

  @override
  void didUpdateWidget(_SensorCard old) {
    super.didUpdateWidget(old);
    if (old.config.luxThreshold != widget.config.luxThreshold) {
      _localThreshold = widget.config.luxThreshold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final luxAsync  = ref.watch(luxReadingProvider);
    final currentLux = luxAsync.value ?? widget.notifier.lastLux;
    final cs        = Theme.of(context).colorScheme;

    return _SettingsCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sensors_rounded, size: 22, color: cs.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Light Threshold',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 100),
                  child: Container(
                    key: ValueKey(_localThreshold.round()),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_localThreshold.round()} lux',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Switch to dark mode when light drops below this level',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            Slider(
              value: _localThreshold.clamp(0, 1000),
              min: 0,
              max: 1000,
              divisions: 200,
              activeColor: cs.primary,
              inactiveColor: cs.primary.withValues(alpha: 0.15),
              onChanged: (v) => setState(() => _localThreshold = v),
              onChangeEnd: (v) => widget.notifier.updateConfig(
                widget.config.copyWith(luxThreshold: v.roundToDouble()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '0 lux\nPitch dark',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                  ),
                  Text(
                    '100 lux\nDim room',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                  ),
                  Text(
                    '1000 lux\nBright office',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: cs.outlineVariant),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded,
                    size: 20, color: cs.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Current reading',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                luxAsync.when(
                  data: (lux) =>
                      _LuxBadge(lux: lux, threshold: _localThreshold, cs: cs),
                  loading: () => _LuxBadge(
                    lux: currentLux,
                    threshold: _localThreshold,
                    cs: cs,
                  ),
                  error: (_, __) => Text(
                    'Sensor unavailable',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LuxBadge extends StatelessWidget {
  const _LuxBadge(
      {required this.lux, required this.threshold, required this.cs});

  final int? lux;
  final double threshold;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    if (lux == null) {
      return Text(
        'Reading…',
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      );
    }
    final dark = lux! < threshold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: dark
            ? cs.surfaceContainerHighest
            : Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            size: 14,
            color: dark ? cs.onSurface : Colors.amber.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            '$lux lux',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: dark ? cs.onSurface : Colors.amber.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hint Card
// ─────────────────────────────────────────────────────────────────────────────

class _HintCard extends StatelessWidget {
  const _HintCard({required this.strategy});

  final DarkModeStrategy strategy;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (icon, text) = switch (strategy) {
      DarkModeStrategy.manual => (
          Icons.info_outline_rounded,
          'Switch dark mode on or off any time from here.',
        ),
      DarkModeStrategy.scheduled => (
          Icons.schedule_rounded,
          'The app switches automatically at the times you set — perfect for night reading. Overnight ranges are supported.',
        ),
      DarkModeStrategy.sensor => (
          Icons.sensors_rounded,
          'Hold your phone in a normal reading position. Lower the threshold to require a darker room before switching.',
        ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.tertiary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: cs.tertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Layout helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: child,
    );
  }
}
