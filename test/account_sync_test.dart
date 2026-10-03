// =============================================================================
// test/account_sync_test.dart — NOBODY LOSES THEIR DATA
// =============================================================================


import 'package:flutter_test/flutter_test.dart';

import 'package:subbies/models/subscription.dart';
import 'package:subbies/services/account_sync.dart';
import 'package:subbies/state/subscriptions_controller.dart';

import 'fakes/fake_repositories.dart';

Subscription sub(String id) => Subscription(
      id: id,
      name: 'Sub $id',
      priceCents: 1000,
      cycle: BillingCycle.monthly,
      category: SubscriptionCategory.other,
      startDate: DateTime(2026, 1, 1),
    );

void main() {
  // Helper: builds the pieces, with a fake "cloud" for the signed-in user.
  (AccountSync, SubscriptionsController) build({
    required InMemorySubscriptionRepository local,
    required InMemorySubscriptionRepository cloud,
  }) {
    final subscriptions = SubscriptionsController(local);
    final sync = AccountSync(
      subscriptions: subscriptions,
      localRepository: local,
      cloudRepositoryFor: (userId) => cloud,
    );
    return (sync, subscriptions);
  }

  test('signed out: shows what is stored on the phone', () async {
    final local = InMemorySubscriptionRepository([sub('a')]);
    final (sync, subscriptions) =
        build(local: local, cloud: InMemorySubscriptionRepository());

    await sync.handleUserChanged(null);

    expect(subscriptions.isLoading, isFalse);
    expect(subscriptions.subscriptions.map((s) => s.id), ['a']);
  });

  test('signing in moves phone data into the account', () async {
    final local = InMemorySubscriptionRepository([sub('a'), sub('b')]);
    final cloud = InMemorySubscriptionRepository([sub('c')]);
    final (sync, subscriptions) = build(local: local, cloud: cloud);

    await sync.handleUserChanged(null);
    await sync.handleUserChanged('user-1');

    expect(await cloud.fetchAll(), hasLength(3)); // a, b and c
    expect(await local.fetchAll(), isEmpty); // Moved, not copied
    expect(subscriptions.subscriptions, hasLength(3)); // Screen shows cloud
  });

  test('an interrupted move can be repeated without duplicates', () async {
    // 'a' already reached the cloud last time, but the phone copy wasn't
    // deleted yet (the app closed halfway, say).
    final local = InMemorySubscriptionRepository([sub('a')]);
    final cloud = InMemorySubscriptionRepository([sub('a')]);
    final (sync, _) = build(local: local, cloud: cloud);

    await sync.handleUserChanged('user-1');

    expect(await cloud.fetchAll(), hasLength(1)); // Still one, not two
    expect(await local.fetchAll(), isEmpty);
  });

  test('signing out switches back to the phone', () async {
    final local = InMemorySubscriptionRepository([sub('a')]);
    final cloud = InMemorySubscriptionRepository();
    final (sync, subscriptions) = build(local: local, cloud: cloud);

    await sync.handleUserChanged('user-1');
    await sync.handleUserChanged(null);

    // The data moved into the account, so the phone list is now empty,
    // exactly what the sign-out dialog promises.
    expect(subscriptions.subscriptions, isEmpty);
    expect(await cloud.fetchAll(), hasLength(1)); // Safe in the account
  });
}