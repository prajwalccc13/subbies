// =============================================================================
// screens/subscriptions_layout.dart — LIST AND DETAILS, SIDE BY SIDE
// =============================================================================
// Wide screens:   [ list ][ editor, or "nothing selected" ]
// Phones:         one page at a time (list, then editor on top)
//
// The URL decides what's open:
//   /subscriptions        -> nothing selected
//   /subscriptions/new    -> adding a new subscription
//   /subscriptions/abc123 -> editing the subscription with id abc123
// =============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:subbies/layout/app_layout.dart';
import 'package:subbies/screens/edit_subscription_screen.dart';
import 'package:subbies/screens/subscriptions_screen.dart';
import 'package:subbies/state/subscriptions_controller.dart';

/// Wraps everything in the Subscriptions tab.
/// `child` is whatever the router decided to show for the current URL.
class SubscriptionsLayout extends StatelessWidget {
  const SubscriptionsLayout({
    super.key,
    required this.selectedId,
    required this.child,
  });

  final String? selectedId; // From the URL, so the list can highlight it
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!AppLayout.of(context).twoPane) return child; // Phones: one page

    return Row(
      children: [
        // The list keeps a comfortable fixed width...
        SizedBox(
          width: 400,
          child: SubscriptionsScreen(selectedId: selectedId),
        ),
        const VerticalDivider(width: 1),
        // ...and the details take all the remaining space.
        Expanded(child: child),
      ],
    );
  }
}

/// What /subscriptions shows.
class SubscriptionsHome extends StatelessWidget {
  const SubscriptionsHome({super.key});

  @override
  Widget build(BuildContext context) {
    // Phones: the list itself. Wide screens: the list is already on the
    // left (in SubscriptionsLayout), so the right side shows a placeholder.
    return AppLayout.of(context).twoPane
        ? const _NothingSelected()
        : const SubscriptionsScreen();
  }
}

/// What /subscriptions/:id shows: the editor for that subscription.
class SubscriptionDetail extends StatelessWidget {
  const SubscriptionDetail({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SubscriptionsController>();

    if (controller.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final subscription =
        controller.subscriptions.where((s) => s.id == id).firstOrNull;
    if (subscription == null) return const _NotFound();

    // ValueKey(id): a different subscription = a different editor, so its
    // fields are filled in fresh (initState runs again).
    return EditSubscriptionScreen(key: ValueKey(id), existing: subscription);
  }
}


class _NothingSelected extends StatelessWidget {
  const _NothingSelected();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 48, color: colors.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'Pick a subscription',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose one from the list to see and edit its details.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 220, 
                child: FilledButton(
                  onPressed: () => context.go('/subscriptions/new'),
                  child: const Text('Add subscription'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/subscriptions')),
      ),
      body: const Center(
        child: Text("This subscription doesn't exist anymore."),
      ),
    );
  }
}