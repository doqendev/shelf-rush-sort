# Manual Playtest Checklist

Use this checklist for every milestone build.

- First screenshot looks like a complete shelf-sorting game.
- The 5x3 rack is readable at 320, 360, 390, 430, and tablet widths.
- Products are distinguishable without relying on tiny labels.
- Empty target cells and locked compartments are obvious.
- Tap-to-select, tap-to-place, drag placement, and lane grab placement work.
- Invalid feedback is visible and machine-readable in debug logs.
- The first clear happens quickly on level 1.
- Moving lane levels feel deterministic and fair.
- Win, loss, revive, reward, map, shop, and settings surfaces open correctly.
- Music, SFX, haptics, and reduce-motion settings apply immediately.
- Offline launch works with bundled content and local save.
- Background/resume preserves the current session.
- Ads and purchases fail gracefully through sandbox/fake providers.
- Analytics events appear in the debug analytics stream.
- No low-end device frame spikes are visible during clear, reveal, or lane-heavy
  moments.
