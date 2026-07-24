local addonName, addonTable = ...
local GroupAdvisor = {}
addonTable.GroupAdvisor = GroupAdvisor

-- Specialized Role Detection
GroupAdvisor.ROLES = {
    TANK = "TANK",
    MELEE = "MELEE",
    RANGED = "RANGED",
    HEALER = "HEALER",
}

GroupAdvisor.SPECS = {
    -- Warriors
    WARRIOR_ARMS = { role = GroupAdvisor.ROLES.MELEE, name = "Arms" },
    WARRIOR_FURY = { role = GroupAdvisor.ROLES.MELEE, name = "Fury" },
    WARRIOR_PROT = { role = GroupAdvisor.ROLES.TANK, name = "Protection" },
    -- Paladins
    PALADIN_HOLY = { role = GroupAdvisor.ROLES.HEALER, name = "Holy" },
    PALADIN_PROT = { role = GroupAdvisor.ROLES.TANK, name = "Protection" },
    PALADIN_RET = { role = GroupAdvisor.ROLES.MELEE, name = "Retribution" },
    -- Hunters
    HUNTER_BM = { role = GroupAdvisor.ROLES.RANGED, name = "Beast Mastery" },
    HUNTER_MARK = { role = GroupAdvisor.ROLES.RANGED, name = "Marksmanship" },
    HUNTER_SURV = { role = GroupAdvisor.ROLES.RANGED, name = "Survival" },
    -- Rogues
    ROGUE_ASSAS = { role = GroupAdvisor.ROLES.MELEE, name = "Assassination" },
    ROGUE_COMBAT = { role = GroupAdvisor.ROLES.MELEE, name = "Combat" },
    ROGUE_SUBTLE = { role = GroupAdvisor.ROLES.MELEE, name = "Subtlety" },
    -- Priests
    PRIEST_DISC = { role = GroupAdvisor.ROLES.HEALER, name = "Discipline" },
    PRIEST_HOLY = { role = GroupAdvisor.ROLES.HEALER, name = "Holy" },
    PRIEST_SHADOW = { role = GroupAdvisor.ROLES.RANGED, name = "Shadow" },
    -- Shamans
    SHAMAN_ELE = { role = GroupAdvisor.ROLES.RANGED, name = "Elemental" },
    SHAMAN_ENH = { role = GroupAdvisor.ROLES.MELEE, name = "Enhancement" },
    SHAMAN_RESTO = { role = GroupAdvisor.ROLES.HEALER, name = "Restoration" },
    -- Mages
    MAGE_ARCANE = { role = GroupAdvisor.ROLES.RANGED, name = "Arcane" },
    MAGE_FIRE = { role = GroupAdvisor.ROLES.RANGED, name = "Fire" },
    MAGE_FROST = { role = GroupAdvisor.ROLES.RANGED, name = "Frost" },
    -- Warlocks
    WARLOCK_AFFLI = { role = GroupAdvisor.ROLES.RANGED, name = "Affliction" },
    WARLOCK_DEMO = { role = GroupAdvisor.ROLES.RANGED, name = "Demonology" },
    WARLOCK_DESTRO = { role = GroupAdvisor.ROLES.RANGED, name = "Destruction" },
    -- Druids
    DRUID_BAL = { role = GroupAdvisor.ROLES.RANGED, name = "Balance" },
    DRUID_FERAL = { role = GroupAdvisor.ROLES.MELEE, name = "Feral" },
    DRUID_RESTO = { role = GroupAdvisor.ROLES.HEALER, name = "Restoration" },
}

-- Mapping of class and talent tab index to spec
GroupAdvisor.CLASS_SPECS = {
    WARRIOR = { "WARRIOR_ARMS", "WARRIOR_FURY", "WARRIOR_PROT" },
    PALADIN = { "PALADIN_HOLY", "PALADIN_PROT", "PALADIN_RET" },
    HUNTER = { "HUNTER_BM", "HUNTER_MARK", "HUNTER_SURV" },
    ROGUE = { "ROGUE_ASSAS", "ROGUE_COMBAT", "ROGUE_SUBTLE" },
    PRIEST = { "PRIEST_DISC", "PRIEST_HOLY", "PRIEST_SHADOW" },
    SHAMAN = { "SHAMAN_ELE", "SHAMAN_ENH", "SHAMAN_RESTO" },
    MAGE = { "MAGE_ARCANE", "MAGE_FIRE", "MAGE_FROST" },
    WARLOCK = { "WARLOCK_AFFLI", "WARLOCK_DEMO", "WARLOCK_DESTRO" },
    DRUID = { "DRUID_BAL", "DRUID_FERAL", "DRUID_RESTO" },
}

-- Scanner State
GroupAdvisor.scanQueue = {}
GroupAdvisor.isScanning = false
GroupAdvisor.currentUnit = nil
GroupAdvisor.raidData = {} -- Stores detected specs for raid members: [name] = { role, name, class }

function GroupAdvisor:GetUnitSpec(unit)
    local _, class = UnitClass(unit)
    if not class then return nil end
    
    local maxPoints = -1
    local specIndex = 1
    
    local isPlayer = UnitIsUnit(unit, "player")
    
    for i = 1, 3 do
        local _, _, pointsSpent
        if isPlayer then
            _, _, pointsSpent = GetTalentTabInfo(i)
        else
            _, _, pointsSpent = GetInspectTalentTabInfo(unit, i)
        end
        
        pointsSpent = pointsSpent or 0
        if pointsSpent > maxPoints then
            maxPoints = pointsSpent
            specIndex = i
        end
    end
    
    local specKey = self.CLASS_SPECS[class] and self.CLASS_SPECS[class][specIndex]
    local specInfo = specKey and self.SPECS[specKey] or { role = self.ROLES.MELEE, name = "Unknown" }
    
    -- Clone to add class info
    return {
        role = specInfo.role,
        name = specInfo.name,
        class = class,
        specIndex = specIndex
    }
end

function GroupAdvisor:StartScan()
    if self.isScanning then return end
    
    self.scanQueue = {}
    -- Note: Don't clear raidData here if we want to keep previous results for people out of range
    
    local numMembers = GetNumRaidMembers()
    if numMembers == 0 then
        table.insert(self.scanQueue, "player")
    else
        for i = 1, numMembers do
            local unit = "raid" .. i
            if UnitExists(unit) then
                table.insert(self.scanQueue, unit)
            end
        end
    end
    
    self.isScanning = true
    print("|cffffff00[WowAddonTest] Starting talent scan...|r")
    self:ProcessNextQueueItem()
end

function GroupAdvisor:ProcessNextQueueItem()
    if #self.scanQueue == 0 then
        self.isScanning = false
        self.currentUnit = nil
        print("|cff00ff00[WowAddonTest] Talent scan complete.|r")
        if self.onScanComplete then
            self:onScanComplete()
        end
        return
    end
    
    local unit = table.remove(self.scanQueue, 1)
    self.currentUnit = unit
    local name = UnitName(unit)
    
    if UnitIsUnit(unit, "player") then
        self.raidData[name] = self:GetUnitSpec("player")
        self:ProcessNextQueueItem()
    elseif CanInspect(unit) and UnitIsConnected(unit) and CheckInteractDistance(unit, 4) then
        NotifyInspect(unit)
        
        -- Timeout fallback in case INSPECT_READY doesn't fire
        if self.timeoutTimer then self.timeoutTimer:Cancel() end
        self.timeoutTimer = C_Timer.NewTimer(2, function()
            if self.currentUnit == unit then
                print("|cffff0000[WowAddonTest] Inspection timeout for " .. name .. "|r")
                if not self.raidData[name] then
                    self.raidData[name] = { role = "UNKNOWN", name = "Timeout", class = select(2, UnitClass(unit)) }
                end
                self:ProcessNextQueueItem()
            end
        end)
    else
        -- Skip or mark as unscannable
        if not self.raidData[name] then
            local _, class = UnitClass(unit)
            self.raidData[name] = { role = "UNKNOWN", name = "Out of Range", class = class }
        end
        self:ProcessNextQueueItem()
    end
end

-- Event Handler
local frame = CreateFrame("Frame")
frame:RegisterEvent("INSPECT_READY")

frame:SetScript("OnEvent", function(self, event, guid)
    if event == "INSPECT_READY" then
        if GroupAdvisor.isScanning and GroupAdvisor.currentUnit then
            if UnitGUID(GroupAdvisor.currentUnit) == guid then
                if GroupAdvisor.timeoutTimer then GroupAdvisor.timeoutTimer:Cancel() end
                
                local name = UnitName(GroupAdvisor.currentUnit)
                GroupAdvisor.raidData[name] = GroupAdvisor:GetUnitSpec(GroupAdvisor.currentUnit)
                
                ClearInspectPlayer()
                GroupAdvisor:ProcessNextQueueItem()
            end
        end
    end
end)

function GroupAdvisor:GenerateOptimization()
    local players = {}
    for name, data in pairs(self.raidData) do
        table.insert(players, {
            name = name,
            role = data.role,
            spec = data.name,
            class = data.class,
            assigned = false
        })
    end

    -- Sort players by name for consistency
    table.sort(players, function(a, b) return a.name < b.name end)

    local groups = { {}, {}, {}, {}, {} }
    local function addToGroup(groupIndex, player)
        if #groups[groupIndex] < 5 then
            table.insert(groups[groupIndex], player)
            player.assigned = true
            player.suggestedGroup = groupIndex
            return true
        end
        return false
    end

    -- 1. Identify Shamans and place them first as anchors
    for _, p in ipairs(players) do
        if p.class == "SHAMAN" then
            if p.spec == "Enhancement" then 
                if not addToGroup(1, p) then addToGroup(2, p) end
            elseif p.spec == "Elemental" then 
                if not addToGroup(3, p) then addToGroup(4, p) end
            elseif p.spec == "Restoration" then
                if not addToGroup(5, p) then addToGroup(4, p) end
            end
        end
    end

    -- 2. Place other key buffers
    for _, p in ipairs(players) do
        if not p.assigned then
            if p.spec == "Feral" then 
                if not addToGroup(1, p) then addToGroup(2, p) end
            elseif p.spec == "Balance" then 
                if not addToGroup(3, p) then addToGroup(4, p) end
            elseif p.spec == "Shadow" then 
                if not addToGroup(3, p) then addToGroup(4, p) end
            end
        end
    end

    -- 3. Fill Melee Group (Group 1, then 2)
    for _, p in ipairs(players) do
        if not p.assigned and p.role == self.ROLES.MELEE then
            if not addToGroup(1, p) then 
                if not addToGroup(2, p) then addToGroup(5, p) end
            end
        end
    end

    -- 4. Fill Caster Group (Group 3, then 4)
    for _, p in ipairs(players) do
        if not p.assigned and p.role == self.ROLES.RANGED then
            if not addToGroup(3, p) then 
                if not addToGroup(4, p) then addToGroup(5, p) end
            end
        end
    end

    -- 5. Fill Healers (Group 5, then 4, then 2)
    for _, p in ipairs(players) do
        if not p.assigned and p.role == self.ROLES.HEALER then
            if not addToGroup(5, p) then
                if not addToGroup(4, p) then 
                    if not addToGroup(2, p) then addToGroup(1, p) end
                end
            end
        end
    end

    -- 6. Fill Tanks (Group 1 or 2)
    for _, p in ipairs(players) do
        if not p.assigned and p.role == self.ROLES.TANK then
            if not addToGroup(1, p) then addToGroup(2, p) end
        end
    end

    -- 7. Final pass for anyone remaining (fill gaps)
    for _, p in ipairs(players) do
        if not p.assigned then
            for i = 1, 5 do
                if addToGroup(i, p) then break end
            end
        end
    end

    return groups
end

-- Roster Update Listener for 25-man notification
local rosterFrame = CreateFrame("Frame")
rosterFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
rosterFrame:SetScript("OnEvent", function(self, event)
    if IsInRaid() and IsRaidLeader() then
        local num = GetNumRaidMembers()
        if num == 25 and not GroupAdvisor.lastNotified25 then
            print("|cff00ffff[WowAddonTest] Raid is now at 25 members. Use /wat balance to optimize groups.|r")
            RaidNotice_AddMessage(RaidWarningFrame, "[WowAddonTest] Raid Full - Optimization Ready", ChatTypeInfo["RAID_WARNING"])
            GroupAdvisor.lastNotified25 = true
        elseif num < 25 then
            GroupAdvisor.lastNotified25 = false
        end
    end
end)
