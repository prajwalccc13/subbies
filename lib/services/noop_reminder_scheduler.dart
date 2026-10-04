// =============================================================================
// services/noop_reminder_scheduler.dart — A SCHEDULER THAT DOES NOTHING
// =============================================================================

import 'package:subbies/models/subscription.dart';
import 'package:subbies/services/reminder_scheduler.dart';


class NoopReminderScheduler implements ReminderScheduler {
  const NoopReminderScheduler();

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> scheduleFor(List<Subscription> subscriptions) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> sendTestNotification() async {}
}