import 'dart:math';


enum BillingCycle {
  weekly('Weekly', 'wk'),
  monthly('Monthly', 'mo'),
  yearly('Yearly', 'yr');

  const BillingCycle(this.label, this.shortLabel);
  final String label;
  final String shortLabel;
}


enum SubscriptionCategory {
  entertainment('Entertainment'),
  music('Music'),
  productivity('Productivity'),
  utilities('Utilities'),
  health('Health'),
  other('Other');

  const SubscriptionCategory(this.label);
  final String label; 
}

class Subscription {
  const Subscription({
    required this.id,
    required this.name,
    required this.priceCents,
    required this.cycle,
    required this.category,
    required this.startDate,
    this.isFreeTrial = false,
    this.isPaused = false,
  });

  final String id;
  final String name;

  final int priceCents;
  final BillingCycle cycle;
  final SubscriptionCategory category;
  final DateTime startDate;
  final bool isFreeTrial;
  final bool isPaused;


  double get monthlyCents => switch(cycle) {
    BillingCycle.weekly => priceCents * 52 / 12,
    BillingCycle.monthly => priceCents.toDouble(),
    BillingCycle.yearly => priceCents / 12,
  };

  double get yearlyCents => monthlyCents * 12;

  bool isOnTrial(DateTime today) {
    if(!isFreeTrial) return false;
    final todayDate = DateTime(today.year, today.month, today.day);
    final trialEnd = DateTime(startDate.year, startDate.month, startDate.day);
    
    return !todayDate.isAfter(trialEnd);
  }

   /// Should this subscription count in "what am I paying"?
  /// Not if it's paused, and not while the free trial is running.
  bool countsTowardSpend(DateTime today) => !isPaused && !isOnTrial(today);

  DateTime nextRenewal(DateTime today) {
    final todayDate = DateTime(today.year, today.month, today.day);

    var cycles = 0;
    var date = _chargeDate(cycles);

    while (date.isBefore(todayDate)) {
      cycles++;
      date = _chargeDate(cycles);
    }
    return date;
  }

  int daysUntilRenewal(DateTime today) {
    final next = nextRenewal(today);
    final from = DateTime.utc(today.year, today.month, today.day);
    final to = DateTime.utc(next.year, next.month, next.day);
    return to.difference(from).inDays;
  } 

  DateTime _chargeDate(int n) => switch(cycle) {
    BillingCycle.weekly => 
      DateTime(startDate.year, startDate.month, startDate.day + 7 *n),
    BillingCycle.monthly => _addMonths(startDate, n),
    BillingCycle.yearly => _addMonths(startDate, 12 * n),
  };

  static DateTime _addMonths(DateTime date, int months) {
    final firstOfMonth = DateTime(date.year, date.month + months, 1);

    final daysInMonth = 
      DateTime(firstOfMonth.year, firstOfMonth.month + 1, 0).day;
    return DateTime(
      firstOfMonth.year,
      firstOfMonth.month,
      min(date.day, daysInMonth),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'priceCents': priceCents,
    'cycle': cycle.name,
    'category': category.name,
    'startDate': startDate.toIso8601String(),
    'isFreeTrial': isFreeTrial, 
    'isPaused': isPaused,
  };

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
    id: json['id'] as String,
    name: json['name'] as String,
    priceCents: json['priceCents'] as int,
    cycle: BillingCycle.values.byName(json['cycle'] as String),
    category: SubscriptionCategory.values.byName(json['category'] as String),
    startDate: DateTime.parse(json['startDate'] as String),
    isFreeTrial: json['isFreeTrial'] as bool? ?? false,
    isPaused: json['isPaused'] as bool? ?? false,
  );

}