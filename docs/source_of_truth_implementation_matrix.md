# Source Of Truth Implementation Matrix

This matrix tracks implementation against
`Shelf_Rush_Sort_Flutter_Flame_Source_of_Truth.md`.

| Area | Status | Evidence | Remaining |
|---|---|---|---|
| Layered Flutter + Flame architecture | Implemented | Domain/application/presentation/infrastructure folders; architecture guard in CI | Keep guard updated as production SDKs land |
| Pure deterministic gameplay domain | Implemented | Board rules, moving lane rules, timers, objectives, boosters, solver, replay player, domain tests | Broaden blocker/booster variants as content uses them |
| 5x3 rack and small-width layout | Implemented with automated guard | Layout calculator and tests for 320, 360, 390, 430, tablet | Full pixel goldens/device screenshots still required |
| First-session tutorial | Implemented | First level-one move hint and session tests | Add visual tutorial callouts/copy polish |
| Moving lanes | Implemented | Deterministic authored queues, lane solver support, replayable lane grabs | Tune lane feel on physical devices |
| Content pipeline | Implemented | Deterministic builder, schemas, 60 SKUs, visual manifest, generated 300-level dev-test pack, validator dashboard | Human-authored production level review remains required |
| Product visual contract | Implemented as procedural manifest | `asset_manifest.json` covers every SKU and validates against catalog tokens | Replace procedural visuals with production atlased sprites before store release |
| Save model | Implemented | Nested save shape, checksum, migrations, local repository tests | Cloud backend integration not enabled |
| Cloud save | Local-first, fail-closed | `CloudSaveRepository` throws when unconfigured; decision doc exists | Real cloud adapter and conflict tests required before enabling sync |
| Remote config | Implemented with defaults | Bundled defaults, feature flags, lane speed multiplier application, tests | Remote fetch/caching SDK integration still external |
| Consent/privacy gate | Implemented shell | Runtime consent service, settings control, consent-aware analytics tests | Privacy policy, platform labels, ATT/UMP SDK integration remain external |
| Analytics | Implemented abstraction and debug console | Event catalog, debug stream, consent wrapper, gameplay/economy/ad/performance events | Production dashboards and provider credentials remain external |
| Monetization architecture | Implemented/fail-closed | Ads/IAP interfaces, fake QA adapters, production adapters return unavailable, rewarded revive/double reward flows | Real mediation SDK, real IAP, receipt validation backend required |
| Meta/liveops shell | Implemented shell | Map, shop, collections, events, daily reward/streak, ledgered claim | Deeper liveops calendar and event content authoring required |
| Audio/haptics | Event-wired shell | Audio/haptic service boundaries, settings, and gameplay event cue mapping exist | Real SFX/music assets required |
| Performance/release audit | Implemented CI guard | QA web/APK builds, release audit budgets, performance level-load event | Physical low-end device profiling remains required |
| QA process | Partially implemented | Unit/widget/layout/content tests, manual checklist, screenshot matrix | Pixel goldens, integration tests, device matrix evidence still required |
| Store/support/localization | Not production-complete | README/docs note current scope | Store assets, support workflow, localization pass, app privacy submissions required |

Current conclusion: the repository is a validated engineering shell with a
generated dev-test pack, deterministic gameplay, content validation metrics,
local save, debug telemetry, fail-closed external adapters, and QA build checks.
It is not yet production-store complete because real SDK credentials, real
product art, human/device QA, store assets, localization, and support/compliance
operations are external production tasks.
