
// Tapping Light or Dark calls settings.setThemeMode(). The controller
// notifies, app.dart (which WATCHES settings) rebuilds MaterialApp, and the
// entire app fades to the new theme. The choice is saved for next time.
//----------------------------------------------------------------------
// "Reminders" switch. Turning it on asks for notification
// permission. If the user says no, the switch stays off and a message
// explains how to change it later.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:subbies/state/reminders_controller.dart';

import 'package:subbies/state/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});


  Future<void> _toggleReminders(BuildContext context, bool value) async {
    final messenger = ScaffoldMessenger.of(context);
    final reminders = context.read<RemindersController>();

    final allowed = await reminders.setEnabled(value);

    if(!allowed) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text (
            "Notifications are blocked for Subbies. "
            "You can allow them in your phone's settings.",
          ),
        )
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final reminders = context.watch<RemindersController>();
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

          // Reminders 
          Text('Reminders', style: headingStyle),
          const SizedBox(height: 10),
          Material(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: SwitchListTile(
              title: const Text('Renewal reminders'),
              subtitle: const Text(
                'A notification at 9 am the day before subscriptions renews '
                'or a free trial ends.',
              ),
              value: reminders.enabled,
              onChanged: (value) => _toggleReminders(context, value),
            ),
          ),

          // kDebugMode  - Send Notifications for testing
          if (kDebugMode) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.read<RemindersController>().sendTest(),
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Send a test notification in 10 seconds'),
              ),
            ),
          ],
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