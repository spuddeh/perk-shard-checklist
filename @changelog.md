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
