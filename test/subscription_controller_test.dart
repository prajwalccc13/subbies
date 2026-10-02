// =============================================================================
// test/subscriptions_controller_test.dart — TESTING THE BRAIN
// =============================================================================
// These tests check the controller's behavior using fake repositories.
// Notice there's no phone, no storage and no screen involved.
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:subbies/models/subscription.dart';
import 'package:subbies/state/subscriptions_controller.dart';

import 'fakes/fake_repositories.dart';

// Helper: a monthly subscription with a given id and price.
Subscription sub(
  String id,
  int priceCents, {
  bool isPaused = false,
  bool isFreeTrial = false,
  DateTime? start,
}) =>
    Subscription(
      id: id,
      name: 'Sub $id',
      priceCents: priceCents,
      cycle: BillingCycle.monthly,
      category: SubscriptionCategory.other,
      startDate: start ?? DateTime(2026, 1, 1),
      isPaused: isPaused,
      isFreeTrial: isFreeTrial,
    );

void main() {
  test('loads saved subscriptions, then stops loading', () async {
    final controller = SubscriptionsController(
      InMemorySubscriptionRepository([sub('a', 1000), sub('b', 500)]),
    );

    expect(controller.isLoading, isTrue); // Before loading

    await controller.load();

    expect(controller.isLoading, isFalse);
    expect(controller.subscriptions, hasLength(2));
    expect(controller.monthlyTotalCents, 1500);
  });

  test('saving the same id twice updates instead of duplicating', () async {
    final repository = InMemorySubscriptionRepository();
    final controller = SubscriptionsController(repository);
    await controller.load();

    await controller.save(sub('a', 1000)); // Add
    await controller.save(sub('a', 1500)); // Edit the same one

    expect(controller.subscriptions, hasLength(1));
    expect(controller.monthlyTotalCents, 1500);
    // Check it really reached storage, not just memory:
    expect(await repository.fetchAll(), hasLength(1));
  });

  test('delete removes from memory and storage', () async {
    final repository = InMemorySubscriptionRepository([sub('a', 1000)]);
    final controller = SubscriptionsController(repository);
    await controller.load();

    await controller.delete(controller.subscriptions.first);

    expect(controller.subscriptions, isEmpty);
    expect(await repository.fetchAll(), isEmpty);
  });

  // The Pantry bug, turned into a test so it can never come back.
  test('a storage failure still finishes loading', () async {
    final controller = SubscriptionsController(FailingSubscriptionRepository());

    await controller.load();

    expect(controller.isLoading, isFalse); // No endless spinner
    expect(controller.subscriptions, isEmpty);
  });

    // NEW
  test('totals leave out paused subscriptions and running trials', () async {
    final controller = SubscriptionsController(
      InMemorySubscriptionRepository([
        sub('paying', 1000),
        sub('paused', 500, isPaused: true),
        sub('trial', 1299, isFreeTrial: true, start: DateTime(2026, 10, 5)),
      ]),
      // A fixed "today", so this test gives the same result forever.
      clock: () => DateTime(2026, 10, 1),
    );
    await controller.load();

    expect(controller.monthlyTotalCents, 1000); // Only 'paying'
    expect(controller.chargingCount, 1);
    expect(controller.pausedMonthlyCents, 500);
    // .map(...) turns each subscription into its id, to compare easily.
    expect(controller.activeTrials.map((s) => s.id), ['trial']);
  });
}