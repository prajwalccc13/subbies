// =============================================================================
// services/spending_forecast.dart — WHAT WILL I PAY, AND WHEN?
// =============================================================================
//   chargesBetween()  -> every charge in a date range (for the dial)
//   monthlyForecast() -> the total for each of the next 12 months
// =============================================================================

import 'package:subbies/models/subscription.dart';


class Charge {
  const Charge({required this.subscription, required this.date});

  final Subscription subscription;
  final DateTime date;

  int get cents => subscription.priceCents;
}

DateTime lastDayOfMonth(DateTime date) =>
  DateTime(date.year, date.month + 1, 0);


