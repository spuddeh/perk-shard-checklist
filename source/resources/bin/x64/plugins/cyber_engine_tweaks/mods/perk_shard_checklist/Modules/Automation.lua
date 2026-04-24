-- ======================================================================================
-- Mod Name: Perk Shard Checklist
-- Author: Spuddeh
-- Description: PSC-specific automation logic. Delegates shared behaviour to ChecklistCore.
-- Mod Version: 2.1.0
-- ======================================================================================

local Automation  = {}
local Core        = require("Modules/ChecklistCore")
local PerkShardsDB = require("db")
local Utils       = require("Modules/Utils")

-- ### FORWARDED CORE API ###
-- init.lua calls these; they delegate to ChecklistCore.

Automation.SetInCombat              = Core.SetInCombat
Automation.SetInCutscene            = Core.SetInCutscene
Automation.SetMenuPaused            = Core.SetMenuPaused
Automation.SetItemStatus            = Core.SetItemStatus
Automation.UpdateState              = Core.UpdateState
Automation.RegisterItemSet          = Core.RegisterItemSet
Automation.UnregisterItemSet        = Core.UnregisterItemSet
Automation.RemoveMappin             = Core.RemoveMappin
Automation.SetVendorOpen            = Core.SetVendorOpen
Automation.HasNearbyEntries         = Core.HasNearbyEntries
Automation.ResolveClosestUncollected = Core.ResolveClosestUncollected

-- ### PSC-SPECIFIC: COLLECTED STATE ###

local _sessionState = nil

local function IsCollected(id)
    return _sessionState and _sessionState.progress and _sessionState.progress[id] == true
end

-- ### PSC-SPECIFIC: BUILD ENTRIES ###

local function BuildEntries()
    local entries = {}
    for _, cat in ipairs(PerkShardsDB) do
        for _, entry in ipairs(cat.entries) do
            if not IsCollected(entry.id) and entry.coords then
                table.insert(entries, {
                    x        = entry.coords.x,
                    y        = entry.coords.y,
                    z        = entry.coords.z,
                    id       = entry.id,
                    name     = entry.name,
                    dbEntry  = entry,
                })
            end
        end
    end
    return entries
end

-- ### PSC-SPECIFIC: INVENTORY CHECK ###

local function HasAnyPerkShard(entity, trans)
    if not entity or not trans then return nil end
    local success, _ = trans:GetItemList(entity)
    if success ~= true then return nil end
    if trans:HasItem(entity, ItemID.new(TweakDBID.new("Items.PerkPointSkillbook")))  then return true end
    if trans:HasItem(entity, ItemID.new(TweakDBID.new("Items.IKPerkPointSkillbook"))) then return true end
    return false
end

-- ### PSC-SPECIFIC: QUEST FACT CHECK (retroactive detection) ###

local function CheckQuestFacts()
    local qs = Game.GetQuestsSystem()
    if not qs then return end
    local count = 0
    for _, cat in ipairs(PerkShardsDB) do
        for _, entry in ipairs(cat.entries) do
            if not IsCollected(entry.id) and entry.quest_fact then
                if qs:GetFactStr(entry.quest_fact) > 0 then
                    Utils.Log("Found completed Quest Fact for " .. entry.id)
                    Core.SetItemStatus(entry.id, true)
                    count = count + 1
                end
            end
        end
    end
    if count > 0 then
        Utils.Log("Retroactively unlocked " .. count .. " items via Quest Facts.")
    end
end

-- ### PSC-SPECIFIC: onItemEnter ###
-- Notification only. Detection zone handles entity snap + inventory check.

local _isDebug = false

local function OnItemEnter(spatialEntry, _)
    local entry = spatialEntry.dbEntry
    if not Core.IsNotified(entry.id) then
        Core.QueueOrShow("Perk Shard detected: " .. entry.name)
        Core.SetNotified(entry.id)
    end
    -- Vendors handled exclusively by vendor UI hook
end

-- ### PSC-SPECIFIC: VENDOR SCAN ###

local function ScanTarget(explicitTargetID, notifyOnSuccess)
    local target     = nil
    local targetHash = nil

    if explicitTargetID then
        target     = Game.FindEntityByID(explicitTargetID)
        targetHash = explicitTargetID.hash
        if _isDebug then Utils.Log("Scanning Vendor Target: " .. tostring(targetHash), Utils.LogLevel.Debug) end
    else
        return
    end
    if not targetHash then return end

    local trans = Game.GetTransactionSystem()
    if not trans then return end

    for _, cat in ipairs(PerkShardsDB) do
        for _, entry in ipairs(cat.entries) do
            local isVendor = false
            if entry.vendor_ui_id and tostring(entry.vendor_ui_id) == tostring(targetHash) then
                isVendor = true
            end
            if entry.vendor_record and target and target.GetRecordID then
                local recID = target:GetRecordID()
                if recID and recID == TweakDBID.new(entry.vendor_record) then
                    isVendor = true
                end
            end

            if not IsCollected(entry.id) and (tostring(entry.container_id) == tostring(targetHash) or isVendor) then
                local result = HasAnyPerkShard(target, trans)
                if result == nil then
                    if _isDebug then
                        Utils.Log("Inventory not ready for target: " .. tostring(targetHash), Utils.LogLevel.Debug)
                    end
                elseif result == true then
                    if notifyOnSuccess and not Core.IsNotified(entry.id) then
                        Core.QueueOrShow("Perk Shard Found: " .. entry.name)
                        Core.SetNotified(entry.id)
                    end
                else
                    Core.SetItemStatus(entry.id, true)
                    if notifyOnSuccess then
                        local label = isVendor and "Vendor" or "Container"
                        Core.QueueOrShow("Verified: " .. label ..
                            (isVendor and " transaction complete." or " empty.") .. " " .. entry.name)
                    end
                end
            end
        end
    end
end

function Automation.ScanTarget(targetID)
    ScanTarget(targetID, true)
end

-- ### SCAN (overlay open) ###

function Automation.Scan()
    CheckQuestFacts()
    Core.Scan()
end

-- ### INIT ###

function Automation.Init(sessionState, _, debugMode, settings)
    _sessionState = sessionState
    _isDebug      = debugMode or false

    Core.Init(GetMod("0-Engine"), sessionState, settings, {
        setName          = "psc_items",
        mappinVariant    = gamedataMappinVariant.ServicePointNetTrainerVariant,
        snapRadius       = 20.0,
        buildEntries     = BuildEntries,
        onItemEnter      = OnItemEnter,
        checkInventory   = HasAnyPerkShard,
        isCollected      = IsCollected,
    }, _isDebug)

    local isComplete, count, total = Core.CheckAllCollected()
    if isComplete then
        Utils.Log(string.format("All items collected (%d/%d).", count, total))
    else
        Utils.Log(string.format("Automation Init: %d/%d collected.", count, total))
    end
end

return Automation
