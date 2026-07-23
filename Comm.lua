local addonName, addonTable = ...

local Comm = {
    prefix = "WOWADDONTEST",
    users = {} -- Tracks players with the addon
}
addonTable.Comm = Comm

function Comm:Initialize()
    C_ChatInfo.RegisterAddonMessagePrefix(self.prefix)
    
    local f = CreateFrame("Frame")
    f:RegisterEvent("CHAT_MSG_ADDON")
    f:RegisterEvent("GROUP_ROSTER_UPDATE")
    f:SetScript("OnEvent", function(_, event, ...)
        if event == "CHAT_MSG_ADDON" then
            self:OnMessageReceived(...)
        elseif event == "GROUP_ROSTER_UPDATE" then
            self:SendPing()
        end
    end)
    
    self:SendPing()
end

function Comm:SendPing()
    if IsInGroup() then
        C_ChatInfo.SendAddonMessage(self.prefix, "PING", IsInRaid() and "RAID" or "PARTY")
    end
end

function Comm:OnMessageReceived(prefix, message, channel, sender)
    if prefix ~= self.prefix then return end
    
    local name = Ambiguate(sender, "none")
    
    if message == "PING" then
        self.users[name] = true
        C_ChatInfo.SendAddonMessage(self.prefix, "PONG", channel)
    elseif message == "PONG" then
        self.users[name] = true
    elseif message:find("^ASSIGN:") then
        self:HandleAssignment(message:sub(8), name)
    end
end

function Comm:HandleAssignment(data, sender)
    -- Format: ASSIGN:Type:Target:Player
    -- Example: ASSIGN:TANK:Skull:MainTank
    local msg = "|cffffff00[WowAddonTest] Assignment from " .. sender .. ":|r " .. data:gsub(":", " -> ")
    RaidNotice_AddMessage(RaidWarningFrame, msg, ChatTypeInfo["RAID_WARNING"])
    print(msg)
end

function Comm:BroadcastAssignment(assignType, target, player)
    local message = string.format("ASSIGN:%s:%s:%s", assignType, target, player)
    
    -- 1. Send to addon users via hidden channel
    if IsInGroup() then
        C_ChatInfo.SendAddonMessage(self.prefix, message, IsInRaid() and "RAID" or "PARTY")
    end
    
    -- 2. Fallback: If player doesn't have the addon, whisper them
    if player and player ~= "" and player ~= UnitName("player") then
        if not self.users[player] then
            local whisperMsg = string.format("[WowAddonTest] Your assignment: %s for %s", assignType, target)
            SendChatMessage(whisperMsg, "WHISPER", nil, player)
        end
    end
end
