import 'dart:convert';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:subbies/data/subscription_repository.dart';
import 'package:subbies/models/subscription.dart';


class LocalSubscriptionRepository implements SubscriptionRepository {
  static const _key = 'subscriptions';

  final _watchers = <StreamController<List<Subscription>>>{};

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
  Stream<List<Subscription>> watchAll() {
    late final StreamController<List<Subscription>> controller;

    controller = StreamController<List<Subscription>> (
      onListen: () async {
        _watchers.add(controller);
        try {
          controller.add(await fetchAll());
        } catch (error, stackTrace) {
          controller.addError(error, stackTrace);
        }
      },
      onCancel: () {
        _watchers.remove(controller);
      }
    );

    return controller.stream;
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
    _notifyWatchers(all);
  }

  @override
  Future<void> delete(String id) async {
    final all = await fetchAll();
    all.removeWhere((s) => s.id == id);
    await _writeAll;
    _notifyWatchers(all);
  }

  Future<void> _writeAll(List<Subscription> all) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(all.map((s) => s.toJson()).toList());
    await prefs.setString(_key, json);
  }

  void _notifyWatchers(List<Subscription> all) {
    for (final watcher in _watchers) {
      watcher.add([...all]);
    }
  }


}