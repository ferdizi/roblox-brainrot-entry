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

function WorldBuilder.build()
	local folder = Instance.new("Folder")
	folder.Name = "KrakatoaIsland"
	folder.Parent = workspace

	-- The island itself: a big sandy disc rising out of the ocean.
	-- The baseplate was lowered (default.project.json) so the ocean
	-- shows: ocean top y=-2, sand top y=0, grass top y=0.7. The island
	-- is 440 wide so every gameplay part (bases at radius 82, volcano
	-- to x=-118, lagoon to x=124, hill to z=-114) sits well inside it.
	part("Island", Vector3.new(440, 4, 440), Vector3.new(0, -2, 0), Color3.fromRGB(194, 178, 128), Enum.Material.Sand, folder)
	part("IslandGrass", Vector3.new(400, 1, 400), Vector3.new(0, 0.2, 0), Color3.fromRGB(96, 160, 80), Enum.Material.Grass, folder)

	-- The ocean: open water around the island, so the island reads as
	-- a lagoon island instead of a disc on a grey plate. Non-colliding:
	-- a player who walks off the island drops onto the lowered
	-- baseplate just under the surface and can walk back up.
	local ocean = part("Ocean", Vector3.new(512, 2, 512), Vector3.new(0, -3, 0), Color3.fromRGB(30, 120, 200), Enum.Material.Water, folder)
	ocean.Transparency = 0.25
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
