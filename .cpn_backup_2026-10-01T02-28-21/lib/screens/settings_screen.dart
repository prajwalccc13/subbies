// =============================================================================
// screens/settings_screen.dart — APPEARANCE
// =============================================================================
// Tapping Light or Dark calls settings.setThemeMode(). The controller
// notifies, app.dart (which WATCHES settings) rebuilds MaterialApp, and the
// entire app fades to the new theme. The choice is saved for next time.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:recurring/state/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final headingStyle = theme.textTheme.titleSmall?.copyWith(
      color: colors.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('Appearance', style: headingStyle),
          const SizedBox(height: 10),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('System')),
              ButtonSegment(value: ThemeMode.light, label: Text('Light')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (selection) =>
                settings.setThemeMode(selection.first),
          ),
          const SizedBox(height: 32),
          Text('Your data', style: headingStyle),
          const SizedBox(height: 10),
          Text(
            'Everything stays on this device. Nothing is sent anywhere.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}