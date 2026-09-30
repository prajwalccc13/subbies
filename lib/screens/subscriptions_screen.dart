import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:subbies/models/subscription.dart';
import 'package:subbies/screens/edit_subscription_screen.dart';
import 'package:subbies/state/subscriptions_controller.dart';
import 'package:subbies/theme/app_theme.dart';
import 'package:subbies/utils/money.dart';
import 'package:subbies/widgets/animated_amount.dart';
import 'package:subbies/widgets/subscription_tile.dart';



class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});


  void _openEditor(BuildContext context, {Subscription? existing}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditSubscriptionScreen(existing: existing),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SubscriptionsController>();
    final today = DateTime.now();
    final subscriptions = controller.byNextRenewal(today);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context),
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
                count: subscriptions.length,
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
                    onTap: (s) => _openEditor(context, existing: s),
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
    required this.count,  
  });

  final double monthlyCents;
  final double yearlyCents;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final noun = count == 1 ? 'subscription' : 'subscriptions';

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
            count == 0
              ? 'Nothing tracked yet.'
              : '${formatCents(yearlyCents)} a year across $count $noun.',
            style: theme.textTheme.bodyMedium
              ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}


class _SubscriptionGroup extends StatelessWidget {
  const _SubscriptionGroup({
    required this.subscriptions,
    required this.today,
    required this.onTap,
  });

  final List<Subscription> subscriptions;
  final DateTime today;
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
        ],
      ),
    );
  }
}