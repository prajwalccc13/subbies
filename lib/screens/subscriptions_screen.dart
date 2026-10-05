import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:subbies/models/subscription.dart';
import 'package:subbies/state/subscriptions_controller.dart';
import 'package:subbies/theme/app_theme.dart';
import 'package:subbies/utils/money.dart';
import 'package:subbies/widgets/animated_amount.dart';
import 'package:subbies/widgets/subscription_tile.dart';
import 'package:subbies/services/account_sync.dart';



class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key, this.selectedId});

  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SubscriptionsController>();
    final today = DateTime.now();
    final subscriptions = controller.byNextRenewal(today);

    // the trial ending soonest, but only if that's within a week.
    // Further away than that, an alert would just be noise.
    final trials = controller.activeTrials;
    final Subscription? endingTrial =
      trials.isNotEmpty && trials.first.daysUntilRenewal(today) <= 7
        ? trials.first
        : null;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/subscriptions/new'),
        tooltip: 'Add subscription',
        child: const Icon(Icons.add),
      ),

      // Body
      body: SafeArea(
        child: controller.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _SummaryHeader(
                monthlyCents: controller.monthlyTotalCents,
                yearlyCents: controller.yearlyTotalCents,
                chargingCount: controller.chargingCount,
                totalCount: subscriptions.length,
              ),
            ),

            // the alert, only when there's a trial to warn about.
            if (endingTrial != null)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverToBoxAdapter(
                  child: _TrialAlert(
                    subscription: endingTrial,
                    today: today,
                    onTap: () =>
                        context.go('/subscriptions/${endingTrial.id}'),
                  ),
                ),
              ),


            if (subscriptions.isEmpty)
              const SliverToBoxAdapter(child: _EmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: _SubscriptionGroup(
                    subscriptions: subscriptions,
                    today: today,
                    selectedId: selectedId,
                    onTap: (s) => context.go('/subscriptions/${s.id}'),
                  )
                )
              ),
            
            // Extra Space for Floating Add Button
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ]
        )
      ),
    );
  }
}



class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.monthlyCents,
    required this.yearlyCents,
    required this.chargingCount,
    required this.totalCount,
  });

  final double monthlyCents;
  final double yearlyCents;
  final int chargingCount; // Subscriptions you're paying for now
  final int totalCount; // Everything in the list

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    final String summary;
    if (totalCount == 0) {
      summary = 'Nothing tracked yet.';
    } else if (chargingCount == 0) {
      summary = 'Nothing is being charged right now.';
    } else {
      final noun = chargingCount == 1 ? 'subscription' : 'subscriptions';
      summary = '${formatCents(yearlyCents)} a year across $chargingCount $noun.';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly spend',
            style: theme.textTheme.bodyMedium
              ?.copyWith(color: colors.onSurfaceVariant)
          ),
          const SizedBox(height: 4),
          AnimatedAmount(
            cents: monthlyCents,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
              fontFeatures: tabularFigures,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            summary,
            style: theme.textTheme.bodyMedium
              ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}


class _TrialAlert extends StatelessWidget {
  const _TrialAlert({
    required this.subscription,
    required this.today,
    required this.onTap,
  });

  final Subscription subscription;
  final DateTime today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amber = trialColor(context);

    final days = subscription.daysUntilRenewal(today);
    final when = switch (days) {
      0 => 'today',
      1 => 'tomorrow',
      _ => 'in $days days',
    };
    final price =
        '${formatCents(subscription.priceCents)}/${subscription.cycle.shortLabel}';
    
    return Material(
      color: amber.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.hourglass_bottom_rounded, color: amber),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${subscription.name} trial ends $when',
                      style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Cancel before then if you don't want to pay $price.",
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _SubscriptionGroup extends StatelessWidget {
  const _SubscriptionGroup({
    required this.subscriptions,
    required this.today,
    required this.selectedId,
    required this.onTap,
  });

  final List<Subscription> subscriptions;
  final DateTime today;
  final String? selectedId;
  final ValueChanged<Subscription> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < subscriptions.length; i++) ...[
            if (i > 0) const Divider(indent: 74),
            SubscriptionTile(
              subscription: subscriptions[i], 
              today: today, 
              selected: subscriptions[i].id == selectedId,
              onTap: () => onTap(subscriptions[i]),
            ),
          ],
        ],
      ),
    );
  }
}


class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.autorenew, 
            size: 40,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: 16,),
          Text(
            'No subscriptions yet',
            style: theme.textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + to add the things you pay for regularly, like streaming, '
            'music or your gym.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
          
          const SizedBox(height: 20),
          // an empty screen becomes an invitation to look around.
          OutlinedButton.icon(
            onPressed: () => context.read<AccountSync>().enterDemo(),
            icon: const Icon(Icons.science_outlined),
            label: const Text('Explore with sample data'),
          ),
        ],
      ),
    );
  }
}