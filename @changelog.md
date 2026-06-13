### [2026-05-19] v3.0.0 — 0-Engine migration

- **[Major] Proximity backend migrated from Cron polling to 0-Engine reactive primitives** (SpatialSet + per-entry detection zones). Removed `Cron.lua`, the polling loop, and the `scanner_interval` config. `init.lua` rewritten: `GetMod` inside `onInit`, `Mod.WhenReady` priority 2, `GameSession.OnEnd` for `isSessionActive` gating. `Automation.lua` is a thin wrapper over the shared `ChecklistCore` (byte-identical across all 4 mods).
- **[New] Required dependency**: 0-Engine (Nexus 27967, pure CET-only build, 0.18.3+). 0-Engine itself requires CET 1.32+, Codeware 1.12+, redscript 0.5.19+.
- **[Change] No `PlayerInvalidated` teardown subscriber.** 0-Engine's `Reset()` does not unregister sets/zones; subscribing a teardown there converts a transient false-invalidation into permanent breakage. Registrations persist; 0-Engine auto-resumes on Lifecycle recovery. (Wiki: `learnings/0-engine-playerinvalidated-no-teardown`.) This is what fixed the vendor-open break and the save break (both 0-Engine-cycle issues, never in published 2.0.2).
- **[Change] "Set Pin" decoupled** into a standalone `init.lua` manual waypoint, independent of Core. Net user-facing behaviour unchanged vs 2.0.2. (Wiki: `decisions/user-pin-decoupled-from-core`.)
- **[Change] Stadium vendor hook** (`FullscreenVendorGameController` observers + `ScanTarget`) reimplemented on the new architecture; behaviour parity with 2.0.2.
- **[New] `GameUI.lua`** (psiberx CET Kit) added for fast loading-screen detection.

### [2026-02-22] Initial
- Repository created from workspace restructure.

---

## Historical Changelog (Pre-Restructure)

### v1.0
- Initial Upload

### v2.0.0
- Proximity Scanning System: Dynamic Mappins - when you get close to an uncollected perk shard, an icon will appear on your HUD along with notification text letting you know which item, and where.
- Optimization: The scanner uses weak references and optimized timers so it has negligible impact on your FPS, even with scanning enabled.
- Improved Directions: Updated text descriptions and fixed some typos.
- Various UI improvements.
- Proximity Scanning System: A passive proximity scanner that runs in the background to let you know when uncollected clothing items are near.

### v2.0.1
- Fixed scanner loop not stopping correctly when everything is collected.
- Added 7s safety delay on teleport to prevent false "auto-collects" during loading screens.

### v2.0.2
- ACTUALLY fixed scanner loop not stopping correctly when everything is collected.
