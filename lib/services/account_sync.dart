

import 'package:flutter/foundation.dart';

import 'package:subbies/data/subscription_repository.dart';
import 'package:subbies/state/subscriptions_controller.dart';

class AccountSync {
  AccountSync({
    required SubscriptionsController subscriptions,
    required SubscriptionRepository localRepository,
    required SubscriptionRepository Function(String userId) cloudRepositoryFor,
  })  : _subscriptions = subscriptions,
        _local = localRepository,
        _cloudFor = cloudRepositoryFor;

  final SubscriptionsController _subscriptions;
  final SubscriptionRepository _local;

  // A function that builds the cloud repository for a given user.
  // (Passing a function instead of the repository itself lets tests hand
  // in a fake one.)
  final SubscriptionRepository Function(String userId) _cloudFor;

  bool _started = false;
  String? _currentUserId;

  // One change at a time: the same queue idea as RemindersController.
  Future<void> _queue = Future.value();

  /// Call with the new user's id, or null when signed out.
  Future<void> handleUserChanged(String? userId) {
    _queue = _queue.then((_) => _apply(userId));
    return _queue;
  }

  Future<void> _apply(String? userId) async {
    // Same user as before? Nothing to do. (`_started` makes sure the very
    // first call always runs, even when that first value is null.)
    if (_started && userId == _currentUserId) return;
    _started = true;
    _currentUserId = userId;

    try {
      if (userId == null) {
        await _subscriptions.switchTo(_local);
        return;
      }

      final cloud = _cloudFor(userId);
      try {
        await _moveLocalData(to: cloud);
      } catch (error) {
        // The phone copy is still intact; we'll try again on next launch.
        debugPrint('Could not move local data yet: $error');
      }
      await _subscriptions.switchTo(cloud);
    } catch (error) {
      debugPrint('Could not switch storage: $error');
    }
  }

  // Named parameter `to:` makes the call read like a sentence:
  //   _moveLocalData(to: cloud)
  Future<void> _moveLocalData({required SubscriptionRepository to}) async {
    final onPhone = await _local.fetchAll();
    if (onPhone.isEmpty) return; // Nothing to move

    // 1. Upload everything...
    for (final subscription in onPhone) {
      await to.upsert(subscription);
    }
    // 2. ...and only THEN remove the phone copies.
    for (final subscription in onPhone) {
      await _local.delete(subscription.id);
    }
  }
}