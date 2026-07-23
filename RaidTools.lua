local addonName, addonTable = ...

local RaidTools = {}
addonTable.RaidTools = RaidTools

function RaidTools:Initialize()
    WowAddonTestDB.assignments = WowAddonTestDB.assignments or {
        tanks = { [1] = "", [2] = "", [3] = "" }, -- 1: Skull, 2: Cross, 3: Square
        cc = { [1] = { name = "", class = "MAGE" }, [2] = { name = "", class = "WARLOCK" } }
    }
    
    self:CreateMainFrame()
end

function RaidTools:CreateMainFrame()
    if self.frame then return end
    
    local f = CreateFrame("Frame", "WowAddonTestRaidToolsFrame", UIParent, "BackdropTemplate")
    f:SetSize(300, 350)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("Raid Assignments")
    
    -- Tank Assignments
    local tankHeader = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    tankHeader:SetPoint("TOPLEFT", 20, -50)
    tankHeader:SetText("Tank Assignments:")
    
    self.tankInputs = {}
    local icons = { "Skull", "Cross", "Square" }
    for i = 1, 3 do
        local label = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", 30, -50 - (i * 30))
        label:SetText(icons[i] .. ":")
        
        local eb = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        eb:SetSize(150, 20)
        eb:SetPoint("LEFT", label, "RIGHT", 10, 0)
        eb:SetAutoFocus(false)
        eb:SetText(WowAddonTestDB.assignments.tanks[i] or "")
        eb:SetScript("OnTextChanged", function(self)
            WowAddonTestDB.assignments.tanks[i] = self:GetText()
        end)
        self.tankInputs[i] = eb
    end
    
    -- CC Assignments
    local ccHeader = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    ccHeader:SetPoint("TOPLEFT", 20, -170)
    ccHeader:SetText("CC Assignments:")
    
    self.ccInputs = {}
    local ccLabels = { "Mage CC:", "Lock CC:" }
    for i = 1, 2 do
        local label = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", 30, -170 - (i * 30))
        label:SetText(ccLabels[i])
        
        local eb = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        eb:SetSize(150, 20)
        eb:SetPoint("LEFT", label, "RIGHT", 10, 0)
        eb:SetAutoFocus(false)
        eb:SetText(WowAddonTestDB.assignments.cc[i].name or "")
        eb:SetScript("OnTextChanged", function(self)
            WowAddonTestDB.assignments.cc[i].name = self:GetText()
        end)
        self.ccInputs[i] = eb
    end
    
    -- Broadcast Button
    local btn = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
    btn:SetSize(120, 30)
    btn:SetPoint("BOTTOM", 0, 20)
    btn:SetText("Broadcast")
    btn:SetScript("OnClick", function()
        addonTable.RaidTools:Broadcast()
    end)
    
    -- Close Button
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)
    
    f:Hide() -- Hide by default
    self.frame = f
end

function RaidTools:Toggle()
    if not self.frame then self:Initialize() end
    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self.frame:Show()
    end
end

function RaidTools:Broadcast()
    print("|cffffff00[WowAddonTest] Broadcasting assignments...|r")
    
    local icons = { "Skull", "Cross", "Square" }
    for i = 1, 3 do
        local name = WowAddonTestDB.assignments.tanks[i]
        if name and name ~= "" then
            if addonTable.Comm then
                addonTable.Comm:BroadcastAssignment("TANK", icons[i], name)
            end
        end
    end
    
    local ccNames = { "Mage", "Warlock" }
    for i = 1, 2 do
        local cc = WowAddonTestDB.assignments.cc[i]
        if cc.name and cc.name ~= "" then
            if addonTable.Comm then
                addonTable.Comm:BroadcastAssignment("CC", ccNames[i], cc.name)
            end
        end
    end
    
    -- Summary in Raid Chat for transparency
    local channel = IsInRaid() and "RAID" or (IsInGroup() and "PARTY" or nil)
    if channel then
        SendChatMessage("--- Raid Assignments Broadcasted ---", channel)
    end
end

-- Slash command to open the tools
SLASH_WOWADDONTEST1 = "/wat"
SlashCmdList["WOWADDONTEST"] = function(msg)
    if msg == "raid" or msg == "tools" or msg == "" then
        addonTable.RaidTools:Toggle()
    end
end
