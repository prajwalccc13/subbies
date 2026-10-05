// =============================================================================
// test/fakes/fake_repositories.dart — STAND-INS FOR TESTING
// =============================================================================


import 'package:subbies/data/subscription_repository.dart';
import 'package:subbies/models/subscription.dart';



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