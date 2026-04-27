ERFSConfig = ERFSConfig or {}
if ERFSConfig.reverseOrder == nil then ERFSConfig.reverseOrder = false end

EventUtil.ContinueOnAddOnLoaded("Blizzard_CompactRaidFrames", function()
    local origAddGroups = CompactRaidFrameContainerMixin.AddGroups
    local reversedGroups = {}
    function CompactRaidFrameContainerMixin:AddGroups()
        if not ERFSConfig.reverseOrder then return origAddGroups(self) end
        RaidUtil_GetUsedGroups(reversedGroups)
        for groupNum = MAX_RAID_GROUPS, 1, -1 do
            if reversedGroups[groupNum] and self.groupFilterFunc(groupNum) then
                self:AddGroup(groupNum)
            end
        end
        FlowContainer_DoLayout(self)
    end

    local origSetFlowSortFunction = CompactRaidFrameContainerMixin.SetFlowSortFunction
    function CompactRaidFrameContainerMixin:SetFlowSortFunction(sortFunc)
        origSetFlowSortFunction(self, function(t1, t2)
            if ERFSConfig.reverseOrder then return sortFunc(t2, t1) end
            return sortFunc(t1, t2)
        end)
    end
end)

EventUtil.ContinueOnAddOnLoaded("Blizzard_EditMode", function()
    local checkbox = ERFSReverseOrderSetting

    checkbox.Button:SetScript("OnClick", function(btn)
        ERFSConfig.reverseOrder = btn:GetChecked()
        CompactRaidFrameContainer:TryUpdate()
    end)

    hooksecurefunc(EditModeSystemSettingsDialogMixin, "UpdateSettings", function(self)
        local isRaid = self.attachedToSystem
            and self.attachedToSystem.system == Enum.EditModeSystem.UnitFrame
            and self.attachedToSystem.systemIndex == Enum.EditModeUnitFrameSystemIndices.Raid

        if not isRaid then
            checkbox:Hide()
            return
        end

        checkbox:SetParent(self.Settings)
        checkbox:SetPoint("TOPLEFT")
        checkbox.layoutIndex = 1000
        checkbox.Button:SetChecked(ERFSConfig.reverseOrder)
        checkbox:Show()
        self.Settings:Layout()
    end)
end)
