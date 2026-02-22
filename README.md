# Perk Shard Checklist

**Perk Shard Checklist** is a Cyberpunk 2077 mod that helps you track down every Skill Shard and Perk Shard in Night City.

## 🚀 Features

* **Comprehensive Database:** Tracks all 13 perk shards in the base game and DLC.
* **Automation (v2.0):**
  * **Proximity Scanner:** Passively detects nearby shards (50m) and marks them on your HUD.
  * **Predictive Looting:** Instantly detects when you loot a generic shard and resolves the closest container (100m).
  * **Smart Pause:** Suspend logic during menus/loading for zero overhead.
  * **Retroactive Unlock:** Checks "Quest Facts" to mark shards from completed gigs (Experimental).
* **Inspector Mode (Dev):** A built-in debugger to inspect target entities and log Quest Facts.
* **Vendor Tracking:** Monitors vendor inventories.

## 🎮 Usage

1. Open the CET Overlay.
2. The mod runs in the background. Items will appear on your HUD as you approach them.
3. The "Perk Shard Checklist" window allows you to view progress or teleport (Lazy Mode).
4. The "Perk Shard Checklist" window will appear.
5. **Manual Mode:** Click the checkbox next to a shard to mark it as found.
6. **Auto Mode:** Just play! The mod will attempt to mark shards as you loot them.
7. **Navigation:**
    * Click **[Pin]** to set a waypoint.
    * Click **[Tp]** (if Lazy Mode is on) to teleport directly to the shard.

## ⚠️ Notes

* "Gig Start" teleports are available for shards located inside quest-locked areas.

## 💻 Console Commands

You can interact with the mod via the CET Console window:

* **Toggle Debug Mode:**

    ```lua
    GetMod("perk_shard_checklist").ToggleDebug()
    ```

    *Enables the Inspector tool / Fact logging without restarting the game.*
