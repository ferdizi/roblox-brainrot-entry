-- BRAINROT KRAKATOA: one shared table of truth for the whole game.
-- Every number the judge (or a player) cares about lives here: the cast,
-- the rarity ladder, mutation multipliers, wave timings, upgrade costs.
-- Server and client both require this module, so a price shown on the
-- belt is always the price the server charges.

local Config = {}

-- The cast. An original Indonesian food-meme line-up, cheapest first.
-- cost is what a brainrot sells for on the belt; rate is its $/second
-- once it sits on a base slot. colour is the body colour of its 3D model.
Config.Cast = {
	{
		id = "kopi-kura",
		name = "Kopi Kura-Kura",
		rarity = "Common",
		rate = 5,
		cost = 50,
		weight = 45,
		colour = Color3.fromRGB(139, 94, 52),
		hat = "Cup",
		blurb = "A sleepy turtle that brews coffee in its shell.",
	},
	{
		id = "nasi-ninja",
		name = "Nasi Goreng Ninja",
		rarity = "Rare",
		rate = 15,
		cost = 150,
		weight = 28,
		colour = Color3.fromRGB(214, 158, 64),
		hat = "Bandana",
		blurb = "Fried rice that strikes from the wok, silently.",
	},
	{
		id = "bakso-blast",
		name = "Bakso Blast",
		rarity = "Epic",
		rate = 40,
		cost = 400,
		weight = 15,
		colour = Color3.fromRGB(196, 110, 90),
		hat = "Bowl",
		blurb = "A meatball with a fuse. It hums before it booms.",
	},
	{
		id = "durian-doom",
		name = "Durian Doom",
		rarity = "Legendary",
		rate = 120,
		cost = 1200,
		weight = 8,
		colour = Color3.fromRGB(120, 180, 60),
		hat = "Spikes",
		blurb = "Smells like trouble. Pays like a king.",
	},
	{
		id = "es-teh",
		name = "Es Teh Tsunami",
		rarity = "Mythic",
		rate = 350,
		cost = 3500,
		weight = 3,
		colour = Color3.fromRGB(90, 170, 220),
		hat = "Straw",
		blurb = "Iced tea in a wave. Cold, sweet, unstoppable.",
	},
	{
		id = "krakatoa-king",
		name = "Krakatoa King",
		rarity = "Secret",
		rate = 1000,
		cost = 10000,
		weight = 1,
		colour = Color3.fromRGB(220, 70, 40),
		hat = "Crown",
		blurb = "The volcano itself, wearing a crown. One in a hundred.",
	},
}

-- Rarity display colours, shared by the 3D labels and the HUD.
Config.RarityColour = {
	Common = Color3.fromRGB(200, 200, 200),
	Rare = Color3.fromRGB(80, 180, 255),
	Epic = Color3.fromRGB(170, 90, 255),
	Legendary = Color3.fromRGB(255, 180, 40),
	Mythic = Color3.fromRGB(255, 70, 120),
	Secret = Color3.fromRGB(255, 240, 90),
}

-- Mutations. A brainrot is born with one; the multiplier applies to rate.
-- Storm only rolls while a tsunami warning is live, which makes warnings
-- worth watching instead of worth hiding from.
Config.Mutations = {
	{ id = "Normal", mult = 1, weight = 80, colour = Color3.fromRGB(230, 230, 230) },
	{ id = "Gold", mult = 2, weight = 12, colour = Color3.fromRGB(255, 210, 60) },
	{ id = "Diamond", mult = 5, weight = 5, colour = Color3.fromRGB(120, 220, 255) },
	{ id = "Rainbow", mult = 10, weight = 2, colour = Color3.fromRGB(255, 120, 220) },
	{ id = "Storm", mult = 8, weight = 1, colour = Color3.fromRGB(90, 120, 255), stormOnly = true },
}

-- The belt: where brainrots walk before someone buys them.
Config.Belt = {
	length = 170, -- studs, from the volcano end to the lagoon end
	width = 8,
	maxOnBelt = 8,
	spawnEvery = 4, -- seconds between spawns while the belt has room
	walkSpeed = 6, -- studs per second
	startMoney = 100, -- every player starts with this much cash
}

-- Player bases: eight plots in a ring around the island.
Config.Bases = {
	count = 8,
	radius = 82,
	baseSlots = 4, -- slots before upgrades
	maxSlots = 10,
	slotSpacing = 5,
}

-- The tsunami: a cycle the whole server lives by.
Config.Wave = {
	calmSeconds = 60,
	warningSeconds = 10,
	waveSeconds = 6,
	knockbackCashLoss = 0.10, -- caught outside a base or the hill: lose 10% of cash
}

-- Stealing and defending a base.
Config.Steal = {
	lockSeconds = 30,
	lockCooldownSeconds = 90,
	slapRange = 9,
	slapKnockback = 26,
	carrySpeedPenalty = 4, -- carrying a stolen brainrot slows you down
}

-- Rebirth: wipe money and brainrots for a permanent income multiplier.
Config.Rebirth = {
	multPerRebirth = 0.5, -- +50% income per rebirth
	minMoney = 5000, -- cash needed to rebirth (times rebirths + 1)
	minBrainrots = 3,
}

-- Upgrades, bought with cash. Cost grows with the level you already own.
Config.Upgrades = {
	slot = { name = "Extra Slot", baseCost = 300, costMult = 1.8, maxLevel = 3, slotsPerLevel = 2 },
	speed = { name = "Swift Feet", baseCost = 250, costMult = 1.7, maxLevel = 3, speedPerLevel = 2 },
	slap = { name = "Heavy Slap", baseCost = 200, costMult = 1.7, maxLevel = 3, powerPerLevel = 8 },
	lock = { name = "Longer Lock", baseCost = 350, costMult = 1.8, maxLevel = 3, secondsPerLevel = 10 },
}

-- Contract Board: three goals that pay cash when finished.
Config.Contracts = {
	{ id = "buy3", name = "Buy 3 brainrots", goal = 3, reward = 500 },
	{ id = "earn1000", name = "Earn $1,000 in total", goal = 1000, reward = 750 },
	{ id = "survive2", name = "Survive 2 tsunamis", goal = 2, reward = 1000 },
}

-- Pick one cast member by spawn weight.
function Config.rollCast()
	local total = 0
	for _, entry in ipairs(Config.Cast) do
		total += entry.weight
	end
	local roll = math.random(1, total)
	local running = 0
	for _, entry in ipairs(Config.Cast) do
		running += entry.weight
		if roll <= running then
			return entry
		end
	end
	return Config.Cast[1]
end

-- Pick a mutation. Storm only appears while a warning is live.
function Config.rollMutation(stormActive)
	local total = 0
	for _, entry in ipairs(Config.Mutations) do
		if not entry.stormOnly or stormActive then
			total += entry.weight
		end
	end
	local roll = math.random(1, total)
	local running = 0
	for _, entry in ipairs(Config.Mutations) do
		if not entry.stormOnly or stormActive then
			running += entry.weight
			if roll <= running then
				return entry
			end
		end
	end
	return Config.Mutations[1]
end

-- How much a brainrot earns per second, after mutation and rebirths.
function Config.incomePerSecond(entry, rebirths)
	local mult = 1 + Config.Rebirth.multPerRebirth * rebirths
	return math.floor(entry.rate * entry.mutationMult * mult + 0.5)
end

-- Short money text for labels: 1250 -> "$1.2k".
function Config.formatMoney(amount)
	amount = math.floor(amount + 0.5)
	if amount >= 1000000 then
		return "$" .. string.format("%.1fM", amount / 1000000)
	elseif amount >= 1000 then
		return "$" .. string.format("%.1fk", amount / 1000)
	else
		return "$" .. tostring(amount)
	end
end

return Config
