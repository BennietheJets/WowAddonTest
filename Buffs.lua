local addonName, addonTable = ...

-- Buff groups: each entry lists every aura name that satisfies the requirement
-- (single-target versions AND group versions), plus the class that provides it.
-- A buff is only considered "required" if a provider of that class is in the group.
addonTable.Buffs = {
    -- Generic buffs that everyone should have
    Common = {
        { name = "Fortitude",        provider = "PRIEST", auras = { "Power Word: Fortitude", "Prayer of Fortitude" } },
        { name = "Mark of the Wild", provider = "DRUID",  auras = { "Mark of the Wild", "Gift of the Wild" } },
    },
    -- Class/Role specific (mana users)
    Intellect = { name = "Intellect", provider = "MAGE",   auras = { "Arcane Intellect", "Arcane Brilliance" } },
    Spirit    = { name = "Spirit",    provider = "PRIEST", auras = { "Divine Spirit", "Prayer of Spirit" } },
}

-- Mapping classes to buff requirements
addonTable.ClassBuffs = {
    ["MAGE"] = { "Intellect" },
    ["PRIEST"] = { "Intellect", "Spirit" },
    ["WARLOCK"] = { "Intellect" },
    ["DRUID"] = { "Intellect", "Spirit" },
    ["SHAMAN"] = { "Intellect" },
    ["PALADIN"] = { "Intellect", "Spirit" },
    ["HUNTER"] = { "Intellect" },
}

-- Paladin Blessing Rankings per Class (Role-aware)
addonTable.PallyRankings = {
    ["WARRIOR"] = {
        DEFAULT = { "Salvation", "Might", "Kings", "Light", "Sanctuary" },
        TANK    = { "Kings", "Might", "Light", "Sanctuary" },
    },
    ["ROGUE"]   = {
        DEFAULT = { "Salvation", "Might", "Kings", "Light" },
    },
    ["MAGE"]    = {
        DEFAULT = { "Salvation", "Wisdom", "Kings", "Light" },
    },
    ["WARLOCK"] = {
        DEFAULT = { "Salvation", "Kings", "Wisdom", "Light" },
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
        TANK    = { "Kings", "Wisdom", "Might", "Light", "Sanctuary" }, -- Prot Tank
        MELEE   = { "Salvation", "Might", "Kings", "Wisdom", "Light" }, -- Retribution
        HEALER  = { "Wisdom", "Kings", "Salvation", "Light" }, -- Holy Healer
    },
}

function addonTable:GetUnitRole(unit)
    local _, class = UnitClass(unit)
    if not class then return "MELEE" end

    -- 1. Check if they are in the Raid Leader's assignment list
    local name = UnitName(unit)
    if WatsonDB and WatsonDB.assignments and WatsonDB.assignments.tanks then
        for i = 1, 3 do
            if WatsonDB.assignments.tanks[i] == name then
                return "TANK"
            end
        end
    end

    -- 2. If it's the player, use the advanced talent-based detection from Watson.lua
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

-- Counts how many members of each class are in the group (including the player)
function addonTable:GetGroupClassCounts()
    local counts = {}
    local numMembers = GetNumGroupMembers()

    -- Solo check
    if numMembers == 0 then
        local _, class = UnitClass("player")
        if class then counts[class] = 1 end
        return counts
    end

    for i = 1, numMembers do
        local unit = (IsInRaid() and "raid"..i) or "party"..i
        if i == numMembers and not IsInRaid() then unit = "player" end

        if UnitExists(unit) then
            local _, class = UnitClass(unit)
            if class then
                counts[class] = (counts[class] or 0) + 1
            end
        end
    end
    return counts
end

function addonTable:GetNumPaladins()
    local counts = self:GetGroupClassCounts()
    return counts["PALADIN"] or 0
end

-- Returns true if the unit has ANY of the listed aura names
function addonTable:UnitHasAnyAura(unit, auraNames)
    for _, auraName in ipairs(auraNames) do
        if AuraUtil.FindAuraByName(auraName, unit, "HELPFUL") then
            return true
        end
    end
    return false
end

function addonTable:CheckUnitBuffs(unit, classCounts)
    local missing = {}
    local _, class = UnitClass(unit)
    if not class then return missing end

    -- Can't reliably scan auras on offline units; skip them
    if not UnitIsConnected(unit) then return missing end

    classCounts = classCounts or self:GetGroupClassCounts()
    local numPaladins = classCounts["PALADIN"] or 0

    -- Check Common Buffs (only if a provider of that class is in the group)
    for _, buff in ipairs(self.Buffs.Common) do
        if (classCounts[buff.provider] or 0) > 0 then
            if not self:UnitHasAnyAura(unit, buff.auras) then
                table.insert(missing, buff.name)
            end
        end
    end

    -- Check Class Specific (mana buffs)
    local required = self.ClassBuffs[class]
    if required then
        for _, buffKey in ipairs(required) do
            local buff = self.Buffs[buffKey]
            if buff and (classCounts[buff.provider] or 0) > 0 then
                if not self:UnitHasAnyAura(unit, buff.auras) then
                    -- Avoid duplicates if already in missing
                    local found = false
                    for _, m in ipairs(missing) do
                        if m == buff.name then found = true break end
                    end
                    if not found then table.insert(missing, buff.name) end
                end
            end
        end
    end

    -- Check Paladin Blessings based on rank, role, and number of Paladins.
    -- Each Paladin can maintain one blessing per player, and either the normal
    -- or the Greater version satisfies the requirement.
    local role = self:GetUnitRole(unit)
    local classRankings = self.PallyRankings[class]
    local ranking = classRankings and (classRankings[role] or classRankings["DEFAULT"])

    if ranking and numPaladins > 0 then
        local needed = math.min(numPaladins, #ranking)

        -- Count how many of the ranked blessings the unit already has
        local have = {}
        local haveCount = 0
        for _, blessing in ipairs(ranking) do
            if self:UnitHasAnyAura(unit, { "Blessing of " .. blessing, "Greater Blessing of " .. blessing }) then
                have[blessing] = true
                haveCount = haveCount + 1
            end
        end

        -- If short on blessings, suggest the highest-priority ones they don't have yet
        if haveCount < needed then
            local shortfall = needed - haveCount
            for i = 1, #ranking do
                if shortfall == 0 then break end
                local blessing = ranking[i]
                if not have[blessing] then
                    table.insert(missing, "Blessing of " .. blessing)
                    shortfall = shortfall - 1
                end
            end
        end
    end

    return missing
end

function addonTable:ReportMissingBuffs()
    local isLeader = UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
    local classCounts = self:GetGroupClassCounts()
    local numPaladins = classCounts["PALADIN"] or 0
    
    if isLeader then
        -- Leader: Check whole raid
        print("|cffffff00[Watson] Raid Buff Check (|r|cff00ffff" .. numPaladins .. " Paladins|r|cffffff00):|r")
        local numGroupMembers = GetNumGroupMembers()
        local raidMissing = false
        
        for i = 1, numGroupMembers do
            local unit = (IsInRaid() and "raid"..i) or "party"..i
            if i == numGroupMembers and not IsInRaid() then unit = "player" end
            
            if UnitExists(unit) and UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) then
                local missing = self:CheckUnitBuffs(unit, classCounts)
                if #missing > 0 then
                    raidMissing = true
                    print(string.format("  |cffff0000%s|r is missing: %s", UnitName(unit), table.concat(missing, ", ")))
                end
            end
        end
        
        if not raidMissing then
            print("  |cff00ff00All players have essential buffs.|r")
        end
    else
        -- Non-leader: Check only self
        local missing = self:CheckUnitBuffs("player", classCounts)
        if #missing > 0 then
            RaidNotice_AddMessage(RaidWarningFrame, "|cffff0000YOU ARE MISSING BUFFS: " .. table.concat(missing, ", ") .. "|r", ChatTypeInfo["RAID_WARNING"])
            print("|cffff0000[Watson] You are missing buffs:|r " .. table.concat(missing, ", "))
        end
    end
end
