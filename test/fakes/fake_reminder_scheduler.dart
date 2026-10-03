// =============================================================================
// test/fakes/fake_reminder_scheduler.dart
// =============================================================================
// Pretends to schedule notifications, and records what it was asked to do,
// so tests can check it.
// =============================================================================

import 'package:subbies/models/subscription.dart';
import 'package:subbies/services/reminder_scheduler.dart';

class FakeReminderScheduler implements ReminderScheduler {
  FakeReminderScheduler({this.grantPermission = true});

  /// What the pretend user answers to the permission dialog.
  final bool grantPermission;

  /// The last list we were asked to schedule (null = nothing scheduled).
  List<Subscription>? lastScheduled;
  int cancelCount = 0;
  int testNotificationsSent = 0;

  @override
  Future<bool> requestPermission() async => grantPermission;

  @override
  Future<void> scheduleFor(List<Subscription> subscriptions) async =>
      lastScheduled = subscriptions;

  @override
  Future<void> cancelAll() async {
    cancelCount++;
    lastScheduled = null;
  }

  @override
  Future<void> sendTestNotification() async => testNotificationsSent++;
}