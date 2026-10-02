// =============================================================================
// test/subscription_test.dart — CHECKING THE TRICKY MATH
// =============================================================================
// Date math is exactly the kind of code that LOOKS right and is subtly
// wrong. Tests prove it handles the awkward cases, like month ends.
// Run with:  flutter test
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:subbies/models/subscription.dart';

// A helper that fills in the boring fields so each test only states
// what matters to it.
Subscription make({
  required int priceCents,
  required BillingCycle cycle,
  required DateTime start,
}) =>
    Subscription(
      id: '1',
      name: 'Test',
      priceCents: priceCents,
      cycle: cycle,
      category: SubscriptionCategory.other,
      startDate: start,
    );

void main() {
  // `group` bundles related tests under one heading in the results.
  group('monthly cost', () {
    test('a yearly plan is divided by 12', () {
      final s = make(
        priceCents: 12000,
        cycle: BillingCycle.yearly,
        start: DateTime(2026, 1, 1),
      );
      expect(s.monthlyCents, 1000);
    });

    test('a weekly plan is 52 weeks spread over 12 months', () {
      final s = make(
        priceCents: 1000,
        cycle: BillingCycle.weekly,
        start: DateTime(2026, 1, 1),
      );
      // closeTo allows a tiny difference, because this is a decimal.
      expect(s.monthlyCents, closeTo(4333.33, 0.01));
    });
  });

  group('next renewal', () {
    test('a plan started on 31 Jan renews on 28 Feb', () {
      final s = make(
        priceCents: 999,
        cycle: BillingCycle.monthly,
        start: DateTime(2026, 1, 31),
      );
      expect(s.nextRenewal(DateTime(2026, 2, 10)), DateTime(2026, 2, 28));
    });

    test('...and goes back to the 31st in March', () {
      final s = make(
        priceCents: 999,
        cycle: BillingCycle.monthly,
        start: DateTime(2026, 1, 31),
      );
      expect(s.nextRenewal(DateTime(2026, 3, 1)), DateTime(2026, 3, 31));
    });

    test('weekly plans step forward 7 days at a time', () {
      final s = make(
        priceCents: 500,
        cycle: BillingCycle.weekly,
        start: DateTime(2026, 9, 1),
      );
      final today = DateTime(2026, 9, 10);
      expect(s.nextRenewal(today), DateTime(2026, 9, 15));
      expect(s.daysUntilRenewal(today), 5);
    });

    test('renewing today counts as today, not next cycle', () {
      final s = make(
        priceCents: 999,
        cycle: BillingCycle.monthly,
        start: DateTime(2026, 8, 20),
      );
      expect(s.daysUntilRenewal(DateTime(2026, 9, 20)), 0);
    });
  });

  test('JSON round trip keeps every field', () {
    final s = make(
      priceCents: 1599,
      cycle: BillingCycle.yearly,
      start: DateTime(2025, 6, 15),
    );
    final copy = Subscription.fromJson(s.toJson());
    expect(copy.priceCents, s.priceCents);
    expect(copy.cycle, s.cycle);
    expect(copy.category, s.category);
    expect(copy.startDate, s.startDate);
  });

    // NEW ---------------------------------------------------------------------
  group('trials and pausing', () {
    test('data saved before Phase 2 still loads', () {
      // Exactly what the OLD app saved: no isFreeTrial, no isPaused.
      final oldJson = {
        'id': '1',
        'name': 'Old subscription',
        'priceCents': 999,
        'cycle': 'monthly',
        'category': 'music',
        'startDate': '2025-03-01T00:00:00.000',
      };

      final s = Subscription.fromJson(oldJson);

      expect(s.isFreeTrial, isFalse);
      expect(s.isPaused, isFalse);
    });

    test('a trial is free up to and including its end date', () {
      final s = Subscription(
        id: '1',
        name: 'Trial',
        priceCents: 1399,
        cycle: BillingCycle.monthly,
        category: SubscriptionCategory.entertainment,
        startDate: DateTime(2026, 10, 10),
        isFreeTrial: true,
      );

      expect(s.isOnTrial(DateTime(2026, 10, 9)), isTrue); // Day before
      expect(s.isOnTrial(DateTime(2026, 10, 10)), isTrue); // Last day
      expect(s.isOnTrial(DateTime(2026, 10, 11)), isFalse); // Converted
      expect(s.countsTowardSpend(DateTime(2026, 10, 11)), isTrue);
    });

    test('a paused subscription never counts toward spend', () {
      final s = Subscription(
        id: '1',
        name: 'Gym',
        priceCents: 4500,
        cycle: BillingCycle.monthly,
        category: SubscriptionCategory.health,
        startDate: DateTime(2026, 1, 1),
        isPaused: true,
      );

      expect(s.countsTowardSpend(DateTime(2026, 10, 1)), isFalse);
    });
  });
}