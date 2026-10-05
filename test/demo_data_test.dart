// =============================================================================
// test/demo_data_test.dart — DOES THE DEMO SHOW WHAT IT SHOULD?
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:subbies/data/demo_data.dart';

void main() {
  // Two very different days, including the end of a month, to make sure
  // the demo looks right whenever someone opens it.
  for (final today in [DateTime(2026, 10, 5), DateTime(2027, 1, 31)]) {
    group('on $today', () {
      final demo = demoSubscriptions(today);

      test('every id is unique', () {
        final ids = demo.map((s) => s.id).toList();
        expect(ids.toSet().length, ids.length);
      });

      test('a free trial ends within a week (for the alert)', () {
        final trials = demo.where((s) => s.isOnTrial(today));
        expect(trials, isNotEmpty);
        expect(trials.first.daysUntilRenewal(today), lessThanOrEqualTo(7));
      });

      test('something is paused', () {
        expect(demo.where((s) => s.isPaused), isNotEmpty);
      });

      test('several renewals fall within the next month', () {
        final soon = demo.where((s) => s.daysUntilRenewal(today) <= 31);
        expect(soon.length, greaterThanOrEqualTo(6));
      });

      test('everything has a brand color', () {
        expect(demo.every((s) => s.brandColor != null), isTrue);
      });
    });
  }
}