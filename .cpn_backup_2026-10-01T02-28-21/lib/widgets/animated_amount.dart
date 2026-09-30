import 'package:flutter/material.dart';

import 'package:recurring/utils/money.dart';


class AnimatedAmount extends StatelessWidget {
  const new({
    super.key,
    required this.cents, 
    this.style
  });

  final double cents;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween(begin: 0, end: cents), 
      duration: const Duration(milliseconds: 700), 
      curve: Curves.easeInOutCubic,
      builder: (context, value, child) => Text(
        formatCents(value),
        style: style
      ),
    );
  }
}