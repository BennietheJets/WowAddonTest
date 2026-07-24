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
    f:SetSize(350, 450)
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
    
    -- Tabs
    local assignBtn = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
    assignBtn:SetSize(100, 25)
    assignBtn:SetPoint("TOPLEFT", 20, -15)
    assignBtn:SetText("Assigns")
    
    local advisorBtn = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
    advisorBtn:SetSize(100, 25)
    advisorBtn:SetPoint("LEFT", assignBtn, "RIGHT", 5, 0)
    advisorBtn:SetText("Advisor")
    
    local assignContent = CreateFrame("Frame", nil, f)
    assignContent:SetAllPoints()
    self.assignContent = assignContent
    
    local advisorContent = CreateFrame("Frame", nil, f)
    advisorContent:SetAllPoints()
    advisorContent:Hide()
    self.advisorContent = advisorContent
    
    assignBtn:SetScript("OnClick", function()
        assignContent:Show()
        advisorContent:Hide()
    end)
    
    advisorBtn:SetScript("OnClick", function()
        assignContent:Hide()
        advisorContent:Show()
    end)

    local title = assignContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -50)
    title:SetText("Raid Assignments")
    
    -- Tank Assignments
    local tankHeader = assignContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    tankHeader:SetPoint("TOPLEFT", 20, -80)
    tankHeader:SetText("Tank Assignments:")
    
    self.tankInputs = {}
    local icons = { "Skull", "Cross", "Square" }
    for i = 1, 3 do
        local label = assignContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", 30, -80 - (i * 30))
        label:SetText(icons[i] .. ":")
        
        local eb = CreateFrame("EditBox", nil, assignContent, "InputBoxTemplate")
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
    local ccHeader = assignContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    ccHeader:SetPoint("TOPLEFT", 20, -200)
    ccHeader:SetText("CC Assignments:")
    
    self.ccInputs = {}
    local ccLabels = { "Mage CC:", "Lock CC:" }
    for i = 1, 2 do
        local label = assignContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", 30, -200 - (i * 30))
        label:SetText(ccLabels[i])
        
        local eb = CreateFrame("EditBox", nil, assignContent, "InputBoxTemplate")
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
    local btn = CreateFrame("Button", nil, assignContent, "GameMenuButtonTemplate")
    btn:SetSize(120, 30)
    btn:SetPoint("BOTTOM", 0, 20)
    btn:SetText("Broadcast")
    btn:SetScript("OnClick", function()
        addonTable.RaidTools:Broadcast()
    end)
    
    -- Advisor UI
    self:CreateAdvisorUI(advisorContent)
    
    -- Close Button
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)
    
    f:Hide() -- Hide by default
    self.frame = f
end

function RaidTools:CreateAdvisorUI(parent)
    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -50)
    title:SetText("Group Advisor")
    
    local scanBtn = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
    scanBtn:SetSize(140, 30)
    scanBtn:SetPoint("TOP", 0, -80)
    scanBtn:SetText("Scan & Balance")
    scanBtn:SetScript("OnClick", function()
        addonTable.GroupAdvisor:StartScan()
    end)
    
    -- Suggestions List
    local scrollFrame = CreateFrame("ScrollFrame", "WowAddonTestAdvisorScroll", parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(300, 250)
    scrollFrame:SetPoint("TOPLEFT", 20, -120)
    
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(280, 500)
    scrollFrame:SetScrollChild(content)
    self.advisorList = content
    
    local applyBtn = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
    applyBtn:SetSize(120, 30)
    applyBtn:SetPoint("BOTTOM", 0, 20)
    applyBtn:SetText("Apply All")
    applyBtn:SetScript("OnClick", function()
        self:ApplySuggestions()
    end)
    
    -- Hook scan completion to update UI
    addonTable.GroupAdvisor.onScanComplete = function()
        self:UpdateAdvisorUI()
    end
end

function RaidTools:UpdateAdvisorUI()
    if not self.advisorList then return end
    
    -- Clear previous
    local children = { self.advisorList:GetChildren() }
    for _, child in ipairs(children) do
        child:Hide()
    end
    
    local groups = addonTable.GroupAdvisor:GenerateOptimization()
    self.lastSuggestions = groups
    
    local yOffset = -10
    for i = 1, 5 do
        local groupHeader = self.advisorList:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        groupHeader:SetPoint("TOPLEFT", 10, yOffset)
        groupHeader:SetText("Group " .. i .. ":")
        yOffset = yOffset - 20
        
        for _, p in ipairs(groups[i]) do
            local text = self.advisorList:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            text:SetPoint("TOPLEFT", 30, yOffset)
            local classColor = RAID_CLASS_COLORS[p.class] or { r=1, g=1, b=1 }
            text:SetText(string.format("|cff%02x%02x%02x%s|r (%s)", 
                classColor.r*255, classColor.g*255, classColor.b*255, p.name, p.spec))
            yOffset = yOffset - 15
        end
        yOffset = yOffset - 10
    end
    
    self.advisorList:SetHeight(math.abs(yOffset) + 20)
end

function RaidTools:ApplySuggestions()
    if not self.lastSuggestions then return end
    if not IsInRaid() then
        print("|cffff0000[WowAddonTest] Not in a raid.|r")
        return
    end
    
    print("|cffffff00[WowAddonTest] Applying group assignments...|r")
    for groupIndex, members in ipairs(self.lastSuggestions) do
        for _, p in ipairs(members) do
            local name, rank, subgroup = GetRaidRosterInfo(0) -- We need to find the unit index
            for i = 1, GetNumRaidMembers() do
                local rName, _, rSubgroup = GetRaidRosterInfo(i)
                if rName == p.name and rSubgroup ~= groupIndex then
                    SetRaidSubgroup(i, groupIndex)
                end
            end
        end
    end
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
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    cmd = cmd:lower()
    
    if cmd == "ssc" then
        if arg == "record" then
            addonTable.SSC:ToggleRecording()
        elseif arg == "list" then
            addonTable.SSC:ListSpells()
        elseif arg == "clear" then
            addonTable.SSC:ClearLog()
        else
            print("|cff00ffff[WowAddonTest]|r SSC Commands: record, list, clear")
        end
    elseif cmd == "balance" or cmd == "advisor" then
        addonTable.RaidTools:Toggle()
        if addonTable.RaidTools.frame:IsShown() then
            addonTable.RaidTools.advisorContent:Show()
            addonTable.RaidTools.assignContent:Hide()
        end
    elseif msg == "raid" or msg == "tools" or msg == "" then
        addonTable.RaidTools:Toggle()
    end
end
