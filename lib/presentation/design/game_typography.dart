import 'package:flutter/material.dart';

import 'game_colors.dart';

/// Cozy v2 typography — Fredoka throughout, rounded and chunky.
final class GameTypography {
  const GameTypography._();

  /// Bundled Fredoka variable font (see `pubspec.yaml`).
  static const String fontFamily = 'Fredoka';

  static const TextStyle levelLabel = TextStyle(
    fontFamily: fontFamily,
    color: GameColors.ink,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle compactLabel = TextStyle(
    fontFamily: fontFamily,
    color: GameColors.ink,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle objective = TextStyle(
    fontFamily: fontFamily,
    color: GameColors.ink,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle secondary = TextStyle(
    fontFamily: fontFamily,
    color: GameColors.mutedInk,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  /// Section eyebrow label (e.g. "BOOSTERS", "GOAL").
  static const TextStyle eyebrow = TextStyle(
    fontFamily: fontFamily,
    color: GameColors.faintInk,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
  );

  /// Body label on cream cards.
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    color: GameColors.ink,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
}
