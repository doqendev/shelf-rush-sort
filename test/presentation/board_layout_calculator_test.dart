import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_rush_sort/domain/core/value_objects.dart';
import 'package:shelf_rush_sort/presentation/flame/board/board_layout_calculator.dart';

void main() {
  const BoardLayoutCalculator calculator = BoardLayoutCalculator();
  final Map<String, Vector2> requiredViewports = <String, Vector2>{
    '320 px phone': Vector2(320, 568),
    '360 px phone': Vector2(360, 640),
    '390 px phone': Vector2(390, 844),
    '430 px phone': Vector2(430, 932),
    'tablet': Vector2(768, 1024),
  };

  for (final MapEntry<String, Vector2> viewport in requiredViewports.entries) {
    test('5x3 rack fits and remains targetable at ${viewport.key}', () {
      for (final bool hasLane in <bool>[false, true]) {
        final BoardLayout layout = calculator.calculate(
          viewport.value,
          hasLane: hasLane,
        );

        expect(layout.compartmentRects, hasLength(compartmentCount));
        expect(layout.cellRects, hasLength(frontCellCount));
        expect(layout.rackRect.left, greaterThanOrEqualTo(0));
        expect(layout.rackRect.right, lessThanOrEqualTo(viewport.value.x));
        expect(layout.rackRect.top, greaterThanOrEqualTo(0));
        expect(layout.rackRect.bottom, lessThan(layout.laneRect.top));
        expect(layout.laneRect.bottom, lessThanOrEqualTo(viewport.value.y));

        for (final MapEntry<CellAddress, Rect> entry
            in layout.cellRects.entries) {
          expect(entry.value.width, greaterThanOrEqualTo(26));
          expect(entry.value.height, greaterThanOrEqualTo(40));
          expect(layout.rackRect.contains(entry.value.center), isTrue);
          expect(
            layout.hitTestCell(
              Vector2(entry.value.center.dx, entry.value.center.dy),
            ),
            entry.key,
          );
        }

        _expectNoOverlappingCells(layout);
      }
    });
  }
}

void _expectNoOverlappingCells(BoardLayout layout) {
  final List<MapEntry<CellAddress, Rect>> entries = layout.cellRects.entries
      .toList(growable: false);
  for (var left = 0; left < entries.length; left += 1) {
    for (var right = left + 1; right < entries.length; right += 1) {
      expect(
        entries[left].value.overlaps(entries[right].value),
        isFalse,
        reason: '${entries[left].key} overlaps ${entries[right].key}',
      );
    }
  }
}
