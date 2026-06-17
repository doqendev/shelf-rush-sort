import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/game.dart';

import '../../../domain/core/value_objects.dart';
import '../../../domain/moving_lanes/moving_lane_def.dart';

final class BoardLayout {
  BoardLayout({
    required this.gameSize,
    required this.rackRect,
    required this.laneRect,
    required Map<String, Rect> laneRects,
    required Map<int, Rect> compartmentRects,
    required Map<int, Rect> compartmentHitRects,
    required Map<CellAddress, Rect> cellRects,
    required Map<CellAddress, Rect> hitCellRects,
  }) : compartmentRects = Map<int, Rect>.unmodifiable(compartmentRects),
       compartmentHitRects = Map<int, Rect>.unmodifiable(compartmentHitRects),
       cellRects = Map<CellAddress, Rect>.unmodifiable(cellRects),
       hitCellRects = Map<CellAddress, Rect>.unmodifiable(hitCellRects),
       laneRects = Map<String, Rect>.unmodifiable(laneRects);

  final Vector2 gameSize;
  final Rect rackRect;
  final Rect laneRect;
  final Map<String, Rect> laneRects;
  final Map<int, Rect> compartmentRects;
  final Map<int, Rect> compartmentHitRects;
  final Map<CellAddress, Rect> cellRects;
  final Map<CellAddress, Rect> hitCellRects;

  Rect compartmentRect(int index) => compartmentRects[index]!;

  Rect cellRect(CellAddress address) => cellRects[address]!;

  Rect hitCellRect(CellAddress address) => hitCellRects[address]!;

  Rect laneRectFor(String laneId) => laneRects[laneId] ?? laneRect;

  CellAddress? hitTestCell(Vector2 canvasPosition) {
    final Offset offset = Offset(canvasPosition.x, canvasPosition.y);
    final List<MapEntry<CellAddress, Rect>> candidates = hitCellRects.entries
        .where((MapEntry<CellAddress, Rect> entry) {
          return entry.value.contains(offset);
        })
        .toList(growable: false);
    if (candidates.isEmpty) {
      return null;
    }
    candidates.sort((
      MapEntry<CellAddress, Rect> left,
      MapEntry<CellAddress, Rect> right,
    ) {
      final double leftDistance =
          (cellRects[left.key]!.center - offset).distanceSquared;
      final double rightDistance =
          (cellRects[right.key]!.center - offset).distanceSquared;
      return leftDistance.compareTo(rightDistance);
    });
    return candidates.first.key;
  }
}

final class BoardLayoutCalculator {
  const BoardLayoutCalculator();

  BoardLayout calculate(
    Vector2 gameSize, {
    required bool hasLane,
    List<MovingLaneDef> laneDefs = const <MovingLaneDef>[],
  }) {
    final double safeWidth = math.max(320, gameSize.x);
    final List<MovingLaneDef> lanes = laneDefs.isEmpty && hasLane
        ? <MovingLaneDef>[
            MovingLaneDef(
              id: '_default_lane',
              orientation: LaneOrientation.horizontal,
              behavior: LaneBehavior.finite,
              speedCellsPerSecond: 1,
              queue: const <MovingLaneProductDef>[],
            ),
          ]
        : laneDefs;
    final bool hasBottomLane = lanes.any(
      (MovingLaneDef lane) => lane.anchor == LaneAnchor.bottom,
    );
    final bool hasTopLane = lanes.any(
      (MovingLaneDef lane) => lane.anchor == LaneAnchor.top,
    );
    final bool hasLeftLane = lanes.any(
      (MovingLaneDef lane) => lane.anchor == LaneAnchor.left,
    );
    final bool hasRightLane = lanes.any(
      (MovingLaneDef lane) => lane.anchor == LaneAnchor.right,
    );
    final double laneHeight = hasLane ? 66 : 26;
    final double sideLaneWidth = 58;
    final double leftReserve = hasLeftLane ? sideLaneWidth : 0;
    final double rightReserve = hasRightLane ? sideLaneWidth : 0;
    final double topReserve = hasTopLane ? laneHeight + 10 : 8;
    final double bottomReserve = hasBottomLane ? laneHeight + 18 : 8;
    final double playableWidth = math.max(
      280,
      safeWidth - leftReserve - rightReserve - 16,
    );
    final double rackWidth = math.min(playableWidth, 430);
    final double availableHeight = math.max(
      260,
      gameSize.y - topReserve - bottomReserve - 8,
    );
    final double rackHeight = math.min(availableHeight, rackWidth * 1.22);
    final double left =
        leftReserve +
        ((gameSize.x - leftReserve - rightReserve - rackWidth) / 2);
    final double top =
        topReserve + ((availableHeight - rackHeight) / 2).clamp(0, 18);
    final Rect rackRect = Rect.fromLTWH(left, top, rackWidth, rackHeight);
    final Map<int, Rect> compartmentRects = <int, Rect>{};
    final Map<int, Rect> compartmentHitRects = <int, Rect>{};
    final Map<CellAddress, Rect> cellRects = <CellAddress, Rect>{};
    final Map<CellAddress, Rect> hitCellRects = <CellAddress, Rect>{};
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
        compartmentHitRects[compartmentIndex] = compartmentRect.inflate(4);
        final double cellWidth = compartmentRect.width / cellsPerCompartment;
        for (var cell = 0; cell < cellsPerCompartment; cell += 1) {
          final CellAddress address = CellAddress(
            row: row,
            column: column,
            cell: cell,
          );
          final Rect visualCellRect = Rect.fromLTWH(
            compartmentRect.left + cell * cellWidth,
            compartmentRect.top + compartmentRect.height * 0.17,
            cellWidth,
            compartmentRect.height * 0.72,
          ).deflate(2);
          cellRects[address] = visualCellRect;
          hitCellRects[address] = _expandedHitRect(
            visualCellRect,
            compartmentRect,
          );
        }
      }
    }

    final Map<String, Rect> laneRects = _laneRectsFor(
      lanes,
      gameSize,
      rackRect,
      laneHeight,
    );
    final Rect laneRect = laneRects.isEmpty
        ? Rect.zero
        : laneRects.values.first;

    return BoardLayout(
      gameSize: gameSize,
      rackRect: rackRect,
      laneRect: laneRect,
      laneRects: laneRects,
      compartmentRects: compartmentRects,
      compartmentHitRects: compartmentHitRects,
      cellRects: cellRects,
      hitCellRects: hitCellRects,
    );
  }

  Rect _expandedHitRect(Rect visualRect, Rect compartmentRect) {
    final double inflateX =
        math.max(0, minInteractiveTargetPx - visualRect.width) / 2 + 0.25;
    final double inflateY =
        math.max(0, minInteractiveTargetPx - visualRect.height) / 2 + 0.25;
    return visualRect
        .inflate(math.max(inflateX, inflateY))
        .intersect(compartmentRect.inflate(10));
  }

  Map<String, Rect> _laneRectsFor(
    List<MovingLaneDef> lanes,
    Vector2 gameSize,
    Rect rackRect,
    double laneHeight,
  ) {
    final Map<String, Rect> rects = <String, Rect>{};
    final Map<LaneAnchor, int> anchorCounts = <LaneAnchor, int>{};
    for (final MovingLaneDef lane in lanes) {
      final int offset = anchorCounts.update(
        lane.anchor,
        (int value) => value + 1,
        ifAbsent: () => 0,
      );
      rects[lane.id] = switch (lane.anchor) {
        LaneAnchor.bottom => Rect.fromLTWH(
          rackRect.left,
          rackRect.bottom + 18 + offset * (laneHeight + 8),
          rackRect.width,
          laneHeight,
        ),
        LaneAnchor.top => Rect.fromLTWH(
          rackRect.left,
          rackRect.top - laneHeight - 10 - offset * (laneHeight + 8),
          rackRect.width,
          laneHeight,
        ),
        LaneAnchor.left => Rect.fromLTWH(
          6 + offset * 58,
          rackRect.top,
          52,
          rackRect.height,
        ),
        LaneAnchor.right => Rect.fromLTWH(
          gameSize.x - 58 - offset * 58,
          rackRect.top,
          52,
          rackRect.height,
        ),
        LaneAnchor.rowOverlay => Rect.fromLTWH(
          rackRect.left,
          rackRect.top +
              (lane.row ?? 0).clamp(0, boardRows - 1) *
                  rackRect.height /
                  boardRows,
          rackRect.width,
          laneHeight,
        ),
        LaneAnchor.columnOverlay => Rect.fromLTWH(
          rackRect.left +
              (lane.column ?? 0).clamp(0, boardColumns - 1) *
                  rackRect.width /
                  boardColumns,
          rackRect.top,
          math.max(52, rackRect.width / boardColumns),
          rackRect.height,
        ),
      };
    }
    return rects;
  }
}
