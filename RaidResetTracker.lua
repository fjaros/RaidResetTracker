
-- Only works with Burning Crusade Classic WoW
if WOW_PROJECT_ID ~= WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
	return
end
local VERSION = GetBuildInfo()
local MAJOR, MINOR, PHASE = strsplit(".", VERSION)
MAJOR = tonumber(MAJOR)
MINOR = tonumber(MINOR)
PHASE = tonumber(PHASE)

-- Due to localization, it's easier to keep track of all US/AUS/Oceanic realms
local ALL_US_REALMS = {
	"Anathema","Arcanite Reaper","Arugal","Ashkandi","Atiesh","Azuresong","Benediction","Bigglesworth","Blaumeux","Bloodsail Buccaneers","Deviate Delight","Earthfury","Faerlina","Fairbanks","Felstriker","Grobbulus","Heartseeker","Herod","Incendius","Kirtonos","Kromcrush","Kurinnaxx","Loatheb","Mankrik","Myzrael","Netherwind","Old Blanchy","Pagle","Rattlegore","Remulos","Skeram","Smolderweb","Stalagg","Sulfuras","Sul'thraze","Thalnos","Thunderfury","Westfall","Whitemane","Windseeker","Yojamba"
}
for _, k in ipairs(ALL_US_REALMS) do
	ALL_US_REALMS[k] = true
end

local RESET_TIME_US = 1624374000
local RESET_TIME_EU = RESET_TIME_US + 57600
local RAID_ORDER = {}

local function addResetTime(id)
	table.insert(RAID_ORDER, 1, id)
end

if PHASE >= 1 then
	addResetTime(544) -- Magtheridon's Lair
	addResetTime(565) -- Gruul's Lair
	addResetTime(532) -- Karazhan
end
if PHASE >= 2 then
	addResetTime(548) -- Serpentshrine Cavern
	addResetTime(550) -- Tempest Keep
end
if PHASE >= 3 then
	addResetTime(534) -- The Battle for Mount Hyjal
	addResetTime(564) -- The Black Temple
end
if PHASE >= 4 then
	-- This reset time might need to change once we find out when it is during phase launch
	addResetTime(568) -- Zul'Aman
end
if PHASE >= 5 then
	addResetTime(580) -- The Sunwell
end

local function getStartTime(id)
	if ALL_US_REALMS[GetRealmName()] then
		return RESET_TIME_US
	else
		if id == 568 then
			return RESET_TIME_EU - 86400
		else
			return RESET_TIME_EU
		end
	end
end

local function getFreq(id)
	local freq = id == 568 and 3 or 7
	return freq * 86400
end

local _GetNumSavedInstances = _G.GetNumSavedInstances
local _GetSavedInstanceInfo = _G.GetSavedInstanceInfo
local resetState

_G.GetNumSavedInstances = function()
	resetState = {unpack(RAID_ORDER)}
	local unsavedRaids = #resetState
	local numRealSavedInstances = _GetNumSavedInstances()
	for i = 1, numRealSavedInstances do
		local name = _GetSavedInstanceInfo(i)
		for _, v in ipairs(resetState) do
			if GetRealZoneText(v) == name then
				unsavedRaids = unsavedRaids - 1
				break
			end
		end
	end
	return unsavedRaids + numRealSavedInstances
end

_G.GetSavedInstanceInfo = function(index)
	if index <= _GetNumSavedInstances() then
		local name = _GetSavedInstanceInfo(index)
		for i, v in ipairs(resetState) do
			if GetRealZoneText(v) == name then
				table.remove(resetState, i)
				break
			end
		end
		return _GetSavedInstanceInfo(index)
	end

	local id = resetState[index - _GetNumSavedInstances()]
	if not id then
		return _GetSavedInstanceInfo(index)
	end
	local epoch = GetServerTime()
	local startTime = getStartTime(id)
	local freq = getFreq(id)
	local nextResetCoef = math.ceil((epoch - startTime) / freq)
	local resetTime = startTime + (freq * nextResetCoef) - epoch
	return GetRealZoneText(id), "NOT SAVED", resetTime, 0, false, false, 0, true
end
