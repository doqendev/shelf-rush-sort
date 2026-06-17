import 'package:flutter/widgets.dart';

final class GameLayoutTokens {
  const GameLayoutTokens._();

  static double horizontalPaddingFor(double width) {
    if (width < 340) {
      return 8;
    }
    if (width < 390) {
      return 10;
    }
    if (width < 720) {
      return 12;
    }
    return 16;
  }

  static double headerHeightFor(double width) {
    if (width < 340) {
      return 48;
    }
    if (width < 390) {
      return 52;
    }
    if (width < 720) {
      return 56;
    }
    return 60;
  }

  static double objectiveHeightFor(double width) {
    if (width < 340) {
      return 38;
    }
    if (width < 390) {
      return 40;
    }
    if (width < 720) {
      return 44;
    }
    return 46;
  }

  static const double minHitTarget = 44;
  static const double maxPhoneRackWidth = 430;
  static const EdgeInsets compactInset = EdgeInsets.symmetric(horizontal: 8);
}
