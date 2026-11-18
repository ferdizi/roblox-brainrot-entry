-- BRAINROT KRAKATOA: the single state store.
-- Every number the game cares about lives in this one module, on the
-- server only. No other server script keeps its own copy of a player's
-- money, brainrots or lock: they all ask State, so the HUD, the economy
-- and the steal rules can never disagree with each other.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local State = {}

-- player -> { money, earnedTotal, rebirths, upgrades, brainrots, dex,
--   contracts, lockedUntil, lockCooldownUntil, carrying, survivedWaves,
--   baseIndex, boughtCount }
State.players = {}

-- Live brainrots still walking the belt, by uid.
State.belt = {}
State.nextUid = 1

-- Tsunami phase shared with the wave loop: "calm", "warning" or "wave".
State.wavePhase = "calm"
State.waveCountdown = Config.Wave.calmSeconds

function State.newPlayerState(baseIndex)
	return {
		money = Config.Belt.startMoney,
		earnedTotal = 0,
		rebirths = 0,
		upgrades = { slot = 0, speed = 0, slap = 0, lock = 0 },
		brainrots = {}, -- slot index -> owned brainrot table
		dex = {}, -- cast id -> true, once ever owned
		contracts = { buy3 = 0, earn1000 = 0, survive2 = 0 },
		contractsDone = {},
		lockedUntil = 0,
		lockCooldownUntil = 0,
		carrying = nil, -- stolen brainrot being carried, or nil
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

-- Total $/second across every brainrot on this player's base.
function State.incomePerSecond(data)
	local total = 0
	for _, owned in pairs(data.brainrots) do
		total += Config.incomePerSecond(owned, data.rebirths)
	end
	return total
end

-- Walk speed for a player, after upgrades and the carry penalty.
function State.walkSpeed(data)
	local speed = 16 + data.upgrades.speed * Config.Upgrades.speed.speedPerLevel
	if data.carrying ~= nil then
		speed -= Config.Steal.carrySpeedPenalty
	end
	return math.max(speed, 8)
end

-- Is this player's base locked right now? Wall-clock seconds, the
-- same clock lockBase writes with, so the two can never disagree.
function State.isLocked(data)
	return os.time() < data.lockedUntil
end

-- Lock length for this player, after lock upgrades.
function State.lockLength(data)
	return Config.Steal.lockSeconds + data.upgrades.lock * Config.Upgrades.lock.secondsPerLevel
end

-- Slap power for this player, after slap upgrades.
function State.slapPower(data)
	return Config.Steal.slapKnockback + data.upgrades.slap * Config.Upgrades.slap.powerPerLevel
end

-- Cost of the next level of an upgrade, or nil when maxed out.
function State.upgradeCost(data, kind)
	local def = Config.Upgrades[kind]
	if not def then
		return nil
	end
	local level = data.upgrades[kind] or 0
	if level >= def.maxLevel then
		return nil
	end
	return math.floor(def.baseCost * (def.costMult ^ level) + 0.5)
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

-- Make a fresh belt brainrot: cast + mutation + price + uid.
function State.newBeltBrainrot(stormActive)
	local cast = Config.rollCast()
	local mutation = Config.rollMutation(stormActive)
	return {
		uid = State.nextUid,
		castId = cast.id,
		name = cast.name,
		rarity = cast.rarity,
		rate = cast.rate,
		cost = cast.cost * mutation.mult,
		mutation = mutation.id,
		mutationMult = mutation.mult,
		colour = cast.colour,
		hat = cast.hat,
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
			rate = Config.incomePerSecond(entry, data.rebirths),
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
	return {
		money = math.floor(data.money),
		income = State.incomePerSecond(data),
		rebirths = data.rebirths,
		rebirthCost = State.rebirthCost(data),
		slotsUsed = State.ownedCount(data),
		slotsMax = State.slotCount(data),
		lockedUntil = data.lockedUntil,
		lockCooldownUntil = data.lockCooldownUntil,
		lockLength = State.lockLength(data),
		carrying = data.carrying ~= nil,
		owned = owned,
		dex = data.dex,
		contracts = data.contracts,
		contractsDone = data.contractsDone,
		wavePhase = State.wavePhase,
		waveCountdown = math.ceil(State.waveCountdown),
		belt = belt,
	}
end

return State
