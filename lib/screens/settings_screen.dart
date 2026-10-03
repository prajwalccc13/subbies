// =============================================================================
// screens/settings_screen.dart — ACCOUNT, APPEARANCE, REMINDERS
// =============================================================================


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

import 'package:subbies/screens/auth_screen.dart';
import 'package:subbies/state/auth_controller.dart';
import 'package:subbies/state/reminders_controller.dart';
import 'package:subbies/state/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _toggleReminders(BuildContext context, bool value) async {
    final messenger = ScaffoldMessenger.of(context);
    final reminders = context.read<RemindersController>();

    final allowed = await reminders.setEnabled(value);
    if (!allowed) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            "Notifications are blocked for Subbies. "
            "You can allow them in your phone's settings.",
          ),
        ),
      );
    }
  }

  void _openSignIn(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final auth = context.read<AuthController>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        // Honest about what happens: nothing is lost, but this device
        // won't show the data until they sign back in.
        content: const Text(
          'Your subscriptions stay safe in your account. This device will '
          'show an empty list until you sign in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true) await auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final reminders = context.watch<RemindersController>();
    final auth = context.watch<AuthController>(); 
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
          // Account 
          const SizedBox(height: 10),
          Material(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: auth.isSignedIn
                  // Signed in: who, plus a way out.
                  ? Row(
                      children: [
                        Icon(Icons.cloud_done_outlined, color: colors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Synced to',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: colors.onSurfaceVariant),
                              ),
                              Text(
                                auth.email ?? 'your account',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _confirmSignOut(context),
                          child: const Text('Sign out'),
                        ),
                      ],
                    )
                  // Signed out: the invitation.
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Back up and sync',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create a free account to keep your subscriptions '
                          'safe and use them on all your devices.',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => _openSignIn(context),
                          child: const Text('Sign in or create account'),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 32),

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

          Text('Reminders', style: headingStyle),
          const SizedBox(height: 10),
          Material(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: SwitchListTile(
              title: const Text('Renewal reminders'),
              subtitle: const Text(
                'A notification at 9 am the day before something renews '
                'or a free trial ends.',
              ),
              value: reminders.enabled,
              onChanged: (value) => _toggleReminders(context, value),
            ),
          ),
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
            auth.isSignedIn
                ? 'Saved to your account and synced to every device you '
                    'sign in on. Only you can access it.'
                : 'Stored on this device only. Nothing is sent anywhere.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}