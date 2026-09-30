import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:subbies/models/subscription.dart';


const tabularFigures = [FontFeature.tabularFigures()];

class AppTheme {

  static final ThemeData light = _build(
    ColorScheme.fromSeed(
      seedColor: const Color(0xFF0E7C66),
      brightness: Brightness.light,
      primary: const Color(0xFF0E7C66), // Deep teal
      surface: const Color(0xFFF2F3F5), // Cool light grey background
      onSurface: const Color(0xFF15171C), // Near-black text
      onSurfaceVariant: const Color(0xFF6A6F7A), // Grey secondary text
      surfaceContainerLowest: Colors.white, // Panels
      outlineVariant: const Color(0xFFE1E3E8), // Dividers
    )
  );

  static final ThemeData dark = _build(
    ColorScheme.fromSeed(
      seedColor: const Color(0xFF3CCB9F),
      brightness: Brightness.light,
      primary: const Color(0xFF3CCB9F), // Brighter teal, readable on dark
      onPrimary: const Color(0xFF06231B), // Dark text on teal buttons
      surface: const Color(0xFF111317), // Deep charcoal background
      onSurface: const Color(0xFFECEDEF),
      onSurfaceVariant: const Color(0xFF9AA0AA),
      surfaceContainerLowest: const Color(0xFF1A1D22), // Panels, slightly lighter
      outlineVariant: const Color(0xFF2A2E35),
    )
  );

  static ThemeData _build(ColorScheme colors) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
    );

    final text = GoogleFonts.manropeTextTheme(base.textTheme).apply(
      bodyColor: colors.onSurface,
      displayColor: colors.onSurface,
    );

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colors.outlineVariant),
    );

    return base.copyWith(
      textTheme: text,

      // app Bar
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),

      // Bottom Navigation Bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        elevation: 0,
        indicatorColor: colors.primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStatePropertyAll(
          text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      // Divider 
      dividerTheme: DividerThemeData(
        color: colors.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLowest,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),

      // FilledButtonTheme
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          // Built from our text theme so the button keeps the Manrope font.
          textStyle: text.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Segmented Button
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          // Selected segment is "inverted": dark in light mode and vice versa.
          selectedBackgroundColor: colors.onSurface,
          selectedForegroundColor: colors.surface,
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.onSurface,
        foregroundColor: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

}

extension CategoryColor on SubscriptionCategory {
  Color get color => switch (this) {
    SubscriptionCategory.entertainment => const Color(0xFFE0654E),
        SubscriptionCategory.music => const Color(0xFF7C5CD6),
        SubscriptionCategory.productivity => const Color(0xFF3A7BD5),
        SubscriptionCategory.utilities => const Color(0xFF7D8591),
        SubscriptionCategory.health => const Color(0xFF2FA37A),
        SubscriptionCategory.other => const Color(0xFFC58B2B),
  };
}