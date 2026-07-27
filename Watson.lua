local addonName, addonTable = ...

-- Function to determine the player's role category
function addonTable:GetPlayerRoleCategory()
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
    
    return "MELEE" -- Default fallback
end

print("|cff00ff00" .. addonName .. " loaded!|r (Role: " .. addonTable:GetPlayerRoleCategory() .. ")")


local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("ENCOUNTER_START")
frame:RegisterEvent("ENCOUNTER_END")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("READY_CHECK")

local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddonName = ...
        if loadedAddonName == addonName then
            -- Initialize SavedVariables
            WatsonDB = WatsonDB or {}
            WatsonDB.spells = WatsonDB.spells or {}
            WatsonDB.sscLog = WatsonDB.sscLog or {}
            
            -- Initialize RaidTools
            if addonTable.RaidTools and addonTable.RaidTools.Initialize then
                addonTable.RaidTools:Initialize()
            end
            
            -- Initialize Comm
            if addonTable.Comm and addonTable.Comm.Initialize then
                addonTable.Comm:Initialize()
            end
            
            print("|cff00ff00" .. addonName .. " database initialized.|r")
        end
        
    elseif event == "ENCOUNTER_START" then
        local encounterID, encounterName, difficultyID, groupSize = ...
        print(string.format("Boss Fight Started: %s (ID: %d)", encounterName, encounterID))
        
    elseif event == "ENCOUNTER_END" then
        local encounterID, encounterName, difficultyID, groupSize, endStatus = ...
        local status = endStatus == 1 and "Defeated" or "Wipe"
        print(string.format("Boss Fight Ended: %s - %s", encounterName, status))
        
    elseif event == "READY_CHECK" then
        if addonTable.ReportMissingBuffs then
            addonTable:ReportMissingBuffs()
        end

    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subevent, _, _, sourceName, sourceFlags, _, destGUID, destName, _, _, spellId, spellName = CombatLogGetCurrentEventInfo()
        
        -- SSC Recording
        if addonTable.SSC and addonTable.SSC.recording then
            if subevent == "SPELL_CAST_START" or subevent == "SPELL_CAST_SUCCESS" then
                -- Only log spells from hostile NPCs
                local isHostileNPC = sourceFlags and 
                    bit.band(sourceFlags, COMBATLOG_OBJECT_CONTROL_NPC) > 0 and 
                    bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0

                if isHostileNPC then
                    local _, _, _, _, _, _, _, instanceID = GetInstanceInfo()
                    if instanceID == 548 then
                        addonTable.SSC:LogSpell(spellId, spellName, sourceName)
                    end
                end
            end
        end

        -- Check if this spell is in our configuration
        local ability = addonTable.BossAbilities[spellId]
        
        -- Handle Spell Casting
        if subevent == "SPELL_CAST_START" or subevent == "SPELL_CAST_SUCCESS" then
            -- Store spell in database if it's new
            if WatsonDB and WatsonDB.spells and spellId then
                if not WatsonDB.spells[spellId] then
                    local description = GetSpellDescription(spellId)
                    WatsonDB.spells[spellId] = {
                        name = spellName,
                        description = description,
                        firstSeen = date("%Y-%m-%d %H:%M:%S"),
                        source = sourceName
                    }
                end
            end

            if ability and (not ability.type or ability.type == "cast") then
                local role = addonTable:GetPlayerRoleCategory()
                local message = ability[role] or ability.message or spellName
                
                RaidNotice_AddMessage(RaidWarningFrame, message, ChatTypeInfo["RAID_WARNING"])
                PlaySound(8959, "Master")
                
                if ability.timer then
                    C_Timer.After(ability.timer, function()
                        RaidNotice_AddMessage(RaidWarningFrame, ">>> " .. spellName .. " NOW! <<<", ChatTypeInfo["RAID_WARNING"])
                        PlaySound(8960, "Master")
                    end)
                end
            elseif sourceFlags and bit.band(sourceFlags, COMBATLOG_OBJECT_CONTROL_NPC) > 0 and bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 and not ability then
                print(string.format("New NPC Spell: %s (%d) from %s", spellName, spellId, sourceName or "Unknown"))
            end

        -- Handle Auras (Debuffs/Buffs)
        elseif subevent == "SPELL_AURA_APPLIED" then
            if ability and ability.type == "aura" then
                -- Check if it's on the player
                local isPlayer = (destGUID == UnitGUID("player"))
                
                if isPlayer or not ability.playerOnly then
                    local role = addonTable:GetPlayerRoleCategory()
                    local message = ability[role] or ability.message or spellName
                    
                    if isPlayer then
                        message = "YOU: " .. message
                    else
                        message = destName .. ": " .. message
                    end
                    
                    RaidNotice_AddMessage(RaidWarningFrame, message, ChatTypeInfo["RAID_WARNING"])
                    PlaySound(8959, "Master")
                end
            end
        end
    end
end

frame:SetScript("OnEvent", OnEvent)
