## Implemented (v3.0.0)
- [x] In-game checklist tracking all 13 Perk Shards (base game and Phantom Liberty).
- [x] 0-Engine proximity scanner: event-driven (no polling interval), notifies within `scanner_radius` (default 50m, adjustable 25-100m). No CPU cost when away.
- [x] Automatic tracking: detects shard pickup (`OnInventoryItemAdded` + closest-uncollected resolve) and checks them off.
- [x] Stadium vendor shard: detected via the vendor UI hook when purchased.
- [x] Quest-fact gating for quest-related shards (retroactive for those).
- [x] Smart Pause: scanner suppressed during loading screens, fast travel, and menus.
- [x] Survives saves/autosaves and vendor opens (no PlayerInvalidated teardown).
- [x] Set Pin waypoint (standalone manual map waypoint, decoupled from Core).
- [x] Teleport to any uncollected shard (Lazy Mode); Unstuck.
- [x] Per-character save persistence.

## Planned
