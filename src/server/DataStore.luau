-- BRAINROT BAZAAR v2: DataStore saving, pcall-wrapped.
-- Saves money, rebirths, upgrades, Dex, quest progress and owned
-- brainrots (as castId + mutation + slot, rebuilt on load). Every
-- DataStore call is pcall-guarded: in Studio without API access, or
-- on any datastore error, the game just plays with a fresh state and
-- never errors. Nothing in this module ever yields the caller.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local State = require(script.Parent:WaitForChild("State"))

local DataStore = {}

local store = nil
pcall(function()
	store = DataStoreService:GetDataStore(Config.DataStoreName)
end)

-- Serialise one player's state into a plain table.
local function serialise(data)
	local brainrots = {}
	for slot, owned in pairs(data.brainrots) do
		table.insert(brainrots, {
			slot = slot,
			castId = owned.castId,
			mutation = owned.mutation,
		})
	end
	local dexList = {}
	for castId in pairs(data.dex) do
		table.insert(dexList, castId)
	end
	local doneList = {}
	for id in pairs(data.contractsDone) do
		table.insert(doneList, id)
	end
	return {
		version = Config.DataStoreVersion,
		money = math.floor(data.money),
		earnedTotal = math.floor(data.earnedTotal),
		rebirths = data.rebirths,
		upgrades = data.upgrades,
		brainrots = brainrots,
		dex = dexList,
		contracts = data.contracts,
		contractsDone = doneList,
		survivedWaves = data.survivedWaves,
		boughtCount = data.boughtCount,
	}
end

-- Apply saved data onto a fresh player state. Returns true if the
-- save was the current version and applied, false otherwise.
local function apply(data, saved)
	if type(saved) ~= "table" then
		return false
	end
	if saved.version ~= Config.DataStoreVersion then
		return false
	end
	data.money = saved.money or Config.Belt.startMoney
	data.earnedTotal = saved.earnedTotal or 0
	data.rebirths = saved.rebirths or 0
	if type(saved.upgrades) == "table" then
		for kind, level in pairs(saved.upgrades) do
			if data.upgrades[kind] ~= nil then
				data.upgrades[kind] = level
			end
		end
	end
	if type(saved.dex) == "table" then
		for _, castId in ipairs(saved.dex) do
			data.dex[castId] = true
		end
	end
	if type(saved.contracts) == "table" then
		for id, progress in pairs(saved.contracts) do
			if data.contracts[id] ~= nil then
				data.contracts[id] = progress
			end
		end
	end
	if type(saved.contractsDone) == "table" then
		for _, id in ipairs(saved.contractsDone) do
			data.contractsDone[id] = true
		end
	end
	data.survivedWaves = saved.survivedWaves or 0
	data.boughtCount = saved.boughtCount or 0
	return true
end

-- Load one player's save. Returns the saved brainrot list (to be
-- rebuilt by BrainrotServer) or nil when there is nothing to load.
function DataStore.load(player, data)
	if not store then
		return nil
	end
	local ok, saved = pcall(function()
		return store:GetAsync("player_" .. tostring(player.UserId))
	end)
	if not ok or saved == nil then
		return nil
	end
	local applied = apply(data, saved)
	if not applied then
		return nil
	end
	return saved.brainrots
end

-- Save one player's state. Never errors.
function DataStore.save(player)
	local data = State.get(player)
	if not data or not store then
		return false
	end
	local ok = pcall(function()
		store:SetAsync("player_" .. tostring(player.UserId), serialise(data))
	end)
	return ok
end

-- Save every player in the game. Used by the autosave loop.
function DataStore.saveAll()
	for player in pairs(State.players) do
		DataStore.save(player)
	end
end

return DataStore
