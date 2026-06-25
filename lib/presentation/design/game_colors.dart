import 'package:flutter/painting.dart';

/// Cozy v2 palette — "Self Rush Short Cozy v2 (No Outline)".
///
/// The whole UI rests on a single mauve ink (`#60455F`) used for every outline,
/// title stroke and drop shadow, warm cream surfaces, and a small candy accent
/// set (sunny yellow, blossom pink, leaf green) layered over per-screen pastels.
final class GameColors {
  const GameColors._();

  // --- Ink & frame -------------------------------------------------------
  /// Primary ink: every border, title stroke and dark label.
  static const Color ink = Color(0xFF60455F);

  /// Muted secondary text.
  static const Color mutedInk = Color(0xFF8D7F9B);

  /// Faint section labels / tertiary text.
  static const Color faintInk = Color(0xFF9A8DA6);

  /// Deep plum phone bezel / heavy frame.
  static const Color bezel = Color(0xFF4A3349);

  // --- Surfaces ----------------------------------------------------------
  /// Default app background (mint home tone).
  static const Color background = Color(0xFFBFE9D6);

  /// Warm cream panel fill.
  static const Color surface = Color(0xFFFFF7E4);

  /// Opaque white for elevated chips.
  static const Color surfaceStrong = Color(0xFFFFFFFF);

  /// Inset tile / locked-slot fill.
  static const Color surfaceInset = Color(0xFFF3E8CF);

  /// Hairline divider inside cream panels.
  static const Color divider = Color(0xFFEFE3CB);

  /// Default border color (solid ink).
  static const Color border = ink;

  // --- Accents -----------------------------------------------------------
  /// Sunny yellow — titles, time bar, reward pills.
  static const Color sunny = Color(0xFFFFE08A);
  static const Color sunnyLip = Color(0xFFE8C56B);

  /// Blossom pink — combo, badges, secondary CTAs.
  static const Color blossom = Color(0xFFFF9BC2);
  static const Color blossomStroke = Color(0xFFB35583);

  /// Leaf green — primary CTAs, toggles-on, progress fills.
  static const Color leaf = Color(0xFF92EC8F);
  static const Color leafLip = Color(0xFF7DB68A);

  /// Toggle-off track.
  static const Color toggleOff = Color(0xFFD8CEDB);

  /// Back-compat alias (was the old green accent).
  static const Color accent = leaf;

  // --- Shelf / board -----------------------------------------------------
  /// Default rack body (warm wood); per-theme overrides may replace it.
  static const Color rackWood = Color(0xFFC99A63);

  /// Default rack lip (chunky drop edge beneath the rack).
  static const Color rackLip = Color(0xFF9C7340);

  /// Back-compat alias for the old dark rack tone.
  static const Color rackDark = rackLip;

  /// Cell gradient — top (deeper tan) to bottom (light cream).
  static const Color cellTop = Color(0xFFE9D7B7);
  static const Color cellBottom = Color(0xFFFBF1DA);

  /// Cool-blue gameplay shelf (design "Puzzle" screen rack).
  static const Color shelf = Color(0xFF9FD8F0);
  static const Color shelfLip = Color(0xFF6FB3D6);

  // --- Per-screen pastel backgrounds ------------------------------------
  static const Color bgMint = Color(0xFFBFE9D6);
  static const Color bgGreen = Color(0xFFB0F9D1);
  static const Color bgPink = Color(0xFFEFD6FF);
  static const Color bgBlue = Color(0xFFCBF1FF);
  static const Color bgYellow = Color(0xFFFFF8E8);

  /// Ink-tinted shadow used by every "sticker" drop shadow — `rgba(96,69,95,a)`.
  static Color shadow(double alpha) => ink.withValues(alpha: alpha);
}
