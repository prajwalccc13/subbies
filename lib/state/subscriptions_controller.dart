import 'package:flutter/foundation.dart';
import 'package:subbies/data/subscription_repository.dart';
import 'package:subbies/models/subscription.dart';



class SubscriptionsController extends ChangeNotifier {
  SubscriptionsController(this._repository);

  final SubscriptionRepository _repository;

  List<Subscription> _subscriptions = [];
  bool _isLoading = true;

  List<Subscription> get subscriptions => List.unmodifiable(_subscriptions);
  bool get isLoading => _isLoading;

  double get monthlyTotalCents => _subscriptions.fold<double>(
    0,
    (total, s) => total + s.monthlyCents,
  );

  double get yearlyTotalCents => monthlyTotalCents * 12;

  Subscription? get mostExpensive => _subscriptions.isEmpty
  ? null
  : _subscriptions.reduce((a, b) => a.monthlyCents >= b.monthlyCents ? a : b);

  List<MapEntry<SubscriptionCategory, double>> get monthlyByCategory {
    final totals = <SubscriptionCategory, double> {};
    for (final s in _subscriptions) {
      totals[s.category] = (totals[s.category] ?? 0) + s.monthlyCents;
    }

    return totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  List<Subscription> byNextRenewal(DateTime today) {
    final sorted = [..._subscriptions];
    sorted.sort((a, b) => a.nextRenewal(today).compareTo(b.nextRenewal(today)));
    return sorted;
  }


  Future<void> load() async {
    try {
      _subscriptions = await _repository.load();
    } catch (error) {
      debugPrint('Could not load subscriptions: $error');
      _subscriptions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> save(Subscription subscription) async {
    final index = _subscriptions.indexWhere((s) => s.id == subscription.id);
    if (index == -1) {
      _subscriptions.add(subscription);
    } else {
      _subscriptions[index] = subscription;
    }
    notifyListeners();
    await _persist();
  }

  Future<void> delete(Subscription subscription) async {
    _subscriptions.removeWhere((s) => s.id == subscription.id);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      await _repository.save(_subscriptions);
    } catch (error) {
      debugPrint('Could not save subscriptions: $error');
    }
  }

}