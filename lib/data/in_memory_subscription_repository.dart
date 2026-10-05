// =============================================================================
// data/in_memory_subscription_repository.dart — DATA THAT ISN'T SAVED
// =============================================================================


import 'dart:async';

import 'package:subbies/data/subscription_repository.dart';
import 'package:subbies/models/subscription.dart';


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
        controller.add([..._items]);
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