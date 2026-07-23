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

-- Paladin Blessing Rankings per Class
addonTable.PallyRankings = {
    ["WARRIOR"] = { "Kings", "Might", "Salvation", "Light", "Sanctuary" },
    ["ROGUE"]   = { "Kings", "Might", "Salvation", "Light" },
    ["MAGE"]    = { "Kings", "Salvation", "Wisdom", "Light" },
    ["WARLOCK"] = { "Kings", "Salvation", "Wisdom", "Light" },
    ["PRIEST"]  = { "Kings", "Salvation", "Wisdom", "Light" },
    ["HUNTER"]  = { "Kings", "Might", "Salvation", "Wisdom", "Light" },
    ["DRUID"]   = { "Kings", "Salvation", "Wisdom", "Light", "Might" },
    ["SHAMAN"]  = { "Kings", "Salvation", "Wisdom", "Light", "Might" },
    ["PALADIN"] = { "Kings", "Salvation", "Wisdom", "Light", "Sanctuary" },
}

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
    
    -- Check Paladin Blessings based on rank and number of Paladins
    local ranking = self.PallyRankings[class]
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
