// =============================================================================
// test/fakes/fake_repositories.dart — STAND-INS FOR TESTING
// =============================================================================

import 'dart:async';

import 'package:subbies/data/subscription_repository.dart';
import 'package:subbies/models/subscription.dart';

/// Keeps subscriptions in a plain list, and announces every change.
class InMemorySubscriptionRepository implements SubscriptionRepository {
  InMemorySubscriptionRepository([List<Subscription> initial = const []])
      : _items = [...initial];

  final List<Subscription> _items;
  final _watchers = <StreamController<List<Subscription>>>{};

  @override
  Future<List<Subscription>> fetchAll() async => [..._items];

  @override
  Stream<List<Subscription>> watchAll() {
    late final StreamController<List<Subscription>> controller;
    controller = StreamController<List<Subscription>>(
      onListen: () {
        _watchers.add(controller);
        controller.add([..._items]); // Current list first
      },
      onCancel: () {
        _watchers.remove(controller);
      },
    );
    return controller.stream;
  }

  @override
  Future<void> upsert(Subscription subscription) async {
    final index = _items.indexWhere((s) => s.id == subscription.id);
    if (index == -1) {
      _items.add(subscription);
    } else {
      _items[index] = subscription;
    }
    _notify();
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((s) => s.id == id);
    _notify();
  }

  void _notify() {
    for (final watcher in _watchers) {
      watcher.add([..._items]);
    }
  }
}

/// Fails at everything, to test that the app copes with errors.
class FailingSubscriptionRepository implements SubscriptionRepository {
  @override
  Future<List<Subscription>> fetchAll() async =>
      throw Exception('Storage unavailable');

  // A stream whose only event is an error.
  @override
  Stream<List<Subscription>> watchAll() =>
      Stream.error(Exception('Storage unavailable'));

  @override
  Future<void> upsert(Subscription subscription) async =>
      throw Exception('Storage unavailable');

  @override
  Future<void> delete(String id) async =>
      throw Exception('Storage unavailable');
}