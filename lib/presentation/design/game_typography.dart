import 'package:flutter/material.dart';

import 'game_colors.dart';

final class GameTypography {
  const GameTypography._();

  static const TextStyle levelLabel = TextStyle(
    color: GameColors.ink,
    fontSize: 18,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle compactLabel = TextStyle(
    color: GameColors.ink,
    fontSize: 13,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle objective = TextStyle(
    color: GameColors.ink,
    fontSize: 14,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle secondary = TextStyle(
    color: GameColors.mutedInk,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );
}
