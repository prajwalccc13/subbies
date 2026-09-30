import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:recurring/models/subscription.dart';
import 'package:recurring/theme/app_theme.dart';
import 'package:recurring/utils/money.dart';
import 'package:recurring/widgets/monogram.dart';


class SubscriptionTile extends StatelessWidget {
  const new({
    super.key,
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
    final colors = theme.colorScheme;

    final days = subscription.daysUntilRenewal(today);
    final renewal = subscription.nextRenewal(today);

    final when = switch (days) {
      0 => 'Renews today',
      1 => 'Renews tomorrow',
      < 7 => 'Renews in $days days',
      _ => 'Renews ${DateFormat('d MMM').format(renewal)}',
    };

    final isSoon = days <= 3; 

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        child: Row(
          children: [
            Hero(
              tag: 'monogram-${subscription.id}',
              child: Monogram(
                name: subscription.name,
                color: subscription.category.color,
              ),
            ),
            const SizedBox(width: 14),

            // Expanded
            Expanded(
              child: Column(
                children: [
                  Text(
                    subscription.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    when,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSoon ? colors.primary : colors.onSurfaceVariant,
                      fontWeight: isSoon ? FontWeight.w700 : null,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 12,),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCents(subscription.priceCents),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: tabularFigures,
                  ),
                ),
                Text(
                  '/${subscription.cycle.shortLabel}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }
}