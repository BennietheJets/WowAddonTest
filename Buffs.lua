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
    -- Paladin blessings are harder to automate without knowing the assignment
}

function addonTable:CheckUnitBuffs(unit)
    local missing = {}
    
    -- Check Common Buffs
    for _, buff in ipairs(self.Buffs.Common) do
        if not AuraUtil.FindAuraByName(buff.name, unit, "HELPFUL") then
            table.insert(missing, buff.name)
        end
    end
    
    -- Check Class Specific
    local _, class = UnitClass(unit)
    local required = self.ClassBuffs[class]
    if required then
        for _, buffName in ipairs(required) do
            -- Find the spellId for the buffName in our database
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
    
    return missing
end

function addonTable:ReportMissingBuffs()
    local isLeader = UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
    
    if isLeader then
        -- Leader: Check whole raid
        print("|cffffff00[WowAddonTest] Raid Buff Check:|r")
        local numGroupMembers = GetNumGroupMembers()
        local raidMissing = false
        
        for i = 1, numGroupMembers do
            local unit = (IsInRaid() and "raid"..i) or "party"..i
            if i == numGroupMembers and not IsInRaid() then unit = "player" end
            
            local missing = self:CheckUnitBuffs(unit)
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
        local missing = self:CheckUnitBuffs("player")
        if #missing > 0 then
            RaidNotice_AddMessage(RaidWarningFrame, "|cffff0000YOU ARE MISSING BUFFS: " .. table.concat(missing, ", ") .. "|r", ChatTypeInfo["RAID_WARNING"])
            print("|cffff0000[WowAddonTest] You are missing buffs:|r " .. table.concat(missing, ", "))
        end
    end
end
