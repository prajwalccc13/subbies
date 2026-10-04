// =============================================================================
// layout/app_layout.dart — WHAT DOES THIS SCREEN SIZE MEAN FOR THE LAYOUT?
// =============================================================================
// Breakpoints follow Material Design's window size classes:
//   compact  < 600   phones
//   medium   < 840   small tablets, phones in landscape
//   expanded < 1200  tablets, small laptops
//   large    ≥ 1200  laptops and desktops
// =============================================================================

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class AppLayout {
  const AppLayout._({
    required this.usesRail,
    required this.extendedRail,
    required this.twoPane,
  });

  factory AppLayout.forWidth(double width) {
    if (width < 600) {
      return const AppLayout._(
        usesRail: false,
        extendedRail: false,
        twoPane: false,
      );
    }
    if (width < 840) {
      return const AppLayout._(
        usesRail: true,
        extendedRail: false,
        twoPane: false,
      );
    }
    if (width < 1200) {
      return const AppLayout._(
        usesRail: true,
        extendedRail: false,
        twoPane: true,
      );
    }
    return const AppLayout._(usesRail: true, extendedRail: true, twoPane: true);
  }

  static AppLayout of(BuildContext context) =>
      AppLayout.forWidth(MediaQuery.sizeOf(context).width);

  final bool usesRail;
  final bool extendedRail;
  final bool twoPane;
}

double centeredGutter(
  double availableWidth, {
  double maxWidth = 720,
  double minGutter = 20,
}) => math.max(minGutter, (availableWidth - maxWidth) / 2);
