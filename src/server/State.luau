-- BRAINROT BAZAAR v2: the single state store.
-- Every number the game cares about lives in this one module, on the
-- server only. No other server script keeps its own copy of a player's
-- money, brainrots or rebirths: they all ask State, so the HUD, the
-- economy and the wave rules can never disagree with each other.
-- v2: no stealing, no locks, no carrying. Added: Golden Touch level,
-- Golden Rush flag, saved-data fields for the DataStore module.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local State = {}

-- player -> { money, earnedTotal, rebirths, upgrades, brainrots, dex,
--   contracts, contractsDone, survivedWaves, baseIndex, boughtCount }
State.players = {}

-- Live brainrots still walking the belt, by uid.
State.belt = {}
State.nextUid = 1

-- Wave phase shared with the wave loop: "calm", "warning" or "wave".
State.wavePhase = "calm"
State.waveCountdown = Config.Wave.calmSeconds

-- Golden Rush bonus: while true, all income is x2.
State.goldenRush = false

-- Server-wide belt-speed bonus from beltSpeed upgrades (all players).
State.beltSpeedBonus = 0

function State.newPlayerState(baseIndex)
	return {
		money = Config.Belt.startMoney,
		earnedTotal = 0,
		rebirths = 0,
		upgrades = { slot = 0, speed = 0, beltSpeed = 0, golden = 0 },
		brainrots = {}, -- slot index -> owned brainrot table
		dex = {}, -- cast id -> true, once ever owned
		contracts = { buy3 = 0, buy10 = 0, earn1000 = 0, earn50000 = 0, survive2 = 0, dex5 = 0 },
		contractsDone = {},
		survivedWaves = 0,
		baseIndex = baseIndex,
		boughtCount = 0,
	}
end

function State.addPlayer(player, baseIndex)
	State.players[player] = State.newPlayerState(baseIndex)
end

function State.removePlayer(player)
	State.players[player] = nil
end

function State.get(player)
	return State.players[player]
end

-- How many base slots this player has right now.
function State.slotCount(data)
	return Config.Bases.baseSlots + data.upgrades.slot * Config.Upgrades.slot.slotsPerLevel
end

-- First empty slot index, or nil when the base is full.
function State.freeSlot(data)
	local max = State.slotCount(data)
	for i = 1, max do
		if data.brainrots[i] == nil then
			return i
		end
	end
	return nil
end

-- Current income multiplier from a Golden Rush (2x) or 1x.
function State.rushMult()
	if State.goldenRush then
		return Config.GoldenRush.mult
	end
	return 1
end

-- Total $/second across every brainrot on this player's base.
function State.incomePerSecond(data)
	local total = 0
	for _, owned in pairs(data.brainrots) do
		total += Config.incomePerSecond(owned, data.rebirths, data.upgrades.golden, State.rushMult())
	end
	return total
end

-- Walk speed for a player, after speed upgrades.
function State.walkSpeed(data)
	local speed = 16 + data.upgrades.speed * Config.Upgrades.speed.speedPerLevel
	return math.max(speed, 8)
end

-- Cost of the next level of an upgrade, or nil when maxed out.
-- The price itself lives in Config, so server and HUD agree on it.
function State.upgradeCost(data, kind)
	local def = Config.Upgrades[kind]
	if not def then
		return nil
	end
	local level = data.upgrades[kind] or 0
	return Config.upgradeCost(kind, level)
end

-- Rebirth price for this player right now.
function State.rebirthCost(data)
	return Config.Rebirth.minMoney * (data.rebirths + 1)
end

-- Count owned brainrots.
function State.ownedCount(data)
	local n = 0
	for _ in pairs(data.brainrots) do
		n += 1
	end
	return n
end

-- Count Dex entries found.
function State.dexCount(data)
	local n = 0
	for _ in pairs(data.dex) do
		n += 1
	end
	return n
end

-- Make a fresh belt brainrot: cast + mutation + price + uid.
-- The uid is handed out here, once, so two brainrots can never share
-- one even if a caller also stamps its own number on the entry.
function State.newBeltBrainrot(stormActive)
	local cast = Config.rollCast()
	local mutation = Config.rollMutation(stormActive)
	local uid = State.nextUid
	State.nextUid += 1
	return {
		uid = uid,
		castId = cast.id,
		name = cast.name,
		rarity = cast.rarity,
		rate = cast.rate,
		cost = math.floor(cast.cost * mutation.mult + 0.5),
		mutation = mutation.id,
		mutationMult = mutation.mult,
		colour = cast.colour,
		blurb = cast.blurb,
		model = nil, -- the 3D Model, set by BrainrotServer when it spawns
		progress = 0, -- studs walked along the belt
	}
end

-- Small snapshot the client HUD can render: money, income, owned list.
function State.snapshotFor(player)
	local data = State.players[player]
	if not data then
		return nil
	end
	local owned = {}
	for slot, entry in pairs(data.brainrots) do
		owned[slot] = {
			name = entry.name,
			rarity = entry.rarity,
			rate = Config.incomePerSecond(entry, data.rebirths, data.upgrades.golden, State.rushMult()),
			mutation = entry.mutation,
			castId = entry.castId,
		}
	end
	local belt = {}
	for _, entry in pairs(State.belt) do
		table.insert(belt, {
			uid = entry.uid,
			name = entry.name,
			rarity = entry.rarity,
			rate = entry.rate * entry.mutationMult,
			cost = entry.cost,
			mutation = entry.mutation,
		})
	end
	table.sort(belt, function(a, b)
		return a.uid < b.uid
	end)
	-- Richest players, top 5 by money (cheap: few players, one sort).
	local leaders = {}
	for other, otherData in pairs(State.players) do
		table.insert(leaders, { name = other.Name, money = math.floor(otherData.money) })
	end
	table.sort(leaders, function(a, b)
		return a.money > b.money
	end)
	while #leaders > 5 do
		table.remove(leaders)
	end
	return {
		leaders = leaders,
		money = math.floor(data.money),
		income = State.incomePerSecond(data),
		rebirths = data.rebirths,
		rebirthCost = State.rebirthCost(data),
		slotsUsed = State.ownedCount(data),
		slotsMax = State.slotCount(data),
		upgrades = data.upgrades, -- so the HUD can price the next level
		owned = owned,
		dex = data.dex,
		contracts = data.contracts,
		contractsDone = data.contractsDone,
		wavePhase = State.wavePhase,
		waveCountdown = math.ceil(State.waveCountdown),
		goldenRush = State.goldenRush,
		belt = belt,
	}
end

return State
