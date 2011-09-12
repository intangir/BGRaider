-- my Ace3 Addon object
BGRaider = LibStub("AceAddon-3.0"):NewAddon("BGRaider", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0");
local addon = BGRaider;
local AceGUI = LibStub("AceGUI-3.0");
local db = nil;
local addonQueued = nil;
local lastBGStatus = "";
-- EVENT HANDLERS --

function addon:OnInitialize()
    -- pre-alpha for private testing only
    --local guildName = GetGuildInfo("player");
    --if(guildName ~= "The Returners") then return end;

    self.db = LibStub("AceDB-3.0"):New("BGRaiderDB");
    db = self.db.profile;
    -- BG Raider Button
    addon.guiButton = CreateFrame("Button", nil, PVPHonorFrame, "OptionsButtonTemplate");
    addon.guiButton:SetPoint("BOTTOMRIGHT", 0, 0);
    addon.guiButton:SetSize(108,22);
    addon.guiButton:SetText("BG Raider");
    addon.guiButton:SetScript("OnClick", function() BGRaider:OpenGui() end);
    if(db.ready) then addon.guiButton:Enable(db.ready) else addon.guiButton:Disable(db.ready) end

    -- Ready Check Button
    addon.readyButton = CreateFrame("CheckButton", "BGRReadyCheck", PVPHonorFrame, "UICheckButtonTemplate");
    addon.readyButton:SetPoint("BOTTOMRIGHT", -140, 0);
    addon.readyButton:SetSize(22,22);
    addon.readyButton.tooltip = "Toggle your availablity status";
    BGRReadyCheckText:SetText("Ready");
    addon.readyButton:SetScript("OnClick", function() BGRaider:ToggleReady() end);
    addon.readyButton:SetChecked(db.ready);

    -- register all commands and events
    addon:RegisterChatCommand("bgr", "OnChatCommand");
    addon:RegisterChatCommand("bgraider", "OnChatCommand");

    addon:RegisterEvent("UPDATE_BATTLEFIELD_STATUS", OnBattlefieldStatus);

    addon:RegisterComm("BGR_STATUS","OnCommStatus");
    addon:RegisterComm("BGR_REQUEST","OnCommRequest");
end

function OnBattlefieldStatus(msg)
    if(not addonQueued) then return end;
    local msg;
    local status = GetBattlefieldStatus(1);
    if(lastBGStatus ~= status) then
        lastBGStatus = status;
        if(status == "queued") then
            msg = "QUEUED";
        elseif(status == "confirm") then
            msg = "CONFIRM";
            addonQueued = nil;
        else
            addonQueued = nil;
            return;
        end
        if(GetRealNumPartyMembers() > 0) then
            msg = msg .. " +" .. GetRealNumPartyMembers();
        end
        addon:SendCommMessage("BGR_STATUS", msg, "GUILD");
    end
end

-- ADDON COMM HANDLERS -- 

function addon:OnCommStatus(prefix, message, distribution, sender)
    addon:Print(date("[%H:%M:%S] ") .. sender .. " sent status " .. message);
end

function addon:OnCommRequest(prefix, message, distribution, sender)
    addon:Print(date("[%H:%M:%S] ") .. sender .. " sent request " .. message);
    local command, args = strsplit(" ", message, 2);
    if(command == "STATUS") then
        addon:SendCommMessage("BGR_STATUS", "READY", distribution, sender);
    elseif(command == "QUEUE") then
        local level, scroll, button = strsplit(" ", args);
        addon:QueueForBG(level, scroll, button);
    end
end

-- /script BGRaider:SendCommMessage("BGR_REQUEST", "QUEUE 85 0 3", "GUILD");

-- COMMAND HANDLERS --

function addon:OnChatCommand(input)
    if(input == "status") then
        addon:SendStatusRequest();
    elseif(input == "ready") then
        addon.readyButton:SetChecked(not db.ready);
        addon:ToggleReady(true);
    end
end

-- ADDON METHODS --

function addon:SendStatusRequest()
    addon:SendCommMessage("BGR_REQUEST", "STATUS", "GUILD");
end

function addon:QueueForBG(level, scroll, button)
    if(not db.ready) then
        addon:Print("Queue Request ignored: Not Ready (type /bgr ready)");
    elseif(level ~= ""..UnitLevel("player")) then
        addon:Print("Queue Request ignored: Wrong Level");
    elseif(GetRealNumPartyMembers() > 0 and not UnitIsPartyLeader("player")) then
        addon:Print("Queue Request ignored: Not Party Leader");
    else
        PVPHonorFrameTypeScrollFrame:SetVerticalScroll(scroll);
        PVPHonor_ButtonClicked(_G["PVPHonorFrameBgButton" .. button]);
        JoinBattlefield(1, UnitIsPartyLeader("player"));
        addonQueued = true;
    end
end

function addon:OpenGui()
    -- later this will open the gui, but for now it will send a queue request immediately
    local level = UnitLevel("player");
    local scroll = strsplit(".", PVPHonorFrameTypeScrollFrame:GetVerticalScroll());
    local button = PVPHonorFrame.selectedButtonIndex;
    addon:SendCommMessage("BGR_REQUEST", "QUEUE "..level.." "..scroll.." "..button, "GUILD");
end

function addon:ToggleReady(verbose)
    db.ready = BGRReadyCheck:GetChecked();
    if(db.ready) then addon.guiButton:Enable(db.ready) else addon.guiButton:Disable(db.ready) end
    if(verbose) then
        addon:Print(db.ready and "Ready" or "Not Ready");
    end
end

