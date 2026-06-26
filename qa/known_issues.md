# Known issues & scope (for review)

State as of the QA bundle. Third-pass audit Phase A + the achievable P1s are done; the items below are deliberately not yet done, so they shouldn't be re-reported as surprises.

## Out of scope for this build
- **Audio** — by product-owner decision. Cues are mapped in code but the service is silent and there are no SFX/music assets yet.
- **Real IAP** — coin packs and Remove Ads are intentionally marked "Soon" (no purchase). Booster purchases with in-game coins are real.

## Done since the third-pass audit
- Economy/reward truthfulness (P0.1 boosters never consumed on a no-op; P0.2 win panel shows only coins actually granted; P0.3 jam revives only when a shuffle can rescue).
- Collection unlocks only products actually seen on a shelf (P1.6).
- Per-level star threshold hook + blocker/lane-aware par (P1.7).
- M2 retained-component rendering: moves animate, settle-gated overlays, drop-in entrance.
- M3 stable per-SKU sprites + collision-validated; M4 booster economy; M5 reason-specific revives; M6 stars/collection/coin count-up.

## Still pending (not done)
- **Phase B — presentation sequencing**: clear → reveal → cascade are not yet an ordered timeline. The retained-component foundation, settle-gated overlay, and drop-in entrance ARE in; hidden-reveal vs pop-FX ordering can still overlap.
- **Phase C — first-session curriculum**: level 1 is a hand-tuned guided tutorial, but levels 2–10 are still generated/full-rack, not a hand-authored ramp.
- **Lanes (P1.3)**: conveyor rendering is still prototype-grade (rebuilt per tick, no carried-lane drag).
- **Responsive (P1.9)**: phone fit is tested; tablet/desktop layouts are not tuned.
- **P1.7 seeding**: star thresholds currently come from the (improved) heuristic; per-level `score` is not yet seeded from solver minimum moves.
- **P1.6 edge**: a hidden product that is revealed and then cleared mid-session may not be recorded as discovered (the recorder is conservative — it counts front cells + still-visible products).

## Content note
The live runtime pack is `level_pack_vertical_slice.json` (curated level 1 + generated levels 2+). The 300-level `level_pack_000.json` is CI-validated only (collision-free, solvable) and is **not** presented as human-tuned player-facing content.
