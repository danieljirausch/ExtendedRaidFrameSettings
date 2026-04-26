local addonName, ns = ...
local LibUIDropDownMenu = LibStub("LibUIDropDownMenu-4.0")

local ERFS = {
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

-- aliased after InitializeSavedVariables so all functions use DB instead of the long global
local DB

local function InitializeSavedVariables()
    if not ExtendedRaidFrameSettings_DB then
        ExtendedRaidFrameSettings_DB = {}
    end
    for k, v in pairs(DEFAULTS) do
        if ExtendedRaidFrameSettings_DB[k] == nil then
            ExtendedRaidFrameSettings_DB[k] = v
        end
    end
    DB = ExtendedRaidFrameSettings_DB
end

local function UpdateClampInsets(growth)
    local container = CompactRaidFrameContainer
    local width = container:GetWidth()

    if growth == "left" then
        container:SetClampRectInsets(width, 0, 10, 0)
    else
        container:SetClampRectInsets(0, -width, 10, 0)
    end
end

-- sets a frame's X anchor to its left-growth position within containerWidth
local function SetFrameLeftGrowth(frame, containerWidth)
    local numPoints = frame:GetNumPoints()
    if numPoints == 0 then return end

    for i = numPoints, 1, -1 do
        local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint(i)
        local w = frame:GetWidth()
        local newX = containerWidth - xOfs - w
        frame:SetPoint(point, relativeTo, relativePoint, newX, yOfs)
    end
end

-- called after Layout() has reset frames to natural positions
local function ApplyRaidGrowth(growth)
    UpdateClampInsets(growth)
    if growth ~= "left" then return end

    local container = CompactRaidFrameContainer
    local W = container:GetWidth()

    for i = 1, #container.flowFrames do
        local frame = container.flowFrames[i]
        if type(frame) == "table" and frame.GetPoint and frame:IsShown() then
            SetFrameLeftGrowth(frame, W)
        end
    end
end

-- called after Layout() has reset frames to natural positions
local function ApplyPartyGrowth(growth)
    if growth ~= "left" then return end

    local container = PartyFrame
    local W = container:GetWidth()

    for memberFrame in container.PartyMemberFramePool:EnumerateActive() do
        if memberFrame:IsShown() then
            SetFrameLeftGrowth(memberFrame, W)
        end
    end
end

local function OnRaidLayout()
    if ERFS.raidLayoutPending then return end
    ERFS.raidLayoutPending = true
    C_Timer.After(0, function()
        if not ERFS.raidLayoutPending then return end
        ERFS.raidLayoutPending = false
        if InCombatLockdown() then return end
        ApplyRaidGrowth(DB.growth)
    end)
end

local function OnPartyLayout()
    if ERFS.partyLayoutPending then return end
    ERFS.partyLayoutPending = true
    C_Timer.After(0, function()
        if not ERFS.partyLayoutPending then return end
        ERFS.partyLayoutPending = false
        if InCombatLockdown() then return end
        ApplyPartyGrowth(DB.growth)
    end)
end

local function OnGrowthSelected(_, value)
    if value == DB.growth then return end

    DB.growth = value
    LibUIDropDownMenu:UIDropDownMenu_SetText(
        ExtendedRaidFrameSettingsDialog.Settings.GrowthDropdown.Dropdown,
        GROWTH_LABELS[value]
    )

    if InCombatLockdown() then return end

    CompactRaidFrameContainer:Layout()
    PartyFrame:Layout()
end

local function BuildGrowthDropdown()
    local info = {
        func = OnGrowthSelected,
    }

    for _, value in ipairs(GROWTH_OPTIONS) do
        info.text = GROWTH_LABELS[value]
        info.arg1 = value
        info.checked = (value == DB.growth)
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
        GROWTH_LABELS[DB.growth]
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
    CompactRaidFrameContainer:Layout()
    PartyFrame:Layout()
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
        InitializeDropdown()

        hooksecurefunc(EditModeSystemSettingsDialog, "UpdateSettings", OnEditModeSelectionChanged)
        hooksecurefunc(CompactRaidFrameContainer, "Layout", OnRaidLayout)
        hooksecurefunc(PartyFrame, "Layout", OnPartyLayout)

        -- frames are in natural state at login; apply growth direction once
        ApplyRaidGrowth(DB.growth)
        ApplyPartyGrowth(DB.growth)

        self:RegisterEvent("PLAYER_REGEN_ENABLED")
    else
        OnCombatEnd()
    end
end)
