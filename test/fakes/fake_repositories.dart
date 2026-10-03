// =============================================================================
// test/fakes/fake_repositories.dart — STAND-INS FOR TESTING
// =============================================================================
// "Fakes" are simple pretend versions of real parts. Because the controller
// only knows the CONTRACT, it can't tell these apart from the real thing.
// =============================================================================

import 'package:subbies/data/subscription_repository.dart';
import 'package:subbies/models/subscription.dart';

/// Keeps subscriptions in a plain list. Nothing is saved anywhere.
class InMemorySubscriptionRepository implements SubscriptionRepository {
  // Square brackets = an optional parameter. Pass a starting list, or none.
  // The part after `:` copies it into our own private list.
  InMemorySubscriptionRepository([List<Subscription> initial = const []])
      : _items = [...initial];

  final List<Subscription> _items;

  @override
  Future<List<Subscription>> fetchAll() async => [..._items];

  @override
  Future<void> upsert(Subscription subscription) async {
    final index = _items.indexWhere((s) => s.id == subscription.id);
    if (index == -1) {
      _items.add(subscription);
    } else {
      _items[index] = subscription;
    }
  }

  @override
  Future<void> delete(String id) async =>
      _items.removeWhere((s) => s.id == id);
}

/// Fails at everything, to test that the app copes with errors.
class FailingSubscriptionRepository implements SubscriptionRepository {
  @override
  Future<List<Subscription>> fetchAll() async =>
      throw Exception('Storage unavailable');

  @override
  Future<void> upsert(Subscription subscription) async =>
      throw Exception('Storage unavailable');

  @override
  Future<void> delete(String id) async =>
      throw Exception('Storage unavailable');
}