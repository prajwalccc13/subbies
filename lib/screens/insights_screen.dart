
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:subbies/models/subscription.dart';
import 'package:subbies/state/subscriptions_controller.dart';
import 'package:subbies/theme/app_theme.dart';
import 'package:subbies/utils/money.dart';
import 'package:subbies/layout/app_layout.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SubscriptionsController>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final categories = controller.monthlyByCategory;
    final total = controller.monthlyTotalCents;
    final priciest = controller.mostExpensive;

    Widget body;
    if (controller.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (categories.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          "Once you add a few subscriptions, you'll see where your money goes.",
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
      );
    } else {
      body =LayoutBuilder(
        builder: (context, constraints) {
          final gutter = centeredGutter(constraints.maxWidth);
          return ListView(
            padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 32),
            children: [
              Text(
                'Monthly spend by category',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              for (final entry in categories)
                _CategoryBar(
                  category: entry.key,
                  cents: entry.value,
                  fraction: entry.value / total, // e.g. 0.4 = 40% of the total
                ),
              const SizedBox(height: 8),
              Material(
                color: colors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    _StatRow(
                      label: 'Per year',
                      value: formatCents(controller.yearlyTotalCents),
                    ),
                    const Divider(indent: 16, endIndent: 16),
                    _StatRow(
                      label: 'Average subscription',
                      value:
                          '${formatCents(total / controller.chargingCount)}/mo',
                    ),
                    if (priciest != null) ...[
                      const Divider(indent: 16, endIndent: 16),
                      _StatRow(label: 'Most expensive', value: priciest.name),
                    ],
          
                    // a little motivation for pausing things you don't use.
                    if (controller.pausedMonthlyCents > 0) ...[
                      const Divider(indent: 16, endIndent: 16),
                      _StatRow(
                        label: 'Saved by pausing',
                        value: '${formatCents(controller.pausedMonthlyCents)}/mo',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        }
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: body,
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.category,
    required this.cents,
    required this.fraction,
  });

  final SubscriptionCategory category;
  final double cents;
  final double fraction; // Between 0 and 1

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 10, color: category.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.label,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${formatCents(cents)}/mo',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: tabularFigures,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ClipRRect = clip the child to rounded corners.
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 10,
              width: double.infinity, // Full width
              // The grey "track" behind the bar...
              child: ColoredBox(
                color: colors.outlineVariant,
                // ...and the colored bar, growing from 0 to its width.
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: fraction),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => FractionallySizedBox(
                    alignment: Alignment.centerLeft, // Grow from the left
                    widthFactor: value,
                    child: child,
                  ),
                  child: ColoredBox(color: category.color),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}