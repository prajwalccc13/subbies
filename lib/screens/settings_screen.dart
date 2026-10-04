// =============================================================================
// screens/settings_screen.dart — ACCOUNT, APPEARANCE, REMINDERS
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'package:subbies/state/auth_controller.dart';
import 'package:subbies/state/reminders_controller.dart';
import 'package:subbies/state/settings_controller.dart';
import 'package:subbies/layout/app_layout.dart';

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

  void _openSignIn(BuildContext context) => context.go('/settings/sign-in');

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

  // NEW
  Future<void> _deleteAccount(BuildContext context) async {
    final auth = context.read<AuthController>();
    final messenger = ScaffoldMessenger.of(context);

    // The dialog returns the typed password, or null if cancelled.
    final password = await showDialog<String>(
      context: context,
      builder: (context) => const _DeleteAccountDialog(),
    );
    if (password == null || password.isEmpty) return;

    final error = await auth.deleteAccount(password);
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? 'Your account and its data have been deleted.'),
      ),
    );
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final gutter = centeredGutter(constraints.maxWidth);
          return ListView(
            padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 32),
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
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.cloud_done_outlined,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Synced to',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: colors.onSurfaceVariant,
                                            ),
                                      ),
                                      Text(
                                        auth.email ?? 'your account',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _confirmSignOut(context),
                                  child: const Text('Sign out'),
                                ),

                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () => _deleteAccount(context),
                                  style: TextButton.styleFrom(
                                    foregroundColor: colors.error,
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Text('Delete account'),
                                ),
                              ],
                            ),
                          ],
                        )
                      // Signed out: the invitation.
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Back up and sync',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create a free account to keep your subscriptions '
                              'safe and use them on all your devices.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
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

              // Reminders
              Text('Reminders', style: headingStyle),
              const SizedBox(height: 10),
              if (kIsWeb)
                Text(
                  'Reminders come from the Android and iOS apps. Install Subbies '
                  'on your phone to get a heads-up before each renewal.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                )
              else ...[
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
                      onPressed: () =>
                          context.read<RemindersController>().sendTest(),
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: const Text(
                        'Send a test notification in 10 seconds',
                      ),
                    ),
                  ),
                ],
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
          );
        },
      ),
    );
  }
}

// The confirmation dialog. It's a StatefulWidget because it owns a
// TextEditingController, which must be disposed when the dialog closes.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Delete your account?'),
      content: Column(
        mainAxisSize: MainAxisSize.min, // As tall as its content, no taller
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plain and honest: what happens, and that it's permanent.
          const Text(
            "This permanently deletes your account and every subscription "
            "saved in it. It can't be undone.",
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter your password to confirm',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_password.text),
          style: TextButton.styleFrom(foregroundColor: colors.error),
          child: const Text('Delete forever'),
        ),
      ],
    );
  }
}
