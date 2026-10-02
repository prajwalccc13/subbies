import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:subbies/models/subscription.dart';
import 'package:subbies/theme/app_theme.dart';
import 'package:subbies/utils/money.dart';
import 'package:subbies/widgets/monogram.dart';


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

    final isPaused = subscription.isPaused;
    final onTrial = subscription.isOnTrial(today);
    final days = subscription.daysUntilRenewal(today);
    final renewal = subscription.nextRenewal(today);

    final String status;
    final Color statusColor;
    FontWeight? statusWeight;

    if (isPaused) {
      status = 'Paused';
      statusColor = colors.onSurfaceVariant;
    } else if (onTrial) {
      status = switch (days) {
        0 => 'Renews today',
        1 => 'Renews tomorrow',
        _ => 'Renews in $days days',
      };
      statusColor = trialColor(context);
      statusWeight = FontWeight.w700;
    } else {
      status = switch (days) {
        0 => 'Renews today',
        1 => 'Renews tomorrow',
        < 7 => 'Renews in $days days',
        _ => 'Renews ${DateFormat('d MMM').format(renewal)}',
      };
      final isSoon = days <= 3;
      statusColor = isSoon ? colors.primary : colors.onSurfaceVariant;
      statusWeight = isSoon ? FontWeight.w700 : null;
    }

    final isSoon = days <= 3; 

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        child: Opacity(
          opacity: isPaused ? 0.5 : 1,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      status,
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
                      color: onTrial ? colors.onSurfaceVariant : null,
                    ),
                  ),
                  Text(
                    onTrial
                      ? 'after trial'
                      : '/${subscription.cycle.shortLabel}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
          
            ],
          ),
        ),
      ),
    );
  }
}