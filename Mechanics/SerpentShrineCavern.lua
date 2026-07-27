local addonName, addonTable = ...

-- Serpent Shrine Cavern Boss Mechanics
addonTable.SSC = {
    recording = false
}

function addonTable.SSC:LogSpell(spellId, spellName, sourceName)
    if not self.recording then return end
    
    if WatsonDB and WatsonDB.sscLog then
        table.insert(WatsonDB.sscLog, {
            id = spellId,
            name = spellName,
            source = sourceName,
            time = date("%H:%M:%S")
        })
        print(string.format("|cff00ffff[SSC Log]|r %s cast %s (%d)", sourceName or "Unknown", spellName, spellId))
        
        if self.frame and self.frame:IsShown() then
            self:UpdateUI()
        end
    end
end

function addonTable.SSC:CreateUI()
    if self.frame then return end
    
    local f = CreateFrame("Frame", "WatsonSSCFrame", UIParent, "BackdropTemplate")
    f:SetSize(550, 450)
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
    title:SetText("SSC Spell Log")
    
    -- Headers
    local headerTime = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    headerTime:SetPoint("TOPLEFT", 25, -45)
    headerTime:SetText("Time")
    
    local headerSource = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    headerSource:SetPoint("TOPLEFT", 90, -45)
    headerSource:SetText("Caster")
    
    local headerSpell = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    headerSpell:SetPoint("TOPLEFT", 220, -45)
    headerSpell:SetText("Spell")
    
    local headerID = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    headerID:SetPoint("TOPLEFT", 420, -45)
    headerID:SetText("ID")

    -- ScrollFrame
    local sf = CreateFrame("ScrollFrame", "WatsonSSCScrollFrame", f, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 15, -65)
    sf:SetPoint("BOTTOMRIGHT", -35, 45)
    
    local content = CreateFrame("Frame", nil, sf)
    content:SetSize(500, 1)
    sf:SetScrollChild(content)
    self.scrollChild = content

    -- Clear Button
    local clearBtn = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
    clearBtn:SetSize(120, 30)
    clearBtn:SetPoint("BOTTOMLEFT", 20, 15)
    clearBtn:SetText("Clear Log")
    clearBtn:SetScript("OnClick", function()
        self:ClearLog()
        self:UpdateUI()
    end)

    -- Close Button
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)
    
    f:Hide()
    self.frame = f
end

function addonTable.SSC:UpdateUI()
    if not self.frame then return end
    
    local logs = WatsonDB.sscLog or {}
    
    if not self.rows then self.rows = {} end
    
    local yOffset = 0
    for i, log in ipairs(logs) do
        local row = self.rows[i]
        if not row then
            row = CreateFrame("Frame", nil, self.scrollChild)
            row:SetSize(500, 20)
            
            row.time = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.time:SetPoint("LEFT", 10, 0)
            
            row.source = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.source:SetPoint("LEFT", 75, 0)
            
            row.spell = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.spell:SetPoint("LEFT", 205, 0)
            
            row.id = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.id:SetPoint("LEFT", 405, 0)
            
            self.rows[i] = row
        end
        
        row:SetPoint("TOPLEFT", 0, -yOffset)
        row.time:SetText(log.time)
        row.source:SetText(log.source or "Unknown")
        row.spell:SetText(log.name)
        row.id:SetText(log.id)
        row:Show()
        
        yOffset = yOffset + 20
    end
    
    -- Hide unused rows if log was cleared
    for i = #logs + 1, #self.rows do
        if self.rows[i] then
            self.rows[i]:Hide()
        end
    end
    
    self.scrollChild:SetHeight(math.max(yOffset, 1))
end

function addonTable.SSC:ListSpells()
    if not WatsonDB or not WatsonDB.sscLog or #WatsonDB.sscLog == 0 then
        print("|cffff0000[Watson] No spells recorded in SSC.|r")
        -- Even if empty, we might want to show the frame? 
        -- Actually, the user might want to see the empty window.
    end

    self:CreateUI()
    self:UpdateUI()
    self.frame:Show()
end

function addonTable.SSC:ToggleRecording()
    self.recording = not self.recording
    local status = self.recording and "|cff00ff00Enabled|r" or "|cffff0000Disabled|r"
    print("|cff00ffff[Watson]|r SSC Spell Recording: " .. status)
end

function addonTable.SSC:ClearLog()
    if WatsonDB then
        WatsonDB.sscLog = {}
        print("|cff00ffff[Watson]|r SSC Log cleared.")
    end
end