import 'package:flutter/material.dart';

import '../../design/game_colors.dart';
import '../../design/game_surfaces.dart';
import '../../design/game_typography.dart';

/// Resolves a cozy art asset path, e.g. `cozyAsset('btn/grass-play.png')`.
String cozyAsset(String path) => 'assets/images/cozy/$path';

/// Chunky headline — a coloured fill behind a thick ink stroke with a hard
/// drop shadow: the signature title treatment used throughout the design.
class CozyTitle extends StatelessWidget {
  const CozyTitle(
    this.text, {
    super.key,
    this.fontSize = 42,
    this.color = GameColors.sunny,
    this.strokeWidth = 4,
    this.textAlign = TextAlign.center,
    this.height = 1.0,
    this.letterSpacing = 0.5,
  });

  final String text;
  final double fontSize;
  final Color color;
  final double strokeWidth;
  final TextAlign textAlign;
  final double height;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    return StrokedText(
      text,
      fontSize: fontSize,
      fillColor: color,
      strokeColor: GameColors.ink,
      strokeWidth: strokeWidth,
      textAlign: textAlign,
      height: height,
      letterSpacing: letterSpacing,
      dropShadow: true,
    );
  }
}

/// Text rendered as an ink outline with a coloured fill on top
/// (CSS `paint-order: stroke fill`).
class StrokedText extends StatelessWidget {
  const StrokedText(
    this.text, {
    super.key,
    required this.fontSize,
    required this.fillColor,
    this.strokeColor = GameColors.ink,
    this.strokeWidth = 2,
    this.textAlign = TextAlign.center,
    this.height = 1.0,
    this.letterSpacing = 0.5,
    this.dropShadow = false,
  });

  final String text;
  final double fontSize;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final TextAlign textAlign;
  final double height;
  final double letterSpacing;
  final bool dropShadow;

  @override
  Widget build(BuildContext context) {
    final TextStyle base = TextStyle(
      fontFamily: GameTypography.fontFamily,
      fontWeight: FontWeight.w700,
      fontSize: fontSize,
      height: height,
      letterSpacing: letterSpacing,
    );
    return Stack(
      children: <Widget>[
        Text(
          text,
          textAlign: textAlign,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..strokeJoin = StrokeJoin.round
              ..color = strokeColor,
            shadows: dropShadow
                ? <Shadow>[
                    Shadow(
                      color: GameColors.shadow(0.28),
                      offset: Offset(0, strokeWidth),
                    ),
                  ]
                : null,
          ),
        ),
        Text(
          text,
          textAlign: textAlign,
          style: base.copyWith(color: fillColor),
        ),
      ],
    );
  }
}

/// Primary call-to-action built on the cozy "big bar" sprite.
class CozyButton extends StatelessWidget {
  const CozyButton({
    super.key,
    required this.label,
    this.onTap,
    this.height = 64,
    this.fontSize = 26,
  });

  final String label;
  final VoidCallback? onTap;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: height,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Positioned.fill(
              child: Image.asset(
                cozyAsset('bar/big-bar.png'),
                fit: BoxFit.fill,
                errorBuilder:
                    (BuildContext context, Object error, StackTrace? stack) =>
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            color: GameColors.leaf,
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                          ),
                        ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: StrokedText(
                label,
                fontSize: fontSize,
                fillColor: const Color(0xFFFFFFFF),
                strokeWidth: 2,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sprite icon button (pause, close, settings…).
class CozyIconButton extends StatelessWidget {
  const CozyIconButton({
    super.key,
    required this.asset,
    this.onTap,
    this.size = 44,
    this.tooltip,
  });

  final String asset;
  final VoidCallback? onTap;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final Widget button = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Image.asset(
        cozyAsset(asset),
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
            SizedBox(width: size, height: size),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Rounded "sticker" pill wrapper.
class CozyPill extends StatelessWidget {
  const CozyPill({
    super.key,
    required this.child,
    this.color = GameColors.surface,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  final Widget child;
  final Color color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: GameSurfaces.pill(color: color),
      child: Padding(padding: padding, child: child),
    );
  }
}
