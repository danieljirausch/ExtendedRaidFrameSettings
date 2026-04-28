local addonName = "RaidGrowth"
local db
local defaults = { growth = "default" }
local isUpdating = false
local hookedGroups = {}
local initialized = false
local updateTimer

local function ApplyLayout()
    if not db or InCombatLockdown() then return end
    if db.growth ~= "reverse" then return end
    if isUpdating then return end

    local container = CompactRaidFrameContainer
    if not container then return end

    isUpdating = true

    local groups = {}
    for _, child in ipairs({container:GetChildren()}) do
        local name = child:GetName() or ""
        if child:IsShown() and name:find("CompactRaidGroup") then
            table.insert(groups, child)
        end
    end

    table.sort(groups, function(a, b)
        local na = tonumber((a:GetName() or ""):match("%d+$")) or 0
        local nb = tonumber((b:GetName() or ""):match("%d+$")) or 0
        return na < nb
    end)

    local x = 0
    for _, group in ipairs(groups) do
        group:ClearAllPoints()
        group:SetPoint("TOPRIGHT", container, "TOPRIGHT", -x, 0)
        x = x + group:GetWidth()
    end

    isUpdating = false
end

local function TriggerUpdate()
    if not InCombatLockdown() then ApplyLayout() end
    if updateTimer then updateTimer:Cancel() end
    updateTimer = C_Timer.NewTimer(0.15, ApplyLayout)
end

local function HookGroups()
    for i = 1, 8 do
        local g = _G["CompactRaidGroup" .. i]
        if g and not hookedGroups[i] then
            g:HookScript("OnShow", TriggerUpdate)
            g:HookScript("OnHide", TriggerUpdate)
            hookedGroups[i] = true
        end
    end
end

local function ApplyAnchorFix()
    if db.growth ~= "reverse" then return end
    if PartyFrame and PartyFrame.alwaysUseTopLeftAnchor then
        PartyFrame.alwaysUseTopLeftAnchor = false
    end
    if CompactRaidFrameContainer and CompactRaidFrameContainer.alwaysUseTopLeftAnchor then
        CompactRaidFrameContainer.alwaysUseTopLeftAnchor = false
    end
end

local function Initialize()
    if initialized then return end
    initialized = true

    ApplyAnchorFix()

    local panel = CreateFrame("Frame", "RaidGrowthEditModePanel", EditModeSystemSettingsDialog, "TranslucentFrameTemplate")
    panel:SetPoint("TOPLEFT", EditModeSystemSettingsDialog, "BOTTOMLEFT")
    panel:SetPoint("TOPRIGHT", EditModeSystemSettingsDialog, "BOTTOMRIGHT")
    panel:SetHeight(50)
    panel:Hide()

    local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 12, -10)
    cb:SetSize(24, 24)

    local label = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    label:SetText("Reverse growth (right-to-left)")

    cb:SetChecked(db.growth == "reverse")
    cb:SetScript("OnClick", function(self)
        db.growth = self:GetChecked() and "reverse" or "default"
        ApplyAnchorFix()
        TriggerUpdate()
    end)

    hooksecurefunc(EditModeSystemSettingsDialog, "UpdateSettings", function(self)
        local system = self.attachedToSystem
        if system and (system.systemNameString == HUD_EDIT_MODE_RAID_FRAMES_LABEL or
                       system.systemNameString == HUD_EDIT_MODE_PARTY_FRAMES_LABEL) then
            cb:SetChecked(db.growth == "reverse")
            panel:Show()
        else
            panel:Hide()
        end
    end)
end

hooksecurefunc("CompactRaidFrameContainer_UpdateDisplayedUnits", TriggerUpdate)
hooksecurefunc("CompactRaidFrameContainer_LayoutFrames", TriggerUpdate)

if CompactRaidFrameContainer and CompactRaidFrameContainer.Layout then
    hooksecurefunc(CompactRaidFrameContainer, "Layout", TriggerUpdate)
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("PLAYER_REGEN_ENABLED")

f:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        RaidGrowthDB = RaidGrowthDB or CopyTable(defaults)
        db = RaidGrowthDB
    elseif event == "PLAYER_ENTERING_WORLD" then
        Initialize()
        HookGroups()
        TriggerUpdate()
        C_Timer.After(1.5, TriggerUpdate)
    elseif event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_REGEN_ENABLED" then
        HookGroups()
        TriggerUpdate()
    end
end)
