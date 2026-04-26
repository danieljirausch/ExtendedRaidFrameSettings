local addonName, ns = ...
local LibUIDropDownMenu = LibStub("LibUIDropDownMenu-4.0")

local ERFS = {
    refreshQueued = false,
    raidLayoutPending = false,
    partyLayoutPending = false,
}

local DEFAULTS = {
    version = 1,
    growth = "right",
}

local GROWTH_OPTIONS = { "right", "left" }

local GROWTH_LABELS = {
    right = "Right",
    left = "Left",
}

local function InitializeSavedVariables()
    if not ExtendedRaidFrameSettings_DB then
        ExtendedRaidFrameSettings_DB = {}
    end
    for k, v in pairs(DEFAULTS) do
        if ExtendedRaidFrameSettings_DB[k] == nil then
            ExtendedRaidFrameSettings_DB[k] = v
        end
    end
end

local function UpdateClampInsets()
    if InCombatLockdown() then
        ERFS.refreshQueued = true
        return
    end

    local container = CompactRaidFrameContainer
    local width = container:GetWidth()

    if ExtendedRaidFrameSettings_DB.growth == "left" then
        container:SetClampRectInsets(width, 0, 10, 0)
    else
        container:SetClampRectInsets(0, -width, 10, 0)
    end
end

local function MirrorFrameX(frame, containerWidth)
    local numPoints = frame:GetNumPoints()
    if numPoints == 0 then return end

    for i = numPoints, 1, -1 do
        local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint(i)
        local w = frame:GetWidth()
        local newX = containerWidth - xOfs - w
        frame:SetPoint(point, relativeTo, relativePoint, newX, yOfs)
    end
end

local function ApplyRaidMirror()
    UpdateClampInsets()
    if ExtendedRaidFrameSettings_DB.growth == "right" then return end
    if InCombatLockdown() then
        ERFS.refreshQueued = true
        return
    end

    local container = CompactRaidFrameContainer
    local W = container:GetWidth()

    for i = 1, #container.flowFrames do
        local frame = container.flowFrames[i]
        if type(frame) == "table" and frame.GetPoint and frame:IsShown() then
            MirrorFrameX(frame, W)
        end
    end
end

local function ApplyPartyMirror()
    if ExtendedRaidFrameSettings_DB.growth == "right" then return end
    if InCombatLockdown() then
        ERFS.refreshQueued = true
        return
    end

    local container = PartyFrame
    local W = container:GetWidth()

    for memberFrame in container.PartyMemberFramePool:EnumerateActive() do
        if memberFrame:IsShown() then
            MirrorFrameX(memberFrame, W)
        end
    end
end

local function ReverseRaidLayout()
    if ERFS.raidLayoutPending then return end
    ERFS.raidLayoutPending = true
    C_Timer.After(0, function()
        if not ERFS.raidLayoutPending then return end
        ERFS.raidLayoutPending = false
        ApplyRaidMirror()
    end)
end

local function ReversePartyLayout()
    if ERFS.partyLayoutPending then return end
    ERFS.partyLayoutPending = true
    C_Timer.After(0, function()
        if not ERFS.partyLayoutPending then return end
        ERFS.partyLayoutPending = false
        ApplyPartyMirror()
    end)
end

local function ReverseAllLayouts()
    ERFS.raidLayoutPending = false
    ERFS.partyLayoutPending = false
    ApplyRaidMirror()
    ApplyPartyMirror()
end

local function OnGrowthSelected(_, value)
    if value == ExtendedRaidFrameSettings_DB.growth then return end

    ExtendedRaidFrameSettings_DB.growth = value
    LibUIDropDownMenu:UIDropDownMenu_SetText(
        ExtendedRaidFrameSettingsDialog.Settings.GrowthDropdown.Dropdown,
        GROWTH_LABELS[value]
    )

    if InCombatLockdown() then
        ERFS.refreshQueued = true
        return
    end

    ReverseAllLayouts()
end

local function BuildGrowthDropdown()
    local info = {
        func = OnGrowthSelected,
    }

    for _, value in ipairs(GROWTH_OPTIONS) do
        info.text = GROWTH_LABELS[value]
        info.arg1 = value
        info.checked = (value == ExtendedRaidFrameSettings_DB.growth)
        LibUIDropDownMenu:UIDropDownMenu_AddButton(info)
    end
end

local function InitializeDropdown()
    local frame = ExtendedRaidFrameSettingsDialog.Settings.GrowthDropdown
    frame:SetPoint("TOPLEFT")
    frame.layoutIndex = 0
    frame.Label:SetText("Growth")

    local width = frame.Dropdown:GetWidth() - 20
    LibUIDropDownMenu:Create_UIDropDownMenu(frame.Dropdown)
    LibUIDropDownMenu:UIDropDownMenu_Initialize(frame.Dropdown, BuildGrowthDropdown)
    LibUIDropDownMenu:UIDropDownMenu_SetWidth(frame.Dropdown, width, 0)
    LibUIDropDownMenu:UIDropDownMenu_JustifyText(frame.Dropdown, "LEFT", 32)
    LibUIDropDownMenu:UIDropDownMenu_SetText(
        frame.Dropdown,
        GROWTH_LABELS[ExtendedRaidFrameSettings_DB.growth]
    )
end

local function OnEditModeSelectionChanged(self)
    local system = self.attachedToSystem
    if not system then return end

    if system.systemNameString == HUD_EDIT_MODE_RAID_FRAMES_LABEL
        or system.systemNameString == HUD_EDIT_MODE_PARTY_FRAMES_LABEL then
        ExtendedRaidFrameSettingsDialog:Show()
    else
        ExtendedRaidFrameSettingsDialog:Hide()
    end
end

local function OnCombatEnd()
    if ERFS.refreshQueued and not InCombatLockdown() then
        ERFS.refreshQueued = false
        ReverseAllLayouts()
    end
end

EventUtil.ContinueOnAddOnLoaded("Blizzard_CompactRaidFrames", function()
    if CompactRaidFrameContainer.alwaysUseTopLeftAnchor ~= nil then
        CompactRaidFrameContainer.alwaysUseTopLeftAnchor = false
    end
end)

EventUtil.ContinueOnAddOnLoaded("Blizzard_UnitFrame", function()
    if PartyFrame.alwaysUseTopLeftAnchor ~= nil then
        PartyFrame.alwaysUseTopLeftAnchor = false
    end
end)

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent(event)

        InitializeSavedVariables()
        UpdateClampInsets()
        InitializeDropdown()

        hooksecurefunc(EditModeSystemSettingsDialog, "UpdateSettings", OnEditModeSelectionChanged)
        hooksecurefunc(CompactRaidFrameContainer, "Layout", ReverseRaidLayout)
        hooksecurefunc(PartyFrame, "Layout", ReversePartyLayout)

        self:RegisterEvent("PLAYER_REGEN_ENABLED")
    else
        OnCombatEnd()
    end
end)
