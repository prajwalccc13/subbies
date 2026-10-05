// =============================================================================
// services/account_sync.dart — WHICH DATA IS SHOWING?
// =============================================================================
// The ONE place that decides where the subscriptions come from:
//   - signed out  -> the phone
//   - signed in   -> the cloud (moving phone data into the account first)
//   - demo        -> sample data in memory (NEW), never saved anywhere
// =============================================================================

import 'package:flutter/foundation.dart';

import 'package:subbies/data/demo_data.dart';
import 'package:subbies/data/in_memory_subscription_repository.dart';
import 'package:subbies/data/subscription_repository.dart';
import 'package:subbies/models/subscription.dart';
import 'package:subbies/state/subscriptions_controller.dart';

class AccountSync extends ChangeNotifier{
  AccountSync({
    required this._subscriptions,
    required SubscriptionRepository localRepository,
    required SubscriptionRepository Function(String userId) cloudRepositoryFor,
    this._demoData = demoSubscriptions,
    DateTime Function()? clock,
  })  : _local = localRepository,
        _cloudFor = cloudRepositoryFor,
        _clock = clock ?? DateTime.now;


  final SubscriptionsController _subscriptions;
  final SubscriptionRepository _local;
  final SubscriptionRepository Function(String userId) _cloudFor;
  final List<Subscription> Function(DateTime today) _demoData;
  final DateTime Function() _clock;

  bool _isDemo = false;

  /// true while sample data is showing.
  bool get isDemo => _isDemo;


  bool _started = false;
  String? _currentUserId;

  // One change at a time: the same queue idea as RemindersController.
  Future<void> _queue = Future.value();


  Future<void> _enqueue(Future<void> Function() job) {
    _queue = _queue.then((_) async {
      try {
        await job();
      } catch (error) {
        debugPrint('AccountSync: $error');
      }
    });
    return _queue;
  }

  /// Call with the new user's id, or null when signed out.
  Future<void> handleUserChanged(String? userId) => _enqueue(() async {
        if (_started && userId == _currentUserId) return;
        _started = true;
        _currentUserId = userId;

        // During the demo, just remember who's signed in. Their real data
        // loads when the demo ends.
        if (_isDemo) return;
        await _showRealData();
      });

  /// swap in fresh sample data. Real data is left untouched.
  Future<void> enterDemo() => _enqueue(() async {
        if (_isDemo) return;
        _isDemo = true;
        notifyListeners();
        // A brand-new in-memory repository every time, so each visit starts
        // from the same fresh demo, with dates relative to today.
        await _subscriptions.switchTo(
          InMemorySubscriptionRepository(_demoData(_clock())),
        );
      });

  /// throw the sample data away and bring the real data back.
  Future<void> exitDemo() => _enqueue(() async {
        if (!_isDemo) return;
        _isDemo = false;
        notifyListeners();
        await _showRealData();
      });

  // The real data for whoever is signed in (or the phone, if nobody is).
  Future<void> _showRealData() async {
    final userId = _currentUserId;
    if (userId == null) {
      await _subscriptions.switchTo(_local);
      return;
    }

    final cloud = _cloudFor(userId);
    try {
      await _moveLocalData(to: cloud);
    } catch (error) {
      debugPrint('Could not move local data yet: $error');
    }
    await _subscriptions.switchTo(cloud);
  }

  // Named parameter `to:` makes the call read like a sentence:
  //   _moveLocalData(to: cloud)
  Future<void> _moveLocalData({required SubscriptionRepository to}) async {
    final onPhone = await _local.fetchAll();
    if (onPhone.isEmpty) return;
    for (final subscription in onPhone) {
      await to.upsert(subscription);
    }
    for (final subscription in onPhone) {
      await _local.delete(subscription.id);
    }
  }
}