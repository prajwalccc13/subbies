// =============================================================================
// test/reminder_planner_test.dart — DOES IT PLAN THE RIGHT REMINDERS?
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:subbies/models/subscription.dart';
import 'package:subbies/services/reminder_planner.dart';

Subscription sub({
  required DateTime start,
  bool isFreeTrial = false,
  bool isPaused = false,
}) =>
    Subscription(
      id: '1',
      name: 'Spotify',
      priceCents: 1199,
      cycle: BillingCycle.monthly,
      category: SubscriptionCategory.music,
      startDate: start,
      isFreeTrial: isFreeTrial,
      isPaused: isPaused,
    );

void main() {
  // 8 am on 1 October 2026, before the 9 am reminder time.
  final now = DateTime(2026, 10, 1, 8);

  test('reminds at 9 am the day before a renewal', () {
    final plan = planReminders([sub(start: DateTime(2026, 1, 5))], now);

    expect(plan, hasLength(1));
    expect(plan.first.at, DateTime(2026, 10, 4, 9));
    expect(plan.first.title, 'Spotify renews tomorrow');
  });

  test('a free trial gets a "cancel" warning', () {
    final plan = planReminders(
      [sub(start: DateTime(2026, 10, 10), isFreeTrial: true)],
      now,
    );

    expect(plan.first.at, DateTime(2026, 10, 9, 9));
    expect(plan.first.title, 'Spotify trial ends tomorrow');
  });

  test('paused subscriptions get no reminders', () {
    final plan = planReminders(
      [sub(start: DateTime(2026, 1, 5), isPaused: true)],
      now,
    );
    expect(plan, isEmpty);
  });

  test('renewing today: plans for the next cycle instead', () {
    // Renews on the 1st; yesterday's 9 am is gone, so next is 31 Oct.
    final plan = planReminders([sub(start: DateTime(2026, 1, 1))], now);
    expect(plan.first.at, DateTime(2026, 10, 31, 9));
  });
}