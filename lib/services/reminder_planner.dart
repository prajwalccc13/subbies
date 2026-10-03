import 'package:subbies/models/subscription.dart';
import 'package:subbies/utils/money.dart';


class PlannedReminder {
  const PlannedReminder({
    required this.at,
    required this.title,
    required this.body,
  });

  final DateTime at;
  final String title;
  final String body;
}

const reminderHour = 9;
const maxReminders = 60;

/// Works out every reminder that should be scheduled right now.
List<PlannedReminder> planReminders (
  List<Subscription> subscriptions,
  DateTime now,
) {
  final planned = <PlannedReminder>[];

  for (final s in subscriptions) {
    if (s.isPaused) continue;

    var charge = s.nextRenewal(now);
    var remindAt = _dayBefore(charge);

    if (!remindAt.isAfter(now)) {
      charge = s.nextRenewal(DateTime(charge.year, charge.month, charge.day + 1));
      remindAt = _dayBefore(charge);
    }

    if (!remindAt.isAfter(now)) continue;

    final price = formatCents(s.priceCents);

    if (s.isOnTrial(charge)) {
      planned.add(PlannedReminder(
        at: remindAt,
        title: '${s.name} trial ends tomorrow',
        body: "Cancel today if you don't want to pay "
            '$price/${s.cycle.shortLabel}.',
      ));
    } else {
      planned.add(PlannedReminder(
        at: remindAt,
        title: '${s.name} renews tomorrow',
        body: '$price will be charged.',
      ));
    }

  }
  // / Soonest first, then keep at most maxReminders.
  // .take(n) gives the first n items.
  planned.sort((a, b) => a.at.compareTo(b.at));
  return planned.take(maxReminders).toList();
}

DateTime _dayBefore(DateTime charge) =>
    DateTime(charge.year, charge.month, charge.day - 1, reminderHour);