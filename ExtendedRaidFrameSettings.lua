local SPELL_ID = 119611  -- Renewing Mist (HoT)
local HEX_COLOR = "16a34a"

local active = {} -- [auraInstanceID] = true if it's our Renewing Mist
local r = tonumber(HEX_COLOR:sub(1, 2), 16) / 255
local g = tonumber(HEX_COLOR:sub(3, 4), 16) / 255
local b = tonumber(HEX_COLOR:sub(5, 6), 16) / 255


--     -- GAIN
--     if updateInfo.addedAuraInstanceIDs then
--         for _, id in ipairs(updateInfo.addedAuraInstanceIDs) do
--             local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, id)
--             if aura and aura.spellId == SPELL_ID and aura.sourceUnit == "player" then
--                 active[id] = true
--                 print(unit .. " gained Renewing Mist")
--             end
--         end
--     end

--     -- FADE
--     if updateInfo.removedAuraInstanceIDs then
--         for _, id in ipairs(updateInfo.removedAuraInstanceIDs) do
--             if active[id] then
--                 active[id] = nil
--                 print(unit .. " lost Renewing Mist")
--             end
--         end
--     end
-- end)

local function OnEvent(self, event, unit, info)
    if not info then return end

	if info.isFullUpdate then
		print("full update") -- loop over all auras, etc
		return
	end

	if info.addedAuras then
		local text = {}
		for _, aura in pairs(info.addedAuras) do
			tinsert(text, format("%d(%s)", aura.auraInstanceID, aura.name))
		end
		print(unit, "|cnGREEN_FONT_COLOR:added|r", table.concat(text, ", "))
	end

	if info.removedAuraInstanceIDs then
		local text = {}
		for _, aura in pairs(info.removedAuraInstanceIDs) do
			tinsert(text, aura)
		end
		print(unit, "|cnRED_FONT_COLOR:removed|r", table.concat(text, ", "))
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("UNIT_AURA")
f:SetScript("OnEvent", OnEvent)