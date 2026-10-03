//  Data layout in Firestore:
//   users/{userId}/subscriptions/{subscriptionId}
// The security rules only let a signed-in user touch users/{their own id}.
//
// OFFLINE: Firestore keeps a copy of the data on the phone. Reads work
// offline, and writes made offline are sent when the connection returns.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:subbies/data/subscription_repository.dart';
import 'package:subbies/models/subscription.dart';


class FirestoreSubscriptionRepository implements SubscriptionRepository {
  FirestoreSubscriptionRepository({
    required this.userId,
    FirebaseFirestore? firestore,
  }): _db = firestore ?? FirebaseFirestore.instance;

  final String userId;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _collection => 
    _db.collection('users').doc(userId).collection('subscriptions');

  @override
  Future<List<Subscription>> fetchAll() async {
    final snapshot = await _collection.get();
    return snapshot.docs.map((doc) => Subscription.fromJson(doc.data())).toList();
  }

  @override
  Stream<List<Subscription>> watchAll() {
    return _collection.snapshots().map(
      (snapshot) => snapshot.docs
        .map((doc) => Subscription.fromJson(doc.data()))
        .toList(),
    );
  }

  @override
  Future<void> upsert(Subscription subscription) {
    return _collection.doc(subscription.id).set(subscription.toJson());
  }

  @override
  Future<void> delete(String id) => _collection.doc(id).delete();
}