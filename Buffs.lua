local addonName, addonTable = ...

addonTable.Buffs = {
    -- Generic buffs that everyone should have
    Common = {
        { name = "Fortitude", spellId = 25389 }, -- PW: Fortitude
        { name = "Mark of the Wild", spellId = 26990 },
    },
    -- Class/Role specific
    Mage = { { name = "Intellect", spellId = 23028 } },
    Priest = { { name = "Spirit", spellId = 25312 } },
}

-- Mapping classes to buff requirements
addonTable.ClassBuffs = {
    ["MAGE"] = { "Intellect" },
    ["PRIEST"] = { "Intellect", "Spirit" },
    ["WARLOCK"] = { "Intellect" },
}

-- Paladin Blessing Rankings per Class (Role-aware)
addonTable.PallyRankings = {
    ["WARRIOR"] = {
        DEFAULT = { "Salvation", "Might", "Kings", "Light", "Sanctuary" },
        TANK    = { "Kings", "Sanctuary", "Might", "Light" },
    },
    ["ROGUE"]   = {
        DEFAULT = { "Salvation", "Might", "Kings", "Light" },
    },
    ["MAGE"]    = {
        DEFAULT = { "Salvation", "Wisdom", "Kings", "Light" },
    },
    ["WARLOCK"] = {
        DEFAULT = { "Salvation", "Wisdom", "Kings", "Light" },
    },
    ["PRIEST"]  = {
        DEFAULT = { "Salvation", "Wisdom", "Kings", "Light" },
        RANGED  = { "Salvation", "Wisdom", "Kings", "Light" }, -- Shadow DPS
        HEALER  = { "Wisdom", "Kings", "Salvation", "Light" }, -- Healers need mana > threat reduction
    },
    ["HUNTER"]  = {
        DEFAULT = { "Salvation", "Might", "Kings", "Wisdom", "Light" },
    },
    ["DRUID"]   = {
        DEFAULT = { "Salvation", "Wisdom", "Kings", "Might", "Light" },
        TANK    = { "Kings", "Might", "Light" }, -- Feral Tank (Sanctuary has no effect on Druids)
        MELEE   = { "Salvation", "Might", "Kings", "Wisdom", "Light" }, -- Feral DPS
        RANGED  = { "Salvation", "Wisdom", "Kings", "Light" }, -- Balance DPS
        HEALER  = { "Wisdom", "Kings", "Salvation", "Light" }, -- Resto Healer
    },
    ["SHAMAN"]  = {
        DEFAULT = { "Salvation", "Wisdom", "Kings", "Might", "Light" },
        MELEE   = { "Salvation", "Might", "Kings", "Wisdom", "Light" }, -- Enhancement
        RANGED  = { "Salvation", "Wisdom", "Kings", "Light" }, -- Elemental
        HEALER  = { "Wisdom", "Kings", "Salvation", "Light" }, -- Restoration
    },
    ["PALADIN"] = {
        DEFAULT = { "Salvation", "Wisdom", "Kings", "Might", "Light" },
        TANK    = { "Kings", "Sanctuary", "Wisdom", "Might", "Light" }, -- Prot Tank
        MELEE   = { "Salvation", "Might", "Kings", "Wisdom", "Light" }, -- Retribution
        HEALER  = { "Wisdom", "Kings", "Salvation", "Light" }, -- Holy Healer
    },
}

function addonTable:GetUnitRole(unit)
    local _, class = UnitClass(unit)
    if not class then return "MELEE" end

    -- 1. Check if they are in the Raid Leader's assignment list
    local name = UnitName(unit)
    if WowAddonTestDB and WowAddonTestDB.assignments and WowAddonTestDB.assignments.tanks then
        for i = 1, 3 do
            if WowAddonTestDB.assignments.tanks[i] == name then
                return "TANK"
            end
        end
    end

    -- 2. If it's the player, use the advanced talent-based detection from WowAddonTest.lua
    if unit == "player" then
        return self:GetPlayerRoleCategory()
    end

    -- 3. Heuristic detection for others in TBC
    if class == "WARRIOR" then
        -- Check for Defensive Stance (Simplified check by name)
        if AuraUtil.FindAuraByName("Defensive Stance", unit, "HELPFUL") then return "TANK" end
    elseif class == "DRUID" then
        -- Check for Bear Forms
        if AuraUtil.FindAuraByName("Bear Form", unit, "HELPFUL") or AuraUtil.FindAuraByName("Dire Bear Form", unit, "HELPFUL") then return "TANK" end
    elseif class == "PALADIN" then
        -- Check for Righteous Fury
        if AuraUtil.FindAuraByName("Righteous Fury", unit, "HELPFUL") then return "TANK" end
    end

    -- Fallback based on class defaults if not detected as TANK
    if class == "MAGE" or class == "WARLOCK" or class == "HUNTER" then return "RANGED" end
    if class == "ROGUE" then return "MELEE" end
    if class == "PRIEST" then return "HEALER" end
    
    return "MELEE"
end

function addonTable:GetNumPaladins()
    local count = 0
    local numMembers = GetNumGroupMembers()
    
    -- Solo check
    if numMembers == 0 then
        local _, class = UnitClass("player")
        return (class == "PALADIN") and 1 or 0
    end

    for i = 1, numMembers do
        local unit = (IsInRaid() and "raid"..i) or "party"..i
        if i == numMembers and not IsInRaid() then unit = "player" end
        
        if UnitExists(unit) then
            local _, class = UnitClass(unit)
            if class == "PALADIN" then
                count = count + 1
            end
        end
    end
    return count
end

function addonTable:CheckUnitBuffs(unit, numPaladins)
    local missing = {}
    local _, class = UnitClass(unit)
    if not class then return missing end
    
    numPaladins = numPaladins or self:GetNumPaladins()
    
    -- Check Common Buffs
    for _, buff in ipairs(self.Buffs.Common) do
        if not AuraUtil.FindAuraByName(buff.name, unit, "HELPFUL") then
            table.insert(missing, buff.name)
        end
    end
    
    -- Check Class Specific
    local required = self.ClassBuffs[class]
    if required then
        for _, buffName in ipairs(required) do
            if not AuraUtil.FindAuraByName(buffName, unit, "HELPFUL") then
                -- Avoid duplicates if already in missing
                local found = false
                for _, m in ipairs(missing) do
                    if m == buffName then found = true break end
                end
                if not found then table.insert(missing, buffName) end
            end
        end
    end
    
    -- Check Paladin Blessings based on rank, role, and number of Paladins
    local role = self:GetUnitRole(unit)
    local classRankings = self.PallyRankings[class]
    local ranking = classRankings and (classRankings[role] or classRankings["DEFAULT"])

    if ranking and numPaladins > 0 then
        local needed = math.min(numPaladins, #ranking)
        for i = 1, needed do
            local blessingName = "Blessing of " .. ranking[i]
            if not AuraUtil.FindAuraByName(blessingName, unit, "HELPFUL") then
                table.insert(missing, ranking[i])
            end
        end
    end
    
    return missing
end

function addonTable:ReportMissingBuffs()
    local isLeader = UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
    local numPaladins = self:GetNumPaladins()
    
    if isLeader then
        -- Leader: Check whole raid
        print("|cffffff00[WowAddonTest] Raid Buff Check (|r|cff00ffff" .. numPaladins .. " Paladins|r|cffffff00):|r")
        local numGroupMembers = GetNumGroupMembers()
        local raidMissing = false
        
        for i = 1, numGroupMembers do
            local unit = (IsInRaid() and "raid"..i) or "party"..i
            if i == numGroupMembers and not IsInRaid() then unit = "player" end
            
            local missing = self:CheckUnitBuffs(unit, numPaladins)
            if #missing > 0 then
                raidMissing = true
                print(string.format("  |cffff0000%s|r is missing: %s", UnitName(unit), table.concat(missing, ", ")))
            end
        end
        
        if not raidMissing then
            print("  |cff00ff00All players have essential buffs.|r")
        end
    else
        -- Non-leader: Check only self
        local missing = self:CheckUnitBuffs("player", numPaladins)
        if #missing > 0 then
            RaidNotice_AddMessage(RaidWarningFrame, "|cffff0000YOU ARE MISSING BUFFS: " .. table.concat(missing, ", ") .. "|r", ChatTypeInfo["RAID_WARNING"])
            print("|cffff0000[WowAddonTest] You are missing buffs:|r " .. table.concat(missing, ", "))
        end
    end
end
