// =============================================================================
// test/app_layout_test.dart — THE RIGHT LAYOUT FOR EVERY WIDTH
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:subbies/layout/app_layout.dart';

void main() {
  test('phones get a bottom bar and one pane', () {
    final layout = AppLayout.forWidth(400);
    expect(layout.usesRail, isFalse);
    expect(layout.twoPane, isFalse);
  });

  test('small tablets get a rail, still one pane', () {
    final layout = AppLayout.forWidth(700);
    expect(layout.usesRail, isTrue);
    expect(layout.extendedRail, isFalse);
    expect(layout.twoPane, isFalse);
  });

  test('tablets and small laptops get two panes', () {
    final layout = AppLayout.forWidth(1000);
    expect(layout.twoPane, isTrue);
    expect(layout.extendedRail, isFalse);
  });

  test('laptops get the full sidebar', () {
    final layout = AppLayout.forWidth(1440);
    expect(layout.extendedRail, isTrue);
    expect(layout.twoPane, isTrue);
  });

  // Edges are where off-by-one mistakes hide, so test them exactly.
  test('breakpoints switch exactly at 600, 840 and 1200', () {
    expect(AppLayout.forWidth(599.9).usesRail, isFalse);
    expect(AppLayout.forWidth(600).usesRail, isTrue);
    expect(AppLayout.forWidth(839.9).twoPane, isFalse);
    expect(AppLayout.forWidth(840).twoPane, isTrue);
    expect(AppLayout.forWidth(1199.9).extendedRail, isFalse);
    expect(AppLayout.forWidth(1200).extendedRail, isTrue);
  });

  test('content is centered once the window is wider than the limit', () {
    expect(centeredGutter(400), 20); // Narrow: minimum padding
    expect(centeredGutter(1720), 500); // (1720 - 720) / 2
  });
}