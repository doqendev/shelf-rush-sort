import 'package:flame/components.dart';
import 'package:flame/palette.dart';

final class ParticleFactory {
  const ParticleFactory();

  Component clearBurst(Vector2 position) {
    return CircleComponent(
      position: position,
      radius: 2,
      paint: BasicPalette.white.paint(),
    );
  }
}
