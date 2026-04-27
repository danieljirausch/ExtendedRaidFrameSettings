local function reverseGroupsIfNeeded(self)
    if ExtendedRaidFrameSettings_DB.growth ~= "right" then return end
    if self:GetGroupMode() ~= "discrete" then return end

    local lo, hi
    for i, v in ipairs(self.flowFrames) do
        if type(v) == "table" and v.isFlowGroup then
            if not lo then lo = i end
            hi = i
        end
    end
    if not lo or lo == hi then return end

    while lo < hi do
        self.flowFrames[lo],     self.flowFrames[hi]     = self.flowFrames[hi],     self.flowFrames[lo]
        self.flowFrameTypes[lo], self.flowFrameTypes[hi] = self.flowFrameTypes[hi], self.flowFrameTypes[lo]
        lo, hi = lo + 1, hi - 1
    end
    FlowContainer_DoLayout(self)
end

local function setupDropdown(LibDD, dialog)
    local dropdown = LibDD:Create_UIDropDownMenu("ERFSDropdown", dialog)
    dropdown:SetPoint("TOP", dialog.Label, "BOTTOM", 0, 2)
    LibDD:UIDropDownMenu_SetWidth(dropdown, 110)

    LibDD:UIDropDownMenu_Initialize(dropdown, function(self, level)
        local current = ExtendedRaidFrameSettings_DB.growth
        for _, value in ipairs({"left", "right"}) do
            local label = value:sub(1, 1):upper() .. value:sub(2)
            local info  = LibDD:UIDropDownMenu_CreateInfo()
            info.text    = label
            info.value   = value
            info.checked = (current == value)
            info.func    = function()
                ExtendedRaidFrameSettings_DB.growth = value
                LibDD:UIDropDownMenu_SetText(dropdown, label)
                CompactRaidFrameContainer:TryUpdate()
            end
            LibDD:UIDropDownMenu_AddButton(info, level)
        end
    end)

    LibDD:UIDropDownMenu_SetText(dropdown,
        ExtendedRaidFrameSettings_DB.growth == "right" and "Right" or "Left")
end

local function hookDialogVisibility(dialog)
    hooksecurefunc(EditModeSystemSettingsDialog, "UpdateSettings", function(self)
        local system = self.attachedToSystem
        if system and system.systemNameString == HUD_EDIT_MODE_RAID_FRAMES_LABEL then
            dialog:Show()
        else
            dialog:Hide()
        end
    end)
end

EventUtil.ContinueOnAddOnLoaded("Blizzard_EditMode", function()
    ExtendedRaidFrameSettings_DB = ExtendedRaidFrameSettings_DB or {}
    ExtendedRaidFrameSettings_DB.growth = ExtendedRaidFrameSettings_DB.growth or "right"

    local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")
    local dialog = ExtendedRaidFrameSettingsDialog

    setupDropdown(LibDD, dialog)
    hookDialogVisibility(dialog)
    hooksecurefunc(CompactRaidFrameContainerMixin, "LayoutFrames", reverseGroupsIfNeeded)

    CompactRaidFrameContainer:TryUpdate()
end)
