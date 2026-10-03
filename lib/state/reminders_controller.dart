// =============================================================================
// state/reminders_controller.dart — KEEPING REMINDERS UP TO DATE
// =============================================================================
// Owns the "reminders on/off" setting and keeps the phone's scheduled
// reminders in sync with the subscriptions.
//
// THE OBSERVER PATTERN: this controller LISTENS to SubscriptionsController,
// just like screens do. Whenever subscriptions change, we reschedule.
// SubscriptionsController doesn't know (or need to know) we exist.
// =============================================================================

import 'package:flutter/foundation.dart';

import 'package:subbies/data/settings_repository.dart';
import 'package:subbies/services/reminder_scheduler.dart';
import 'package:subbies/state/subscriptions_controller.dart';


class RemindersController extends ChangeNotifier {
  RemindersController({
    required this._scheduler,
    required this._settings,
    required this._subscriptions,
  }){
    _subscriptions.addListener(_onSubscriptionsChanged);
  }

  final ReminderScheduler _scheduler;
  final SettingsRepository _settings;
  final SubscriptionsController _subscriptions;

  bool _enabled = false;
  bool get enabled => _enabled;

  Future<void> _queue = Future.value();

  /// @visibleForTesting = "only tests should use this". The analyzer warns
  /// if normal app code does.
  @visibleForTesting
  Future<void> get pendingSync => _queue;

  Future<void> load() async {
    try {
      _enabled = await _settings.loadRemindersEnabled();
    } catch (error) {
      debugPrint('Could not load reminder setting: $error');
    }
    notifyListeners();
    await _sync();
  }

  /// Turn reminders on or off.
  /// Returns false if the user refused notification permission.
  Future<bool> setEnabled(bool value) async {
    if (value) {
      final granted = await _scheduler.requestPermission();
      if (!granted) return false; // Stay off;
    }

    _enabled = value;
    notifyListeners();
    try {
      await _settings.saveRemindersEnabled(value);
    } catch (error) {
      debugPrint('Could not save reminder setting: $error');
    }
    await _sync();
    return true;
  }

  Future<void> sendTest() async {
    try {
      await _scheduler.sendTestNotification();
    } catch (error) {
      debugPrint('Could not send test notification: $error');
    }
  }

  // Called every time SubscriptionsController calls notifyListeners().
  void _onSubscriptionsChanged() => _sync();

  Future<void> _sync() {
    _queue = _queue.then((_) => _runSync());
    return _queue;
  }

  Future<void> _runSync() async {
    // Don't schedule from a half-loaded list.
    if (_subscriptions.isLoading) return;

    // If one job in a .then() chain
    // fails, every job queued after it is skipped, and reminders would
    // silently stop updating.
    try {
      if (_enabled) {
        await _scheduler.scheduleFor(_subscriptions.subscriptions);
      } else {
        await _scheduler.cancelAll();
      }
    } catch (error) {
      debugPrint('Could not update reminders: $error');
    }
  }

  // Stop listening when this controller is thrown away.
  @override
  void dispose() {
    _subscriptions.removeListener(_onSubscriptionsChanged);
    super.dispose();
  }
}