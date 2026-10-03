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
Subscription sub(String id, int priceCents) => Subscription(
      id: id,
      name: 'Sub $id',
      priceCents: priceCents,
      cycle: BillingCycle.monthly,
      category: SubscriptionCategory.other,
      startDate: DateTime(2026, 1, 1),
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
}