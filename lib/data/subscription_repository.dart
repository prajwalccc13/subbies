import 'package:subbies/models/subscription.dart';

abstract interface class SubscriptionRepository {
  /// Every saved subscription, once.
  Future<List<Subscription>> fetchAll();

  /// the current list now, then a new list after every change.
  Stream<List<Subscription>> watchAll();

  /// Save one subscription: add it if new, replace it if the id exists.
  Future<void> upsert(Subscription subscription);

  /// Remove the subscription with this id.
  Future<void> delete(String id);
}