// =============================================================================
// data/demo_data.dart — SAMPLE SUBSCRIPTIONS FOR THE DEMO
// =============================================================================
// Every date is worked out FROM TODAY ("renews in 3 days"), never written as
// a fixed date. A fixed date would make the demo look broken a month later.
//
// The mix is chosen to show off the app: renewals spread across the month,
// a free trial about to end, a paused subscription, and yearly plans.
// =============================================================================

import 'package:subbies/data/service_catalog.dart';
import 'package:subbies/models/subscription.dart';

List<Subscription> demoSubscriptions(DateTime today) {
  final t = DateTime(today.year, today.month, today.day);

  // Builds one demo subscription from a catalog service.
  //   renewsInDays: when the next charge (or trial end) should be
  //   cyclesAgo:    how many billing cycles ago it started (its "history")
  Subscription make(
    String name, {
    required int renewsInDays,
    int cyclesAgo = 6,
    bool trial = false,
    bool paused = false,
    BillingCycle? cycle,
    int? priceCents,
  }) {
    // firstWhere: the first catalog entry with this name.
    final service = serviceCatalog.firstWhere((s) => s.name == name);
    final billing = cycle ?? service.cycle;

    // Work backwards from "next charge in N days" to a start date.
    // (DateTime fixes overflow for us: day 35 of a month rolls into the next.)
    final DateTime start = trial
        ? DateTime(t.year, t.month, t.day + renewsInDays) // Trial ends then
        : switch (billing) {
            BillingCycle.weekly =>
              DateTime(t.year, t.month, t.day + renewsInDays - 7 * cyclesAgo),
            BillingCycle.monthly =>
              DateTime(t.year, t.month - cyclesAgo, t.day + renewsInDays),
            BillingCycle.yearly =>
              DateTime(t.year - cyclesAgo, t.month, t.day + renewsInDays),
          };

    return Subscription(
      // A readable, unique id like 'demo-netflix'.
      id: 'demo-${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}',
      name: name,
      priceCents: priceCents ?? service.typicalPriceCents,
      cycle: billing,
      category: service.category,
      startDate: start,
      isFreeTrial: trial,
      isPaused: paused,
      brandColor: service.brandColor,
    );
  }

  return [
    make('Disney+', renewsInDays: 2, trial: true), // The trial alert
    make('Netflix', renewsInDays: 3, cyclesAgo: 14),
    make('Xbox Game Pass', renewsInDays: 6, cyclesAgo: 5),
    make('Spotify', renewsInDays: 9, cyclesAgo: 30),
    make('Notion', renewsInDays: 12, cyclesAgo: 8),
    make('iCloud+', renewsInDays: 16, cyclesAgo: 20),
    make('YouTube Premium', renewsInDays: 18, paused: true),
    make('Strava', renewsInDays: 21, cyclesAgo: 4),
    make('ChatGPT Plus', renewsInDays: 25, cyclesAgo: 10),
    make('Amazon Prime',
        renewsInDays: 47, cycle: BillingCycle.yearly, priceCents: 13900, cyclesAgo: 3),
    make('Duolingo Super', renewsInDays: 130, cyclesAgo: 2),
  ];
}