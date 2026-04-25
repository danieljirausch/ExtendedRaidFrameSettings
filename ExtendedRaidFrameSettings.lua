local addonName, ns = ...
local LibUIDropDownMenu = LibStub("LibUIDropDownMenu-4.0")

local ERFS = {
    isReversing = false,
    refreshQueued = false,
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

local function CheckCombatLockdown()
    if InCombatLockdown() then
        if not ERFS.refreshQueued then
            print("ExtendedRaidFrameSettings: Your settings will be applied when you leave combat.")
            ERFS.refreshQueued = true
        end
        return true
    end
    return false
end

local function MirrorFrameX(frame, containerWidth)
    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint(1)
    if not point then return end

    local w = frame:GetWidth()
    local newX = containerWidth - xOfs - w

    frame:ClearAllPoints()
    frame:SetPoint(point, relativeTo, relativePoint, newX, yOfs)
end

local function ReverseRaidLayout()
    if ERFS.isReversing then return end
    if ExtendedRaidFrameSettings_DB.growth == "right" then return end
    if CheckCombatLockdown() then return end

    ERFS.isReversing = true

    local container = CompactRaidFrameContainer
    local W = container:GetWidth()

    for i = 1, #container.flowFrames do
        local frame = container.flowFrames[i]
        if type(frame) == "table" and frame.GetPoint and frame:IsShown() then
            MirrorFrameX(frame, W)
        end
    end

    ERFS.isReversing = false
end

local function ReversePartyLayout()
    if ERFS.isReversing then return end
    if ExtendedRaidFrameSettings_DB.growth == "right" then return end
    if CheckCombatLockdown() then return end

    ERFS.isReversing = true

    local container = PartyFrame
    local W = container:GetWidth()

    for memberFrame in container.PartyMemberFramePool:EnumerateActive() do
        if memberFrame:IsShown() then
            MirrorFrameX(memberFrame, W)
        end
    end

    ERFS.isReversing = false
end

local function ReverseAllLayouts()
    ReverseRaidLayout()
    ReversePartyLayout()
end

local function OnGrowthSelected(_, value)
    if value == ExtendedRaidFrameSettings_DB.growth then return end

    ExtendedRaidFrameSettings_DB.growth = value
    LibUIDropDownMenu:UIDropDownMenu_SetText(
        ExtendedRaidFrameSettingsDialog.Settings.GrowthDropdown.Dropdown,
        GROWTH_LABELS[value]
    )

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

local function DisableTopLeftAnchorLock()
    for _, container in ipairs({ CompactRaidFrameContainer, PartyFrame }) do
        if container.alwaysUseTopLeftAnchor ~= nil then
            container.alwaysUseTopLeftAnchor = false
        end
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent(event)

        InitializeSavedVariables()
        DisableTopLeftAnchorLock()
        InitializeDropdown()

        hooksecurefunc(EditModeSystemSettingsDialog, "UpdateSettings", OnEditModeSelectionChanged)
        hooksecurefunc(CompactRaidFrameContainer, "Layout", ReverseRaidLayout)
        hooksecurefunc(PartyFrame, "Layout", ReversePartyLayout)

        self:RegisterEvent("PLAYER_REGEN_ENABLED")
    else
        OnCombatEnd()
    end
end)
