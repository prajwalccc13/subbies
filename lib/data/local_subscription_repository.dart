import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:subbies/data/subscription_repository.dart';
import 'package:subbies/models/subscription.dart';


class LocalSubscriptionRepository implements SubscriptionRepository {
  static const _key = 'subscriptions';

  @override
  Future<List<Subscription>> fetchAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Subscription.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> upsert(Subscription subscription) async {
    final all = await fetchAll();
    final index = all.indexWhere((s) => s.id == subscription.id);

    if (index == -1) {
      all.add(subscription);
    } else {
      all[index ]= subscription;
    }
    await _writeAll(all);
  }

  @override
  Future<void> delete(String id) async {
    final all = await fetchAll();
    all.removeWhere((s) => s.id == id);
    await _writeAll;
  }

  Future<void> _writeAll(List<Subscription> all) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(all.map((s) => s.toJson()).toList());
    await prefs.setString(_key, json);
  }


}