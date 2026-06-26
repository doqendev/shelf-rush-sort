import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'qa_bridge.dart';

/// Attaches [bridge] to `window.shelfRushQa` so QA automation can drive and
/// inspect the game. Only invoked in non-production builds. Mutators return a
/// structured result object (jsified) so automation doesn't infer success.
void installQaBridge(QaBridge bridge) {
  final JSObject api = JSObject();

  api['goToLevel'] =
      ((JSNumber level) => bridge.goToLevel(level.toDartInt).jsify()).toJS;
  api['restartLevel'] = (() => bridge.restartLevel().jsify()).toJS;
  api['resetSave'] = (() => bridge.resetSave().jsify()).toJS;
  api['pause'] = (() => bridge.pause().jsify()).toJS;
  api['resume'] = (() => bridge.resume().jsify()).toJS;
  api['tapCell'] =
      ((JSNumber compartment, JSNumber cell) =>
              bridge.tapCell(compartment.toDartInt, cell.toDartInt).jsify())
          .toJS;
  api['dragCellToCell'] =
      ((JSNumber fromC, JSNumber fromCell, JSNumber toC, JSNumber toCell) =>
              bridge
                  .dragCellToCell(
                    fromC.toDartInt,
                    fromCell.toDartInt,
                    toC.toDartInt,
                    toCell.toDartInt,
                  )
                  .jsify())
          .toJS;
  api['useBooster'] =
      ((JSString kind) => bridge.useBooster(kind.toDart).jsify()).toJS;
  api['getState'] = (() => bridge.getState().jsify()).toJS;
  api['viewportInfo'] = (() => bridge.viewportInfo().jsify()).toJS;
  api['isPresentationBusy'] = (() => bridge.isPresentationBusy().toJS).toJS;
  api['ready'] = (() => bridge.ready().jsify()).toJS;

  globalContext['shelfRushQa'] = api;
}
