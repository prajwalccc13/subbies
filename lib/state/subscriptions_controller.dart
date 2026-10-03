import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:subbies/data/subscription_repository.dart';
import 'package:subbies/models/subscription.dart';



class SubscriptionsController extends ChangeNotifier {
  SubscriptionsController(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  SubscriptionRepository _repository;
  final DateTime Function() _clock;

  StreamSubscription<List<Subscription>>? _watching;

  List<Subscription> _subscriptions = [];
  bool _isLoading = true;

  List<Subscription> get subscriptions => List.unmodifiable(_subscriptions);
  bool get isLoading => _isLoading;

  DateTime get _today => _clock(); 

  /// Start watching the current repository.
  Future<void> load() => _watch(_repository);

  /// stop watching the current repository and start watching another
  Future<void> switchTo(SubscriptionRepository repository) {
    _repository = repository;
    return _watch(repository);
  }

  /// Listens to the repository's stream. The Future it returns finishes
  /// when the FIRST list arrives, so callers can `await` "loaded".
  Future<void> _watch(SubscriptionRepository repository) {
    _watching?.cancel(); // Stop listening to the old one, if any
    _isLoading = true;
    notifyListeners();

    final firstData = Completer<void>();

    _watching = repository.watchAll().listen(
      (items) {
        _subscriptions = [...items];
        _isLoading = false;
        notifyListeners();
        if (!firstData.isCompleted) firstData.complete();
      },
      onError: (Object error) {
        debugPrint('Could not load subscriptions: $error');
        _isLoading = false;
        notifyListeners();
        if (!firstData.isCompleted) firstData.complete();
      },
    );

    return firstData.future;
  }


  /// subscriptions currently costing money (not paused, not on trial).
  List<Subscription> get _charging {
    final today = _today;
    return _subscriptions.where((s) => s.countsTowardSpend(today)).toList();
  }

  int get chargingCount => _charging.length;

  double get monthlyTotalCents => _charging.fold<double>(
    0,
    (total, s) => total + s.monthlyCents,
  );

  double get yearlyTotalCents => monthlyTotalCents * 12;

  // what paused subscriptions WOULD cost per month.
  double get pausedMonthlyCents => _subscriptions
      .where((s) => s.isPaused)
      .fold<double>(0, (total, s) => total + s.monthlyCents);

  /// running (and not paused) trials, the one ending soonest first.
  List<Subscription> get activeTrials {
    final today = _today;
    final trials = _subscriptions
      .where((s) => !s.isPaused && s.isOnTrial(today))
      .toList();
    trials.sort((a, b) => a.startDate.compareTo(b.startDate));
    return trials;
  }

  // Most expensive subscriptions 
  Subscription? get mostExpensive {
    final charging = _charging;
    return charging.isEmpty
      ? null
      : charging.reduce((a, b) => a.monthlyCents >= b.monthlyCents ? a: b);
  }

  List<MapEntry<SubscriptionCategory, double>> get monthlyByCategory {
    final totals = <SubscriptionCategory, double> {};
    for (final s in _charging) {
      totals[s.category] = (totals[s.category] ?? 0) + s.monthlyCents;
    }

    return totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  // paused subscriptions go to the bottom; everything else is
  /// sorted by next renewal (a trial's "renewal" is its end date).
  List<Subscription> byNextRenewal(DateTime today) {
    final sorted = [..._subscriptions];
    sorted.sort( (a, b) {
        if (a.isPaused != b.isPaused) return a.isPaused ? 1: -1;
        return a.nextRenewal(today).compareTo(b.nextRenewal(today));
      }
    );
    return sorted;
  }

  Future<void> save(Subscription subscription) async {
    final index = _subscriptions.indexWhere((s) => s.id == subscription.id);
    if (index == -1) {
      _subscriptions.add(subscription);
    } else {
      _subscriptions[index] = subscription;
    }
    notifyListeners();
    try {
      await _repository.upsert(subscription);
    } catch (error) {
      debugPrint('Could not save ${subscription.name}: $error');
    }
  }

  Future<void> delete(Subscription subscription) async {
    _subscriptions.removeWhere((s) => s.id == subscription.id);
    notifyListeners();
    try {
      await _repository.delete(subscription.id);
    } catch (error) {
      debugPrint('Could not delete ${subscription.name}: $error');
    }
  }

  // stop listening when the controller is thrown away.
  @override
  void dispose() {
    _watching?.cancel();
    super.dispose();
  }

}