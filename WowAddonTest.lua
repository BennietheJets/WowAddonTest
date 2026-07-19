local addonName, addonTable = ...

-- Function to determine the player's role category
local function GetPlayerRoleCategory()
    -- Check if we are in Retail (Retail has GetSpecialization)
    if GetSpecialization then
        local specIndex = GetSpecialization()
        if not specIndex or specIndex == 0 then return "UNKNOWN" end
        
        local _, _, _, _, role = GetSpecializationInfo(specIndex)
        if role == "TANK" then return "TANK" end
        if role == "HEALER" then return "HEALER" end
        
        -- If role is DAMAGER, we distinguish between Melee and Ranged
        local _, class = UnitClass("player")
        
        -- Ranged-only classes
        if class == "MAGE" or class == "WARLOCK" or class == "PRIEST" or class == "EVOKER" then
            return "RANGED"
        end
        
        -- Melee-only classes
        if class == "ROGUE" or class == "WARRIOR" or class == "DEATHKNIGHT" or class == "DEMONHUNTER" or class == "MONK" or class == "PALADIN" then
            return "MELEE"
        end
        
        -- Hybrid classes (indices for Retail)
        if class == "DRUID" then
            return (specIndex == 1) and "RANGED" or "MELEE" -- 1: Balance, 2: Feral
        elseif class == "SHAMAN" then
            return (specIndex == 1) and "RANGED" or "MELEE" -- 1: Elemental, 2: Enhancement
        elseif class == "HUNTER" then
            return (specIndex == 3) and "MELEE" or "RANGED" -- 3: Survival, 1&2: Ranged
        end
    else
        -- Classic / TBC Logic (Determining spec by talent points)
        local _, class = UnitClass("player")
        
        -- Pure roles for TBC
        if class == "MAGE" or class == "WARLOCK" or class == "HUNTER" then return "RANGED" end
        if class == "ROGUE" then return "MELEE" end
        
        -- Check talent tabs to find the "active" spec
        local maxPoints = 0
        local specIndex = 1
        for i = 1, 3 do
            local _, _, pointsSpent = GetTalentTabInfo(i)
            if (pointsSpent or 0) > maxPoints then
                maxPoints = pointsSpent
                specIndex = i
            end
        end
        
        if class == "WARRIOR" then
            return (specIndex == 3) and "TANK" or "MELEE" -- 3: Protection
        elseif class == "PALADIN" then
            if specIndex == 1 then return "HEALER" end -- 1: Holy
            if specIndex == 2 then return "TANK" end   -- 2: Protection
            return "MELEE"                             -- 3: Retribution
        elseif class == "PRIEST" then
            return (specIndex == 3) and "RANGED" or "HEALER" -- 3: Shadow
        elseif class == "SHAMAN" then
            if specIndex == 1 then return "RANGED" end -- 1: Elemental
            if specIndex == 2 then return "MELEE" end  -- 2: Enhancement
            return "HEALER"                            -- 3: Restoration
        elseif class == "DRUID" then
            if specIndex == 1 then return "RANGED" end -- 1: Balance
            if specIndex == 3 then return "HEALER" end -- 3: Restoration
            return "MELEE"                             -- 2: Feral (Tank/DPS)
        end
    end
    
    return "MELEE" -- Default fallback
end

print("|cff00ff00" .. addonName .. " loaded!|r (Role: " .. GetPlayerRoleCategory() .. ")")


local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("ENCOUNTER_START")
frame:RegisterEvent("ENCOUNTER_END")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddonName = ...
        if loadedAddonName == addonName then
            -- Initialize SavedVariables
            WowAddonTestDB = WowAddonTestDB or {}
            WowAddonTestDB.spells = WowAddonTestDB.spells or {}
            print("|cff00ff00" .. addonName .. " database initialized.|r")
        end
        
    elseif event == "ENCOUNTER_START" then
        local encounterID, encounterName, difficultyID, groupSize = ...
        print(string.format("Boss Fight Started: %s (ID: %d)", encounterName, encounterID))
        
    elseif event == "ENCOUNTER_END" then
        local encounterID, encounterName, difficultyID, groupSize, endStatus = ...
        local status = endStatus == 1 and "Defeated" or "Wipe"
        print(string.format("Boss Fight Ended: %s - %s", encounterName, status))
        
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subevent, _, _, sourceName, sourceFlags, _, _, _, _, _, spellId, spellName = CombatLogGetCurrentEventInfo()
        
        -- We focus on spell casting events
        if subevent == "SPELL_CAST_START" or subevent == "SPELL_CAST_SUCCESS" then
            -- Store spell in database if it's new
            if WowAddonTestDB and WowAddonTestDB.spells and spellId then
                if not WowAddonTestDB.spells[spellId] then
                    local description = GetSpellDescription(spellId)
                    WowAddonTestDB.spells[spellId] = {
                        name = spellName,
                        description = description,
                        firstSeen = date("%Y-%m-%d %H:%M:%S"),
                        source = sourceName
                    }
                end
            end

            -- Check if this spell is in our configuration
            local ability = addonTable.BossAbilities[spellId]
            
            if ability then
                local role = GetPlayerRoleCategory()
                -- Use role-specific message if available, otherwise fallback to default message or spell name
                local message = ability[role] or ability.message or spellName
                
                -- 1. Display Alert
                RaidNotice_AddMessage(RaidWarningFrame, message, ChatTypeInfo["RAID_WARNING"])
                PlaySound(8959, "Master") -- Play "Raid Warning" sound
                
                -- 2. Handle Simple Timer
                if ability.timer then
                    print(string.format("Timer started for: %s", spellName))
                    C_Timer.After(ability.timer, function()
                        RaidNotice_AddMessage(RaidWarningFrame, ">>> " .. spellName .. " NOW! <<<", ChatTypeInfo["RAID_WARNING"])
                        PlaySound(8960, "Master")
                    end)
                end
            elseif sourceFlags and bit.band(sourceFlags, COMBATLOG_OBJECT_CONTROL_NPC) > 0 then
                -- If it's an NPC spell we DON'T know yet, print it to chat so you can find the ID
                print(string.format("New NPC Spell: %s (%d) from %s", spellName, spellId, sourceName or "Unknown"))
            end
        end
    end
end

frame:SetScript("OnEvent", OnEvent)
