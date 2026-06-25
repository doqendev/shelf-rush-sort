import 'package:flutter/material.dart';

import '../presentation/design/game_colors.dart';
import '../presentation/design/game_typography.dart';

final class ShelfRushTheme {
  const ShelfRushTheme._();

  static ThemeData build() {
    final ColorScheme scheme =
        ColorScheme.fromSeed(
          seedColor: GameColors.ink,
          brightness: Brightness.light,
        ).copyWith(
          primary: GameColors.ink,
          secondary: GameColors.leaf,
          surface: GameColors.surface,
          onSurface: GameColors.ink,
        );
    return ThemeData(
      useMaterial3: true,
      fontFamily: GameTypography.fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: GameColors.bgMint,
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontWeight: FontWeight.w700),
        labelLarge: TextStyle(fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: GameColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: GameColors.ink, width: 3),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: GameColors.leaf,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: GameColors.ink, width: 3),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: GameColors.ink,
          side: const BorderSide(color: GameColors.ink, width: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: GameColors.surface,
        side: BorderSide(color: GameColors.ink, width: 2),
        shape: StadiumBorder(),
      ),
      iconTheme: const IconThemeData(color: GameColors.ink),
    );
  }
}
