import 'package:flutter/material.dart';

import 'game_colors.dart';

/// Cozy v2 surfaces — chunky "sticker" cards, pills and CTAs.
///
/// The signature look: a thick ink outline, generous rounding, and a hard
/// offset drop shadow (no blur) that makes every element feel like a sticker
/// pressed onto the screen.
final class GameSurfaces {
  const GameSurfaces._();

  /// Hard offset "sticker" shadow used across the whole UI.
  static List<BoxShadow> stickerShadow({
    double dy = 5,
    double alpha = 0.18,
    double blur = 0,
  }) {
    return <BoxShadow>[
      BoxShadow(
        color: GameColors.shadow(alpha),
        offset: Offset(0, dy),
        blurRadius: blur,
      ),
    ];
  }

  /// Cream sticker card (the workhorse panel).
  static BoxDecoration panel({
    Color color = GameColors.surface,
    double radius = 22,
    double borderWidth = 3.5,
    double shadowDy = 5,
    double shadowAlpha = 0.16,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: GameColors.border, width: borderWidth),
      boxShadow: stickerShadow(dy: shadowDy, alpha: shadowAlpha),
    );
  }

  /// Rounded pill — counters, chips, toggles.
  static BoxDecoration pill({
    Color color = GameColors.surface,
    double borderWidth = 3,
    double shadowDy = 3,
    double shadowAlpha = 0.18,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: GameColors.border, width: borderWidth),
      boxShadow: stickerShadow(dy: shadowDy, alpha: shadowAlpha),
    );
  }

  /// Accent action surface (leaf green by default).
  static BoxDecoration button({
    Color color = GameColors.leaf,
    double radius = 14,
    double borderWidth = 3,
    double shadowDy = 3,
    double shadowAlpha = 0.2,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: GameColors.border, width: borderWidth),
      boxShadow: stickerShadow(dy: shadowDy, alpha: shadowAlpha),
    );
  }

  /// Bottom dock surface.
  static BoxDecoration dock() {
    return BoxDecoration(
      color: GameColors.surface.withValues(alpha: 0.92),
      border: const Border(top: BorderSide(color: GameColors.border, width: 3)),
    );
  }
}
