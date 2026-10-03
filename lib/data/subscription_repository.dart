import 'package:subbies/models/subscription.dart';


// class SubscriptionRepository {

//   static const _key = 'subscriptions';

//   Future<List<Subscription>> load() async {
//     final prefs = await SharedPreferences.getInstance();
//     final raw = prefs.getString(_key);
//     if (raw == null) return [];
//     final list = jsonDecode(raw) as List<dynamic>;
//     return list
//       .map((e) => Subscription.fromJson(e as Map<String, dynamic>))
//       .toList();
//   }

//   Future<void> save(List<Subscription> subscriptions) async {
//     final prefs = await SharedPreferences.getInstance();
//     final json = jsonEncode(subscriptions.map((s) => s.toJson()).toList());
//     await prefs.setString(_key, json);
//   }
// }


abstract interface class SubscriptionRepository {

  Future<List<Subscription>> fetchAll();

  /// Save one subscription: add it if new, replace it if the id exists.
  Future<void> upsert(Subscription subscription);

  /// Remove the subscription with this id.
  Future<void> delete(String id);
}