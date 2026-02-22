-- ======================================================================================
-- Mod Name: Perk Shard Checklist
-- Author: Spuddeh
-- Description: Main entry point and initialization logic.
-- Mod Version: 2.0.2
-- ======================================================================================

local PerkShardsDB = require("db")
local GameSession = require("Modules/GameSession")
local ChecklistUI = require("Modules/ChecklistUI")
local SettingsUI = require("Modules/SettingsUI")
local Automation = require("Modules/Automation")
local Inspector = require("Modules/Inspector")
local Cron = require("Modules/Cron")
local Utils = require("Modules/Utils")

-- ### TOGGLES ###

-- local DEV_MODE = false -- Set to false for Nexus release -> Removed for persistence

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
  current_mappin = nil
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
  if not settings.scanner_interval then settings.scanner_interval = 5.0 end
  if not settings.scanner_radius then settings.scanner_radius = 50.0 end

  -- Sync dev mode toggle to runtime settings -> Removed, handled by JSON load
  -- settings.dev_mode_enabled = DEV_MODE
end

-- ### CALLBACKS ###

local uiCallbacks = {
  onToggle = function(id, value)
    -- Use Automation to handle state changes (triggers stop logic/debug logs)
    if Automation.SetItemStatus then
      Automation.SetItemStatus(id, value)
    else
      -- Fallback if Automation not ready (shouldn't happen)
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
        Utils.Log("Teleported to: " .. name)
      end
    end

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
        local pin_pos = Vector4.new(coords.x, coords.y, coords.z, 0)
        runtimeState.current_mappin = Game.GetMappinSystem():RegisterMappin(mappinData, pin_pos)
        Utils.Log("Map pin set for: " .. name)
      end
    end

    if action == "teleport" then
      Automation.OnTeleport()
      TeleportTo(entry.coords, entry.name)
    elseif action == "gig_teleport" then
      Automation.OnTeleport()
      TeleportTo(entry.gig_coords, entry.name .. " (Gig Start)")
    elseif action == "mappin" then
      SetPin(entry.coords, entry.name)
    elseif action == "gig_mappin" then
      SetPin(entry.gig_coords, entry.name .. " (Gig Start)")
    end
  end,

  -- Settings Callbacks being delegated to SettingsUI
  drawSettings = function()
    -- Define sub-callbacks for the SettingsUI module
    local settingsCallbacks = {
      onSettingChanged = function()
        Automation.UpdateState()
        SaveConfig()
      end,

      drawCustomSettings = function()
        if settings.dev_mode_enabled then
          ImGui.Spacing()
          ImGui.TextDisabled("Dev Tools")

          if ImGui.Button("INSPECT TARGET (LOG FACTS/ID)") then
            -- Directly call Inspector
            Inspector.DumpFacts()
          end
          if ImGui.IsItemHovered() then
            ImGui.SetTooltip(
              "Dumps: Entity ID, Coords, District, Quest Facts, and Container Contents.\nCheck 'perk_shard_checklist.log'.")
          end

          ImGui.Spacing()
          -- Fact Listener Toggle
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
  LoadConfig()

  if settings.dev_mode_enabled then
    Utils.Log("DEV MODE ACTIVE - Inspector Enabled")
    Inspector.Init()
    -- Sync Fact Listener state from saved settings
    if settings.log_facts then
      Inspector.ToggleFactListener(true)
    end
  end



  -- VENDOR LISTENER: Precise ID from UI Data
  ObserveAfter("FullscreenVendorGameController", "OnSetUserData", function(this)
    if not isSessionActive then return end

    -- The 'userData' is stored in the controller after SetUserData runs
    local userData = this.vendorUserData
    if userData and userData.vendorData and userData.vendorData.data then
      local vendorID = userData.vendorData.data.entityID

      -- Notify Automation that Vendor UI is open (queues messages)
      Automation.SetVendorOpen(true)

      local vendorEnt = Game.FindEntityByID(vendorID)
      if vendorEnt then
        Utils.Log("Vendor UI Opened. Entity ID: " .. tostring(vendorID))
        if vendorEnt.GetRecordID then
          local recordID = vendorEnt:GetRecordID()
          Utils.Log("Vendor Record ID: " .. tostring(recordID))
        end

        -- Pass the Entity object or ID? logic usually takes ID, but we might need to handle record checks now.
        -- For now, we still pass ID, but we need to update Automation to check Records.
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
    -- evt is UIVendorItemsBoughtEvent
    local userData = this.vendorUserData
    if userData and userData.vendorData and userData.vendorData.data then
      local vendorID = userData.vendorData.data.entityID
      Utils.Log("Item Purchased. Re-scanning Vendor ID: " .. tostring(vendorID))
      Automation.ScanTarget(vendorID)
    end
  end)

  -- LOOT TRACKING STATE
  -- Controlled by Automation scanner (LookAt) -> Removed as we use PlayerPuppet hook now

  -- PLAYER INVENTORY LISTENER: Detect Looting
  -- Switched to UIInventoryScriptableSystem for reliability (like CSC)
  Observe("UIInventoryScriptableSystem", "OnInventoryItemAdded", function(_, request)
    if not isSessionActive then return end

    local itemID = request.itemID
    local tdbid = ItemID.GetTDBID(itemID)

    if not tdbid then return end

    local idString = tostring(tdbid)

    if string.find(idString, "Skillbook") or string.find(idString, "PerkPoint") then
      -- Log generic receipt (cannot identify specific container from ItemID alone)
      if settings.dev_mode_enabled then
        Utils.Log("[Loot] Perk Shard added to inventory. Triggering proximity resolution...", Utils.LogLevel.Debug)
      end

      -- PREDICTIVE RESOLUTION: Check for closest uncollected container (100m radius)
      local resolvedEntry = Automation.ResolveClosestUncollected(100.0)

      if resolvedEntry then
        -- Match Found! Mark collected immediately
        sessionState.progress[resolvedEntry.id] = true
        Utils.Notify("Perk Shard Looted: " .. resolvedEntry.name)

        if settings.dev_mode_enabled then
          Utils.Log("[Loot] MATCH FOUND: " .. resolvedEntry.name, Utils.LogLevel.Debug)
        end

        -- Cleanup Mappin if exists
        Automation.RemoveMappin(resolvedEntry.id)
      else
        -- No match in range. Fallback to full scan.
        if settings.dev_mode_enabled then
          Utils.Log("[Loot] No container found within 100m. Falling back to full scan.", Utils.LogLevel.Debug)
        end
        Automation.ProximityScan()
      end
    end
  end)

  -- GameSession Setup (CET Kit Style)
  GameSession.StoreInDir('sessions')
  GameSession.Persist(sessionState)

  -- GameSession Triggers
  GameSession.OnStart(function()
    Utils.Log("Game Session Started. Initializing Automation.")
    isSessionActive = true

    -- Initialize Automation (Inject Dependencies)
    Automation.Init(sessionState, uiCallbacks, settings.dev_mode_enabled, settings)

    -- Initial Scan & Start Loop
    Automation.UpdateState()
  end)

  GameSession.OnEnd(function()
    Utils.Log("Game Session Ended. Cleanup.")
    isSessionActive = false
    activeContainerID = nil

    Automation.StopScanner()
  end)

  GameSession.OnSave(function()
    SaveConfig()
  end)

  Utils.Log("Loaded (Wait for Session Start).")
end)

registerForEvent("onUpdate", function(deltaTime)
  Cron.Update(deltaTime)
end)

registerForEvent("onOverlayOpen", function()
  isOverlayOpen = true
  if isSessionActive then
    Automation.Scan() -- Force scan when user checks the list
  end
end)

registerForEvent("onOverlayClose", function()
  isOverlayOpen = false
end)

registerForEvent("onDraw", function()
  if isOverlayOpen then
    if isSessionActive then
      -- Pass all context explicitly to Draw (Stateless Pattern)
      ChecklistUI.Draw("Perk Shard Checklist", true, PerkShardsDB, sessionState.progress, settings, uiCallbacks, "manual")
    else
      ChecklistUI.DrawSplashScreen("Perk Shard Checklist")
    end
  end
end)

-- ### CONSOLE COMMANDS ###

--- Toggles Debug Mode via Console
-- Usage: GetMod("perk_shard_checklist").ToggleDebug()
local function ToggleDebug()
  settings.dev_mode_enabled = not settings.dev_mode_enabled
  -- DEV_MODE = settings.dev_mode_enabled -- Sync local -> Removed

  -- RE-INIT Automation to update debug state
  Automation.Init(sessionState, uiCallbacks, settings.dev_mode_enabled, settings)

  if settings.dev_mode_enabled then
    Utils.Log("Debug Mode ENABLED via Console.")
    Inspector.Init() -- Ensure inspector is ready
    -- Sync facts listener if setting is on
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
