import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';

import '../../flame/shelf_rush_game.dart';

final class GameViewport extends StatelessWidget {
  const GameViewport({super.key, required this.game});

  final ShelfRushGame game;

  @override
  Widget build(BuildContext context) {
    return ClipRect(child: GameWidget(game: game));
  }
}
