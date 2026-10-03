import 'package:subbies/models/subscription.dart';

abstract interface class ReminderScheduler {
  /// Ask the user for permission to show notifications.
  /// Returns true if allowed.
  Future<bool> requestPermission();

  /// Replace all scheduled reminders with fresh ones for these subscriptions.
  Future<void> scheduleFor(List<Subscription> subscriptions);

  /// Remove every scheduled reminder.
  Future<void> cancelAll();

  /// Schedule a test notification a few seconds from now (for checking
  /// that the setup works).
  Future<void> sendTestNotification();


}