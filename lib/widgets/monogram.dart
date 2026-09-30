import 'package:flutter/material.dart';

class Monogram extends StatelessWidget {

  const Monogram({
    super.key,
    required this.name,
    required this.color,
    this.size = 44,
  });

  final String name;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final letter = 
      trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Text(
          letter,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.42,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}