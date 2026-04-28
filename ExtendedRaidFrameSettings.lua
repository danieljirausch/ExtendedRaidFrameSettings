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

    -- HookScript on Blizzard frames taints their entire script chain, causing
    -- CompactUnitFrame_UpdateHealthColor to run tainted (GetStatusBarColor returns
    -- secret values that can't be compared). Use a dedicated listener instead.
    local trackedFrames = setmetatable({}, {__mode = "k"})

    hooksecurefunc("CompactUnitFrame_RegisterEvents", function(frame)
        trackedFrames[frame] = true
    end)

    local unitAuraListener = CreateFrame("Frame")
    unitAuraListener:RegisterEvent("UNIT_AURA")
    unitAuraListener:SetScript("OnEvent", function(self, event, unit)
        for frame in pairs(trackedFrames) do
            if frame.unit == unit or frame.displayedUnit == unit then
                if frame.unit and UnitHasBuff(frame.unit, SPELL_ID) then
                    frame.healthBar:SetStatusBarColor(r, g, b)
                else
                    CompactUnitFrame_SetHealthDirty(frame)
                end
            end
        end
    end)
end)
