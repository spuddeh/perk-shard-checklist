-- ======================================================================================
-- Mod Name: Perk Shard Checklist
-- Author: Spuddeh
-- Description: Main entry point and initialization logic.
-- Mod Version: 3.0.0
-- ======================================================================================

local PerkShardsDB = require("db")
local GameSession = require("Modules/GameSession")
local GameUI      = require("Modules/GameUI")
local ChecklistUI = require("Modules/ChecklistUI")
local SettingsUI = require("Modules/SettingsUI")
local Automation = require("Modules/Automation")
local Inspector = require("Modules/Inspector")
local Utils = require("Modules/Utils")
Utils.LogPrefix = IconGlyphs.BookArrowUp .. " [Perk Shard Checklist] "

-- ### MOD STATE ###

local sessionState = {
  progress = {}
}

-- Global Settings (Default)
local settings = {
  lazy_mode = false,
  log_facts = false,
  dev_mode_enabled = false
}

local isOverlayOpen = false
local isSessionActive = false
-- Runtime State (Non-persistent)
local runtimeState = {
  current_mappin = nil           -- handle of the active manual "Set Pin" waypoint (single slot)
}
local config_file = "config.json"

-- ### CONFIG IO ###

local function SaveConfig()
  local file = io.open(config_file, "w")
  if file then
    file:write(json.encode(settings))
    file:close()
  end
end

local function LoadConfig()
  local file = io.open(config_file, "r")
  if file then
    local content = file:read("*a")
    file:close()
    if content then
      local loaded = json.decode(content)
      for k, v in pairs(loaded) do
        settings[k] = v
      end
    end
  end
  -- Enforce defaults for new settings if missing
  if settings.automation_enabled == nil then settings.automation_enabled = true end
  if not settings.scanner_radius then settings.scanner_radius = 50.0 end
end

-- ### CALLBACKS ###

local uiCallbacks = {
  onToggle = function(id, value)
    if Automation.SetItemStatus then
      Automation.SetItemStatus(id, value)
    else
      sessionState.progress[id] = value
    end
  end,

  onAction = function(action, entry)
    local player = GetPlayer()
    if not player then return end

    local function TeleportTo(coords, name)
      if coords then
        local pos = ToVector4 { x = coords.x, y = coords.y, z = coords.z, w = 1 }
        local rot = ToEulerAngles { roll = 0, pitch = 0, yaw = coords.yaw or 0 }
        Game.GetTeleportationFacility():Teleport(player, pos, rot)
        Utils.Log("Teleported to: " .. name, Utils.LogLevel.Debug)
      end
    end

    -- Standalone manual waypoint, fully owned here. Independent of Core's proximity
    -- automation: behaves exactly like a user-placed map waypoint, just at exact
    -- coords. Single-pin slot, shared by entry-coords and gig-start coords.
    local function SetPin(coords, name)
      if runtimeState.current_mappin then
        Game.GetMappinSystem():UnregisterMappin(runtimeState.current_mappin)
        runtimeState.current_mappin = nil
      end
      if coords then
        local mappinData = MappinData.new()
        mappinData.mappinType = TweakDBID.new('Mappins.DefaultStaticMappin')
        mappinData.variant = gamedataMappinVariant.CustomPositionVariant
        mappinData.visibleThroughWalls = true
        local pin_pos = Vector4.new(coords.x, coords.y, coords.z, 1.0)
        runtimeState.current_mappin = Game.GetMappinSystem():RegisterMappin(mappinData, pin_pos)
        Utils.Log("Map pin set for: " .. name)
      end
    end

    if action == "teleport" then
      TeleportTo(entry.coords, entry.name)
    elseif action == "gig_teleport" then
      TeleportTo(entry.gig_coords, entry.name .. " (Gig Start)")
    elseif action == "mappin" then
      SetPin(entry.coords, entry.name)
    elseif action == "gig_mappin" then
      SetPin(entry.gig_coords, entry.name .. " (Gig Start)")
    end
  end,

  drawSettings = function()
    local settingsCallbacks = {
      onSettingChanged = function()
        Automation.UpdateState()
        SaveConfig()
      end,

      onClearAllPins = function()
        if runtimeState.current_mappin then
          Game.GetMappinSystem():UnregisterMappin(runtimeState.current_mappin)
          runtimeState.current_mappin = nil
          Utils.Log("Last map pin cleared.")
        else
          Utils.Log("No map pin to clear.")
        end
      end,

      drawCustomSettings = function()
        if settings.dev_mode_enabled then
          ImGui.Spacing()
          ImGui.TextDisabled("Dev Tools")

          if ImGui.Button("INSPECT TARGET (LOG FACTS/ID)") then
            Inspector.DumpFacts()
          end
          if ImGui.IsItemHovered() then
            ImGui.SetTooltip(
              "Dumps: Entity ID, Coords, District, Quest Facts, and Container Contents.\nCheck 'perk_shard_checklist.log'.")
          end

          ImGui.Spacing()
          if settings.log_facts == nil then settings.log_facts = false end
          local new_log_facts = ImGui.Checkbox("Log Fact Changes (Spammy!)", settings.log_facts)
          if new_log_facts ~= settings.log_facts then
            settings.log_facts = new_log_facts
            Inspector.ToggleFactListener(new_log_facts)
            SaveConfig()
          end
          if ImGui.IsItemHovered() then
            ImGui.SetTooltip(
              "Prints quest facts to the log as they change.\nUse this to find which fact triggers when you loot something.")
          end

          ImGui.Spacing()
          ImGui.Separator()
          Inspector.DrawMappinUI()
        end
      end
    }

    SettingsUI.Draw(settings, runtimeState, settingsCallbacks)
  end,

  drawCustomActions = function(entry)
  end
}

-- ### EVENTS ###

registerForEvent("onInit", function()
  local Engine = GetMod("0-Engine")
  if not Engine then
    spdlog.error("[PSC] FATAL: 0-Engine not found. Install from Nexus (ID 27967).")
    return
  end
  local Mod = Engine.Register("perk_shard_checklist")

  LoadConfig()
  Utils.SetDebugMode(settings.dev_mode_enabled)

  if settings.dev_mode_enabled then
    Utils.Log("DEV MODE ACTIVE - Inspector Enabled")
    Inspector.Init()
    if settings.log_facts then
      Inspector.ToggleFactListener(true)
    end
  end

  -- 0-Engine: combat and cutscene suppression
  Engine.Subscribe("CombatStateChanged", function(inCombat)
    Automation.SetInCombat(inCombat)
  end)
  Engine.Subscribe("SceneTierChanged", function(tier)
    Automation.SetInCutscene(tier > 1)
  end)

  -- GameUI: handles loading screens and menus with correct timing.
  -- OnLoadingStart fires via LoadingScreenProgressBarController::SetProgress —
  -- immediately when the loading screen initialises, before the bar moves.
  GameUI.OnLoadingStart(function() Automation.SetMenuPaused(true) end)
  GameUI.OnLoadingFinish(function() Automation.SetMenuPaused(false) end)
  GameUI.OnMenuOpen(function() Automation.SetMenuPaused(true) end)
  GameUI.OnMenuClose(function() Automation.SetMenuPaused(false) end)

  -- VENDOR LISTENER: Precise ID from UI Data
  ObserveAfter("FullscreenVendorGameController", "OnSetUserData", function(this)
    if not isSessionActive then return end

    local userData = this.vendorUserData
    if userData and userData.vendorData and userData.vendorData.data then
      local vendorID = userData.vendorData.data.entityID

      Automation.SetVendorOpen(true)

      local vendorEnt = Game.FindEntityByID(vendorID)
      if vendorEnt then
        Utils.Log("Vendor UI Opened. Entity ID: " .. tostring(vendorID))
        if vendorEnt.GetRecordID then
          local recordID = vendorEnt:GetRecordID()
          Utils.Log("Vendor Record ID: " .. tostring(recordID))
        end

        Automation.ScanTarget(vendorID)
      end
    end
  end)

  -- VENDOR CLOSE LISTENER: Flush Queue
  Observe("FullscreenVendorGameController", "OnUninitialize", function()
    if not isSessionActive then return end
    Utils.Log("Vendor UI Closed.")
    Automation.SetVendorOpen(false)
  end)

  -- VENDOR PURCHASE LISTENER: Re-scan immediately on buy
  ObserveAfter("FullscreenVendorGameController", "OnUIVendorItemBoughtEvent", function(this, evt)
    if not isSessionActive then return end
    local userData = this.vendorUserData
    if userData and userData.vendorData and userData.vendorData.data then
      local vendorID = userData.vendorData.data.entityID
      Utils.Log("Item Purchased. Re-scanning Vendor ID: " .. tostring(vendorID))
      Automation.ScanTarget(vendorID)
    end
  end)

  -- PLAYER INVENTORY LISTENER: Detect Looting
  -- Early-exit: skip entirely if not near any uncollected shard (SpatialSet proximity guard)
  Observe("UIInventoryScriptableSystem", "OnInventoryItemAdded", function(_, request)
    if not isSessionActive then return end
    if not Automation.HasNearbyEntries() then return end

    local tdbid = ItemID.GetTDBID(request.itemID)
    if not tdbid then return end

    local idString = tostring(tdbid)

    if string.find(idString, "Skillbook") or string.find(idString, "PerkPoint") then
      if settings.dev_mode_enabled then
        Utils.Log("[Loot] Perk Shard added to inventory. Triggering proximity resolution...", Utils.LogLevel.Debug)
      end

      local resolvedEntry = Automation.ResolveClosestUncollected(100.0)

      if resolvedEntry then
        Automation.SetItemStatus(resolvedEntry.id, true)
        Utils.Notify("Perk Shard Looted: " .. resolvedEntry.name)

        if settings.dev_mode_enabled then
          Utils.Log("[Loot] MATCH FOUND: " .. resolvedEntry.name, Utils.LogLevel.Debug)
        end
      else
        if settings.dev_mode_enabled then
          Utils.Log("[Loot] No container found within 100m.", Utils.LogLevel.Debug)
        end
      end
    end
  end)

  -- GameSession: per-character save persistence (unchanged)
  GameSession.StoreInDir('sessions')
  GameSession.Persist(sessionState)

  GameSession.OnSave(function()
    SaveConfig()
  end)

  -- 0-Engine: session lifecycle
  Mod.WhenReady(function(player)
    Utils.Log("Player Ready. Initializing Automation.")
    isSessionActive = true

    Automation.Init(sessionState, uiCallbacks, settings.dev_mode_enabled, settings)
    Automation.UpdateState()  -- register SpatialSet and zones (suppressed if loading)
    -- SetMenuPaused(false) is NOT called here — GameUI.OnLoadingFinish/OnMenuClose
    -- fires when gameplay actually resumes and handles it, ensuring zones stay
    -- suppressed throughout the entire loading screen.
    if not GameSession.IsPaused() then
      Automation.Scan()  -- retroactive detection only when gameplay is active
    end
  end, nil, 2)

  -- NO PlayerInvalidated teardown — deliberate. 0-Engine's SpatialHash.Reset()/
  -- Proximity.Reset() (called on PlayerInvalidated) only clear active state; they do
  -- NOT unregister our SpatialSet/zones. Calling UnregisterItemSet() here would destroy
  -- registrations that otherwise persist, turning a transient false-invalidation
  -- (0-Engine 1.18.2 fires PlayerInvalidated on saves) into a permanent "broken until
  -- reload". By doing nothing, the registrations survive and 0-Engine auto-resumes
  -- polling them once its Lifecycle recovers. isSessionActive stays gated by
  -- GameSession.OnEnd (true session end only).

  -- GameSession.OnEnd fires only on true session end (return to main menu).
  GameSession.OnEnd(function()
    Utils.Log("Game Session Ended.")
    isSessionActive = false
  end)

  Utils.Log("Loaded (Wait for Player Ready).")
end)

registerForEvent("onOverlayOpen", function()
  isOverlayOpen = true
  if isSessionActive then
    Automation.Scan()
  end
end)

registerForEvent("onOverlayClose", function()
  isOverlayOpen = false
end)

registerForEvent("onDraw", function()
  if isOverlayOpen then
    if isSessionActive then
      ChecklistUI.Draw("Perk Shard Checklist", true, PerkShardsDB, sessionState.progress, settings, uiCallbacks, "manual")
    else
      ChecklistUI.DrawSplashScreen("Perk Shard Checklist")
    end
  end
end)

-- ### CONSOLE COMMANDS ###

local function ToggleDebug()
  settings.dev_mode_enabled = not settings.dev_mode_enabled
  Utils.SetDebugMode(settings.dev_mode_enabled)

  Automation.Init(sessionState, uiCallbacks, settings.dev_mode_enabled, settings)

  if settings.dev_mode_enabled then
    Utils.Log("Debug Mode ENABLED via Console.")
    Inspector.Init()
    if settings.log_facts then
      Inspector.ToggleFactListener(true)
    end
  else
    Utils.Log("Debug Mode DISABLED via Console.")
    Inspector.ToggleFactListener(false)
  end
  SaveConfig()
end

return {
  ToggleDebug = ToggleDebug
}
