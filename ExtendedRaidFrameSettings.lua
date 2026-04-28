-- Spell ID and hex color to highlight when the buff is active on a raid member
local SPELL_ID = 119611  -- Renewing Mist (HoT)
local HEX_COLOR = "16a34a"

local r = tonumber(HEX_COLOR:sub(1, 2), 16) / 255
local g = tonumber(HEX_COLOR:sub(3, 4), 16) / 255
local b = tonumber(HEX_COLOR:sub(5, 6), 16) / 255

local function UnitHasBuff(unit, spellID)
    local i = 1
    while true do
        local aura = C_UnitAuras.GetBuffDataByIndex(unit, i)
        if not aura then break end
        if aura.spellId == spellID then return true end
        i = i + 1
    end
    return false
end

EventUtil.ContinueOnAddOnLoaded("Blizzard_CompactRaidFrames", function()
    hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame)
        if not frame.unit then return end
        if not UnitHasBuff(frame.unit, SPELL_ID) then return end
        frame.healthBar:SetStatusBarColor(r, g, b)
    end)

    -- UNIT_AURA doesn't trigger UpdateHealthColor normally, so re-trigger per frame
    hooksecurefunc("CompactUnitFrame_RegisterEvents", function(frame)
        frame:HookScript("OnEvent", function(self, event, arg1)
            if event ~= "UNIT_AURA" then return end
            if arg1 == self.unit or arg1 == self.displayedUnit then
                CompactUnitFrame_UpdateHealthColor(self)
            end
        end)
    end)
end)
