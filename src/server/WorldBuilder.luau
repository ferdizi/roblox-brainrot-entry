-- BRAINROT KRAKATOA: builds the 3D island the game is played on.
-- Rojo only ships the baseplate; everything a player can see and walk
-- on is built here, once, when the server starts, so the place file
-- stays small and the world lives in readable code. Bases are laid out
-- in a ring, the belt runs volcano-to-lagoon through the middle, and the
-- safe hill stands opposite the volcano for tsunami escapes.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local WorldBuilder = {}

-- Where each base sits, and which way its open front faces (towards 0,0).
-- The ring is turned half a step (22.5 degrees), so no base sits on
-- an axis: on the axes sit the belt, the volcano, the lagoon, the
-- shop and the safe hill, and a base there would swallow them.
WorldBuilder.basePositions = {}
for i = 1, Config.Bases.count do
	local angle = (i - 1) * (math.pi * 2 / Config.Bases.count) + math.pi / Config.Bases.count
	WorldBuilder.basePositions[i] = Vector3.new(
		math.cos(angle) * Config.Bases.radius,
		0,
		math.sin(angle) * Config.Bases.radius
	)
end

-- The ten slot pads inside one base, in local offsets from the base
-- centre: three rows of three, plus one pad by the gate for the tenth.
local SLOT_OFFSETS = {
	Vector3.new(-5, 0, -4),
	Vector3.new(0, 0, -4),
	Vector3.new(5, 0, -4),
	Vector3.new(-5, 0, 0),
	Vector3.new(0, 0, 0),
	Vector3.new(5, 0, 0),
	Vector3.new(-5, 0, 4),
	Vector3.new(0, 0, 4),
	Vector3.new(5, 0, 4),
	Vector3.new(0, 0, -6.5),
}

local function part(name, size, position, colour, material, parent, anchored)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = position
	p.Color = colour
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = anchored ~= false
	p.CanCollide = true
	p.Parent = parent
	return p
end

local function label(parent, text, colour, size)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Sign"
	gui.Size = UDim2.fromOffset(220, 52)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
	gui.AlwaysOnTop = false
	gui.Parent = parent
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 0.35
	t.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	t.TextColor3 = colour or Color3.fromRGB(255, 255, 255)
	t.Text = text
	t.TextScaled = true
	t.Font = Enum.Font.SourceSansBold
	t.Parent = gui
	return gui
end

-- Decoration helpers. Decor is purely visual: every part it makes is
-- Anchored and CanCollide=false, so it can never change how the game
-- plays — it only makes the island look like a real place.
local function decor(name, size, position, colour, material, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = position
	p.Color = colour
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.Parent = parent
	return p
end

local function decorT(name, size, position, colour, material, parent, transparency)
	local p = decor(name, size, position, colour, material, parent)
	p.Transparency = transparency
	return p
end

-- Decor rotated around Y (yaw in radians).
local function decorR(name, size, position, colour, material, parent, yaw)
	local p = decor(name, size, position, colour, material, parent)
	p.CFrame = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
	return p
end

local function ball(name, diameter, position, colour, material, parent, transparency)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(diameter, diameter, diameter)
	p.Position = position
	p.Color = colour
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.Transparency = transparency or 0
	p.Parent = parent
	return p
end

local function flatball(name, size, position, colour, material, parent, transparency)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Ball
	p.Size = size
	p.Position = position
	p.Color = colour
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.Transparency = transparency or 0
	p.Parent = parent
	return p
end

-- One accent colour per base, so every base reads as its own team.
local BASE_ACCENTS = {
	Color3.fromRGB(255, 70, 70),
	Color3.fromRGB(255, 150, 40),
	Color3.fromRGB(255, 220, 60),
	Color3.fromRGB(80, 200, 90),
	Color3.fromRGB(70, 150, 255),
	Color3.fromRGB(170, 90, 255),
	Color3.fromRGB(255, 90, 180),
	Color3.fromRGB(60, 220, 220),
}

-- Build one player base: floor, back wall, side walls, slot pads, a sign.
-- Returns the folder holding it, so the server can find its slot pads.
function WorldBuilder.buildBase(index, centre)
	local folder = Instance.new("Folder")
	folder.Name = "Base" .. tostring(index)
	folder.Parent = workspace

	local floorColour = Color3.fromRGB(90, 140, 90)
	if index % 2 == 0 then
		floorColour = Color3.fromRGB(140, 110, 70)
	end
	local floor = part("Floor", Vector3.new(18, 1, 14), centre + Vector3.new(0, 0.5, 0), floorColour, Enum.Material.Grass, folder)
	label(floor, "BASE " .. tostring(index), Color3.fromRGB(255, 240, 120), 24)

	-- Back wall faces away from the island centre; the front stays open.
	local outward = centre.Unit
	local backPos = centre + outward * 6.5
	part("BackWall", Vector3.new(18, 6, 1), backPos + Vector3.new(0, 3, 0), Color3.fromRGB(70, 70, 90), Enum.Material.Concrete, folder)
	local sideDir = Vector3.new(-outward.Z, 0, outward.X)
	part("SideWallL", Vector3.new(1, 4, 14), centre + sideDir * 8.5 + Vector3.new(0, 2, 0), Color3.fromRGB(70, 70, 90), Enum.Material.Concrete, folder)
	part("SideWallR", Vector3.new(1, 4, 14), centre - sideDir * 8.5 + Vector3.new(0, 2, 0), Color3.fromRGB(70, 70, 90), Enum.Material.Concrete, folder)

	-- The lock gate: a bright bar across the open front while locked.
	local gate = part("LockGate", Vector3.new(18, 3, 1), centre - outward * 6.5 + Vector3.new(0, 2.5, 0), Color3.fromRGB(255, 60, 60), Enum.Material.Neon, folder)
	gate.Transparency = 1
	gate.CanCollide = false
	gate.Name = "LockGate"

	-- Slot pads, rotated to face the island centre.
	local yaw = math.atan2(-outward.X, -outward.Z)
	for slot, offset in ipairs(SLOT_OFFSETS) do
		local rotated = Vector3.new(
			offset.X * math.cos(yaw) - offset.Z * math.sin(yaw),
			0,
			offset.X * math.sin(yaw) + offset.Z * math.cos(yaw)
		)
		local pad = part("Slot" .. tostring(slot), Vector3.new(3.4, 0.4, 3.4), centre + rotated + Vector3.new(0, 1.2, 0), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, folder)
		pad.Transparency = 0.35
	end

	-- Base character (visual only): an accent trim on the back wall,
	-- gate posts at the front corners, a flag on the back wall, and
	-- an awning over it. The floor, walls, pads and lock gate above
	-- are untouched.
	local accent = BASE_ACCENTS[((index - 1) % #BASE_ACCENTS) + 1]
	decorR("Trim", Vector3.new(18, 0.5, 0.3), backPos - outward * 0.6 + Vector3.new(0, 5.6, 0), accent, Enum.Material.Neon, folder, yaw)
	decor("GatePostL", Vector3.new(1, 5, 1), centre - outward * 6.5 + sideDir * 8.5 + Vector3.new(0, 3.5, 0), accent, Enum.Material.SmoothPlastic, folder)
	decor("GatePostR", Vector3.new(1, 5, 1), centre - outward * 6.5 - sideDir * 8.5 + Vector3.new(0, 3.5, 0), accent, Enum.Material.SmoothPlastic, folder)
	decor("FlagPole", Vector3.new(0.4, 6, 0.4), backPos + Vector3.new(0, 9, 0), Color3.fromRGB(90, 90, 100), Enum.Material.Metal, folder)
	decorR("Flag", Vector3.new(3.2, 2, 0.15), backPos + Vector3.new(0, 10.8, 0), accent, Enum.Material.Neon, folder, yaw)
	decorR("Awning", Vector3.new(18, 0.5, 4), backPos + outward * 2 + Vector3.new(0, 6.4, 0), accent, Enum.Material.SmoothPlastic, folder, yaw)

	return folder
end

-- Where a brainrot model stands on a base slot. The y puts the body's
-- centre a half-body above the pad top (pad top y=1.4, body half 1.5),
-- so the model stands on the pad instead of sinking into it.
function WorldBuilder.slotPosition(baseIndex, slot)
	local centre = WorldBuilder.basePositions[baseIndex]
	if not centre then
		return Vector3.new(0, 2.9, 0)
	end
	local offset = SLOT_OFFSETS[slot] or SLOT_OFFSETS[1]
	local outward = centre.Unit
	local yaw = math.atan2(-outward.X, -outward.Z)
	local rotated = Vector3.new(
		offset.X * math.cos(yaw) - offset.Z * math.sin(yaw),
		0,
		offset.X * math.sin(yaw) + offset.Z * math.cos(yaw)
	)
	return centre + rotated + Vector3.new(0, 2.9, 0)
end

-- Volcano dressing: lava flows down the stepped faces, smoke puffs
-- above the crater, lava drips on the crater rim, boulders at the foot.
-- The east tier-1 flow sits clear of the belt start pad (off to its
-- side and above it), so no flow ever touches the belt.
local function decorateVolcano(folder)
	local lava = Color3.fromRGB(255, 150, 40)
	local orange = Color3.fromRGB(255, 110, 25)
	decor("LavaFlowE1", Vector3.new(0.6, 6, 3), Vector3.new(-73.7, 6, 8), lava, Enum.Material.Neon, folder)
	decor("LavaFlowE2", Vector3.new(0.6, 6, 3), Vector3.new(-80.7, 15, -4), lava, Enum.Material.Neon, folder)
	decor("LavaFlowE3", Vector3.new(0.6, 5, 2.5), Vector3.new(-87.7, 24, 3), lava, Enum.Material.Neon, folder)
	decor("LavaFlowN1", Vector3.new(3, 7, 0.6), Vector3.new(-100, 5, -21.7), lava, Enum.Material.Neon, folder)
	decor("LavaFlowN2", Vector3.new(3, 6, 0.6), Vector3.new(-92, 15, -14.7), lava, Enum.Material.Neon, folder)
	decor("LavaFlowS1", Vector3.new(3, 7, 0.6), Vector3.new(-102, 5, 21.7), lava, Enum.Material.Neon, folder)
	decor("LavaFlowS2", Vector3.new(3, 6, 0.6), Vector3.new(-90, 15, 14.7), lava, Enum.Material.Neon, folder)
	decor("LavaFlowW1", Vector3.new(0.6, 7, 3), Vector3.new(-118.3, 5, 5), lava, Enum.Material.Neon, folder)
	decor("LavaFlowW2", Vector3.new(0.6, 6, 3), Vector3.new(-111.3, 15, -6), lava, Enum.Material.Neon, folder)
	local smoke = Color3.fromRGB(130, 130, 130)
	ball("Smoke1", 8, Vector3.new(-96, 34, 0), smoke, Enum.Material.SmoothPlastic, folder, 0.45)
	ball("Smoke2", 6, Vector3.new(-91, 38, 4), smoke, Enum.Material.SmoothPlastic, folder, 0.5)
	ball("Smoke3", 7, Vector3.new(-101, 37, -4), smoke, Enum.Material.SmoothPlastic, folder, 0.45)
	ball("Smoke4", 5, Vector3.new(-96, 42, 1), smoke, Enum.Material.SmoothPlastic, folder, 0.55)
	decor("CraterDrip1", Vector3.new(2, 1, 2), Vector3.new(-90.5, 29, 0), orange, Enum.Material.Neon, folder)
	decor("CraterDrip2", Vector3.new(2, 1, 2), Vector3.new(-101.5, 29, 0), orange, Enum.Material.Neon, folder)
	decor("CraterDrip3", Vector3.new(2, 1, 2), Vector3.new(-96, 29, 5.5), orange, Enum.Material.Neon, folder)
	decor("CraterDrip4", Vector3.new(2, 1, 2), Vector3.new(-96, 29, -5.5), orange, Enum.Material.Neon, folder)
	local rock = Color3.fromRGB(100, 95, 90)
	ball("VolcanoRock1", 4, Vector3.new(-122, 2.3, 12), rock, Enum.Material.Rock, folder, 0)
	ball("VolcanoRock2", 3, Vector3.new(-120, 1.8, -14), rock, Enum.Material.Rock, folder, 0)
	ball("VolcanoRock3", 3.5, Vector3.new(-76, 2.05, 16), rock, Enum.Material.Rock, folder, 0)
	ball("VolcanoRock4", 4, Vector3.new(-78, 2.3, -14), rock, Enum.Material.Rock, folder, 0)
end

-- Belt dressing: side skirts and glowing rails so it reads as a real
-- conveyor, roller stripes across it, and chevrons pointing east, the
-- way brainrots walk. All flat on the belt top, never in their path.
local function decorateBelt(folder)
	local beltStart = Config.Belt.startX
	local beltEnd = beltStart + Config.Belt.length
	local midX = beltStart + Config.Belt.length / 2
	local halfW = Config.Belt.width / 2
	decor("BeltSkirtN", Vector3.new(Config.Belt.length, 1, 0.8), Vector3.new(midX, 0.7, -halfW - 0.4), Color3.fromRGB(45, 45, 55), Enum.Material.Metal, folder)
	decor("BeltSkirtS", Vector3.new(Config.Belt.length, 1, 0.8), Vector3.new(midX, 0.7, halfW + 0.4), Color3.fromRGB(45, 45, 55), Enum.Material.Metal, folder)
	decor("BeltRailN", Vector3.new(Config.Belt.length, 0.3, 0.4), Vector3.new(midX, 1.35, -halfW - 0.4), Color3.fromRGB(255, 220, 60), Enum.Material.Neon, folder)
	decor("BeltRailS", Vector3.new(Config.Belt.length, 0.3, 0.4), Vector3.new(midX, 1.35, halfW + 0.4), Color3.fromRGB(255, 220, 60), Enum.Material.Neon, folder)
	for x = beltStart + 8, beltEnd - 8, 20 do
		decor("BeltRoller", Vector3.new(1, 0.12, Config.Belt.width - 1), Vector3.new(x, 1.26, 0), Color3.fromRGB(180, 180, 190), Enum.Material.Metal, folder)
	end
	for _, cx in ipairs({ -40, 0, 40 }) do
		decorR("BeltChevronA", Vector3.new(2.6, 0.15, 0.9), Vector3.new(cx, 1.3, -0.92), Color3.fromRGB(255, 220, 60), Enum.Material.Neon, folder, math.rad(135))
		decorR("BeltChevronB", Vector3.new(2.6, 0.15, 0.9), Vector3.new(cx, 1.3, 0.92), Color3.fromRGB(255, 220, 60), Enum.Material.Neon, folder, math.rad(-135))
	end
end

-- Lagoon dressing: a foam rim framing the water, rocks at its edge.
local function decorateLagoon(folder)
	local foam = Color3.fromRGB(240, 245, 255)
	decorT("LagoonFoamN", Vector3.new(58, 0.15, 2), Vector3.new(96, 0.85, -23), foam, Enum.Material.SmoothPlastic, folder, 0.25)
	decorT("LagoonFoamS", Vector3.new(58, 0.15, 2), Vector3.new(96, 0.85, 23), foam, Enum.Material.SmoothPlastic, folder, 0.25)
	decorT("LagoonFoamW", Vector3.new(2, 0.15, 46), Vector3.new(67, 0.85, 0), foam, Enum.Material.SmoothPlastic, folder, 0.25)
	decorT("LagoonFoamE", Vector3.new(2, 0.15, 46), Vector3.new(125, 0.85, 0), foam, Enum.Material.SmoothPlastic, folder, 0.25)
	local rock = Color3.fromRGB(110, 110, 110)
	ball("LagoonRock1", 3, Vector3.new(68, 1.8, -22), rock, Enum.Material.Rock, folder, 0)
	ball("LagoonRock2", 4, Vector3.new(124, 2.3, 22), rock, Enum.Material.Rock, folder, 0)
	ball("LagoonRock3", 2.5, Vector3.new(68, 1.55, 22), rock, Enum.Material.Rock, folder, 0)
	ball("LagoonRock4", 3, Vector3.new(124, 1.8, -22), rock, Enum.Material.Rock, folder, 0)
end

-- Safe hill dressing: a flag on the summit, grass tufts on the
-- terraces, rocks at its foot, and stepping stones down to the belt.
local function decorateHill(folder)
	decor("HillFlagPole", Vector3.new(0.4, 7, 0.4), Vector3.new(0, 18.5, -96), Color3.fromRGB(90, 90, 100), Enum.Material.Metal, folder)
	decor("HillFlag", Vector3.new(3.5, 2, 0.15), Vector3.new(0, 20.5, -96), Color3.fromRGB(255, 220, 60), Enum.Material.Neon, folder)
	local tuft = Color3.fromRGB(60, 140, 60)
	ball("HillTuft1", 2, Vector3.new(-13, 8.7, -96), tuft, Enum.Material.Grass, folder, 0)
	ball("HillTuft2", 2, Vector3.new(13, 8.7, -96), tuft, Enum.Material.Grass, folder, 0)
	ball("HillTuft3", 2, Vector3.new(0, 8.7, -84), tuft, Enum.Material.Grass, folder, 0)
	ball("HillTuft4", 2, Vector3.new(0, 8.7, -108), tuft, Enum.Material.Grass, folder, 0)
	ball("HillTuft5", 2, Vector3.new(-13, 8.7, -84), tuft, Enum.Material.Grass, folder, 0)
	ball("HillTuft6", 2, Vector3.new(13, 8.7, -108), tuft, Enum.Material.Grass, folder, 0)
	local rock = Color3.fromRGB(110, 110, 110)
	ball("HillRock1", 3, Vector3.new(-16, 1.8, -78), rock, Enum.Material.Rock, folder, 0)
	ball("HillRock2", 3.5, Vector3.new(16, 2.05, -78), rock, Enum.Material.Rock, folder, 0)
	ball("HillRock3", 2.5, Vector3.new(0, 1.55, -116), rock, Enum.Material.Rock, folder, 0)
	local stone = Color3.fromRGB(200, 185, 140)
	for _, z in ipairs({ -70, -55, -40, -25 }) do
		decor("HillPath", Vector3.new(3, 0.2, 2), Vector3.new(0, 0.8, z), stone, Enum.Material.Slate, folder)
	end
end

-- Shop dressing: a little stall — posts at the pad corners, a striped
-- awning roof above, and a counter at the back of the pad.
local function decorateShop(folder)
	local wood = Color3.fromRGB(120, 85, 50)
	decor("ShopPost1", Vector3.new(0.6, 5, 0.6), Vector3.new(-6.5, 3.7, 65.5), wood, Enum.Material.Wood, folder)
	decor("ShopPost2", Vector3.new(0.6, 5, 0.6), Vector3.new(6.5, 3.7, 65.5), wood, Enum.Material.Wood, folder)
	decor("ShopPost3", Vector3.new(0.6, 5, 0.6), Vector3.new(-6.5, 3.7, 78.5), wood, Enum.Material.Wood, folder)
	decor("ShopPost4", Vector3.new(0.6, 5, 0.6), Vector3.new(6.5, 3.7, 78.5), wood, Enum.Material.Wood, folder)
	local red = Color3.fromRGB(220, 60, 60)
	local white = Color3.fromRGB(245, 245, 240)
	for i = 0, 5 do
		local colour = red
		if i % 2 == 1 then colour = white end
		decor("ShopAwning", Vector3.new(16, 0.4, 2.67), Vector3.new(0, 6.4, 65.33 + i * 2.67), colour, Enum.Material.SmoothPlastic, folder)
	end
	decor("ShopCounter", Vector3.new(10, 2, 2), Vector3.new(0, 2.2, 77.5), wood, Enum.Material.Wood, folder)
end

-- Island dressing: palm trees, scattered rocks, torches flanking the
-- belt, and clouds drifting high above. All placed clear of bases,
-- belt, volcano, lagoon, hill, shop and spawn.
local function decorateIsland(folder)
	local leaf = Color3.fromRGB(60, 170, 70)
	local trunk = Color3.fromRGB(110, 80, 45)
	for _, pos in ipairs({
		Vector3.new(60, 0, -60),
		Vector3.new(-60, 0, 60),
		Vector3.new(130, 0, -45),
		Vector3.new(-130, 0, 45),
	}) do
		decor("PalmTrunk", Vector3.new(1.2, 9, 1.2), pos + Vector3.new(0, 5.2, 0), trunk, Enum.Material.Wood, folder)
		flatball("PalmLeaf", Vector3.new(6, 1.2, 2.5), pos + Vector3.new(2.5, 9.8, 0), leaf, Enum.Material.Grass, folder, 0)
		flatball("PalmLeaf", Vector3.new(6, 1.2, 2.5), pos + Vector3.new(-2.5, 9.8, 0), leaf, Enum.Material.Grass, folder, 0)
		flatball("PalmLeaf", Vector3.new(2.5, 1.2, 6), pos + Vector3.new(0, 9.8, 2.5), leaf, Enum.Material.Grass, folder, 0)
		flatball("PalmLeaf", Vector3.new(2.5, 1.2, 6), pos + Vector3.new(0, 9.8, -2.5), leaf, Enum.Material.Grass, folder, 0)
	end
	local rock = Color3.fromRGB(110, 110, 110)
	ball("IslandRock1", 4, Vector3.new(150, 2.3, 30), rock, Enum.Material.Rock, folder, 0)
	ball("IslandRock2", 5, Vector3.new(-150, 2.8, -30), rock, Enum.Material.Rock, folder, 0)
	ball("IslandRock3", 4, Vector3.new(30, 2.3, 150), rock, Enum.Material.Rock, folder, 0)
	ball("IslandRock4", 3, Vector3.new(-30, 1.8, -150), rock, Enum.Material.Rock, folder, 0)
	ball("IslandRock5", 3, Vector3.new(160, 1.8, -80), rock, Enum.Material.Rock, folder, 0)
	ball("IslandRock6", 4, Vector3.new(-160, 2.3, 80), rock, Enum.Material.Rock, folder, 0)
	local flame = Color3.fromRGB(255, 140, 30)
	for _, pos in ipairs({
		Vector3.new(-40, 0, -8),
		Vector3.new(-40, 0, 8),
		Vector3.new(40, 0, -8),
		Vector3.new(40, 0, 8),
	}) do
		decor("TorchPost", Vector3.new(0.5, 3, 0.5), pos + Vector3.new(0, 2.2, 0), Color3.fromRGB(90, 65, 40), Enum.Material.Wood, folder)
		ball("TorchFlame", 1.5, pos + Vector3.new(0, 4.3, 0), flame, Enum.Material.Neon, folder, 0)
	end
	local cloud = Color3.fromRGB(245, 245, 245)
	flatball("Cloud1", Vector3.new(20, 6, 12), Vector3.new(0, 45, -60), cloud, Enum.Material.SmoothPlastic, folder, 0.3)
	flatball("Cloud2", Vector3.new(16, 5, 10), Vector3.new(-80, 48, 40), cloud, Enum.Material.SmoothPlastic, folder, 0.3)
	flatball("Cloud3", Vector3.new(18, 6, 11), Vector3.new(80, 42, -30), cloud, Enum.Material.SmoothPlastic, folder, 0.3)
	flatball("Cloud4", Vector3.new(15, 5, 10), Vector3.new(30, 50, 80), cloud, Enum.Material.SmoothPlastic, folder, 0.3)
	flatball("Cloud5", Vector3.new(17, 5, 10), Vector3.new(-40, 44, -100), cloud, Enum.Material.SmoothPlastic, folder, 0.3)

	-- Four more palms at the island corners, inside the grass disc.
	local leaf2 = Color3.fromRGB(60, 170, 70)
	local trunk2 = Color3.fromRGB(110, 80, 45)
	for _, pos in ipairs({
		Vector3.new(135, 0, 135),
		Vector3.new(-135, 0, 135),
		Vector3.new(135, 0, -135),
		Vector3.new(-135, 0, -135),
	}) do
		decor("PalmTrunk", Vector3.new(1.2, 9, 1.2), pos + Vector3.new(0, 5.2, 0), trunk2, Enum.Material.Wood, folder)
		flatball("PalmLeaf", Vector3.new(6, 1.2, 2.5), pos + Vector3.new(2.5, 9.8, 0), leaf2, Enum.Material.Grass, folder, 0)
		flatball("PalmLeaf", Vector3.new(6, 1.2, 2.5), pos + Vector3.new(-2.5, 9.8, 0), leaf2, Enum.Material.Grass, folder, 0)
		flatball("PalmLeaf", Vector3.new(2.5, 1.2, 6), pos + Vector3.new(0, 9.8, 2.5), leaf2, Enum.Material.Grass, folder, 0)
		flatball("PalmLeaf", Vector3.new(2.5, 1.2, 6), pos + Vector3.new(0, 9.8, -2.5), leaf2, Enum.Material.Grass, folder, 0)
	end
	-- Six more rocks on the outer sand ring.
	local rock2 = Color3.fromRGB(110, 110, 110)
	ball("IslandRock7", 4, Vector3.new(185, 2.3, 100), rock2, Enum.Material.Rock, folder, 0)
	ball("IslandRock8", 5, Vector3.new(-185, 2.8, 100), rock2, Enum.Material.Rock, folder, 0)
	ball("IslandRock9", 4, Vector3.new(185, 2.3, -100), rock2, Enum.Material.Rock, folder, 0)
	ball("IslandRock10", 3, Vector3.new(-185, 1.8, -100), rock2, Enum.Material.Rock, folder, 0)
	ball("IslandRock11", 4, Vector3.new(100, 2.3, 185), rock2, Enum.Material.Rock, folder, 0)
	ball("IslandRock12", 3, Vector3.new(-100, 1.8, 185), rock2, Enum.Material.Rock, folder, 0)
	-- Six more torches: four more along the belt, two flanking spawn.
	local flame2 = Color3.fromRGB(255, 140, 30)
	for _, pos in ipairs({
		Vector3.new(-60, 0, -8), Vector3.new(-60, 0, 8),
		Vector3.new(60, 0, -8), Vector3.new(60, 0, 8),
		Vector3.new(-8, 0, 45), Vector3.new(8, 0, 45),
	}) do
		decor("TorchPost", Vector3.new(0.5, 3, 0.5), pos + Vector3.new(0, 2.2, 0), Color3.fromRGB(90, 65, 40), Enum.Material.Wood, folder)
		ball("TorchFlame", 1.5, pos + Vector3.new(0, 4.3, 0), flame2, Enum.Material.Neon, folder, 0)
	end
	-- Beach umbrellas on the sand by the lagoon (outside the water).
	for _, pos in ipairs({
		Vector3.new(55, 0, -32), Vector3.new(55, 0, 32),
		Vector3.new(132, 0, -30), Vector3.new(132, 0, 30),
	}) do
		decor("UmbrellaPole", Vector3.new(0.4, 5, 0.4), pos + Vector3.new(0, 3.2, 0), Color3.fromRGB(240, 240, 240), Enum.Material.SmoothPlastic, folder)
		flatball("UmbrellaTop", Vector3.new(7, 1, 7), pos + Vector3.new(0, 5.9, 0), Color3.fromRGB(255, 90, 90), Enum.Material.SmoothPlastic, folder, 0)
	end
	-- Two bright flags flanking the spawn path.
	decor("SpawnFlagPoleL", Vector3.new(0.4, 6, 0.4), Vector3.new(-12, 3.7, 40), Color3.fromRGB(90, 90, 100), Enum.Material.Metal, folder)
	decor("SpawnFlagL", Vector3.new(3, 1.8, 0.15), Vector3.new(-12, 5.5, 40), Color3.fromRGB(255, 220, 60), Enum.Material.Neon, folder)
	decor("SpawnFlagPoleR", Vector3.new(0.4, 6, 0.4), Vector3.new(12, 3.7, 40), Color3.fromRGB(90, 90, 100), Enum.Material.Metal, folder)
	decor("SpawnFlagR", Vector3.new(3, 1.8, 0.15), Vector3.new(12, 5.5, 40), Color3.fromRGB(60, 220, 220), Enum.Material.Neon, folder)
end

-- Ground fill: the island surface itself must not read as a flat blank
-- slab. Darker sand patches, grass tufts, flower clusters, bushes and
-- stone paths break the surface up, so the ground looks lived-in from
-- any camera angle. All flat on the grass top (y=0.7), all
-- CanCollide=false, all placed clear of the belt, bases, volcano,
-- lagoon, hill, shop and spawn.
local function decorateGroundFill(folder)
	-- Darker sand patches scattered on the grass.
	local sandPatch = Color3.fromRGB(168, 148, 98)
	local patchSpots = {
		{ 45, 25, 0.3 }, { -45, 25, 1.1 }, { 45, -25, 2.0 }, { -45, -25, 0.7 },
		{ 110, 60, 0.9 }, { -110, 60, 2.4 }, { 110, -60, 1.6 }, { -110, -60, 0.2 },
		{ 20, -45, 2.8 }, { -20, -45, 1.3 }, { 150, 100, 0.5 }, { -150, 100, 2.1 },
		{ 150, -100, 1.9 }, { -150, -100, 0.8 },
	}
	for i, s in ipairs(patchSpots) do
		decorR("SandPatch" .. tostring(i), Vector3.new(10, 0.15, 8), Vector3.new(s[1], 0.75, s[2]), sandPatch, Enum.Material.Sand, folder, s[3])
	end

	-- Grass tufts across the whole island, not just the hill.
	local tuft = Color3.fromRGB(70, 150, 70)
	local tuftSpots = {
		{ 30, 18 }, { -30, 18 }, { 30, -18 }, { -30, -18 },
		{ 55, 30 }, { -55, 30 }, { 55, -30 }, { -55, -30 },
		{ 15, -30 }, { -15, -30 }, { 15, 35 }, { -15, 35 },
		{ 100, 45 }, { -100, 45 }, { 100, -45 }, { -100, -45 },
		{ 140, 120 }, { -140, 120 }, { 140, -120 }, { -140, -120 },
		{ 170, 20 }, { -170, 20 }, { 170, -20 }, { -170, -20 },
		{ 80, 60 }, { -80, 60 }, { 80, -60 }, { -80, -60 },
	}
	for i, s in ipairs(tuftSpots) do
		ball("GroundTuft" .. tostring(i), 2, Vector3.new(s[1], 1.2, s[2]), tuft, Enum.Material.Grass, folder, 0)
	end

	-- Flower clusters: three tiny bright dots each.
	local flowerCols = {
		Color3.fromRGB(255, 120, 180),
		Color3.fromRGB(255, 220, 60),
		Color3.fromRGB(255, 255, 255),
		Color3.fromRGB(180, 100, 255),
	}
	local flowerSpots = {
		{ 25, 25 }, { -25, 25 }, { 25, -25 }, { -25, -25 },
		{ 60, 45 }, { -60, 45 }, { 60, -45 }, { -60, -45 },
	}
	for i, s in ipairs(flowerSpots) do
		local c = flowerCols[((i - 1) % #flowerCols) + 1]
		ball("Flower" .. tostring(i) .. "a", 0.8, Vector3.new(s[1], 1.0, s[2]), c, Enum.Material.SmoothPlastic, folder, 0)
		ball("Flower" .. tostring(i) .. "b", 0.8, Vector3.new(s[1] + 1.5, 1.0, s[2] + 1), c, Enum.Material.SmoothPlastic, folder, 0)
		ball("Flower" .. tostring(i) .. "c", 0.8, Vector3.new(s[1] - 1.2, 1.0, s[2] + 1.4), c, Enum.Material.SmoothPlastic, folder, 0)
	end

	-- Bushes: bigger green blobs at the island edges and between bases.
	local bush = Color3.fromRGB(50, 130, 60)
	local bushSpots = {
		{ 120, 80, 4 }, { -120, 80, 3.5 }, { 120, -80, 4 }, { -120, -80, 3 },
		{ 180, 60, 4 }, { -180, 60, 3.5 }, { 180, -60, 3 }, { -180, -60, 4 },
		{ 90, 130, 3.5 }, { -90, 130, 4 }, { 90, -130, 4 }, { -90, -130, 3.5 },
	}
	for i, s in ipairs(bushSpots) do
		ball("Bush" .. tostring(i), s[3], Vector3.new(s[1], 0.7 + s[3] * 0.4, s[2]), bush, Enum.Material.Grass, folder, 0)
	end

	-- Stone paths: spawn to the belt, and spawn to the shop.
	local stone = Color3.fromRGB(190, 180, 160)
	for _, z in ipairs({ 40, 34, 28, 22, 16, 10 }) do
		decor("PathStone", Vector3.new(3, 0.2, 2), Vector3.new(0, 0.8, z), stone, Enum.Material.Slate, folder)
	end
	for _, z in ipairs({ 56, 60, 64 }) do
		decor("PathStone", Vector3.new(3, 0.2, 2), Vector3.new(0, 0.8, z), stone, Enum.Material.Slate, folder)
	end
end

function WorldBuilder.build()
	local folder = Instance.new("Folder")
	folder.Name = "KrakatoaIsland"
	folder.Parent = workspace

	-- The island itself: a big sandy disc rising out of the ocean.
	-- The baseplate was lowered (default.project.json) so the ocean
	-- shows: ocean top y=-2, sand top y=0, grass top y=0.7. The island
	-- is 440 wide so every gameplay part (bases at radius 82, volcano
	-- to x=-118, lagoon to x=124, hill to z=-114) sits well inside it.
	local island = part("Island", Vector3.new(440, 4, 440), Vector3.new(0, -2, 0), Color3.fromRGB(194, 178, 128), Enum.Material.Sand, folder)
	island.TopSurface = Enum.SurfaceType.Smooth
	local islandGrass = part("IslandGrass", Vector3.new(400, 1, 400), Vector3.new(0, 0.2, 0), Color3.fromRGB(96, 160, 80), Enum.Material.Grass, folder)
	islandGrass.TopSurface = Enum.SurfaceType.Smooth

	-- The ocean: open water around the island, so the island reads as
	-- a lagoon island instead of a disc on a grey plate. Non-colliding:
	-- a player who walks off the island drops onto the lowered
	-- baseplate just under the surface and can walk back up.
	local ocean = part("Ocean", Vector3.new(512, 2, 512), Vector3.new(0, -3, 0), Color3.fromRGB(30, 120, 200), Enum.Material.Water, folder)
	-- Fully opaque: at 25% transparency the grey studded baseplate
	-- showed straight through and the "ocean" read as grey studs.
	ocean.Transparency = 0
	ocean.TopSurface = Enum.SurfaceType.Smooth
	ocean.CanCollide = false

	-- The lagoon: blue water at the east end of the belt.
	local lagoon = part("Lagoon", Vector3.new(56, 1, 44), Vector3.new(96, 0.6, 0), Color3.fromRGB(40, 140, 220), Enum.Material.Water, folder)
	lagoon.Transparency = 0.25
	label(lagoon, "LAGOON", Color3.fromRGB(160, 220, 255), 24)

	-- The volcano: stepped rock at the west end, lava cap on top.
	part("VolcanoBase", Vector3.new(44, 10, 44), Vector3.new(-96, 5, 0), Color3.fromRGB(90, 80, 80), Enum.Material.Rock, folder)
	part("VolcanoMid", Vector3.new(30, 10, 30), Vector3.new(-96, 15, 0), Color3.fromRGB(80, 70, 70), Enum.Material.Rock, folder)
	part("VolcanoTop", Vector3.new(16, 8, 16), Vector3.new(-96, 24, 0), Color3.fromRGB(70, 60, 60), Enum.Material.Rock, folder)
	local lava = part("Lava", Vector3.new(12, 2, 12), Vector3.new(-96, 28.5, 0), Color3.fromRGB(255, 90, 20), Enum.Material.Neon, folder)
	label(lava, "KRAKATOA", Color3.fromRGB(255, 180, 80), 24)

	-- The safe hill: high ground opposite the volcano for tsunami escapes.
	part("HillBase", Vector3.new(36, 8, 36), Vector3.new(0, 4, -96), Color3.fromRGB(100, 150, 80), Enum.Material.Grass, folder)
	part("HillTop", Vector3.new(22, 6, 22), Vector3.new(0, 11, -96), Color3.fromRGB(120, 170, 90), Enum.Material.Grass, folder)
	local hillTop = part("HillPad", Vector3.new(20, 1, 20), Vector3.new(0, 14.5, -96), Color3.fromRGB(150, 200, 110), Enum.Material.Grass, folder)
	label(hillTop, "SAFE HILL", Color3.fromRGB(255, 255, 255), 24)

	-- The belt: the runway brainrots walk, volcano end to lagoon end.
	-- Its centre and end pads come from Config.Belt, so the part, the
	-- spawn point and the walk code can never disagree about its ends.
	local beltStart = Config.Belt.startX
	local beltEnd = beltStart + Config.Belt.length
	local belt = part("Belt", Vector3.new(Config.Belt.length, 1, Config.Belt.width), Vector3.new(beltStart + Config.Belt.length / 2, 0.7, 0), Color3.fromRGB(60, 60, 75), Enum.Material.Concrete, folder)
	label(belt, "BRAINROT BELT - click a brainrot to buy it", Color3.fromRGB(255, 240, 120), 20)
	part("BeltStart", Vector3.new(8, 1.4, 10), Vector3.new(beltStart, 0.9, 0), Color3.fromRGB(255, 120, 40), Enum.Material.Neon, folder)
	part("BeltEnd", Vector3.new(8, 1.4, 10), Vector3.new(beltEnd, 0.9, 0), Color3.fromRGB(60, 160, 255), Enum.Material.Neon, folder)

	-- The shop pad: where upgrades are bought (the HUD buttons do it too).
	local shop = part("ShopPad", Vector3.new(14, 1, 14), Vector3.new(0, 0.7, 72), Color3.fromRGB(255, 200, 60), Enum.Material.SmoothPlastic, folder)
	label(shop, "SHOP - upgrades & rebirth in the HUD", Color3.fromRGB(60, 40, 0), 20)

	-- Spawn point near the shop, facing the belt.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "IslandSpawn"
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = Vector3.new(0, 1, 48)
	spawn.Color = Color3.fromRGB(120, 200, 120)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = folder

	-- Eight bases in a ring.
	for i = 1, Config.Bases.count do
		WorldBuilder.buildBase(i, WorldBuilder.basePositions[i])
	end

	-- Visual polish (decor only, all CanCollide=false): a richer
	-- volcano, conveyor belt, lagoon, hill, shop and island dressing.
	decorateVolcano(folder)
	decorateBelt(folder)
	decorateLagoon(folder)
	decorateHill(folder)
	decorateShop(folder)
	decorateIsland(folder)
	decorateGroundFill(folder)

	return folder
end

-- Belt position for a brainrot that has walked a given distance in studs.
-- The y puts the body's centre a half-body above the belt top (belt
-- top y=1.2, body half 1.5), so it walks on the belt, not inside it.
function WorldBuilder.beltPosition(progress)
	local x = Config.Belt.startX + progress
	return Vector3.new(x, 2.7, 0)
end

return WorldBuilder
