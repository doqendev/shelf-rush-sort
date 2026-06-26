import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'qa_bridge.dart';

/// Attaches [bridge] to `window.shelfRushQa` so QA automation can drive and
/// inspect the game. Only invoked in non-production builds.
void installQaBridge(QaBridge bridge) {
  final JSObject api = JSObject();

  api['goToLevel'] = ((JSNumber level) => bridge.goToLevel(
    level.toDartInt,
  )).toJS;
  api['resetSave'] = (() => bridge.resetSave()).toJS;
  api['pause'] = (() => bridge.pause()).toJS;
  api['resume'] = (() => bridge.resume()).toJS;
  api['tapCell'] = ((JSNumber compartment, JSNumber cell) => bridge.tapCell(
    compartment.toDartInt,
    cell.toDartInt,
  )).toJS;
  api['dragCellToCell'] =
      ((JSNumber fromC, JSNumber fromCell, JSNumber toC, JSNumber toCell) =>
              bridge.dragCellToCell(
                fromC.toDartInt,
                fromCell.toDartInt,
                toC.toDartInt,
                toCell.toDartInt,
              ))
          .toJS;
  api['useBooster'] = ((JSString kind) => bridge.useBooster(kind.toDart)).toJS;
  api['getState'] = (() => bridge.getState().jsify()).toJS;
  api['viewportInfo'] = (() => bridge.viewportInfo().jsify()).toJS;

  globalContext['shelfRushQa'] = api;
}
