-- BRAINROT BAZAAR v2: one shared table of truth for the whole game.
-- Every number the judge (or a player) cares about lives here: the
-- cast, the rarity ladder, mutation multipliers, wave timings, upgrade
-- costs. Server and client both require this module, so a price shown
-- on the belt is always the price the server charges.
--
-- v2 changes: 25 original characters (Gadiel's 14 core names + 11
-- originals), mutations Gula Aren / Gosong / Glitch / Pelangi, no
-- stealing at all — the goo wave is the single threat — plus a Golden
-- Touch income upgrade, a Golden Rush bonus event, and six quests.
-- NEVER use popular brainrot names (Tung Tung, Tralalero, etc.).

local Config = {}

-- The cast: 25 original meme characters, cheapest first. cost is
-- what a brainrot sells for on the belt; rate is its $/second once
-- it sits on a base slot. colour is the body colour of its 3D model.
-- Shape fields drive the model builder: bodyShape/bodyW/bodyH/bodyD,
-- headShape/headW/headH/headD, idle ("bob" | "bounce" | "spin"),
-- ghostly (translucent body+head), prop (which detail set to draw).
-- Fields not listed use the builder defaults: Block body 4.5^3,
-- Block head 2.6x2.2x2.6, idle "bob".
Config.Cast = {
	-- Common (5)
	{
		id = "sandalo-pepino",
		name = "Sandalo Pepino",
		rarity = "Common",
		rate = 2,
		cost = 20,
		weight = 45,
		colour = Color3.fromRGB(120, 200, 90),
		bodyW = 4.2, bodyH = 4.5, bodyD = 3.0,
		headW = 2.6, headH = 2.2, headD = 2.6,
		prop = "sandal",
		blurb = "A sandal with a cucumber soul. It walks. It crunches.",
	},
	{
		id = "kerupuko-dudu",
		name = "Kerupuko Dudu",
		rarity = "Common",
		rate = 4,
		cost = 40,
		weight = 40,
		colour = Color3.fromRGB(250, 220, 150),
		bodyShape = "Ball",
		bodyW = 4.5, bodyH = 4.5, bodyD = 4.5,
		headShape = "Ball",
		headW = 2.4, headH = 2.4, headD = 2.4,
		idle = "bounce",
		prop = "kerupuk",
		blurb = "A puffy cracker that dudu-dudus everywhere it goes.",
	},
	{
		id = "bantalo-zzz",
		name = "Bantalo Zzz",
		rarity = "Common",
		rate = 6,
		cost = 60,
		weight = 35,
		colour = Color3.fromRGB(200, 220, 255),
		bodyW = 4.6, bodyH = 3.8, bodyD = 3.4,
		headW = 2.4, headH = 2.0, headD = 2.4,
		prop = "pillow",
		blurb = "A sleepy pillow. It earns money in its dreams.",
	},
	{
		id = "soggy-toastino",
		name = "Soggy Toastino",
		rarity = "Common",
		rate = 8,
		cost = 80,
		weight = 30,
		colour = Color3.fromRGB(196, 154, 108),
		bodyW = 4.2, bodyH = 4.5, bodyD = 3.0,
		headW = 2.6, headH = 2.6, headD = 1.0,
		prop = "toaster",
		blurb = "A toaster with legs and a very sad slice of toast.",
	},
	{
		id = "bonk-pigeon",
		name = "Bonk Pigeon",
		rarity = "Common",
		rate = 10,
		cost = 100,
		weight = 25,
		colour = Color3.fromRGB(140, 160, 190),
		bodyShape = "Ball",
		headShape = "Ball",
		headW = 2.4, headH = 2.4, headD = 2.4,
		idle = "bounce",
		prop = "pigeon",
		blurb = "A fat pigeon in a tiny helmet. It bonks. You pay.",
	},
	-- Rare (5)
	{
		id = "gorengo-splash",
		name = "Gorengo Splash",
		rarity = "Rare",
		rate = 15,
		cost = 150,
		weight = 22,
		colour = Color3.fromRGB(230, 160, 60),
		bodyShape = "Ball",
		bodyW = 4.5, bodyH = 4.5, bodyD = 4.5,
		headShape = "Ball",
		headW = 2.4, headH = 2.4, headD = 2.4,
		prop = "gorengan",
		blurb = "A fried fritter that splashes oil and money.",
	},
	{
		id = "cilokko-bambino",
		name = "Cilokko Bambino",
		rarity = "Rare",
		rate = 18,
		cost = 180,
		weight = 20,
		colour = Color3.fromRGB(240, 200, 160),
		bodyShape = "Ball",
		bodyW = 4.4, bodyH = 4.4, bodyD = 4.4,
		headShape = "Ball",
		headW = 2.4, headH = 2.4, headD = 2.4,
		idle = "bounce",
		prop = "cilok",
		blurb = "A chewy tapioca ball on a stick, forever a bambino.",
	},
	{
		id = "sendokini-spin",
		name = "Sendokini Spin",
		rarity = "Rare",
		rate = 24,
		cost = 240,
		weight = 18,
		colour = Color3.fromRGB(180, 180, 190),
		bodyShape = "Cylinder",
		bodyW = 4.2, bodyH = 4.8, bodyD = 4.2,
		headShape = "Ball",
		headW = 2.4, headH = 2.4, headD = 2.4,
		idle = "spin",
		prop = "spoon",
		blurb = "A spoon that spins. Nobody knows why. It just does.",
	},
	{
		id = "professor-pickles",
		name = "Professor Pickles",
		rarity = "Rare",
		rate = 30,
		cost = 300,
		weight = 16,
		colour = Color3.fromRGB(90, 180, 70),
		bodyShape = "Cylinder",
		bodyW = 4.2, bodyH = 4.8, bodyD = 4.2,
		headShape = "Ball",
		headW = 2.2, headH = 2.2, headD = 2.2,
		prop = "pickle",
		blurb = "A pickle scientist. Every experiment ends in brine.",
	},
	{
		id = "disco-dumpling",
		name = "Disco Dumpling",
		rarity = "Rare",
		rate = 40,
		cost = 400,
		weight = 14,
		colour = Color3.fromRGB(240, 220, 255),
		bodyShape = "Ball",
		bodyW = 4.6, bodyH = 4.6, bodyD = 4.6,
		headShape = "Ball",
		headW = 2.2, headH = 2.2, headD = 2.2,
		idle = "spin",
		prop = "disco",
		blurb = "A dumpling that only moves to a beat nobody can hear.",
	},
	-- Epic (5)
	{
		id = "tahuro-turbino",
		name = "Tahuro Turbino",
		rarity = "Epic",
		rate = 60,
		cost = 600,
		weight = 12,
		colour = Color3.fromRGB(250, 245, 230),
		bodyD = 4.0,
		prop = "tahu",
		blurb = "A tofu block with a turbo. Soft outside, fast inside.",
	},
	{
		id = "kopiccino-zoomzoom",
		name = "Kopiccino Zoomzoom",
		rarity = "Epic",
		rate = 85,
		cost = 850,
		weight = 10,
		colour = Color3.fromRGB(140, 90, 50),
		bodyShape = "Cylinder",
		bodyW = 4.4, bodyH = 4.8, bodyD = 4.4,
		headShape = "Ball",
		headW = 2.4, headH = 2.4, headD = 2.4,
		idle = "bounce",
		prop = "kopi",
		blurb = "A coffee cup that zooms. It never sleeps. Ever.",
	},
	{
		id = "bakwanto-gladiatore",
		name = "Bakwanto Gladiatore",
		rarity = "Epic",
		rate = 110,
		cost = 1100,
		weight = 9,
		colour = Color3.fromRGB(220, 150, 70),
		bodyShape = "Ball",
		bodyW = 4.6, bodyH = 4.6, bodyD = 4.6,
		headShape = "Ball",
		headW = 2.4, headH = 2.4, headD = 2.4,
		prop = "gladiator",
		blurb = "A fritter gladiator. Crispy armour, zero mercy.",
	},
	{
		id = "sir-crustacio",
		name = "Sir Crustacio",
		rarity = "Epic",
		rate = 130,
		cost = 1300,
		weight = 8,
		colour = Color3.fromRGB(220, 60, 50),
		bodyD = 4.0,
		prop = "crab",
		blurb = "A crab knight. Its sword is a baguette. Fear it.",
	},
	{
		id = "madame-flamingatto",
		name = "Madame Flamingatto",
		rarity = "Epic",
		rate = 150,
		cost = 1500,
		weight = 7,
		colour = Color3.fromRGB(255, 150, 200),
		bodyShape = "Ball",
		bodyW = 4.2, bodyH = 4.2, bodyD = 4.2,
		headShape = "Ball",
		headW = 2.2, headH = 2.2, headD = 2.2,
		idle = "spin",
		prop = "flamingo",
		blurb = "A flamingo in sunglasses, carrying a handbag.",
	},
	-- Legendary (5)
	{
		id = "sambalo-dragonelli",
		name = "Sambalo Dragonelli",
		rarity = "Legendary",
		rate = 300,
		cost = 3000,
		weight = 6,
		colour = Color3.fromRGB(230, 60, 40),
		bodyW = 4.4, bodyH = 4.6, bodyD = 3.6,
		headW = 2.6, headH = 2.4, headD = 2.6,
		prop = "dragon",
		blurb = "A chilli-sauce dragon. One breath and you are sambal.",
	},
	{
		id = "nasgorini-crocodilo",
		name = "Nasgorini Crocodilo",
		rarity = "Legendary",
		rate = 420,
		cost = 4200,
		weight = 5,
		colour = Color3.fromRGB(240, 200, 100),
		bodyW = 5.0, bodyH = 3.6, bodyD = 3.4,
		headW = 2.8, headH = 2.0, headD = 2.4,
		prop = "crocodile",
		blurb = "A fried-rice crocodile. It snaps, it sizzles, it serves.",
	},
	{
		id = "odongo-bombardiro",
		name = "Odongo Bombardiro",
		rarity = "Legendary",
		rate = 500,
		cost = 5000,
		weight = 4,
		colour = Color3.fromRGB(255, 120, 200),
		bodyW = 4.6, bodyH = 4.4, bodyD = 3.6,
		headShape = "Ball",
		headW = 2.4, headH = 2.4, headD = 2.4,
		idle = "bounce",
		prop = "odong",
		blurb = "A fairground ride that bombards the bazaar with lights.",
	},
	{
		id = "king-kebab",
		name = "King Kebab",
		rarity = "Legendary",
		rate = 550,
		cost = 5500,
		weight = 4,
		colour = Color3.fromRGB(200, 120, 60),
		bodyShape = "Cylinder",
		bodyW = 4.4, bodyH = 4.8, bodyD = 4.4,
		headShape = "Ball",
		headW = 2.4, headH = 2.4, headD = 2.4,
		prop = "kebab",
		blurb = "A kebab king, skewered by destiny and garlic sauce.",
	},
	{
		id = "great-gazpacho",
		name = "The Great Gazpacho",
		rarity = "Legendary",
		rate = 600,
		cost = 6000,
		weight = 3,
		colour = Color3.fromRGB(220, 80, 60),
		bodyShape = "Cylinder",
		bodyW = 4.4, bodyH = 4.6, bodyD = 4.4,
		headShape = "Ball",
		headW = 2.4, headH = 2.4, headD = 2.4,
		prop = "wizard",
		blurb = "A soup wizard. His spells are served cold.",
	},
	-- Mythic (3)
	{
		id = "rendangzilla-mamma",
		name = "Rendangzilla Mamma",
		rarity = "Mythic",
		rate = 1500,
		cost = 15000,
		weight = 3,
		colour = Color3.fromRGB(160, 60, 40),
		bodyW = 5.0, bodyH = 5.2, bodyD = 4.4,
		headW = 2.8, headH = 2.6, headD = 2.8,
		prop = "rendangzilla",
		blurb = "A rendang Godzilla. Mamma always brings seconds.",
	},
	{
		id = "ojeklo-turbo-turbo",
		name = "Ojeklo Turbo-Turbo",
		rarity = "Mythic",
		rate = 2200,
		cost = 22000,
		weight = 2,
		colour = Color3.fromRGB(255, 200, 40),
		bodyW = 5.0, bodyH = 3.4, bodyD = 3.0,
		headW = 2.6, headH = 1.8, headD = 2.2,
		idle = "bounce",
		prop = "ojek",
		blurb = "A motorcycle taxi with two turbos and no brakes.",
	},
	{
		id = "glorpo-ghost-burger",
		name = "Glorpo the Ghost Burger",
		rarity = "Mythic",
		rate = 2500,
		cost = 25000,
		weight = 2,
		colour = Color3.fromRGB(230, 240, 255),
		bodyShape = "Ball",
		bodyW = 4.8, bodyH = 4.8, bodyD = 4.8,
		headShape = "Ball",
		headW = 2.6, headH = 2.6, headD = 2.6,
		ghostly = true,
		prop = "ghostburger",
		blurb = "A translucent burger with a glowing smile.",
	},
	-- Secret (2) — Secret glows RAINBOW, biggest and brightest.
	{
		id = "tuyul-cosmico",
		name = "Tuyul Cosmico",
		rarity = "Secret",
		rate = 8000,
		cost = 80000,
		weight = 1,
		colour = Color3.fromRGB(120, 200, 255),
		bodyShape = "Ball",
		bodyW = 4.8, bodyH = 4.8, bodyD = 4.8,
		headShape = "Ball",
		headW = 2.6, headH = 2.6, headD = 2.6,
		idle = "spin",
		prop = "tuyul",
		blurb = "A cosmic child spirit. It steals coins from the stars.",
	},
	{
		id = "pocongo-disco-ninja",
		name = "Pocongo Disco-Ninja",
		rarity = "Secret",
		rate = 12000,
		cost = 120000,
		weight = 1,
		colour = Color3.fromRGB(255, 255, 255),
		bodyW = 4.6, bodyH = 5.2, bodyD = 3.6,
		headW = 2.6, headH = 2.4, headD = 2.6,
		idle = "spin",
		prop = "pocong",
		blurb = "A shroud ghost, disco ninja. It boogies, then vanishes.",
	},
}

-- Rarity display colours, shared by the 3D labels and the HUD.
-- Secret glows rainbow: the builder cycles its aura and lights.
Config.RarityColour = {
	Common = Color3.fromRGB(200, 200, 200),
	Rare = Color3.fromRGB(80, 180, 255),
	Epic = Color3.fromRGB(170, 90, 255),
	Legendary = Color3.fromRGB(255, 180, 40),
	Mythic = Color3.fromRGB(255, 70, 120),
	Secret = Color3.fromRGB(255, 240, 90),
}

-- Mutations. A brainrot is born with one; the multiplier applies to
-- rate and to cost. Each has a DIFFERENT visual effect:
-- Gula Aren = golden sugar glaze; Gosong = charred black + ember
-- glow; Glitch = flickering purple/cyan (warning only); Pelangi =
-- rainbow cycling colours. Glitch only rolls while a wave warning
-- is live, which makes warnings worth watching.
Config.Mutations = {
	{ id = "Normal", mult = 1, weight = 80, colour = Color3.fromRGB(230, 230, 230) },
	{ id = "Gula Aren", mult = 1.5, weight = 12, colour = Color3.fromRGB(255, 190, 60) },
	{ id = "Gosong", mult = 2, weight = 5, colour = Color3.fromRGB(255, 90, 30) },
	{ id = "Glitch", mult = 3, weight = 1, colour = Color3.fromRGB(160, 100, 255), stormOnly = true },
	{ id = "Pelangi", mult = 5, weight = 2, colour = Color3.fromRGB(255, 120, 220) },
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
Config.Bases = {
	count = 6,
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

-- Golden Rush: a bonus event, 2x income for 30 seconds, every
-- ~2.5 minutes. The wave is the only THREAT; this is the reward
-- that keeps players watching the timer.
Config.GoldenRush = {
	everySeconds = 150,
	durationSeconds = 30,
	mult = 2,
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
	beltSpeed = { name = "Faster Conveyor", baseCost = 400, costMult = 1.8, maxLevel = 3, speedPerLevel = 1.5 },
	golden = { name = "Golden Touch", baseCost = 500, costMult = 1.9, maxLevel = 3, incomePerLevel = 0.10 },
}

-- Quest Board: six goals that pay cash when finished.
Config.Contracts = {
	{ id = "buy3", name = "Buy 3 brainrots", goal = 3, reward = 500 },
	{ id = "buy10", name = "Buy 10 brainrots", goal = 10, reward = 2500 },
	{ id = "earn1000", name = "Earn $1,000 in total", goal = 1000, reward = 750 },
	{ id = "earn50000", name = "Earn $50,000 in total", goal = 50000, reward = 5000 },
	{ id = "survive2", name = "Survive 2 waves", goal = 2, reward = 1000 },
	{ id = "dex5", name = "Find 5 brainrots in the Dex", goal = 5, reward = 1000 },
}

-- DataStore: saved per player (pcall-wrapped, fails safe in Studio).
Config.DataStoreName = "BrainrotBazaarV2"
Config.DataStoreVersion = 2

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

-- Find a cast entry by id.
function Config.findCast(castId)
	for _, entry in ipairs(Config.Cast) do
		if entry.id == castId then
			return entry
		end
	end
	return nil
end

-- How much a brainrot earns per second, after mutation, Golden Touch
-- upgrades, rebirths, and a Golden Rush multiplier. A cast entry on
-- its own has no mutationMult, so a missing one counts as plain x1
-- instead of erroring on nil arithmetic.
function Config.incomePerSecond(entry, rebirths, goldenLevel, rushMult)
	local mutationMult = entry.mutationMult or 1
	local mult = 1 + Config.Rebirth.multPerRebirth * (rebirths or 0)
	mult *= 1 + 0.10 * (goldenLevel or 0)
	mult *= rushMult or 1
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
