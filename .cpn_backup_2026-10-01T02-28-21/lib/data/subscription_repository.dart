import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recurring/models/subscription.dart';


class SubscriptionRepository {

  static const _key = 'subscriptions';

  Future<List<Subscription>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
      .map((e) => Subscription.fromJson(e as Map<String, dynamic>))
      .toList();
  }

  Future<void> save(List<Subscription> subscriptions) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(subscriptions.map((s) => s.toJson()).toList());
    await prefs.setString(_key, json);
  }
}