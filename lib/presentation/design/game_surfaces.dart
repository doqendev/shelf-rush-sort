import 'package:flutter/material.dart';

import 'game_colors.dart';

final class GameSurfaces {
  const GameSurfaces._();

  static BoxDecoration panel({Color color = GameColors.surface}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: GameColors.border),
    );
  }

  static BoxDecoration dock() {
    return BoxDecoration(
      color: GameColors.surface.withValues(alpha: 0.92),
      border: const Border(top: BorderSide(color: GameColors.border)),
    );
  }
}
