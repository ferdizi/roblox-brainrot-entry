-- BRAINROT BAZAAR: one shared table of truth for the whole game.
-- Every number the judge (or a player) cares about lives here: the cast,
-- the rarity ladder, mutation multipliers, wave timings, upgrade costs.
-- Server and client both require this module, so a price shown on the
-- belt is always the price the server charges.

local Config = {}

-- The cast. "Brainrot Bazaar": eleven original meme characters,
-- cheapest first. cost is what a brainrot sells for on the belt;
-- rate is its $/second once it sits on a base slot. colour is the
-- body colour of its 3D model.
Config.Cast = {
	{
		id = "soggy-toastino",
		name = "Soggy Toastino",
		rarity = "Common",
		rate = 2,
		cost = 20,
		weight = 45,
		colour = Color3.fromRGB(196, 154, 108),
		hat = "Toaster",
		blurb = "A toaster with legs and a very sad slice of toast.",
	},
	{
		id = "bonk-pigeon",
		name = "Bonk Pigeon",
		rarity = "Common",
		rate = 4,
		cost = 40,
		weight = 40,
		colour = Color3.fromRGB(140, 160, 190),
		hat = "Helmet",
		blurb = "A fat pigeon in a tiny helmet. It bonks. You pay.",
	},
	{
		id = "captain-noodlebeard",
		name = "Captain Noodlebeard",
		rarity = "Rare",
		rate = 12,
		cost = 120,
		weight = 24,
		colour = Color3.fromRGB(245, 230, 200),
		hat = "PirateHat",
		blurb = "A bowl-headed pirate with ramen noodle whiskers.",
	},
	{
		id = "lil-wobblecone",
		name = "Lil Wobblecone",
		rarity = "Rare",
		rate = 18,
		cost = 180,
		weight = 20,
		colour = Color3.fromRGB(255, 140, 40),
		hat = "Cone",
		blurb = "A traffic cone wobbling forever on a skateboard.",
	},
	{
		id = "sir-crustacio",
		name = "Sir Crustacio",
		rarity = "Epic",
		rate = 60,
		cost = 600,
		weight = 14,
		colour = Color3.fromRGB(220, 60, 50),
		hat = "Helmet",
		blurb = "A crab knight. Its sword is a baguette. Fear it.",
	},
	{
		id = "madame-flamingatto",
		name = "Madame Flamingatto",
		rarity = "Epic",
		rate = 85,
		cost = 850,
		weight = 11,
		colour = Color3.fromRGB(255, 150, 200),
		hat = "Sunglasses",
		blurb = "A flamingo in sunglasses, carrying a handbag.",
	},
	{
		id = "turbo-tungtung",
		name = "Turbo Tungtung Toaster-Jr",
		rarity = "Legendary",
		rate = 300,
		cost = 3000,
		weight = 7,
		colour = Color3.fromRGB(150, 105, 60),
		hat = "RocketPack",
		blurb = "A speedy wooden log robot with a rocket pack.",
	},
	{
		id = "duchess-cactoona",
		name = "Duchess Cactoona",
		rarity = "Legendary",
		rate = 420,
		cost = 4200,
		weight = 5,
		colour = Color3.fromRGB(60, 180, 90),
		hat = "Crown",
		blurb = "A cactus opera singer. The notes float. So does she.",
	},
	{
		id = "glorpo-ghost-burger",
		name = "Glorpo the Ghost Burger",
		rarity = "Mythic",
		rate = 1500,
		cost = 15000,
		weight = 3,
		colour = Color3.fromRGB(230, 240, 255),
		hat = "Ghost",
		blurb = "A translucent burger with a glowing smile.",
	},
	{
		id = "baron-vroomvroom",
		name = "Baron Vroomvroom",
		rarity = "Mythic",
		rate = 2200,
		cost = 22000,
		weight = 2,
		colour = Color3.fromRGB(220, 30, 30),
		hat = "Moustache",
		blurb = "A moustached sports car with human legs.",
	},
	{
		id = "blobfather",
		name = "The Great Brainrot Blobfather",
		rarity = "Secret",
		rate = 12000,
		cost = 120000,
		weight = 1,
		colour = Color3.fromRGB(150, 60, 220),
		hat = "Crown",
		blurb = "A giant gelatinous blob with a crown and glitch cubes.",
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
-- Glitch only rolls while a wave warning is live, which makes warnings
-- worth watching instead of worth hiding from.
Config.Mutations = {
	{ id = "Normal", mult = 1, weight = 80, colour = Color3.fromRGB(230, 230, 230) },
	{ id = "Gold", mult = 1.5, weight = 12, colour = Color3.fromRGB(255, 210, 60) },
	{ id = "Diamond", mult = 2, weight = 5, colour = Color3.fromRGB(120, 220, 255) },
	{ id = "Rainbow", mult = 3, weight = 2, colour = Color3.fromRGB(255, 120, 220) },
	{ id = "Glitch", mult = 4, weight = 1, colour = Color3.fromRGB(160, 100, 255), stormOnly = true },
}

-- The belt: where brainrots walk before someone buys them.
-- The belt runs down the middle of the street, west to east, so a
-- brainrot is visible the whole way.
Config.Belt = {
	startX = -70, -- studs: west end of the belt
	length = 170, -- studs, from the west end to the east end
	width = 8,
	maxOnBelt = 8,
	spawnEvery = 4, -- seconds between spawns while the belt has room
	walkSpeed = 6, -- studs per second
	startMoney = 100, -- every player starts with this much cash
}

-- Player bases: six plots, 3 north + 3 south along the street.
-- (WorldBuilder still lays them out in a ring; a world phase
-- repositions them. Only the count lives here.)
Config.Bases = {
	count = 6,
	radius = 82,
	baseSlots = 4, -- slots before upgrades
	maxSlots = 10,
	slotSpacing = 5,
}

-- The wave: a cycle the whole server lives by.
Config.Wave = {
	calmSeconds = 60,
	warningSeconds = 10,
	waveSeconds = 6,
	knockbackCashLoss = 0.10, -- caught outside a base or the safe plaza: lose 10% of cash
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
	beltSpeed = { name = "Faster Conveyor", baseCost = 400, costMult = 1.8, maxLevel = 3, speedPerLevel = 1.5 },
}

-- Contract Board: three goals that pay cash when finished.
Config.Contracts = {
	{ id = "buy3", name = "Buy 3 brainrots", goal = 3, reward = 500 },
	{ id = "earn1000", name = "Earn $1,000 in total", goal = 1000, reward = 750 },
	{ id = "survive2", name = "Survive 2 waves", goal = 2, reward = 1000 },
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

-- Pick a mutation. Glitch only appears while a warning is live.
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
-- A cast entry on its own has no mutationMult, so a missing one counts
-- as plain x1 instead of erroring on nil arithmetic.
function Config.incomePerSecond(entry, rebirths)
	local mutationMult = entry.mutationMult or 1
	local mult = 1 + Config.Rebirth.multPerRebirth * rebirths
	return math.floor(entry.rate * mutationMult * mult + 0.5)
end

-- Cost of the next level of an upgrade, or nil when maxed out. Lives
-- here, not in State, so the client HUD can price the same buttons
-- with the same numbers the server charges.
function Config.upgradeCost(kind, level)
	local def = Config.Upgrades[kind]
	if not def then
		return nil
	end
	if level >= def.maxLevel then
		return nil
	end
	return math.floor(def.baseCost * (def.costMult ^ level) + 0.5)
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
