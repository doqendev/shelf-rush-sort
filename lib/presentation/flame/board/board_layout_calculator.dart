import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/game.dart';

import '../../../domain/core/value_objects.dart';

final class BoardLayout {
  BoardLayout({
    required this.gameSize,
    required this.rackRect,
    required this.laneRect,
    required Map<int, Rect> compartmentRects,
    required Map<CellAddress, Rect> cellRects,
  }) : compartmentRects = Map<int, Rect>.unmodifiable(compartmentRects),
       cellRects = Map<CellAddress, Rect>.unmodifiable(cellRects);

  final Vector2 gameSize;
  final Rect rackRect;
  final Rect laneRect;
  final Map<int, Rect> compartmentRects;
  final Map<CellAddress, Rect> cellRects;

  Rect compartmentRect(int index) => compartmentRects[index]!;

  Rect cellRect(CellAddress address) => cellRects[address]!;

  CellAddress? hitTestCell(Vector2 canvasPosition) {
    final Offset offset = Offset(canvasPosition.x, canvasPosition.y);
    for (final MapEntry<CellAddress, Rect> entry in cellRects.entries) {
      if (entry.value.contains(offset)) {
        return entry.key;
      }
    }
    return null;
  }
}

final class BoardLayoutCalculator {
  const BoardLayoutCalculator();

  BoardLayout calculate(Vector2 gameSize, {required bool hasLane}) {
    final double safeWidth = math.max(320, gameSize.x);
    final double laneHeight = hasLane ? 66 : 26;
    final double topInset = math.max(78, gameSize.y * 0.11);
    final double bottomInset = 88 + laneHeight;
    final double rackWidth = math.min(safeWidth - 24, 430);
    final double availableHeight = math.max(
      420,
      gameSize.y - topInset - bottomInset,
    );
    final double rackHeight = math.min(availableHeight, rackWidth * 1.22);
    final double left = (gameSize.x - rackWidth) / 2;
    final double top =
        topInset + ((availableHeight - rackHeight) / 2).clamp(0, 22);
    final Rect rackRect = Rect.fromLTWH(left, top, rackWidth, rackHeight);
    final Map<int, Rect> compartmentRects = <int, Rect>{};
    final Map<CellAddress, Rect> cellRects = <CellAddress, Rect>{};
    final double compartmentWidth = rackRect.width / boardColumns;
    final double compartmentHeight = rackRect.height / boardRows;

    for (var row = 0; row < boardRows; row += 1) {
      for (var column = 0; column < boardColumns; column += 1) {
        final int compartmentIndex = row * boardColumns + column;
        final Rect compartmentRect = Rect.fromLTWH(
          rackRect.left + column * compartmentWidth,
          rackRect.top + row * compartmentHeight,
          compartmentWidth,
          compartmentHeight,
        ).deflate(4);
        compartmentRects[compartmentIndex] = compartmentRect;
        final double cellWidth = compartmentRect.width / cellsPerCompartment;
        for (var cell = 0; cell < cellsPerCompartment; cell += 1) {
          final CellAddress address = CellAddress(
            row: row,
            column: column,
            cell: cell,
          );
          cellRects[address] = Rect.fromLTWH(
            compartmentRect.left + cell * cellWidth,
            compartmentRect.top + compartmentRect.height * 0.17,
            cellWidth,
            compartmentRect.height * 0.72,
          ).deflate(2);
        }
      }
    }

    final Rect laneRect = Rect.fromLTWH(
      rackRect.left,
      rackRect.bottom + 18,
      rackRect.width,
      laneHeight,
    );

    return BoardLayout(
      gameSize: gameSize,
      rackRect: rackRect,
      laneRect: laneRect,
      compartmentRects: compartmentRects,
      cellRects: cellRects,
    );
  }
}
