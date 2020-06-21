
local VERSION = GetBuildInfo()
local MAJOR, MINOR, PHASE = strsplit(".", VERSION)
MAJOR = tonumber(MAJOR)
MINOR = tonumber(MINOR)
PHASE = tonumber(PHASE)
-- Only works with Classic WoW
if MAJOR ~= 1 or MINOR ~= 13 then
	return
end

-- Due to localization, it's easier to keep track of all US/AUS/Oceanic realms
local ALL_US_REALMS = {
	"Anathema","Arcanite Reaper","Arugal","Ashkandi","Atiesh","Azuresong","Benediction","Bigglesworth","Blaumeux","Bloodsail Buccaneers","Deviate Delight","Earthfury","Faerlina","Fairbanks","Felstriker","Grobbulus","Heartseeker","Herod","Incendius","Kirtonos","Kromcrush","Kurinaxx","Kurinnaxx","Loatheb","Mankrik","Myzrael","Netherwind","Old Blanchy","Pagle","Rattlegore","Remulos","Skeram","Smolderweb","Stalagg","Sulfuras","Sul'thraze","Thalnos","Thunderfury","Westfall","Whitemane","Windseeker","Yojamba"
}
for _, k in ipairs(ALL_US_REALMS) do
	ALL_US_REALMS[k] = true
end

local RESET_TIMES = {}
local RAID_ORDER = {}
if PHASE >= 1 then
	RESET_TIMES[409] = { -- MC
		start_us = 1592323200,
		start_eu = 1592377200,
		freq = 86400 * 7,
	}
	RESET_TIMES[249] = { -- Onyxia
		start_us = 1592496000,
		start_eu = 1592377200,
		freq = 86400 * 5,
	}
	table.insert(RAID_ORDER, 409)
	table.insert(RAID_ORDER, 249)
end
if PHASE >= 3 then
	RESET_TIMES[469] = { -- BWL
		start_us = 1592323200,
		start_eu = 1592377200,
		freq = 86400 * 7,
	}
	table.insert(RAID_ORDER, 1, 469)
end
if PHASE >= 4 then
	RESET_TIMES[309] = { -- ZG
		start_us = 1592496000,
		start_eu = 1592722800,
		freq = 86400 * 3,
	}
	table.insert(RAID_ORDER, 309)
end
if PHASE >= 5 then
	RESET_TIMES[531] = { -- AQ40
		start_us = 1592323200,
		start_eu = 1592377200,
		freq = 86400 * 7,
	}
	RESET_TIMES[509] = { -- AQ20
		start_us = 1592496000,
		start_eu = 1592722800,
		freq = 86400 * 3,
	}
	table.insert(RAID_ORDER, 1, 531)
	table.insert(RAID_ORDER, #RAID_ORDER - 1, 509)
end
if PHASE >= 6 then
	RESET_TIMES[533] = { -- Naxx
		start_us = 1592323200,
		start_eu = 1592377200,
		freq = 86400 * 7,
	}
	table.insert(RAID_ORDER, 1, 533)
end

local lockState = {unpack(RAID_ORDER)}
local _GetNumSavedInstances = _G.GetNumSavedInstances
_G.GetNumSavedInstances = function()
	lockState = {unpack(RAID_ORDER)}
	return #lockState
end

local _GetSavedInstanceInfo = _G.GetSavedInstanceInfo
_G.GetSavedInstanceInfo = function(index)
	if index <= _GetNumSavedInstances() then
		local name = _GetSavedInstanceInfo(index)
		for i, v in ipairs(lockState) do
			if GetRealZoneText(v) == name then
				table.remove(lockState, i)
				break
			end
		end
		return _GetSavedInstanceInfo(index)
	end

	local id = lockState[index - _GetNumSavedInstances()]
	local epoch = GetServerTime()
	local startTime = ALL_US_REALMS[GetRealmName()] and RESET_TIMES[id].start_us or RESET_TIMES[id].start_eu
	local freq = RESET_TIMES[id].freq
	local nextResetCoef = math.ceil((epoch - startTime) / freq)
	local resetTime = startTime + (freq * nextResetCoef) - epoch
	return GetRealZoneText(id), "NOT SAVED", resetTime, 0, false, false, 0, true
end
