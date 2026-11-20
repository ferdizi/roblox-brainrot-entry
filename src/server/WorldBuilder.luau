-- BRAINROT BAZAAR v2: builds the 3D neon night-market the game is
-- played on. Rojo only ships the baseplate; everything a player can
-- see and walk on is built here, once, when the server starts, so the
-- place file stays small and the world lives in readable code.
--
-- v2 BRIGHTNESS RULE (the old game died here): the world is BRIGHT.
-- Ground is warm cream, the street is a red carpet, the belt is gold,
-- stall walls are cream, the plaza is cyan. Nothing dark: every big
-- surface is RGB 200+. Characters are bright too, so bodies read
-- against the world from across the street. The spawn faces the belt,
-- so the DEFAULT camera (no Scriptable override) opens on the street,
-- the belt and Base 1 in one frame. The centrepiece is a giant
-- glowing Pocongo Disco-Ninja statue on the safe plaza.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local WorldBuilder = {}

-- Where each base sits: 3 on the north side (z=-32) and 3 on the south
-- side (z=+32), at x=-60, 0, +60. Bases face the street (open front
-- toward z=0).
WorldBuilder.basePositions = {
	Vector3.new(-60, 0, -32),
	Vector3.new(0, 0, -32),
	Vector3.new(60, 0, -32),
	Vector3.new(-60, 0, 32),
	Vector3.new(0, 0, 32),
	Vector3.new(60, 0, 32),
}

local function baseOutward(index)
	if index <= 3 then
		return Vector3.new(0, 0, -1)
	end
	return Vector3.new(0, 0, 1)
end

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

local function label(parent, text, colour, size, widthPx)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Sign"
	gui.Size = UDim2.fromOffset(widthPx or 120, 28)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 0, 0)
	gui.MaxDistance = 60
	gui.AlwaysOnTop = false
	gui.Parent = parent
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 0.35
	t.BackgroundColor3 = Color3.fromRGB(65, 65, 85)
	t.TextColor3 = colour or Color3.fromRGB(255, 255, 255)
	t.Text = text
	t.TextScaled = false
	t.TextSize = size or 14
	t.Font = Enum.Font.SourceSansBold
	t.Parent = gui
	return gui
end

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

local function decorR(name, size, position, colour, material, parent, yaw)
	local p = decor(name, size, position, colour, material, parent)
	p.CFrame = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
	return p
end

local function light(parent, colour, range, brightness)
	local l = Instance.new("PointLight")
	l.Color = colour
	l.Range = range
	l.Brightness = brightness
	l.Parent = parent
	return l
end

-- Uniform ball only: a Ball part with a non-cubic size ERRORS at
-- runtime and can kill the spawner. Every ball goes through here.
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

-- One player base as a market stall: bright floor, cream walls, slot
-- pads as display pedestals, a neon sign, a striped awning, a
-- counter, and a lock gate (decorative in v2). Returns the folder.
function WorldBuilder.buildBase(index, centre)
	local folder = Instance.new("Folder")
	folder.Name = "Base" .. tostring(index)
	folder.Parent = workspace

	local accent = BASE_ACCENTS[((index - 1) % #BASE_ACCENTS) + 1]
	local outward = baseOutward(index)
	local sideDir = Vector3.new(-outward.Z, 0, outward.X)
	local yaw = math.atan2(-outward.X, -outward.Z)

	local function rotate(offset)
		return Vector3.new(
			offset.X * math.cos(yaw) - offset.Z * math.sin(yaw),
			0,
			offset.X * math.sin(yaw) + offset.Z * math.cos(yaw)
		)
	end

	-- Floor: bright white tile, alternating warm tint per stall.
	local floorColour = Color3.fromRGB(245, 245, 240)
	if index % 2 == 0 then
		floorColour = Color3.fromRGB(250, 235, 210)
	end
	part("Floor", Vector3.new(18, 1, 14), centre + Vector3.new(0, 0.5, 0), floorColour, Enum.Material.SmoothPlastic, folder)

	-- Back wall (cream) and side walls; the front stays open.
	local backPos = centre + outward * 6.5
	part("BackWall", Vector3.new(18, 6, 1), backPos + Vector3.new(0, 3, 0), Color3.fromRGB(250, 240, 220), Enum.Material.Concrete, folder)
	part("SideWallL", Vector3.new(1, 4, 14), centre + sideDir * 8.5 + Vector3.new(0, 2, 0), Color3.fromRGB(250, 240, 220), Enum.Material.Concrete, folder)
	part("SideWallR", Vector3.new(1, 4, 14), centre - sideDir * 8.5 + Vector3.new(0, 2, 0), Color3.fromRGB(250, 240, 220), Enum.Material.Concrete, folder)

	-- Neon sign board above the back wall, in the stall's accent.
	local signBoard = decor("SignBoard", Vector3.new(10, 2.5, 0.5), backPos + Vector3.new(0, 7.2, 0), Color3.fromRGB(65, 65, 85), Enum.Material.SmoothPlastic, folder)
	label(signBoard, "BASE " .. tostring(index), accent, 14)
	decorR("SignTrim", Vector3.new(10, 0.4, 0.6), backPos + Vector3.new(0, 5.9, 0), accent, Enum.Material.Neon, folder, yaw)

	-- Striped awning over the stall, alternating accent and white.
	for i = 0, 4 do
		local colour = accent
		if i % 2 == 1 then
			colour = Color3.fromRGB(245, 245, 240)
		end
		decorR("Awning", Vector3.new(18, 0.3, 1.5), centre + rotate(Vector3.new(0, 0, -6 + i * 1.5)) + Vector3.new(0, 6.3, 0), colour, Enum.Material.SmoothPlastic, folder, yaw)
	end

	-- Counter near the front, kept LOW (top y=1.3) so it never hides
	-- the characters on the front pads.
	decorR("Counter", Vector3.new(10, 1.0, 1.6), centre + rotate(Vector3.new(0, 0, 5.8)) + Vector3.new(0, 0.5, 0), Color3.fromRGB(200, 150, 100), Enum.Material.Wood, folder, yaw)
	decorR("CounterTop", Vector3.new(10.4, 0.3, 2), centre + rotate(Vector3.new(0, 0, 5.8)) + Vector3.new(0, 1.15, 0), accent, Enum.Material.Neon, folder, yaw)

	-- Warm stall light under the awning.
	local stallLamp = decor("StallLamp", Vector3.new(1, 0.4, 1), centre + Vector3.new(0, 5.5, 0), Color3.fromRGB(255, 220, 150), Enum.Material.Neon, folder)
	light(stallLamp, Color3.fromRGB(255, 200, 130), 15, 1.5)

	-- Gate posts and a flag on the back wall.
	decor("GatePostL", Vector3.new(1, 5, 1), centre - outward * 6.5 + sideDir * 8.5 + Vector3.new(0, 3.5, 0), accent, Enum.Material.SmoothPlastic, folder)
	decor("GatePostR", Vector3.new(1, 5, 1), centre - outward * 6.5 - sideDir * 8.5 + Vector3.new(0, 3.5, 0), accent, Enum.Material.SmoothPlastic, folder)
	decor("FlagPole", Vector3.new(0.4, 6, 0.4), backPos + Vector3.new(0, 9, 0), Color3.fromRGB(150, 150, 170), Enum.Material.Metal, folder)
	decorR("Flag", Vector3.new(3.2, 2, 0.15), backPos + Vector3.new(0, 10.8, 0), accent, Enum.Material.Neon, folder, yaw)

	-- Slot pads as display pedestals: bright plinth, glowing ring.
	for slot, offset in ipairs(SLOT_OFFSETS) do
		local rotated = rotate(offset)
		local padCentre = centre + rotated
		decor("Pedestal" .. tostring(slot), Vector3.new(2.8, 1, 2.8), padCentre + Vector3.new(0, 0.5, 0), Color3.fromRGB(230, 230, 245), Enum.Material.SmoothPlastic, folder)
		decor("PedestalGlow" .. tostring(slot), Vector3.new(3.8, 0.15, 3.8), padCentre + Vector3.new(0, 1.08, 0), accent, Enum.Material.Neon, folder)
		local pad = part("Slot" .. tostring(slot), Vector3.new(3.4, 0.4, 3.4), padCentre + Vector3.new(0, 1.2, 0), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, folder)
		pad.Transparency = 0.35
	end

	return folder
end

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

-- Belt dressing: skirts, glowing neon rails, roller stripes, chevrons.
local function decorateBelt(folder)
	local beltStart = Config.Belt.startX
	local beltEnd = beltStart + Config.Belt.length
	local midX = beltStart + Config.Belt.length / 2
	local halfW = Config.Belt.width / 2
	decor("BeltSkirtN", Vector3.new(Config.Belt.length, 1, 0.8), Vector3.new(midX, 0.7, -halfW - 0.4), Color3.fromRGB(200, 170, 90), Enum.Material.Metal, folder)
	decor("BeltSkirtS", Vector3.new(Config.Belt.length, 1, 0.8), Vector3.new(midX, 0.7, halfW + 0.4), Color3.fromRGB(200, 170, 90), Enum.Material.Metal, folder)
	decor("BeltRailN", Vector3.new(Config.Belt.length, 0.3, 0.4), Vector3.new(midX, 1.35, -halfW - 0.4), Color3.fromRGB(255, 60, 180), Enum.Material.Neon, folder)
	decor("BeltRailS", Vector3.new(Config.Belt.length, 0.3, 0.4), Vector3.new(midX, 1.35, halfW + 0.4), Color3.fromRGB(60, 220, 255), Enum.Material.Neon, folder)
	for i, lx in ipairs({ -60, -20, 20, 60 }) do
		decor("BeltLampPost", Vector3.new(0.4, 2.5, 0.4), Vector3.new(lx, 2.6, -halfW - 0.4), Color3.fromRGB(150, 150, 170), Enum.Material.Metal, folder)
		local bulbColour = Color3.fromRGB(255, 60, 180)
		if i % 2 == 0 then
			bulbColour = Color3.fromRGB(60, 220, 255)
		end
		local beltBulb = ball("BeltLampBulb", 1, Vector3.new(lx, 4, -halfW - 0.4), bulbColour, Enum.Material.Neon, folder, 0)
		light(beltBulb, bulbColour, 15, 1.2)
	end
	for x = beltStart + 8, beltEnd - 8, 20 do
		decor("BeltRoller", Vector3.new(1, 0.12, Config.Belt.width - 1), Vector3.new(x, 1.26, 0), Color3.fromRGB(220, 190, 110), Enum.Material.Metal, folder)
	end
	for _, cx in ipairs({ -40, 0, 40 }) do
		decorR("BeltChevronA", Vector3.new(2.6, 0.15, 0.9), Vector3.new(cx, 1.3, -0.92), Color3.fromRGB(255, 220, 60), Enum.Material.Neon, folder, math.rad(135))
		decorR("BeltChevronB", Vector3.new(2.6, 0.15, 0.9), Vector3.new(cx, 1.3, 0.92), Color3.fromRGB(255, 220, 60), Enum.Material.Neon, folder, math.rad(-135))
	end
end

-- The big arch over the street at x=0 with the market's name.
local function decorateArch(folder)
	local pink = Color3.fromRGB(255, 60, 180)
	local cyan = Color3.fromRGB(60, 220, 255)
	decor("ArchPostN", Vector3.new(1.5, 14, 1.5), Vector3.new(0, 7, -13), Color3.fromRGB(200, 200, 220), Enum.Material.Metal, folder)
	decor("ArchPostS", Vector3.new(1.5, 14, 1.5), Vector3.new(0, 7, 13), Color3.fromRGB(200, 200, 220), Enum.Material.Metal, folder)
	decor("ArchPostTrimN", Vector3.new(1.7, 0.5, 1.7), Vector3.new(0, 13.5, -13), pink, Enum.Material.Neon, folder)
	decor("ArchPostTrimS", Vector3.new(1.7, 0.5, 1.7), Vector3.new(0, 13.5, 13), cyan, Enum.Material.Neon, folder)
	local beam = decor("ArchBeam", Vector3.new(2, 3, 28), Vector3.new(0, 14.5, 0), Color3.fromRGB(90, 90, 120), Enum.Material.SmoothPlastic, folder)
	label(beam, "BRAINROT BAZAAR", Color3.fromRGB(255, 220, 60), 16, 200)
	decor("ArchBeamTrim", Vector3.new(2.2, 0.4, 28), Vector3.new(0, 13, 0), pink, Enum.Material.Neon, folder)
	for i = 0, 8 do
		local colour = pink
		if i % 2 == 1 then
			colour = cyan
		end
		ball("ArchBulb", 0.8, Vector3.new(0, 16.4, -12 + i * 3), colour, Enum.Material.Neon, folder, 0)
	end
end

-- Market stalls along both sidewalk edges (z=+-16). Two kept signs
-- only (TOYS, NOODLES), far apart, so signs never stack on screen.
local function decorateStalls(folder)
	local stallXs = { -80, -40, 40, 80 }
	local stallCols = {
		Color3.fromRGB(255, 60, 180),
		Color3.fromRGB(60, 220, 255),
		Color3.fromRGB(255, 220, 60),
		Color3.fromRGB(170, 90, 255),
	}
	local keptStallSigns = {
		[2] = { "TOYS", 6.3 },
		[8] = { "NOODLES", 6.7 },
	}
	local n = 0
	for _, side in ipairs({ -1, 1 }) do
		for _, x in ipairs(stallXs) do
			n = n + 1
			local accent = stallCols[((n - 1) % #stallCols) + 1]
			local z = side * 16
			local wood = Color3.fromRGB(200, 150, 100)
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
			local stallLamp = decor("StallLamp", Vector3.new(1, 0.4, 1), Vector3.new(x, 5, z), Color3.fromRGB(255, 220, 150), Enum.Material.Neon, folder)
			light(stallLamp, Color3.fromRGB(255, 200, 130), 12, 1.2)
			local kept = keptStallSigns[n]
			if kept then
				local sign = decor("StallSign", Vector3.new(5, 2, 0.4), Vector3.new(x, kept[2], z), Color3.fromRGB(65, 65, 85), Enum.Material.SmoothPlastic, folder)
				label(sign, kept[1], accent, 13)
			end
			ball("StallSteam", 3, Vector3.new(x + 2, 4.5, z), Color3.fromRGB(240, 240, 245), Enum.Material.SmoothPlastic, folder, 0.6)
		end
	end
end

-- String lights across the street + banners.
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
		decor("LightPoleN", Vector3.new(0.4, 10, 0.4), Vector3.new(x, 5, -12.5), Color3.fromRGB(150, 150, 170), Enum.Material.Metal, folder)
		decor("LightPoleS", Vector3.new(0.4, 10, 0.4), Vector3.new(x, 5, 12.5), Color3.fromRGB(150, 150, 170), Enum.Material.Metal, folder)
		local bulbN = ball("LampBulb", 1.2, Vector3.new(x, 10.4, -12.5), Color3.fromRGB(255, 220, 150), Enum.Material.Neon, folder, 0)
		light(bulbN, Color3.fromRGB(255, 200, 130), 25, 1.5)
		local bulbS = ball("LampBulb", 1.2, Vector3.new(x, 10.4, 12.5), Color3.fromRGB(255, 220, 150), Enum.Material.Neon, folder, 0)
		light(bulbS, Color3.fromRGB(255, 200, 130), 25, 1.5)
		for i = 0, 8 do
			local t = i / 8
			local z = -12 + t * 24
			local y = 10 - math.sin(t * math.pi) * 1.5
			ball("StringBulb", 0.8, Vector3.new(x, y, z), bulbCols[(i % #bulbCols) + 1], Enum.Material.Neon, folder, 0)
		end
		if li == 2 or li == 3 then
			decor("Banner", Vector3.new(2, 3, 0.15), Vector3.new(x, 7.6, 0), bannerCols[li - 1], Enum.Material.SmoothPlastic, folder)
		end
	end
end

-- Paper lanterns floating above the sidewalks.
local function decorateLanterns(folder)
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

-- The safe plaza: stepped neon platform, top at y=15, centre
-- (0, 15, -96) — the spot WaveServer treats as safe.
local function decoratePlaza(folder)
	decor("PlazaTrimBase", Vector3.new(36.5, 0.4, 36.5), Vector3.new(0, 8.2, -96), Color3.fromRGB(60, 220, 255), Enum.Material.Neon, folder)
	decor("PlazaTrimTop", Vector3.new(22.5, 0.4, 22.5), Vector3.new(0, 14.2, -96), Color3.fromRGB(255, 60, 180), Enum.Material.Neon, folder)
	for _, dx in ipairs({ -9, 9 }) do
		for _, dz in ipairs({ -9, 9 }) do
			decor("PlazaPost", Vector3.new(0.8, 4, 0.8), Vector3.new(dx, 17, -96 + dz), Color3.fromRGB(200, 200, 220), Enum.Material.Metal, folder)
			ball("PlazaGlow", 1.5, Vector3.new(dx, 19.4, -96 + dz), Color3.fromRGB(255, 220, 60), Enum.Material.Neon, folder, 0)
		end
	end
	decor("PlazaFlagPole", Vector3.new(0.4, 7, 0.4), Vector3.new(0, 18.5, -96), Color3.fromRGB(150, 150, 170), Enum.Material.Metal, folder)
	decor("PlazaFlag", Vector3.new(3.5, 2, 0.15), Vector3.new(0, 20.5, -96), Color3.fromRGB(255, 220, 60), Enum.Material.Neon, folder)
	local stone = Color3.fromRGB(60, 220, 255)
	for _, z in ipairs({ -70, -58, -46 }) do
		decor("PlazaPath", Vector3.new(3, 0.2, 2), Vector3.new(0, 0.6, z), stone, Enum.Material.Neon, folder)
	end
end

-- THE CENTREPIECE: a giant glowing Pocongo Disco-Ninja statue on the
-- safe plaza — the top Secret character, ~20 studs tall, white shroud
-- body, disco-ball head, ninja headband, rainbow lights. It is the
-- focal point of every screenshot taken from the street.
local function decorateStatue(folder)
	local base = Vector3.new(0, 15, -96) -- plaza top
	local white = Color3.fromRGB(255, 255, 255)
	local pink = Color3.fromRGB(255, 60, 180)
	local cyan = Color3.fromRGB(60, 220, 255)
	local gold = Color3.fromRGB(255, 210, 60)
	-- Shroud body: wide white block, tapering top.
	decor("StatueBody", Vector3.new(8, 12, 5), base + Vector3.new(0, 6, 0), white, Enum.Material.SmoothPlastic, folder)
	decor("StatueBodyTop", Vector3.new(6, 3, 4), base + Vector3.new(0, 13, 0), white, Enum.Material.SmoothPlastic, folder)
	-- Disco-ball head (uniform ball) with a ninja headband.
	local head = ball("StatueHead", 5, base + Vector3.new(0, 17, 0), Color3.fromRGB(200, 220, 255), Enum.Material.Metal, folder, 0)
	light(head, Color3.fromRGB(200, 220, 255), 30, 2)
	decor("StatueBand", Vector3.new(5.2, 1, 5.2), base + Vector3.new(0, 17.5, 0), pink, Enum.Material.Neon, folder)
	decor("StatueBandTail", Vector3.new(0.8, 4, 0.3), base + Vector3.new(3, 15, -2), pink, Enum.Material.Neon, folder)
	-- Glowing eyes on the head.
	decor("StatueEyeL", Vector3.new(0.8, 1.2, 0.4), base + Vector3.new(-1.2, 17.3, 2.4), gold, Enum.Material.Neon, folder)
	decor("StatueEyeR", Vector3.new(0.8, 1.2, 0.4), base + Vector3.new(1.2, 17.3, 2.4), gold, Enum.Material.Neon, folder)
	-- Rainbow ring lights around the base.
	for i = 0, 7 do
		local angle = i * (math.pi * 2 / 8)
		local colour = pink
		if i % 3 == 1 then
			colour = cyan
		elseif i % 3 == 2 then
			colour = gold
		end
		ball("StatueRing", 1.2, base + Vector3.new(math.cos(angle) * 7, 0.8, math.sin(angle) * 7), colour, Enum.Material.Neon, folder, 0)
	end
	-- Name sign on the statue base.
	local sign = decor("StatueSign", Vector3.new(10, 2.5, 0.5), base + Vector3.new(0, 1.5, 4.5), Color3.fromRGB(65, 65, 85), Enum.Material.SmoothPlastic, folder)
	label(sign, "POCONGO DISCO-NINJA", Color3.fromRGB(255, 240, 90), 14, 180)
end

-- Shop kiosk on the shop pad by the spawn.
local function decorateShop(folder)
	local wood = Color3.fromRGB(200, 150, 100)
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
	local sign = decor("ShopSign", Vector3.new(8, 2, 0.4), Vector3.new(0, 7.2, 72), Color3.fromRGB(65, 65, 85), Enum.Material.SmoothPlastic, folder)
	label(sign, "SHOP", Color3.fromRGB(255, 220, 60), 14)
end

-- A giant wave silhouette in the far distance at the west end.
local function decorateWaveSilhouette(folder)
	local goo = Color3.fromRGB(40, 140, 220)
	decorT("WaveSilhouette", Vector3.new(4, 45, 70), Vector3.new(-118, 18, 0), goo, Enum.Material.Neon, folder, 0.55)
	ball("WaveCrest", 20, Vector3.new(-116, 42, 0), goo, Enum.Material.Neon, folder, 0.55)
	ball("WaveCrest2", 12, Vector3.new(-116, 38, 18), goo, Enum.Material.Neon, folder, 0.6)
	ball("WaveCrest3", 12, Vector3.new(-116, 38, -18), goo, Enum.Material.Neon, folder, 0.6)
end

-- Distant skyline: bright building silhouettes with neon windows.
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
		decor("Skyline", Vector3.new(b[3], h, b[5]), Vector3.new(b[1], h / 2, b[2]), Color3.fromRGB(180, 180, 210), Enum.Material.SmoothPlastic, folder)
		local wc = winCols[((i - 1) % #winCols) + 1]
		for _, wy in ipairs({ h * 0.35, h * 0.65 }) do
			decor("SkylineWindows", Vector3.new(b[3] + 0.2, 1, b[5] * 0.6), Vector3.new(b[1], wy, b[2]), wc, Enum.Material.Neon, folder)
		end
	end
end

-- Confetti dots scattered on the street and sidewalks (deterministic).
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
			z = z + 6
		end
		decorR("Confetti", Vector3.new(0.6, 0.12, 0.6), Vector3.new(x, 0.56, z), cols[((i - 1) % #cols) + 1], Enum.Material.Neon, folder, (i * 0.7) % math.pi)
	end
end

function WorldBuilder.build()
	local folder = Instance.new("Folder")
	folder.Name = "BazaarBazaar"
	folder.Parent = workspace

	-- Ground slab: warm cream, filling the whole view, top y=0.
	local ground = part("Ground", Vector3.new(260, 2, 260), Vector3.new(0, -1, 0), Color3.fromRGB(240, 220, 190), Enum.Material.SmoothPlastic, folder)
	ground.TopSurface = Enum.SurfaceType.Smooth

	-- The street: a bright red carpet under the belt, 200 long, 24 wide.
	local street = part("Street", Vector3.new(200, 1, 24), Vector3.new(0, 0, 0), Color3.fromRGB(255, 90, 90), Enum.Material.SmoothPlastic, folder)
	street.TopSurface = Enum.SurfaceType.Smooth
	-- Neon edge strips: hot pink north, cyan south.
	decor("StreetEdgeN", Vector3.new(200, 0.15, 0.6), Vector3.new(0, 0.55, -12), Color3.fromRGB(255, 60, 180), Enum.Material.Neon, folder)
	decor("StreetEdgeS", Vector3.new(200, 0.15, 0.6), Vector3.new(0, 0.55, 12), Color3.fromRGB(60, 220, 255), Enum.Material.Neon, folder)
	-- Crosswalk markings at x=-40, 0, 40.
	for _, cx in ipairs({ -40, 0, 40 }) do
		for iz = -5, 5 do
			decor("Crosswalk", Vector3.new(1.5, 0.12, 1.2), Vector3.new(cx, 0.55, iz * 2), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic, folder)
		end
	end

	-- Sidewalks on both sides of the street, light lavender-grey.
	local walkN = part("SidewalkN", Vector3.new(200, 1, 13), Vector3.new(0, 0, -18.5), Color3.fromRGB(205, 205, 225), Enum.Material.Concrete, folder)
	walkN.TopSurface = Enum.SurfaceType.Smooth
	local walkS = part("SidewalkS", Vector3.new(200, 1, 13), Vector3.new(0, 0, 18.5), Color3.fromRGB(205, 205, 225), Enum.Material.Concrete, folder)
	walkS.TopSurface = Enum.SurfaceType.Smooth

	-- The safe plaza: stepped platform, top at y=15, centre (0, 15, -96).
	-- Bright cyan top so it reads as the safe zone from anywhere.
	part("PlazaBase", Vector3.new(36, 8, 36), Vector3.new(0, 4, -96), Color3.fromRGB(150, 210, 235), Enum.Material.Slate, folder)
	part("PlazaTop", Vector3.new(22, 6, 22), Vector3.new(0, 11, -96), Color3.fromRGB(120, 200, 240), Enum.Material.Slate, folder)
	part("PlazaPad", Vector3.new(20, 1, 20), Vector3.new(0, 14.5, -96), Color3.fromRGB(100, 220, 255), Enum.Material.Slate, folder)

	-- The belt: a GOLDEN runway brainrots walk, west end to east end.
	local beltStart = Config.Belt.startX
	local beltEnd = beltStart + Config.Belt.length
	part("Belt", Vector3.new(Config.Belt.length, 1, Config.Belt.width), Vector3.new(beltStart + Config.Belt.length / 2, 0.7, 0), Color3.fromRGB(255, 200, 60), Enum.Material.Concrete, folder)
	part("BeltStart", Vector3.new(8, 1.4, 10), Vector3.new(beltStart, 0.9, 0), Color3.fromRGB(255, 120, 40), Enum.Material.Neon, folder)
	part("BeltEnd", Vector3.new(8, 1.4, 10), Vector3.new(beltEnd, 0.9, 0), Color3.fromRGB(60, 160, 255), Enum.Material.Neon, folder)

	-- The shop pad: where upgrades are bought (the HUD buttons do it too).
	part("ShopPad", Vector3.new(14, 1, 14), Vector3.new(0, 0.7, 72), Color3.fromRGB(255, 200, 60), Enum.Material.SmoothPlastic, folder)

	-- Spawn point near the shop, FACING the belt: the character spawns
	-- looking north-west down the street, so the DEFAULT camera opens
	-- on the belt, the arch and Base 1 in one frame. No Scriptable
	-- camera anywhere — zoom and orbit keep working.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "BazaarSpawn"
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.lookAt(Vector3.new(0, 1, 48), Vector3.new(-30, 4, -10))
	spawn.Color = Color3.fromRGB(120, 220, 120)
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
	decorateLanterns(folder)
	decoratePlaza(folder)
	decorateStatue(folder)
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
