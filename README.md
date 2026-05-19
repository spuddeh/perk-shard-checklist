# Perk Shard Checklist

**Perk Shard Checklist** is a Cyberpunk 2077 mod that helps you track down every Perk Shard in the base game and Phantom Liberty.

📥 **Download:** [Perk Shard Checklist on Nexus Mods](https://www.nexusmods.com/cyberpunk2077/mods/25594)

## 🚀 Features

* **Comprehensive Database:** Tracks all 13 Perk Shards (base game and Phantom Liberty).
* **Reactive Proximity Scanner (v3.0.0):** Built on 0-Engine. Reacts the moment you cross into range of an uncollected shard and marks it on your HUD. No polling timer, so no CPU cost when you are away.
* **Automatic Tracking:** Detects when you loot a shard and resolves the closest uncollected entry to check it off.
* **Vendor Shard:** The Stadium vendor shard is detected through the vendor UI when you purchase it.
* **Quest-Fact Gating:** Quest-locked shards are not flagged before they are accessible, and are checked off retroactively once their quest fact is set.
* **Smart Pause:** Suppressed during loading screens, fast travel, and menus.
* **Set Pin & Lazy Mode:** Standalone waypoint button; optional Lazy Mode adds Teleport and Unstuck.
* **Inspector Mode (Dev):** A built-in debugger to inspect target entities and log Quest Facts.
* **Per-Character Persistence:** Progress is tied to each save file.

## 📋 Requirements

* [Cyber Engine Tweaks](https://www.nexusmods.com/cyberpunk2077/mods/107).
* [0-Engine](https://www.nexusmods.com/cyberpunk2077/mods/27967) (pure CET-only build). New required dependency as of 3.0.0; it has its own requirements listed on its mod page.
* **Phantom Liberty** for the Phantom Liberty shards.

## 🎮 Usage

1. Open the CET overlay.
2. The mod runs in the background. Shards appear on your HUD as you approach them.
3. Open the **Perk Shard Checklist** window to view progress.
4. **Manual Mode:** Click the checkbox next to a shard to mark it found.
5. **Auto Mode:** Just play. Shards are checked off as you loot them.
6. **Navigation:** Click **Set Pin** for a waypoint, or **Teleport** (if Lazy Mode is on).
7. Adjust the detection range in Settings (default 50m, adjustable 25m to 100m).

## ⚠️ Notes

* "Gig Start" teleports are available for shards located inside quest-locked areas.

## 💻 Console Commands

* **Toggle Debug Mode** (enables the Inspector / Fact logging without a game restart):

    ```lua
    GetMod("perk_shard_checklist").ToggleDebug()
    ```

## 🤖 Disclaimer

This mod was developed with the assistance of an LLM. All in-game testing and code validation was performed by a human. No rogue AIs were permitted through the Blackwall.
