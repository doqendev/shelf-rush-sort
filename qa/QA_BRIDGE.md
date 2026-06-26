# Shelf Rush Sort — QA build & automation bridge

This is a QA build of the Flutter web app, built with:

```
flutter build web --release --dart-define=SHELF_RUSH_ENV=qa --pwa-strategy=none --no-web-resources-cdn --base-href "/"
```

- `--pwa-strategy=none`: no service worker, so there is no stale-cache / hard-refresh problem.
- `--no-web-resources-cdn`: CanvasKit is bundled locally (`canvaskit/`), so the build runs **fully offline** — no gstatic/CDN fetch.
- `SHELF_RUSH_ENV=qa`: enables the automation bridge below (it is **never** present in production builds).

## Running it

Serve `build-web/` with any static server and open it in Chrome (headless or headed):

```
cd build-web
python -m http.server 8080
# open http://localhost:8080/
```

The app boots directly into a playable level at `/`. Most gameplay is drawn into a `<canvas>`, so the DOM alone is not enough to verify state — use the bridge.

## The bridge: `window.shelfRushQa`

Available once the app has loaded a level. All mutating calls **drive the game controller directly** (not synthetic pixel events), so they are deterministic and obey exactly the same rules as real input (tutorial restrictions, move validation, booster availability, etc.). **Every mutator returns a structured result** (e.g. `{ok, reason, ...}`) so you never have to infer success from before/after diffs.

| Call | Signature → returns | Effect |
|---|---|---|
| `getState()` | `() => object` | Full game + economy state (see payload below). `{status:"no_active_game"}` if no level is open. |
| `goToLevel(n)` | `(int) => {ok, level}` | Load level `n` in a **fresh** session — even if already on it (fixes the same-level reload trap). |
| `restartLevel()` | `() => {ok, level}` | Reload the current level fresh. |
| `tapCell(compartment, cell)` | `(int,int) => {ok, selectedCell}` | Select the product in shelf `compartment`, slot `cell`. |
| `dragCellToCell(fromC, fromCell, toC, toCell)` | `(int×4) => {ok, moveCount, status, visibleProductCount}` | Make a move (select + place). |
| `useBooster(kind)` | `(string) => {ok, kind, reason, consumed, beforeCount, afterCount}` | Use a booster (`hint`/`shuffle`/`hammer`/`freezeTime`/`extraShelf`/`revealHidden`/`slowConveyor`). Mirrors the real flow — consumed only if it actually applies (P0.1). |
| `pause()` / `resume()` | `() => {ok}` | Pause / resume the simulation. |
| `resetSave()` | `() => {ok}` | Reset to a fresh player (coins/stars/collection/boosters) **and** restart the active level. |
| `isPresentationBusy()` | `() => bool` | True while clear/move animations are still playing — poll until false to wait for settle. |
| `viewportInfo()` | `() => object` | `{gameWidth, gameHeight, hasActiveGame}`. |

### Addressing

`compartment` is the 0-based shelf index exactly as reported in `getState().board[].index`; `cell` is `0..2` within that shelf (left→right). Read `getState().board` first to see which shelf holds which products — there are 15 shelves (`boardColumns=3 × boardRows=5`), 3 cells each.

### `getState()` payload

```json
{
  "level": 1,
  "levelId": "...",
  "status": "playing",          // playing | won | failed
  "moveCount": 0,
  "visibleProductCount": 6,
  "objectiveType": "clearAll",
  "objectiveText": "Put 3 matching products on one shelf",
  "remainingText": "6 left",
  "selectedCell": null,          // e.g. "1:0" when a cell is selected
  "failReason": "none",
  "timerSeconds": null,          // null on untimed levels
  "coins": 500,
  "stars": 0,
  "levelStars": {},              // { "<levelId>": 3 }
  "discoveredSkus": [],
  "ledgerKeys": [],              // economy ledger keys (grant idempotency)
  "boosterCounts": { "hint": 3, "shuffle": 1, "hammer": 1 },
  "canRevive": false,
  "winRewardAvailable": false,   // first-completion coin reward still pending
  "doubleRewardAvailable": false,
  "presentationBusy": false,
  "board": [
    { "index": 0, "locked": false, "decorative": false, "interactable": true, "cells": ["sku_000", "sku_000", null] }
  ]
}
```

### Example: verify the booster-trust fix (P0.1)

```js
shelfRushQa.goToLevel(1);                      // untimed level
const before = shelfRushQa.getState().boosterCounts.freezeTime;
shelfRushQa.useBooster('freezeTime');          // nothing to freeze on an untimed level
const after = shelfRushQa.getState().boosterCounts.freezeTime;
// before === after  -> inventory was NOT consumed for a no-op
```

See `qa_manifest.json` for ready-made flows with expected outcomes.
