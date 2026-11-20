-- BRAINROT BAZAAR: builds the 3D night-market street the game is played on.
-- Rojo only ships the baseplate; everything a player can see and walk
-- on is built here, once, when the server starts, so the place file
-- stays small and the world lives in readable code. The belt runs down
-- the middle of a neon night street (west to east), six market-stall
-- bases line both sides of the street, the spawn and shop sit south,
-- and a raised neon plaza stands north for wave escapes.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local WorldBuilder = {}

-- Where each base sits: 3 on the north side (z=-32) and 3 on the south
-- side (z=+32), at x=-60, 0, +60. Bases face the street (open front
-- toward z=0). Config.Bases.count becomes 6; build() loops over this
-- table, so the world and the count can never disagree.
WorldBuilder.basePositions = {
	Vector3.new(-60, 0, -32),
	Vector3.new(0, 0, -32),
	Vector3.new(60, 0, -32),
	Vector3.new(-60, 0, 32),
	Vector3.new(0, 0, 32),
	Vector3.new(60, 0, 32),
}

-- Which way a base's open front faces: north bases face +Z (toward
-- the street), south bases face -Z. The back wall is the opposite way.
local function baseOutward(index)
	if index <= 3 then
		return Vector3.new(0, 0, -1)
	end
	return Vector3.new(0, 0, 1)
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
-- plays — it only makes the street look like a real night market.
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

-- A real light: a PointLight parented to a part, so it actually
-- illuminates the ground and the characters near it. Every light is
-- parented to a part that exists for the whole server lifetime, and
-- there are only a few dozen in total, so performance stays fine.
local function light(parent, colour, range, brightness)
	local l = Instance.new("PointLight")
	l.Color = colour
	l.Range = range
	l.Brightness = brightness
	l.Parent = parent
	return l
end

-- Uniform ball only: a Ball part with a non-cubic size ERRORS at
-- runtime and can kill the spawner (broke the game once in c056694).
-- Every ball in this file goes through here with one diameter.
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

-- Flattened decor piece. Deliberately a plain box, NOT a Ball: a Ball
-- with a non-cubic size errors, so anything flat must be a box.
local function flatball(name, size, position, colour, material, parent, transparency)
	local p = decor(name, size, position, colour, material, parent)
	p.Transparency = transparency or 0
	return p
end

-- One accent colour per base, so every stall reads as its own shop.
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

-- Build one player base as a market stall: floor, back wall, side
-- walls, slot pads as display pedestals, a neon sign, a striped
-- awning, a counter, and a lock gate across the open front.
-- Returns the folder holding it, so the server can find its slot pads.
function WorldBuilder.buildBase(index, centre)
	local folder = Instance.new("Folder")
	folder.Name = "Base" .. tostring(index)
	folder.Parent = workspace

	local accent = BASE_ACCENTS[((index - 1) % #BASE_ACCENTS) + 1]
	local outward = baseOutward(index)
	local sideDir = Vector3.new(-outward.Z, 0, outward.X)
	local yaw = math.atan2(-outward.X, -outward.Z)

	-- Rotate a local offset (x along the stall, z toward the back
	-- wall) into world space. North stalls yaw 0, south stalls yaw pi.
	local function rotate(offset)
		return Vector3.new(
			offset.X * math.cos(yaw) - offset.Z * math.sin(yaw),
			0,
			offset.X * math.sin(yaw) + offset.Z * math.cos(yaw)
		)
	end

	-- Floor: dark market tile, slightly alternating per stall.
	local floorColour = Color3.fromRGB(45, 45, 60)
	if index % 2 == 0 then
		floorColour = Color3.fromRGB(60, 45, 55)
	end
	part("Floor", Vector3.new(18, 1, 14), centre + Vector3.new(0, 0.5, 0), floorColour, Enum.Material.SmoothPlastic, folder)

	-- Back wall faces away from the street; the front stays open.
	local backPos = centre + outward * 6.5
	part("BackWall", Vector3.new(18, 6, 1), backPos + Vector3.new(0, 3, 0), Color3.fromRGB(35, 35, 50), Enum.Material.Concrete, folder)
	part("SideWallL", Vector3.new(1, 4, 14), centre + sideDir * 8.5 + Vector3.new(0, 2, 0), Color3.fromRGB(35, 35, 50), Enum.Material.Concrete, folder)
	part("SideWallR", Vector3.new(1, 4, 14), centre - sideDir * 8.5 + Vector3.new(0, 2, 0), Color3.fromRGB(35, 35, 50), Enum.Material.Concrete, folder)

	-- Neon sign board above the back wall, in the stall's accent.
	local signBoard = decor("SignBoard", Vector3.new(10, 2.5, 0.5), backPos + Vector3.new(0, 7.2, 0), Color3.fromRGB(20, 20, 30), Enum.Material.SmoothPlastic, folder)
	label(signBoard, "BASE " .. tostring(index), accent, 24)
	decorR("SignTrim", Vector3.new(10, 0.4, 0.6), backPos + Vector3.new(0, 5.9, 0), accent, Enum.Material.Neon, folder, yaw)

	-- The lock gate: a bright bar across the open front while locked.
	local gate = part("LockGate", Vector3.new(18, 3, 1), centre - outward * 6.5 + Vector3.new(0, 2.5, 0), Color3.fromRGB(255, 60, 60), Enum.Material.Neon, folder)
	gate.Transparency = 1
	gate.CanCollide = false
	gate.Name = "LockGate"

	-- Striped awning over the stall, from the back wall toward the
	-- front: alternating accent and white strips.
	for i = 0, 4 do
		local colour = accent
		if i % 2 == 1 then
			colour = Color3.fromRGB(245, 245, 240)
		end
		decorR("Awning", Vector3.new(18, 0.3, 1.5), centre + rotate(Vector3.new(0, 0, -6 + i * 1.5)) + Vector3.new(0, 6.3, 0), colour, Enum.Material.SmoothPlastic, folder, yaw)
	end

	-- Counter near the front, between the front pads and the gate.
	decorR("Counter", Vector3.new(10, 1.6, 1.6), centre + rotate(Vector3.new(0, 0, 5.8)) + Vector3.new(0, 1.8, 0), Color3.fromRGB(120, 85, 50), Enum.Material.Wood, folder, yaw)
	decorR("CounterTop", Vector3.new(10.4, 0.3, 2), centre + rotate(Vector3.new(0, 0, 5.8)) + Vector3.new(0, 2.7, 0), accent, Enum.Material.Neon, folder, yaw)

	-- Warm stall light under the awning, so the stall, its pedestals
	-- and any brainrots on them read clearly at night.
	local stallLamp = decor("StallLamp", Vector3.new(1, 0.4, 1), centre + Vector3.new(0, 5.5, 0), Color3.fromRGB(255, 220, 150), Enum.Material.Neon, folder)
	light(stallLamp, Color3.fromRGB(255, 200, 130), 15, 1.5)

	-- Gate posts at the front corners, flag on the back wall.
	decor("GatePostL", Vector3.new(1, 5, 1), centre - outward * 6.5 + sideDir * 8.5 + Vector3.new(0, 3.5, 0), accent, Enum.Material.SmoothPlastic, folder)
	decor("GatePostR", Vector3.new(1, 5, 1), centre - outward * 6.5 - sideDir * 8.5 + Vector3.new(0, 3.5, 0), accent, Enum.Material.SmoothPlastic, folder)
	decor("FlagPole", Vector3.new(0.4, 6, 0.4), backPos + Vector3.new(0, 9, 0), Color3.fromRGB(90, 90, 100), Enum.Material.Metal, folder)
	decorR("Flag", Vector3.new(3.2, 2, 0.15), backPos + Vector3.new(0, 10.8, 0), accent, Enum.Material.Neon, folder, yaw)

	-- Slot pads as display pedestals: a dark plinth, a glowing neon
	-- ring plate, and the pad itself on top (pad top y=1.4, unchanged,
	-- so models sit exactly where they did before).
	for slot, offset in ipairs(SLOT_OFFSETS) do
		local rotated = rotate(offset)
		local padCentre = centre + rotated
		decor("Pedestal" .. tostring(slot), Vector3.new(2.8, 1, 2.8), padCentre + Vector3.new(0, 0.5, 0), Color3.fromRGB(30, 30, 42), Enum.Material.SmoothPlastic, folder)
		decor("PedestalGlow" .. tostring(slot), Vector3.new(3.8, 0.15, 3.8), padCentre + Vector3.new(0, 1.08, 0), accent, Enum.Material.Neon, folder)
		local pad = part("Slot" .. tostring(slot), Vector3.new(3.4, 0.4, 3.4), padCentre + Vector3.new(0, 1.2, 0), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, folder)
		pad.Transparency = 0.35
	end

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
	local outward = baseOutward(baseIndex)
	local yaw = math.atan2(-outward.X, -outward.Z)
	local rotated = Vector3.new(
		offset.X * math.cos(yaw) - offset.Z * math.sin(yaw),
		0,
		offset.X * math.sin(yaw) + offset.Z * math.cos(yaw)
	)
	return centre + rotated + Vector3.new(0, 2.9, 0)
end

-- Belt dressing: side skirts and glowing neon rails so it reads as a
-- real conveyor, roller stripes across it, and chevrons pointing east,
-- the way brainrots walk. All flat on the belt top, never in their path.
local function decorateBelt(folder)
	local beltStart = Config.Belt.startX
	local beltEnd = beltStart + Config.Belt.length
	local midX = beltStart + Config.Belt.length / 2
	local halfW = Config.Belt.width / 2
	decor("BeltSkirtN", Vector3.new(Config.Belt.length, 1, 0.8), Vector3.new(midX, 0.7, -halfW - 0.4), Color3.fromRGB(25, 25, 35), Enum.Material.Metal, folder)
	decor("BeltSkirtS", Vector3.new(Config.Belt.length, 1, 0.8), Vector3.new(midX, 0.7, halfW + 0.4), Color3.fromRGB(25, 25, 35), Enum.Material.Metal, folder)
	decor("BeltRailN", Vector3.new(Config.Belt.length, 0.3, 0.4), Vector3.new(midX, 1.35, -halfW - 0.4), Color3.fromRGB(255, 60, 180), Enum.Material.Neon, folder)
	decor("BeltRailS", Vector3.new(Config.Belt.length, 0.3, 0.4), Vector3.new(midX, 1.35, halfW + 0.4), Color3.fromRGB(60, 220, 255), Enum.Material.Neon, folder)
	-- Belt lamps: short posts on the north rail with a glowing bulb and
	-- a real PointLight, so the belt and the brainrots walking it are
	-- lit. Clear of the walking path (z=-4.4, characters walk at z=0).
	for i, lx in ipairs({ -60, -20, 20, 60 }) do
		decor("BeltLampPost", Vector3.new(0.4, 2.5, 0.4), Vector3.new(lx, 2.6, -halfW - 0.4), Color3.fromRGB(60, 60, 75), Enum.Material.Metal, folder)
		local bulbColour = Color3.fromRGB(255, 60, 180)
		if i % 2 == 0 then
			bulbColour = Color3.fromRGB(60, 220, 255)
		end
		local beltBulb = ball("BeltLampBulb", 1, Vector3.new(lx, 4, -halfW - 0.4), bulbColour, Enum.Material.Neon, folder, 0)
		light(beltBulb, bulbColour, 15, 1.2)
	end
	for x = beltStart + 8, beltEnd - 8, 20 do
		decor("BeltRoller", Vector3.new(1, 0.12, Config.Belt.width - 1), Vector3.new(x, 1.26, 0), Color3.fromRGB(180, 180, 190), Enum.Material.Metal, folder)
	end
	for _, cx in ipairs({ -40, 0, 40 }) do
		decorR("BeltChevronA", Vector3.new(2.6, 0.15, 0.9), Vector3.new(cx, 1.3, -0.92), Color3.fromRGB(255, 220, 60), Enum.Material.Neon, folder, math.rad(135))
		decorR("BeltChevronB", Vector3.new(2.6, 0.15, 0.9), Vector3.new(cx, 1.3, 0.92), Color3.fromRGB(255, 220, 60), Enum.Material.Neon, folder, math.rad(-135))
	end
end

-- The big arch over the street at x=0: two posts, a beam, and the
-- market's name glowing above the belt.
local function decorateArch(folder)
	local pink = Color3.fromRGB(255, 60, 180)
	local cyan = Color3.fromRGB(60, 220, 255)
	decor("ArchPostN", Vector3.new(1.5, 14, 1.5), Vector3.new(0, 7, -13), Color3.fromRGB(40, 40, 55), Enum.Material.Metal, folder)
	decor("ArchPostS", Vector3.new(1.5, 14, 1.5), Vector3.new(0, 7, 13), Color3.fromRGB(40, 40, 55), Enum.Material.Metal, folder)
	decor("ArchPostTrimN", Vector3.new(1.7, 0.5, 1.7), Vector3.new(0, 13.5, -13), pink, Enum.Material.Neon, folder)
	decor("ArchPostTrimS", Vector3.new(1.7, 0.5, 1.7), Vector3.new(0, 13.5, 13), cyan, Enum.Material.Neon, folder)
	local beam = decor("ArchBeam", Vector3.new(2, 3, 28), Vector3.new(0, 14.5, 0), Color3.fromRGB(20, 20, 30), Enum.Material.SmoothPlastic, folder)
	label(beam, "BRAINROT BAZAAR", Color3.fromRGB(255, 220, 60), 28)
	decor("ArchBeamTrim", Vector3.new(2.2, 0.4, 28), Vector3.new(0, 13, 0), pink, Enum.Material.Neon, folder)
	-- A row of little neon bulbs along the top of the beam.
	for i = 0, 8 do
		local colour = pink
		if i % 2 == 1 then
			colour = cyan
		end
		ball("ArchBulb", 0.8, Vector3.new(0, 16.4, -12 + i * 3), colour, Enum.Material.Neon, folder, 0)
	end
end

-- Market stalls along both sidewalk edges (z=+-16): counter, posts,
-- striped awning, hanging sign. Pure decor, clear of bases and belt.
local function decorateStalls(folder)
	local stallXs = { -80, -40, 40, 80 }
	local stallCols = {
		Color3.fromRGB(255, 60, 180),
		Color3.fromRGB(60, 220, 255),
		Color3.fromRGB(255, 220, 60),
		Color3.fromRGB(170, 90, 255),
	}
	local stallNames = { "RAMEN", "TOYS", "CANDY", "NOODLES" }
	local n = 0
	for _, side in ipairs({ -1, 1 }) do
		for _, x in ipairs(stallXs) do
			n = n + 1
			local accent = stallCols[((n - 1) % #stallCols) + 1]
			local z = side * 16
			local wood = Color3.fromRGB(120, 85, 50)
			decor("StallCounter", Vector3.new(7, 2, 2), Vector3.new(x, 1.5, z), wood, Enum.Material.Wood, folder)
			decor("StallCounterTop", Vector3.new(7.4, 0.3, 2.4), Vector3.new(x, 2.6, z), accent, Enum.Material.Neon, folder)
			for _, dx in ipairs({ -3.4, 3.4 }) do
				for _, dz in ipairs({ -2.6, 2.6 }) do
					decor("StallPost", Vector3.new(0.5, 5, 0.5), Vector3.new(x + dx, 3.2, z + dz), wood, Enum.Material.Wood, folder)
				end
			end
			for i = 0, 2 do
				local colour = accent
				if i % 2 == 1 then
					colour = Color3.fromRGB(245, 245, 240)
				end
				decor("StallAwning", Vector3.new(8, 0.3, 2.2), Vector3.new(x, 5.9, z - 2.2 + i * 2.2), colour, Enum.Material.SmoothPlastic, folder)
			end
			-- Warm lamp under the awning, so the stall and its counter read at night.
			local stallLamp = decor("StallLamp", Vector3.new(1, 0.4, 1), Vector3.new(x, 5, z), Color3.fromRGB(255, 220, 150), Enum.Material.Neon, folder)
			light(stallLamp, Color3.fromRGB(255, 200, 130), 12, 1.2)
			local sign = decor("StallSign", Vector3.new(5, 2, 0.4), Vector3.new(x, 7.2, z), Color3.fromRGB(20, 20, 30), Enum.Material.SmoothPlastic, folder)
			label(sign, stallNames[((n - 1) % #stallNames) + 1], accent, 20)
			-- Steam puff above the counter (uniform ball, transparent).
			ball("StallSteam", 3, Vector3.new(x + 2, 4.5, z), Color3.fromRGB(230, 230, 235), Enum.Material.SmoothPlastic, folder, 0.6)
		end
	end
end

-- String lights across the street: poles at the edges, then a sagging
-- line of little neon bulbs. Banners hang from two of the lines.
local function decorateStringLights(folder)
	local bulbCols = {
		Color3.fromRGB(255, 60, 180),
		Color3.fromRGB(60, 220, 255),
		Color3.fromRGB(255, 220, 60),
	}
	local bannerCols = {
		Color3.fromRGB(255, 60, 180),
		Color3.fromRGB(60, 220, 255),
	}
	for li, x in ipairs({ -50, -25, 25, 50 }) do
		decor("LightPoleN", Vector3.new(0.4, 10, 0.4), Vector3.new(x, 5, -12.5), Color3.fromRGB(60, 60, 75), Enum.Material.Metal, folder)
		decor("LightPoleS", Vector3.new(0.4, 10, 0.4), Vector3.new(x, 5, 12.5), Color3.fromRGB(60, 60, 75), Enum.Material.Metal, folder)
		-- Warm lamp bulb on top of each pole, with a real PointLight
		-- so the street and sidewalks are actually lit, not just neon.
		local bulbN = ball("LampBulb", 1.2, Vector3.new(x, 10.4, -12.5), Color3.fromRGB(255, 220, 150), Enum.Material.Neon, folder, 0)
		light(bulbN, Color3.fromRGB(255, 200, 130), 25, 1.5)
		local bulbS = ball("LampBulb", 1.2, Vector3.new(x, 10.4, 12.5), Color3.fromRGB(255, 220, 150), Enum.Material.Neon, folder, 0)
		light(bulbS, Color3.fromRGB(255, 200, 130), 25, 1.5)
		for i = 0, 8 do
			local t = i / 8 -- 0 at north edge, 1 at south edge
			local z = -12 + t * 24
			-- Sag: the middle of the line hangs ~1.5 studs lower.
			local y = 10 - math.sin(t * math.pi) * 1.5
			ball("StringBulb", 0.8, Vector3.new(x, y, z), bulbCols[(i % #bulbCols) + 1], Enum.Material.Neon, folder, 0)
		end
		if li == 2 or li == 3 then
			decor("Banner", Vector3.new(2, 3, 0.15), Vector3.new(x, 7.6, 0), bannerCols[li - 1], Enum.Material.SmoothPlastic, folder)
		end
	end
end

-- Hanging neon signs on the outer sidewalk edge, and paper lanterns
-- (uniform balls) floating above the sidewalks.
local function decorateSignsAndLanterns(folder)
	local signData = {
		{ -90, -24, "SUSHI", Color3.fromRGB(255, 60, 180) },
		{ -30, -24, "BOBA", Color3.fromRGB(60, 220, 255) },
		{ 30, -24, "ARCADE", Color3.fromRGB(255, 220, 60) },
		{ 90, -24, "PLUSH", Color3.fromRGB(170, 90, 255) },
		{ -90, 24, "TACO", Color3.fromRGB(255, 220, 60) },
		{ -30, 24, "KTV", Color3.fromRGB(255, 60, 180) },
		{ 30, 24, "MOCHI", Color3.fromRGB(60, 220, 255) },
		{ 90, 24, "FIGURES", Color3.fromRGB(170, 90, 255) },
	}
	for _, s in ipairs(signData) do
		decor("HangPole", Vector3.new(0.4, 7, 0.4), Vector3.new(s[1], 4, s[2]), Color3.fromRGB(60, 60, 75), Enum.Material.Metal, folder)
		local board = decor("HangSign", Vector3.new(4, 3, 0.3), Vector3.new(s[1], 8.2, s[2]), Color3.fromRGB(20, 20, 30), Enum.Material.SmoothPlastic, folder)
		label(board, s[3], s[4], 20)
	end
	local lanternCols = {
		Color3.fromRGB(255, 60, 180),
		Color3.fromRGB(255, 220, 60),
		Color3.fromRGB(60, 220, 255),
	}
	local lanternSpots = {
		{ -70, 7, -18 }, { -20, 7.5, -18 }, { 20, 7, -18 }, { 70, 7.5, -18 },
		{ -70, 7.5, 18 }, { -20, 7, 18 }, { 20, 7.5, 18 }, { 70, 7, 18 },
	}
	for i, s in ipairs(lanternSpots) do
		ball("Lantern", 2, Vector3.new(s[1], s[2], s[3]), lanternCols[((i - 1) % #lanternCols) + 1], Enum.Material.Neon, folder, 0)
	end
end

-- The safe plaza: the old safe hill spot, restyled as a raised neon
-- platform. Its top stays at y=15 with centre (0, 15, -96), which is
-- what WaveServer checks for wave safety. Neon trim + glow posts.
local function decoratePlaza(folder)
	decor("PlazaTrimBase", Vector3.new(36.5, 0.4, 36.5), Vector3.new(0, 8.2, -96), Color3.fromRGB(60, 220, 255), Enum.Material.Neon, folder)
	decor("PlazaTrimTop", Vector3.new(22.5, 0.4, 22.5), Vector3.new(0, 14.2, -96), Color3.fromRGB(255, 60, 180), Enum.Material.Neon, folder)
	for _, dx in ipairs({ -9, 9 }) do
		for _, dz in ipairs({ -9, 9 }) do
			decor("PlazaPost", Vector3.new(0.8, 4, 0.8), Vector3.new(dx, 17, -96 + dz), Color3.fromRGB(40, 40, 55), Enum.Material.Metal, folder)
			ball("PlazaGlow", 1.5, Vector3.new(dx, 19.4, -96 + dz), Color3.fromRGB(255, 220, 60), Enum.Material.Neon, folder, 0)
		end
	end
	decor("PlazaFlagPole", Vector3.new(0.4, 7, 0.4), Vector3.new(0, 18.5, -96), Color3.fromRGB(90, 90, 100), Enum.Material.Metal, folder)
	decor("PlazaFlag", Vector3.new(3.5, 2, 0.15), Vector3.new(0, 20.5, -96), Color3.fromRGB(255, 220, 60), Enum.Material.Neon, folder)
	-- Neon stepping stones from the plaza down to the street.
	local stone = Color3.fromRGB(60, 220, 255)
	for _, z in ipairs({ -70, -58, -46 }) do
		decor("PlazaPath", Vector3.new(3, 0.2, 2), Vector3.new(0, 0.6, z), stone, Enum.Material.Neon, folder)
	end
end

-- Shop kiosk: a stall on the shop pad by the spawn — posts at the pad
-- corners, a striped awning roof above, and a counter at the back.
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
	decor("ShopCounterTop", Vector3.new(10.4, 0.3, 2.4), Vector3.new(0, 3.3, 77.5), Color3.fromRGB(255, 220, 60), Enum.Material.Neon, folder)
	local sign = decor("ShopSign", Vector3.new(8, 2, 0.4), Vector3.new(0, 7.6, 72), Color3.fromRGB(20, 20, 30), Enum.Material.SmoothPlastic, folder)
	label(sign, "SHOP", Color3.fromRGB(255, 220, 60), 20)
end

-- A giant wave silhouette in the far distance at the west end: a tall
-- translucent goo wall with a crest curl. Decorative only — the real
-- wave is WaveServer's wall sweeping the belt.
local function decorateWaveSilhouette(folder)
	local goo = Color3.fromRGB(40, 140, 220)
	decorT("WaveSilhouette", Vector3.new(4, 45, 70), Vector3.new(-118, 18, 0), goo, Enum.Material.Neon, folder, 0.55)
	ball("WaveCrest", 20, Vector3.new(-116, 42, 0), goo, Enum.Material.Neon, folder, 0.55)
	ball("WaveCrest2", 12, Vector3.new(-116, 38, 18), goo, Enum.Material.Neon, folder, 0.6)
	ball("WaveCrest3", 12, Vector3.new(-116, 38, -18), goo, Enum.Material.Neon, folder, 0.6)
end

-- Distant skyline: dark building silhouettes with neon window strips,
-- outside the play area so they never interfere with the game.
local function decorateSkyline(folder)
	local buildings = {
		{ -120, -60, 22, 34, 22 }, { -60, -125, 24, 48, 24 }, { 0, -125, 20, 38, 20 },
		{ 60, -125, 24, 54, 24 }, { 120, -60, 22, 40, 22 }, { 130, 60, 22, 36, 22 },
		{ -130, 60, 22, 44, 22 }, { 0, 125, 26, 42, 26 },
	}
	local winCols = {
		Color3.fromRGB(255, 220, 60),
		Color3.fromRGB(60, 220, 255),
		Color3.fromRGB(255, 60, 180),
	}
	for i, b in ipairs(buildings) do
		local h = b[4]
		decor("Skyline", Vector3.new(b[3], h, b[5]), Vector3.new(b[1], h / 2, b[2]), Color3.fromRGB(18, 18, 30), Enum.Material.SmoothPlastic, folder)
		local wc = winCols[((i - 1) % #winCols) + 1]
		for _, wy in ipairs({ h * 0.35, h * 0.65 }) do
			decor("SkylineWindows", Vector3.new(b[3] + 0.2, 1, b[5] * 0.6), Vector3.new(b[1], wy, b[2]), wc, Enum.Material.Neon, folder)
		end
	end
end

-- Confetti dots scattered on the street and sidewalks (deterministic
-- spread, so the street looks the same every server start).
local function decorateConfetti(folder)
	local cols = {
		Color3.fromRGB(255, 60, 180),
		Color3.fromRGB(60, 220, 255),
		Color3.fromRGB(255, 220, 60),
		Color3.fromRGB(170, 90, 255),
	}
	for i = 1, 40 do
		local x = -95 + ((i * 37) % 190)
		local z = -11 + ((i * 53) % 22)
		if z > -3 and z < 3 then
			z = z + 6 -- keep the belt itself clear
		end
		decorR("Confetti", Vector3.new(0.6, 0.12, 0.6), Vector3.new(x, 0.56, z), cols[((i - 1) % #cols) + 1], Enum.Material.Neon, folder, (i * 0.7) % math.pi)
	end
end

function WorldBuilder.build()
	local folder = Instance.new("Folder")
	folder.Name = "BazaarBazaar"
	folder.Parent = workspace

	-- Ground slab: dark night-market ground filling the whole view, so
	-- no bare baseplate studs show. Top y=0.
	local ground = part("Ground", Vector3.new(260, 2, 260), Vector3.new(0, -1, 0), Color3.fromRGB(28, 28, 40), Enum.Material.SmoothPlastic, folder)
	ground.TopSurface = Enum.SurfaceType.Smooth

	-- The street: dark asphalt strip under the belt, 200 long, 24 wide.
	local street = part("Street", Vector3.new(200, 1, 24), Vector3.new(0, 0, 0), Color3.fromRGB(35, 35, 48), Enum.Material.SmoothPlastic, folder)
	street.TopSurface = Enum.SurfaceType.Smooth
	-- Neon edge strips: hot pink north, cyan south.
	decor("StreetEdgeN", Vector3.new(200, 0.15, 0.6), Vector3.new(0, 0.55, -12), Color3.fromRGB(255, 60, 180), Enum.Material.Neon, folder)
	decor("StreetEdgeS", Vector3.new(200, 0.15, 0.6), Vector3.new(0, 0.55, 12), Color3.fromRGB(60, 220, 255), Enum.Material.Neon, folder)
	-- Crosswalk markings at x=-40, 0, 40.
	for _, cx in ipairs({ -40, 0, 40 }) do
		for iz = -5, 5 do
			decor("Crosswalk", Vector3.new(1.5, 0.12, 1.2), Vector3.new(cx, 0.55, iz * 2), Color3.fromRGB(240, 240, 240), Enum.Material.SmoothPlastic, folder)
		end
	end

	-- Sidewalks on both sides of the street, up to the stall fronts.
	local walkN = part("SidewalkN", Vector3.new(200, 1, 13), Vector3.new(0, 0, -18.5), Color3.fromRGB(48, 48, 64), Enum.Material.Concrete, folder)
	walkN.TopSurface = Enum.SurfaceType.Smooth
	local walkS = part("SidewalkS", Vector3.new(200, 1, 13), Vector3.new(0, 0, 18.5), Color3.fromRGB(48, 48, 64), Enum.Material.Concrete, folder)
	walkS.TopSurface = Enum.SurfaceType.Smooth

	-- The safe plaza: stepped neon platform, top at y=15, centre
	-- (0, 15, -96) — the spot WaveServer treats as safe.
	part("PlazaBase", Vector3.new(36, 8, 36), Vector3.new(0, 4, -96), Color3.fromRGB(30, 30, 48), Enum.Material.Slate, folder)
	part("PlazaTop", Vector3.new(22, 6, 22), Vector3.new(0, 11, -96), Color3.fromRGB(38, 38, 58), Enum.Material.Slate, folder)
	local plazaTop = part("PlazaPad", Vector3.new(20, 1, 20), Vector3.new(0, 14.5, -96), Color3.fromRGB(48, 48, 70), Enum.Material.Slate, folder)
	label(plazaTop, "SAFE PLAZA", Color3.fromRGB(255, 255, 255), 24)

	-- The belt: the runway brainrots walk, west end to east end.
	-- Its centre and end pads come from Config.Belt, so the part, the
	-- spawn point and the walk code can never disagree about its ends.
	local beltStart = Config.Belt.startX
	local beltEnd = beltStart + Config.Belt.length
	local belt = part("Belt", Vector3.new(Config.Belt.length, 1, Config.Belt.width), Vector3.new(beltStart + Config.Belt.length / 2, 0.7, 0), Color3.fromRGB(40, 40, 55), Enum.Material.Concrete, folder)
	label(belt, "BRAINROT BELT - hold E or click a brainrot to buy it", Color3.fromRGB(255, 240, 120), 20)
	part("BeltStart", Vector3.new(8, 1.4, 10), Vector3.new(beltStart, 0.9, 0), Color3.fromRGB(255, 120, 40), Enum.Material.Neon, folder)
	part("BeltEnd", Vector3.new(8, 1.4, 10), Vector3.new(beltEnd, 0.9, 0), Color3.fromRGB(60, 160, 255), Enum.Material.Neon, folder)

	-- The shop pad: where upgrades are bought (the HUD buttons do it too).
	local shop = part("ShopPad", Vector3.new(14, 1, 14), Vector3.new(0, 0.7, 72), Color3.fromRGB(255, 200, 60), Enum.Material.SmoothPlastic, folder)
	label(shop, "SHOP - upgrades & rebirth in the HUD", Color3.fromRGB(60, 40, 0), 20)

	-- Spawn point near the shop, facing the belt.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "BazaarSpawn"
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = Vector3.new(0, 1, 48)
	spawn.Color = Color3.fromRGB(120, 200, 120)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = folder

	-- Six stall bases flanking the street.
	for i = 1, #WorldBuilder.basePositions do
		WorldBuilder.buildBase(i, WorldBuilder.basePositions[i])
	end

	-- Visual polish (decor only, all CanCollide=false).
	decorateBelt(folder)
	decorateArch(folder)
	decorateStalls(folder)
	decorateStringLights(folder)
	decorateSignsAndLanterns(folder)
	decoratePlaza(folder)
	decorateShop(folder)
	decorateWaveSilhouette(folder)
	decorateSkyline(folder)
	decorateConfetti(folder)

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
