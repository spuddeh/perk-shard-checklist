-- ======================================================================================
-- Mod Name: Perk Shard Checklist
-- Author: Spuddeh
-- Description: "All-in-One" Research Tool. Dumps Coords, Facts, Items.
-- Mod Version: 2.0.2
-- =============================================================================================================

local Inspector = {}

local Utils = require("Modules/Utils")

-- State flag for listener
local isListeningToFacts = false

function Inspector.Init()
    Utils.Log("[Inspector] Initialized. Ready to scan.", Utils.LogLevel.Debug)

    -- Register Observer ONCE
    -- This prevents the "multiple logs per event" bug if toggled repeatedly.
    Observe("QuestsSystem", "SetFactStr", function(self, factName, value)
        if isListeningToFacts then
            Utils.Log(string.format("[Fact Changed] %s: %s", factName, tostring(value)), Utils.LogLevel.Debug)
        end
    end)
end

-- ### FACT LISTENER ###

--- Toggle the Real-Time Fact Listener
-- @param enable (boolean)
function Inspector.ToggleFactListener(enable)
    if enable == isListeningToFacts then return end
    isListeningToFacts = enable

    if enable then
        Utils.Log("[Inspector] Started listening for Quest Fact changes...", Utils.LogLevel.Debug)
    else
        Utils.Log("[Inspector] Stopped listening for Quest Fact changes.", Utils.LogLevel.Debug)
    end
end

-- ### LOCATION HELPERS (From SimpleLocationManager) ###

--- Gets the district data at the given position
---@return table { district="Name", subDistrict="Name" }
local function GetLocationData()
    local data = { district = "Unknown", subDistrict = "Unknown" }

    -- 1. Main District Recursive Logic
    pcall(function()
        local sys = Game.GetScriptableSystemsContainer():Get("PreventionSystem")
        if sys and sys.districtManager then
            local districtObj = sys.districtManager:GetCurrentDistrict()
            local currentRecord = nil

            if districtObj and districtObj.GetDistrictID then
                -- Lint fix logic: wrap in pcall if type mismatch suspected
                pcall(function()
                    currentRecord = TweakDBInterface.GetDistrictRecord(districtObj:GetDistrictID())
                end)
            end

            if currentRecord then
                local ancestry = {}
                local ptr = currentRecord
                while ptr do
                    table.insert(ancestry, ptr)
                    local parent = ptr:ParentDistrict()
                    if not parent or parent:EnumName() == "NightCity" then
                        break
                    end
                    ptr = parent
                end

                if #ancestry > 0 then
                    local root = ancestry[#ancestry]
                    if root then
                        data.district = root:LocalizedName()
                    end

                    if #ancestry >= 2 then
                        local sub = ancestry[#ancestry - 1]
                        if sub then
                            data.subDistrict = sub:LocalizedName()
                        end
                    else
                        if ancestry[1] then
                            data.subDistrict = ancestry[1]:LocalizedName()
                        end
                    end
                end
            end
        end
    end)


    -- 2. Sub-District Refinement (Blackboard)
    pcall(function()
        local blackboardDefs = GetAllBlackboardDefs()
        if blackboardDefs and blackboardDefs.UI_Map then
            local system = Game.GetBlackboardSystem()
            if system then
                local uiBlackboard = system:Get(blackboardDefs.UI_Map)
                if uiBlackboard then
                    local locStr = uiBlackboard:GetString(blackboardDefs.UI_Map.currentLocation)
                    if locStr and locStr ~= "" then
                        local localized = GetLocalizedText(locStr)
                        local bbText = (localized and localized ~= "") and localized or locStr

                        if bbText ~= "" and bbText ~= "Unknown" then
                            if data.subDistrict == "Unknown" or data.subDistrict == nil then
                                data.subDistrict = bbText
                            end
                        end
                    end
                end
            end
        end
    end)

    if data.district and string.find(data.district, "LocKey#") then
        local loc = GetLocalizedText(data.district)
        if loc and loc ~= "" then data.district = loc end
    end
    if data.subDistrict and string.find(data.subDistrict, "LocKey#") then
        local loc = GetLocalizedText(data.subDistrict)
        if loc and loc ~= "" then data.subDistrict = loc end
    end

    if data.district == "Dogtown" or data.subDistrict == "Dogtown" then
        if data.subDistrict == "Dogtown" and data.district == "Pacificia" then
            data.district = "Dogtown"
            data.subDistrict = nil
        elseif data.district == "Dogtown" then
            data.subDistrict = nil
        end
    end

    if data.subDistrict == data.district then
        data.subDistrict = nil
    end

    if (data.district == "Unknown" or data.district == "") and data.subDistrict ~= "Unknown" then
        data.district = data.subDistrict
        data.subDistrict = nil
    end

    return data
end

-- Helper: Get Player Position & District
local function GetPlayerInfo()
    local player = Game.GetPlayer()
    if not player then return "Player not found", "Unknown", "Unknown" end

    local pos = player:GetWorldPosition()
    local coordsStr = string.format("x=%.2f, y=%.2f, z=%.2f, yaw=%.2f", pos.x, pos.y, pos.z, 0)

    local locData = GetLocationData()

    return coordsStr, locData.district, locData.subDistrict
end

function Inspector.DumpFacts()
    Utils.Log("================ INSPECTION REPORT ================", Utils.LogLevel.Debug)

    -- 1. Player Info
    local coords, dist, sub = GetPlayerInfo()
    Utils.Log(string.format("LOCATION: %s", coords), Utils.LogLevel.Debug)
    Utils.Log(string.format("DISTRICT: %s / %s", dist, (sub or "-")), Utils.LogLevel.Debug)

    local targeting = Game.GetTargetingSystem()
    local player = Game.GetPlayer()
    local trans = Game.GetTransactionSystem()

    if targeting and player and trans then
        local lookedAtObject = targeting:GetLookAtObject(player)

        if lookedAtObject then
            Utils.Log("--- TARGET OBJECT ---", Utils.LogLevel.Debug)

            -- Entity ID (Container ID)
            local entityID = lookedAtObject:GetEntityID()
            Utils.Log("ENTITY ID (Hash): " .. tostring(entityID.hash), Utils.LogLevel.Debug)

            -- Object Name (TweakDB)
            pcall(function()
                local recordID = lookedAtObject:GetRecordID()
                if recordID then
                    Utils.Log("RECORD ID: " .. tostring(recordID), Utils.LogLevel.Debug)
                end
            end)

            -- Inventory Scan (Red Hot Tools Logic)
            Utils.Log("--- CONTENTS ---", Utils.LogLevel.Debug)
            local pcallSuccess, gameSuccess, itemList = pcall(function()
                return trans:GetItemList(lookedAtObject)
            end)

            local finalItems = nil
            if pcallSuccess then
                if type(itemList) == "table" then
                    finalItems = itemList
                elseif type(gameSuccess) == "table" then
                    finalItems = gameSuccess
                end
            end

            if finalItems then
                if #finalItems == 0 then
                    Utils.Log("(Empty)", Utils.LogLevel.Debug)
                else
                    for i, itemData in ipairs(finalItems) do
                        local decodedID = "Unknown"
                        local function TryDecode(item)
                            return item:GetID().id.value
                        end
                        pcall(function()
                            local raw = TryDecode(itemData)
                            if raw then decodedID = tostring(raw) end
                        end)
                        if decodedID == "Unknown" then
                            pcall(function() decodedID = tostring(ItemID.GetTDBID(itemData:GetID())) end)
                        end
                        Utils.Log(string.format("[%d] %s", i, decodedID), Utils.LogLevel.Debug)
                    end
                end
            else
                Utils.Log("Failed to retrieve inventory list.", Utils.LogLevel.Debug)
            end
        else
            Utils.Log("No object in crosshairs.", Utils.LogLevel.Debug)
        end
    else
        Utils.Log("Systems missing (Targeting/Player/Transaction).", Utils.LogLevel.Debug)
    end

    Utils.Log("================ END REPORT ================", Utils.LogLevel.Debug)
end

-- ### MAPPIN DEBUGGER ###
local mappinVariants = {
    { name = "ActionDealDamage",              value = "gamedataMappinVariant.ActionDealDamageVariant" },
    { name = "ActionFastSolo",                value = "gamedataMappinVariant.ActionFastSoloVariant" },
    { name = "ActionGenericInteraction",      value = "gamedataMappinVariant.ActionGenericInteractionVariant" },
    { name = "ActionNetrunner",               value = "gamedataMappinVariant.ActionNetrunnerVariant" },
    { name = "ActionNetrunnerAccessPoint",    value = "gamedataMappinVariant.ActionNetrunnerAccessPointVariant" },
    { name = "ActionNetrunner",               value = "gamedataMappinVariant.ActionNetrunnerVariant" },
    { name = "ActionScan",                    value = "gamedataMappinVariant.ActionScanVariant" },
    { name = "ActionSolo",                    value = "gamedataMappinVariant.ActionSoloVariant" },
    { name = "ActionTechie",                  value = "gamedataMappinVariant.ActionTechieVariant" },
    { name = "Aim",                           value = "gamedataMappinVariant.AimVariant" },
    { name = "Allow",                         value = "gamedataMappinVariant.AllowVariant" },
    { name = "Apartment",                     value = "gamedataMappinVariant.ApartmentVariant" },
    { name = "Arrow",                         value = "gamedataMappinVariant.ArrowVariant" },
    { name = "BackOut",                       value = "gamedataMappinVariant.BackOutVariant" },
    { name = "BountyHunt",                    value = "gamedataMappinVariant.BountyHuntVariant" },
    { name = "Call",                          value = "gamedataMappinVariant.CallVariant" },
    { name = "ChangeToFriendly",              value = "gamedataMappinVariant.ChangeToFriendlyVariant" },
    { name = "ClientInDistress",              value = "gamedataMappinVariant.ClientInDistressVariant" },
    { name = "Conversation",                  value = "gamedataMappinVariant.ConversationVariant" },
    { name = "Convoy",                        value = "gamedataMappinVariant.ConvoyVariant" },
    { name = "Cool",                          value = "gamedataMappinVariant.CoolVariant" },
    { name = "Courier",                       value = "gamedataMappinVariant.CourierVariant" },
    { name = "CustomPosition",                value = "gamedataMappinVariant.CustomPositionVariant" },
    { name = "CyberspaceNPC",                 value = "gamedataMappinVariant.CyberspaceNPC" },
    { name = "CyberspaceObject",              value = "gamedataMappinVariant.CyberspaceObject" },
    { name = "DefaultInteraction",            value = "gamedataMappinVariant.DefaultInteractionVariant" },
    { name = "DefaultQuest",                  value = "gamedataMappinVariant.DefaultQuestVariant" },
    { name = "Default",                       value = "gamedataMappinVariant.DefaultVariant" },
    { name = "Distract",                      value = "gamedataMappinVariant.DistractVariant" },
    { name = "Dropbox",                       value = "gamedataMappinVariant.DropboxVariant" },
    { name = "DynamicEvent",                  value = "gamedataMappinVariant.DynamicEventVariant" },
    { name = "EffectAlarm",                   value = "gamedataMappinVariant.EffectAlarmVariant" },
    { name = "EffectControlNetwork",          value = "gamedataMappinVariant.EffectControlNetworkVariant" },
    { name = "EffectControlOtherDevice",      value = "gamedataMappinVariant.EffectControlOtherDeviceVariant" },
    { name = "EffectControlSelf",             value = "gamedataMappinVariant.EffectControlSelfVariant" },
    { name = "EffectCutPower",                value = "gamedataMappinVariant.EffectCutPowerVariant" },
    { name = "EffectDistract",                value = "gamedataMappinVariant.EffectDistractVariant" },
    { name = "EffectDropPoint",               value = "gamedataMappinVariant.EffectDropPointVariant" },
    { name = "EffectExplodeLethal",           value = "gamedataMappinVariant.EffectExplodeLethalVariant" },
    { name = "EffectExplodeNonLethal",        value = "gamedataMappinVariant.EffectExplodeNonLethalVariant" },
    { name = "EffectFall",                    value = "gamedataMappinVariant.EffectFallVariant" },
    { name = "EffectGrantInformation",        value = "gamedataMappinVariant.EffectGrantInformationVariant" },
    { name = "EffectHideBody",                value = "gamedataMappinVariant.EffectHideBodyVariant" },
    { name = "EffectLoot",                    value = "gamedataMappinVariant.EffectLootVariant" },
    { name = "EffectOpenPath",                value = "gamedataMappinVariant.EffectOpenPathVariant" },
    { name = "EffectPush",                    value = "gamedataMappinVariant.EffectPushVariant" },
    { name = "EffectServicePoint",            value = "gamedataMappinVariant.EffectServicePointVariant" },
    { name = "EffectShoot",                   value = "gamedataMappinVariant.EffectShootVariant" },
    { name = "EffectSpreadGas",               value = "gamedataMappinVariant.EffectSpreadGasVariant" },
    { name = "EffectStoreItems",              value = "gamedataMappinVariant.EffectStoreItemsVariant" },
    { name = "ExclamationMark",               value = "gamedataMappinVariant.ExclamationMarkVariant" },
    { name = "FailedCrossing",                value = "gamedataMappinVariant.FailedCrossingVariant" },
    { name = "FastTravel",                    value = "gamedataMappinVariant.FastTravelVariant" },
    { name = "Fixer",                         value = "gamedataMappinVariant.FixerVariant" },
    { name = "FocusClue",                     value = "gamedataMappinVariant.FocusClueVariant" },
    { name = "GangWatch",                     value = "gamedataMappinVariant.GangWatchVariant" },
    { name = "GenericRole",                   value = "gamedataMappinVariant.GenericRoleVariant" },
    { name = "GetIn",                         value = "gamedataMappinVariant.GetInVariant" },
    { name = "GetUp",                         value = "gamedataMappinVariant.GetUpVariant" },
    { name = "GPSForcedPath",                 value = "gamedataMappinVariant.GPSForcedPathVariant" },
    { name = "GPSPortal",                     value = "gamedataMappinVariant.GPSPortalVariant" },
    { name = "Grenade",                       value = "gamedataMappinVariant.GrenadeVariant" },
    { name = "GunSuicide",                    value = "gamedataMappinVariant.GunSuicideVariant" },
    { name = "Hand",                          value = "gamedataMappinVariant.HandVariant" },
    { name = "HazardWarning",                 value = "gamedataMappinVariant.HazardWarningVariant" },
    { name = "HiddenStash",                   value = "gamedataMappinVariant.HiddenStashVariant" },
    { name = "Hit",                           value = "gamedataMappinVariant.HitVariant" },
    { name = "HuntForPsycho",                 value = "gamedataMappinVariant.HuntForPsychoVariant" },
    { name = "ImportantInteraction",          value = "gamedataMappinVariant.ImportantInteractionVariant" },
    { name = "Invalid",                       value = "gamedataMappinVariant.InvalidVariant" },
    { name = "JackIn",                        value = "gamedataMappinVariant.JackInVariant" },
    { name = "JamWeapon",                     value = "gamedataMappinVariant.JamWeaponVariant" },
    { name = "LifepathCorpo",                 value = "gamedataMappinVariant.LifepathCorpoVariant" },
    { name = "LifepathNomad",                 value = "gamedataMappinVariant.LifepathNomadVariant" },
    { name = "LifepathStreetKid",             value = "gamedataMappinVariant.LifepathStreetKidVariant" },
    { name = "Loot",                          value = "gamedataMappinVariant.LootVariant" },
    { name = "MinorActivity",                 value = "gamedataMappinVariant.MinorActivityVariant" },
    { name = "NPC",                           value = "gamedataMappinVariant.NPCVariant" },
    { name = "NetrunnerAccessPoint",          value = "gamedataMappinVariant.NetrunnerAccessPointVariant" },
    { name = "NetrunnerSoloTechie",           value = "gamedataMappinVariant.NetrunnerSoloTechieVariant" },
    { name = "NetrunnerSolo",                 value = "gamedataMappinVariant.NetrunnerSoloVariant" },
    { name = "NetrunnerTechie",               value = "gamedataMappinVariant.NetrunnerTechieVariant" },
    { name = "Netrunner",                     value = "gamedataMappinVariant.NetrunnerVariant" },
    { name = "NonLethalTakedown",             value = "gamedataMappinVariant.NonLethalTakedownVariant" },
    { name = "Off",                           value = "gamedataMappinVariant.OffVariant" },
    { name = "OpenVendor",                    value = "gamedataMappinVariant.OpenVendorVariant" },
    { name = "Outpost",                       value = "gamedataMappinVariant.OutpostVariant" },
    { name = "PhoneCall",                     value = "gamedataMappinVariant.PhoneCallVariant" },
    { name = "QuestGiver",                    value = "gamedataMappinVariant.QuestGiverVariant" },
    { name = "QuestionMark",                  value = "gamedataMappinVariant.QuestionMarkVariant" },
    { name = "QuickHack",                     value = "gamedataMappinVariant.QuickHackVariant" },
    { name = "Reflexes",                      value = "gamedataMappinVariant.ReflexesVariant" },
    { name = "Resource",                      value = "gamedataMappinVariant.ResourceVariant" },
    { name = "Retrieving",                    value = "gamedataMappinVariant.RetrievingVariant" },
    { name = "SOSsignal",                     value = "gamedataMappinVariant.SOSsignalVariant" },
    { name = "Sabotage",                      value = "gamedataMappinVariant.SabotageVariant" },
    { name = "ServicePointBar",               value = "gamedataMappinVariant.ServicePointBarVariant" },
    { name = "ServicePointClothes",           value = "gamedataMappinVariant.ServicePointClothesVariant" },
    { name = "ServicePointCyberware",         value = "gamedataMappinVariant.ServicePointCyberwareVariant" },
    { name = "ServicePointDropPoint",         value = "gamedataMappinVariant.ServicePointDropPointVariant" },
    { name = "ServicePointFood",              value = "gamedataMappinVariant.ServicePointFoodVariant" },
    { name = "ServicePointGuns",              value = "gamedataMappinVariant.ServicePointGunsVariant" },
    { name = "ServicePointJunk",              value = "gamedataMappinVariant.ServicePointJunkVariant" },
    { name = "ServicePointMeds",              value = "gamedataMappinVariant.ServicePointMedsVariant" },
    { name = "ServicePointMeleeTrainer",      value = "gamedataMappinVariant.ServicePointMeleeTrainerVariant" },
    { name = "ServicePointNetTrainer",        value = "gamedataMappinVariant.ServicePointNetTrainerVariant" },
    { name = "ServicePointProstitute",        value = "gamedataMappinVariant.ServicePointProstituteVariant" },
    { name = "ServicePointRipperdoc",         value = "gamedataMappinVariant.ServicePointRipperdocVariant" },
    { name = "ServicePointTech",              value = "gamedataMappinVariant.ServicePointTechVariant" },
    { name = "Sit",                           value = "gamedataMappinVariant.SitVariant" },
    { name = "SmugglersDen",                  value = "gamedataMappinVariant.SmugglersDenVariant" },
    { name = "SoloTechie",                    value = "gamedataMappinVariant.SoloTechieVariant" },
    { name = "Solo",                          value = "gamedataMappinVariant.SoloVariant" },
    { name = "Speech",                        value = "gamedataMappinVariant.SpeechVariant" },
    { name = "TakeControl",                   value = "gamedataMappinVariant.TakeControlVariant" },
    { name = "TakeDown",                      value = "gamedataMappinVariant.TakeDownVariant" },
    { name = "Tarot",                         value = "gamedataMappinVariant.TarotVariant" },
    { name = "Techie",                        value = "gamedataMappinVariant.TechieVariant" },
    { name = "Thievery",                      value = "gamedataMappinVariant.ThieveryVariant" },
    { name = "Use",                           value = "gamedataMappinVariant.UseVariant" },
    { name = "Vehicle",                       value = "gamedataMappinVariant.VehicleVariant" },
    { name = "WanderingMerchant",             value = "gamedataMappinVariant.WanderingMerchantVariant" },
    { name = "Zzz01_CarForPurchase",          value = "gamedataMappinVariant.Zzz01_CarForPurchaseVariant" },
    { name = "Zzz02_MotorcycleForPurchase",   value = "gamedataMappinVariant.Zzz02_MotorcycleForPurchaseVariant" },
    { name = "Zzz03_Motorcycle",              value = "gamedataMappinVariant.Zzz03_MotorcycleVariant" },
    { name = "Zzz04_PreventionVehicle",       value = "gamedataMappinVariant.Zzz04_PreventionVehicleVariant" },
    { name = "Zzz05_ApartmentToPurchase",     value = "gamedataMappinVariant.Zzz05_ApartmentToPurchaseVariant" },
    { name = "Zzz06_NCPDGig",                 value = "gamedataMappinVariant.Zzz06_NCPDGigVariant" },
    { name = "Zzz07_PlayerStash",             value = "gamedataMappinVariant.Zzz07_PlayerStashVariant" },
    { name = "Zzz08_Wardrobe",                value = "gamedataMappinVariant.Zzz08_WardrobeVariant" },
    { name = "Zzz09_CourierSandboxActivity",  value = "gamedataMappinVariant.Zzz09_CourierSandboxActivityVariant" },
    { name = "Zzz10_RemoteControlDriving",    value = "gamedataMappinVariant.Zzz10_RemoteControlDrivingVariant" },
    { name = "Zzz11_RoadBlockade",            value = "gamedataMappinVariant.Zzz11_RoadBlockadeVariant" },
    { name = "Zzz12_QuickHackQueue",          value = "gamedataMappinVariant.Zzz12_QuickHackQueueVariant" },
    { name = "Zzz12_WorldEncounter",          value = "gamedataMappinVariant.Zzz12_WorldEncounterVariant" },
    { name = "Zzz13_DogtownGate",             value = "gamedataMappinVariant.Zzz13_DogtownGateVariant" },
    { name = "Zzz14_ServicePointBlackMarket", value = "gamedataMappinVariant.Zzz14_ServicePointBlackMarketVariant" },
    { name = "Zzz15_QuickHackDuration",       value = "gamedataMappinVariant.Zzz15_QuickHackDurationVariant" },
    { name = "Zzz16_RelicDeviceBasic",        value = "gamedataMappinVariant.Zzz16_RelicDeviceBasicVariant" },
    { name = "Zzz16_RelicDeviceSpecial",      value = "gamedataMappinVariant.Zzz16_RelicDeviceSpecialVariant" },
    { name = "Zzz17_NCART",                   value = "gamedataMappinVariant.Zzz17_NCARTVariant" },
    { name = "Zzz18_Racing",                  value = "gamedataMappinVariant.Zzz18_RacingVariant" },
    { name = "Zzz19_DelamainTaxi",            value = "gamedataMappinVariant.Zzz19_DelamainTaxiVariant" },
    { name = "Zzz20_DelamainTaxiDestination", value = "gamedataMappinVariant.Zzz20_DelamainTaxiDestinationVariant" }
}
local selectedMappinIdx = 1
local testMappinID = nil

local function SpawnTestMappin()
    local variantStr = mappinVariants[selectedMappinIdx].value

    -- Resolve Enum Value
    local variantEnum = nil
    local success, res = pcall(loadstring("return " .. variantStr))
    if success then variantEnum = res end

    if variantEnum then
        -- Remove old one first
        if testMappinID then
            Game.GetMappinSystem():UnregisterMappin(testMappinID)
            testMappinID = nil
        end

        local player = Game.GetPlayer()
        if player then
            -- Determine Position: LookAt Object -> Front of Player -> Player Pos
            local pos = nil
            local locationInfo = "Unknown"

            local targeting = Game.GetTargetingSystem()
            local target = targeting:GetLookAtObject(player, false, false)

            if target then
                pos = target:GetWorldPosition()
                locationInfo = "LookAt Target"
            else
                -- Fallback: 2 meters in front of player (approx)
                local pPos = player:GetWorldPosition()
                local pFwd = player:GetWorldForward()
                pos = Vector4.new(pPos.x + (pFwd.x * 2.0), pPos.y + (pFwd.y * 2.0), pPos.z + (pFwd.z * 2.0), 1.0)
                locationInfo = "Player Front (2m)"
            end

            local data = MappinData.new()
            data.mappinType = TweakDBID.new('Mappins.DefaultStaticMappin')
            data.variant = variantEnum
            data.visibleThroughWalls = true
            testMappinID = Game.GetMappinSystem():RegisterMappin(data, pos)
            Utils.Log("Spawned Test Mappin (" .. locationInfo .. "): " .. variantStr .. " ID: " .. tostring(testMappinID))
        end
    else
        Utils.Log("Failed to resolve Enum: " .. variantStr)
    end
end

function Inspector.DrawMappinUI()
    if ImGui.CollapsingHeader("Mappin Debugger (Dev)") then
        ImGui.Text("Select a variant to test:")

        -- Navigation Buttons
        if ImGui.Button("<< Prev") then
            selectedMappinIdx = selectedMappinIdx - 1
            if selectedMappinIdx < 1 then selectedMappinIdx = #mappinVariants end
            if testMappinID then SpawnTestMappin() end
        end

        ImGui.SameLine()
        if ImGui.Button("Next >>") then
            selectedMappinIdx = selectedMappinIdx + 1
            if selectedMappinIdx > #mappinVariants then selectedMappinIdx = 1 end
            if testMappinID then SpawnTestMappin() end
        end

        ImGui.SameLine()
        ImGui.Text(string.format("(%d / %d)", selectedMappinIdx, #mappinVariants))

        ImGui.SameLine()
        if ImGui.Button("Copy Value") then
            ImGui.SetClipboardText(mappinVariants[selectedMappinIdx].value)
            Utils.Log("Copied to clipboard: " .. mappinVariants[selectedMappinIdx].value)
        end

        -- Simplified Combo for CET/ImGui
        local nameStr = ""
        if mappinVariants[selectedMappinIdx] then
            nameStr = mappinVariants[selectedMappinIdx].name
        end

        if ImGui.BeginCombo("Variant", nameStr) then
            for i, v in ipairs(mappinVariants) do
                local isSelected = (i == selectedMappinIdx)
                if ImGui.Selectable(v.name, isSelected) then
                    selectedMappinIdx = i
                    -- Auto-update if active
                    if testMappinID then
                        SpawnTestMappin()
                    end
                end
                if isSelected then
                    ImGui.SetItemDefaultFocus()
                end
            end
            ImGui.EndCombo()
        end

        ImGui.Spacing()

        if ImGui.Button("Spawn Test Mappin (At LookAt)") then
            SpawnTestMappin()
        end

        ImGui.SameLine()

        if ImGui.Button("Clear Test Mappin") then
            if testMappinID then
                Game.GetMappinSystem():UnregisterMappin(testMappinID)
                testMappinID = nil
                Utils.Log("Cleared Test Mappin.")
            else
                Utils.Log("No test mappin active.")
            end
        end
    end
end

return Inspector
