// =============================================================================
// test/reminders_controller_test.dart — THE OBSERVER AND THE PERMISSION FLOW
// =============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:subbies/data/settings_repository.dart';
import 'package:subbies/models/subscription.dart';
import 'package:subbies/state/reminders_controller.dart';
import 'package:subbies/state/subscriptions_controller.dart';
   import 'package:subbies/data/in_memory_subscription_repository.dart';

import 'fakes/fake_reminder_scheduler.dart';
// import 'fakes/fake_repositories.dart';

Subscription sub(String id) => Subscription(
      id: id,
      name: 'Sub $id',
      priceCents: 1000,
      cycle: BillingCycle.monthly,
      category: SubscriptionCategory.other,
      startDate: DateTime(2026, 1, 1),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // setUp runs before EVERY test: each one starts with empty storage.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // Builds everything a test needs. Returns three things at once as a
  // "record": (a, b, c).
  Future<(RemindersController, SubscriptionsController, FakeReminderScheduler)>
      setUpControllers({bool grant = true}) async {
    final subscriptions = SubscriptionsController(
      InMemorySubscriptionRepository([sub('a'), sub('b')]),
    );
    await subscriptions.load();
    final scheduler = FakeReminderScheduler(grantPermission: grant);
    final reminders = RemindersController(
      scheduler: scheduler,
      settings: SettingsRepository(),
      subscriptions: subscriptions,
    );
    await reminders.load();
    return (reminders, subscriptions, scheduler);
  }

  test('turning reminders on schedules every subscription', () async {
    final (reminders, _, scheduler) = await setUpControllers();

    final allowed = await reminders.setEnabled(true);

    expect(allowed, isTrue);
    expect(reminders.enabled, isTrue);
    expect(scheduler.lastScheduled, hasLength(2));
  });

  test('if permission is refused, reminders stay off', () async {
    final (reminders, _, scheduler) = await setUpControllers(grant: false);

    final allowed = await reminders.setEnabled(true);

    expect(allowed, isFalse);
    expect(reminders.enabled, isFalse);
    expect(scheduler.lastScheduled, isNull);
  });

  test('adding a subscription reschedules automatically', () async {
    final (reminders, subscriptions, scheduler) = await setUpControllers();
    await reminders.setEnabled(true);

    await subscriptions.save(sub('c'));
    await reminders.pendingSync; // Wait for the queued sync to finish

    expect(scheduler.lastScheduled, hasLength(3)); // The observer worked
  });

  test('turning reminders off cancels them', () async {
    final (reminders, _, scheduler) = await setUpControllers();
    await reminders.setEnabled(true);

    await reminders.setEnabled(false);

    expect(scheduler.lastScheduled, isNull);
    expect(scheduler.cancelCount, greaterThan(0));
  });

  test('the on/off choice is remembered', () async {
    final (reminders, subscriptions, scheduler) = await setUpControllers();
    await reminders.setEnabled(true);

    // A brand-new controller, like after restarting the app:
    final restarted = RemindersController(
      scheduler: scheduler,
      settings: SettingsRepository(),
      subscriptions: subscriptions,
    );
    await restarted.load();

    expect(restarted.enabled, isTrue);
  });


  test('no reminders are scheduled for demo data', () async {
    final subscriptions = SubscriptionsController(
      InMemorySubscriptionRepository([sub('a')]),
    );
    await subscriptions.load();
    final scheduler = FakeReminderScheduler();
    var demo = false;
    final reminders = RemindersController(
      scheduler: scheduler,
      settings: SettingsRepository(),
      subscriptions: subscriptions,
      isDemo: () => demo, // We control the answer from the test
    );
    await reminders.load();
    await reminders.setEnabled(true);
    final realSchedule = scheduler.lastScheduled;

    demo = true;
    await subscriptions.switchTo(
      InMemorySubscriptionRepository([sub('x'), sub('y'), sub('z')]),
    );
    await reminders.pendingSync;

    // Still the real schedule: the demo's three subscriptions were ignored.
    expect(scheduler.lastScheduled, same(realSchedule));
  });
}