
-- Only works with Classic WoW
if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
	return
end

local RESET_TIME_US = 1744124400
local RESET_TIME_EU = RESET_TIME_US + 57600
local NAME_ID_MAP = {
	["Onyxia's Lair"] = 249,
	["Zul'Gurub"] = 309,
	["Molten Core"] = 409,
	["Blackwing Lair"] = 469,
	["Ruins of Ahn'Qiraj"] = 509,
	["Ahn'Qiraj Temple"] = 531,
	["Naxxramas"] = 533,
}
local RAID_ORDER = {}
local SAVED_INSTANCES = {}

local function addResetTime(id)
	table.insert(RAID_ORDER, id)
end

addResetTime(249) -- Onyxia's Lair
addResetTime(309) -- Zul'Gurub
addResetTime(409) -- Molten Core
addResetTime(469) -- Blackwing Lair
addResetTime(509) -- Ruins of Ahn'Qiraj
addResetTime(531) -- Ahn'Qiraj Temple
addResetTime(533) -- Naxxramas

local function is20(id)
	return id == 309 or id == 509
end

local function getStartTime(id)
	local reset
	if GetCurrentRegion() == 1 then
		reset = RESET_TIME_US
	else
		reset = RESET_TIME_EU
	end
	if is20(id) then
		reset = reset + 3600
	end
	return reset
end

local function getFreq(id)
	local freq
	if is20(id) then
		freq = 3
	elseif id == 249 then
		freq = 5
	else
		freq = 7
	end
	return freq * 86400
end

local _GetNumSavedInstances = _G.GetNumSavedInstances
local _GetSavedInstanceInfo = _G.GetSavedInstanceInfo

_G.GetNumSavedInstances = function()
	SAVED_INSTANCES = {}
	for i = 1, _GetNumSavedInstances() do
		local name = _GetSavedInstanceInfo(i)
		SAVED_INSTANCES[NAME_ID_MAP[name]] = i
	end
	return #RAID_ORDER
end

_G.GetSavedInstanceInfo = function(index)
	local id = RAID_ORDER[index]
	if SAVED_INSTANCES[id] then
		return _GetSavedInstanceInfo(SAVED_INSTANCES[id])
	end

	local epoch = GetServerTime()
	local startTime = getStartTime(id)
	local freq = getFreq(id)
	local nextResetCoef = math.ceil((epoch - startTime) / freq)
	local resetTime = startTime + (freq * nextResetCoef) - epoch

	local difficultyId
	local maxPlayers
	if is20(id) then
		difficultyId = 148
		maxPlayers = 20
	else
		difficultyId = 9
		maxPlayers = 40
	end
	local difficultyName = GetDifficultyInfo(difficultyId)

	return GetRealZoneText(id), "NOT SAVED", resetTime, difficultyId, false, false, 0, true, maxPlayers, difficultyName, 0, 0, false, id
end
