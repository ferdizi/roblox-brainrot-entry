-- BRAINROT BAZAAR v2: the belt, the buying and the money.
-- Owns every brainrot walking the belt, every brainrot sitting on a
-- base, and the one-second income tick that pays for them. Buying is
-- server-authoritative: the client only asks, the server checks the
-- cash, the free slot and the belt, and only then moves the model.
-- v2: 25 characters, Gadiel's roster, mutations Gula Aren / Gosong /
-- Glitch / Pelangi with distinct visuals, Secret = rainbow glow,
-- Mythic/Secret biggest and brightest. No stealing anywhere.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local State = require(script.Parent:WaitForChild("State"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

local BrainrotServer = {}
BrainrotServer.remotes = nil

local walking = {}
local idleBase = {}
local displayModels = {}

local function playSound(name)
	pcall(function()
		local sound = SoundService:FindFirstChild(name)
		if sound then
			sound:Play()
		end
	end)
end

-- Rainbow hues for Pelangi mutation and Secret rarity.
local RAINBOW_HUES = {
	Color3.fromRGB(255, 60, 60),
	Color3.fromRGB(255, 150, 40),
	Color3.fromRGB(255, 220, 60),
	Color3.fromRGB(80, 220, 90),
	Color3.fromRGB(60, 180, 255),
	Color3.fromRGB(170, 90, 255),
	Color3.fromRGB(255, 90, 180),
}
local GLITCH_HUES = {
	Color3.fromRGB(160, 100, 255),
	Color3.fromRGB(80, 230, 255),
	Color3.fromRGB(255, 120, 220),
}

-- Build the 3D model for one brainrot. Data-driven: the cast entry
-- carries its body/head shapes and sizes; the prop switch adds the
-- character details. Feet sit at local y=-1.5; the model pivots on
-- an invisible Root part at local (0,0,0) (Model.PivotOffset is NOT
-- scriptable and is never read or written).
-- HARD RULES: every Ball part has a UNIFORM Size (X=Y=Z); every
-- Cylinder has Y==Z. Anything non-uniform is a Block.
local function buildModelInner(entry)
	local model = Instance.new("Model")
	model.Name = entry.name

	local cast = Config.findCast(entry.castId) or Config.Cast[1]
	local mutationId = entry.mutation or "Normal"
	local mutationColour = nil
	for _, mut in ipairs(Config.Mutations) do
		if mut.id == mutationId then
			mutationColour = mut.colour
			break
		end
	end

	-- SCALE: Mythic and Secret are the biggest and brightest.
	local SCALE = 1.4
	if entry.rarity == "Mythic" then
		SCALE = 1.6
	elseif entry.rarity == "Secret" then
		SCALE = 1.7
	end

	local function brighten(colour)
		local m = math.max(colour.R, colour.G, colour.B)
		if m < 0.85 then
			local s = 0.85 / m
			return Color3.new(
				math.min(colour.R * s, 1),
				math.min(colour.G * s, 1),
				math.min(colour.B * s, 1))
		end
		return colour
	end

	-- Mutation visuals (each DIFFERENT):
	-- Gula Aren = golden sugar glaze (amber, Metal).
	-- Gosong = charred black body + orange ember light.
	-- Glitch = flickers purple/cyan (idle loop cycles it).
	-- Pelangi = rainbow cycling colours (idle loop cycles it).
	local bodyColour = brighten(entry.colour)
	local bodyMaterial = Enum.Material.SmoothPlastic
	local emberLight = false
	if mutationId == "Gula Aren" then
		bodyColour = Color3.fromRGB(255, 190, 60)
		bodyMaterial = Enum.Material.Metal
	elseif mutationId == "Gosong" then
		bodyColour = Color3.fromRGB(45, 32, 25)
		emberLight = true
	end
	local darkColour = Color3.new(bodyColour.R * 0.8, bodyColour.G * 0.8, bodyColour.B * 0.8)
	local rarityColour = Config.RarityColour[entry.rarity] or Color3.fromRGB(255, 255, 255)

	local function part(name, size, pos, colour, shape, material, rot, transparency)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		if rot then
			p.CFrame = CFrame.new(pos) * rot
		else
			p.Position = pos
		end
		p.Color = colour
		p.Shape = shape or Enum.PartType.Block
		p.Material = material or Enum.Material.SmoothPlastic
		if transparency then
			p.Transparency = transparency
		end
		p.Anchored = true
		p.CanCollide = false
		p.Parent = model
		return p
	end

	-- Body/head geometry from the cast spec (defaults: Block 4.5^3,
	-- Block head 2.6x2.2x2.6).
	local function shapeOf(s)
		if s == "Ball" then
			return Enum.PartType.Ball
		elseif s == "Cylinder" then
			return Enum.PartType.Cylinder
		else
			return Enum.PartType.Block
		end
	end
	local id = entry.castId
	local bodyW = cast.bodyW or 4.5
	local bodyH = cast.bodyH or 4.5
	local bodyD = cast.bodyD or 4.5
	local bodyShape = shapeOf(cast.bodyShape)
	local headShape = shapeOf(cast.headShape)
	local headW = cast.headW or 2.6
	local headH = cast.headH or 2.2
	local headD = cast.headD or 2.6
	local eyeScale = 1
	if headShape == Enum.PartType.Ball then
		eyeScale = 1.4
	end
	local legSize = Vector3.new(1, 1.5, 1)
	local armSize = Vector3.new(0.9, 2.2, 0.9)
	local armShape = Enum.PartType.Block
	local idleType = cast.idle or "bob"
	local ghostly = cast.ghostly or false
	if id == "bonk-pigeon" or id == "kerupuko-dudu" then
		legSize = Vector3.new(0.6, 1.0, 0.6)
		armSize = Vector3.new(0.7, 1.8, 1.6)
	end

	local bodyCentreY = (bodyH - 3) / 2
	local bodyTopY = bodyH - 1.5
	local bodySize = Vector3.new(bodyW, bodyH, bodyD)
	local bodyRot = nil
	if bodyShape == Enum.PartType.Cylinder then
		bodySize = Vector3.new(bodyH, bodyW, bodyD)
		bodyRot = CFrame.Angles(0, 0, math.pi / 2)
	end
	local bodyTransparency = ghostly and 0.35 or nil
	local body = part("Body", bodySize, Vector3.new(0, bodyCentreY, 0), bodyColour, bodyShape, bodyMaterial, bodyRot, bodyTransparency)

	-- Neon torso band in the rarity colour.
	part("NeonBand", Vector3.new(bodyW + 0.4, 0.9, bodyD + 0.4), Vector3.new(0, bodyCentreY, 0), rarityColour, Enum.PartType.Block, Enum.Material.Neon)

	-- Legs end at local y=-1.5 for every cast member.
	local legX = bodyW / 2 - 0.9
	local legY = -0.75
	for _, sx in ipairs({ -1, 1 }) do
		part("Leg", legSize, Vector3.new(sx * legX, legY, 0), darkColour)
	end

	-- Neon shoes in the rarity colour.
	for _, sx in ipairs({ -1, 1 }) do
		part("Shoe", Vector3.new(1.2, 0.5, 1.4), Vector3.new(sx * legX, -1.25, 0), rarityColour, Enum.PartType.Block, Enum.Material.Neon)
	end

	-- Arms.
	local armX = bodyW / 2 + 0.45
	local armY = 0.9
	for _, sx in ipairs({ -1, 1 }) do
		part("Arm", armSize, Vector3.new(sx * armX, armY, 0), darkColour, armShape)
	end

	-- Head.
	local headCentreY = bodyTopY + headH / 2
	local headTopY = bodyTopY + headH
	local headSize = Vector3.new(headW, headH, headD)
	local headRot = nil
	if headShape == Enum.PartType.Cylinder then
		headSize = Vector3.new(headH, headW, headD)
		headRot = CFrame.Angles(0, 0, math.pi / 2)
	end
	part("Head", headSize, Vector3.new(0, headCentreY, 0), bodyColour, headShape, Enum.Material.SmoothPlastic, headRot, bodyTransparency)

	-- Eyes + pupils on the front face.
	local eyeZ = headD / 2 + 0.1
	if headShape == Enum.PartType.Ball then
		eyeZ = headD / 2 + 0.05
	end
	local eyeW, eyeH = 0.55 * eyeScale, 0.75 * eyeScale
	for _, x in ipairs({ -0.62, 0.62 }) do
		part("Eye", Vector3.new(eyeW, eyeH, 0.35), Vector3.new(x, headCentreY + 0.3, eyeZ), Color3.fromRGB(255, 255, 255))
		part("Pupil", Vector3.new(0.28 * eyeScale, 0.4 * eyeScale, 0.16), Vector3.new(x, headCentreY + 0.3, eyeZ + 0.19), Color3.fromRGB(20, 20, 20))
	end

	-- Mouth (most characters).
	local mouthY = headCentreY - headH / 2 + 0.35
	if id == "soggy-toastino" then
		for _, sx in ipairs({ -1, 1 }) do
			part("Frown", Vector3.new(0.55, 0.22, 0.2), Vector3.new(sx * 0.35, mouthY, headD / 2 + 0.1), Color3.fromRGB(60, 30, 20), Enum.PartType.Block, nil, CFrame.Angles(0, 0, sx * 0.5))
		end
	elseif id == "glorpo-ghost-burger" then
		part("Smile", Vector3.new(1.2, 0.3, 0.2), Vector3.new(0, mouthY, headD / 2 + 0.1), Color3.fromRGB(255, 230, 90), Enum.PartType.Block, Enum.Material.Neon)
	else
		part("Mouth", Vector3.new(1.1, 0.35, 0.2), Vector3.new(0, mouthY, headD / 2 + 0.1), Color3.fromRGB(60, 30, 20))
	end

	-- Character details: what makes each cast member its own character.
	-- Each prop is a few parts; keep them simple and bright.
	local prop = cast.prop or ""
	if prop == "toaster" then
		for _, x in ipairs({ -0.9, 0.9 }) do
			part("Slot", Vector3.new(1.4, 0.2, 2.0), Vector3.new(x, bodyTopY - 0.05, 0), Color3.fromRGB(40, 40, 40))
		end
		part("Lever", Vector3.new(0.5, 0.5, 0.5), Vector3.new(bodyW / 2 + 0.25, 1.4, 0), Color3.fromRGB(220, 60, 60), Enum.PartType.Ball)
	elseif prop == "pigeon" then
		part("Helmet", Vector3.new(0.5, 2.6, 2.6), Vector3.new(0, headTopY + 0.1, 0), Color3.fromRGB(120, 130, 140), Enum.PartType.Cylinder, nil, CFrame.Angles(0, 0, math.pi / 2))
		part("Beak", Vector3.new(0.7, 0.4, 0.5), Vector3.new(0, headCentreY - 0.2, headD / 2 + 0.1), Color3.fromRGB(255, 170, 40))
	elseif prop == "sandal" then
		-- Cucumber slices on the body + sandal straps.
		for _, y in ipairs({ 0.5, 1.8 }) do
			part("Cucumber", Vector3.new(1.0, 1.0, 0.4), Vector3.new(-1.2, y, bodyD / 2 + 0.1), Color3.fromRGB(60, 200, 80), Enum.PartType.Ball)
			part("Cucumber", Vector3.new(1.0, 1.0, 0.4), Vector3.new(1.2, y, bodyD / 2 + 0.1), Color3.fromRGB(60, 200, 80), Enum.PartType.Ball)
		end
		part("Strap", Vector3.new(2.4, 0.3, 0.3), Vector3.new(0, headTopY - 0.2, headD / 2 + 0.1), Color3.fromRGB(255, 120, 60))
	elseif prop == "kerupuk" then
		-- Puffy cracker bubbles on the body.
		for _, pos in ipairs({ Vector3.new(-1.2, 0.5, 1.6), Vector3.new(1.2, 1.2, 1.6), Vector3.new(0, 2.2, 1.6) }) do
			part("Bubble", Vector3.new(0.9, 0.9, 0.9), pos, Color3.fromRGB(255, 240, 200), Enum.PartType.Ball)
		end
	elseif prop == "pillow" then
		-- Sleep cap + a floating "Z".
		part("SleepCap", Vector3.new(2.8, 0.8, 2.8), Vector3.new(0, headTopY + 0.3, 0), Color3.fromRGB(90, 120, 220))
		part("Zed", Vector3.new(0.9, 0.9, 0.3), Vector3.new(2.2, headTopY + 1.2, 0), Color3.fromRGB(255, 220, 60), Enum.PartType.Block, Enum.Material.Neon)
	elseif prop == "gorengan" then
		-- Oil splash drops + crispy bits.
		for _, pos in ipairs({ Vector3.new(-1.4, 1.0, 1.8), Vector3.new(1.4, 0.4, 1.8), Vector3.new(0.4, 2.4, 1.8) }) do
			part("OilDrop", Vector3.new(0.7, 0.7, 0.7), pos, Color3.fromRGB(255, 200, 40), Enum.PartType.Ball, Enum.Material.Neon)
		end
		part("Crispy", Vector3.new(1.6, 0.4, 0.4), Vector3.new(0, headTopY + 0.2, 0), Color3.fromRGB(180, 110, 40))
	elseif prop == "cilok" then
		-- Skewer stick through the body + red sauce drizzle.
		part("Skewer", Vector3.new(0.35, 0.35, 6.5), Vector3.new(0, bodyCentreY + 0.5, 0), Color3.fromRGB(200, 150, 100), Enum.PartType.Cylinder, nil, CFrame.Angles(math.pi / 2, 0, 0))
		part("Sauce", Vector3.new(2.0, 0.3, 0.3), Vector3.new(0, headCentreY - 0.6, headD / 2 + 0.1), Color3.fromRGB(220, 40, 40))
	elseif prop == "spoon" then
		-- Spoon bowl on the head + handle.
		part("SpoonBowl", Vector3.new(1.8, 0.5, 1.8), Vector3.new(0, headTopY + 0.4, 0), Color3.fromRGB(220, 220, 230), Enum.PartType.Ball)
		part("SpoonHandle", Vector3.new(0.4, 2.0, 0.4), Vector3.new(1.6, headTopY + 0.5, 0), Color3.fromRGB(220, 220, 230))
	elseif prop == "pickle" then
		-- Round glasses + white lab-collar.
		for _, x in ipairs({ -0.62, 0.62 }) do
			part("Glasses", Vector3.new(1.0, 1.0, 0.2), Vector3.new(x, headCentreY + 0.3, eyeZ + 0.1), Color3.fromRGB(30, 30, 30))
		end
		part("Collar", Vector3.new(3.4, 0.5, 3.4), Vector3.new(0, bodyTopY - 0.2, 0), Color3.fromRGB(255, 255, 255))
	elseif prop == "disco" then
		-- Mirror-ball hat + sparkles.
		part("MirrorBall", Vector3.new(1.6, 1.6, 1.6), Vector3.new(0, headTopY + 0.8, 0), Color3.fromRGB(220, 220, 240), Enum.PartType.Ball, Enum.Material.Metal)
		for _, pos in ipairs({ Vector3.new(-2.0, headTopY + 1.0, 0.5), Vector3.new(2.0, headTopY + 0.4, -0.5) }) do
			part("Sparkle", Vector3.new(0.5, 0.5, 0.5), pos, Color3.fromRGB(255, 240, 90), Enum.PartType.Ball, Enum.Material.Neon)
		end
	elseif prop == "tahu" then
		-- Turbo flames behind the tofu block.
		for _, sx in ipairs({ -1, 1 }) do
			part("TurboFlame", Vector3.new(0.9, 0.9, 0.9), Vector3.new(sx * 1.0, bodyCentreY - 0.6, -bodyD / 2 - 0.5), Color3.fromRGB(255, 140, 40), Enum.PartType.Ball, Enum.Material.Neon)
		end
		part("TofuTop", Vector3.new(2.0, 0.4, 2.0), Vector3.new(0, bodyTopY + 0.1, 0), Color3.fromRGB(255, 250, 240))
	elseif prop == "kopi" then
		-- Steam puffs above the cup + zoom lines.
		for _, pos in ipairs({ Vector3.new(-0.6, headTopY + 1.0, 0), Vector3.new(0.6, headTopY + 1.5, 0) }) do
			part("Steam", Vector3.new(0.9, 0.9, 0.9), pos, Color3.fromRGB(240, 240, 245), Enum.PartType.Ball, nil, nil, 0.6)
		end
		for _, sx in ipairs({ -1, 1 }) do
			part("ZoomLine", Vector3.new(1.6, 0.25, 0.25), Vector3.new(sx * (bodyW / 2 + 0.8), 1.5, 0), Color3.fromRGB(255, 220, 60), Enum.PartType.Block, Enum.Material.Neon)
		end
	elseif prop == "gladiator" then
		-- Helmet + sword.
		part("GladHelm", Vector3.new(headW + 0.2, 0.8, headD + 0.2), Vector3.new(0, headTopY + 0.4, 0), Color3.fromRGB(180, 180, 190))
		part("Plume", Vector3.new(0.5, 1.2, 1.2), Vector3.new(0, headTopY + 1.4, 0), Color3.fromRGB(255, 60, 60))
		part("GladSword", Vector3.new(0.6, 3.4, 0.6), Vector3.new(armX + 0.5, 2.6, 0), Color3.fromRGB(220, 220, 230), Enum.PartType.Block, nil, CFrame.Angles(0, 0, -0.4))
	elseif prop == "crab" then
		-- Knight helmet + red plume + baguette sword.
		part("KnightHelm", Vector3.new(headW + 0.2, 0.8, headD + 0.2), Vector3.new(0, headTopY + 0.4, 0), Color3.fromRGB(180, 180, 190))
		part("Plume", Vector3.new(0.5, 1.2, 1.2), Vector3.new(0, headTopY + 1.4, 0), Color3.fromRGB(255, 60, 60))
		part("Baguette", Vector3.new(0.7, 3.4, 0.7), Vector3.new(armX + 0.5, 2.6, 0), Color3.fromRGB(220, 170, 90), Enum.PartType.Block, nil, CFrame.Angles(0, 0, -0.4))
	elseif prop == "flamingo" then
		-- Long neck, sunglasses, handbag.
		part("Neck", Vector3.new(2.0, 0.9, 0.9), Vector3.new(0, bodyTopY + 0.5, 0), bodyColour, Enum.PartType.Cylinder, nil, CFrame.Angles(0, 0, math.pi / 2))
		part("Sunglasses", Vector3.new(2.4, 0.6, 0.3), Vector3.new(0, headCentreY + 0.3, eyeZ + 0.1), Color3.fromRGB(20, 20, 20))
		part("Handbag", Vector3.new(1.4, 1.2, 0.5), Vector3.new(armX + 0.3, -0.2, 0.3), Color3.fromRGB(200, 60, 140))
	elseif prop == "dragon" then
		-- Wings, horns, chilli.
		for _, sx in ipairs({ -1, 1 }) do
			part("Wing", Vector3.new(0.3, 2.4, 1.8), Vector3.new(sx * (bodyW / 2 + 0.6), bodyCentreY + 1.2, -0.5), Color3.fromRGB(255, 90, 60), Enum.PartType.Block, nil, CFrame.Angles(0, 0, sx * 0.5))
			part("Horn", Vector3.new(0.5, 1.2, 0.5), Vector3.new(sx * 0.8, headTopY + 0.6, 0), Color3.fromRGB(255, 220, 60), Enum.PartType.Cylinder)
		end
		part("Chilli", Vector3.new(0.6, 1.4, 0.6), Vector3.new(0, headTopY + 0.8, 0), Color3.fromRGB(220, 30, 30), Enum.PartType.Ball)
	elseif prop == "crocodile" then
		-- Snout + teeth + fried egg on top.
		part("Snout", Vector3.new(2.0, 0.8, 1.6), Vector3.new(0, headCentreY - 0.3, headD / 2 + 0.6), bodyColour)
		for _, x in ipairs({ -0.6, 0, 0.6 }) do
			part("Tooth", Vector3.new(0.3, 0.4, 0.3), Vector3.new(x, headCentreY - 0.7, headD / 2 + 1.2), Color3.fromRGB(255, 255, 255))
		end
		part("EggWhite", Vector3.new(1.4, 0.4, 1.4), Vector3.new(0, headTopY + 0.2, 0), Color3.fromRGB(255, 255, 255), Enum.PartType.Ball)
		part("EggYolk", Vector3.new(0.7, 0.7, 0.7), Vector3.new(0, headTopY + 0.5, 0), Color3.fromRGB(255, 200, 40), Enum.PartType.Ball)
	elseif prop == "odong" then
		-- Ride car on the back + coloured lights.
		part("RideCar", Vector3.new(2.4, 1.6, 2.0), Vector3.new(0, bodyCentreY + 1.0, -bodyD / 2 - 0.8), Color3.fromRGB(255, 120, 200))
		for _, pos in ipairs({ Vector3.new(-1.0, bodyCentreY + 2.2, -bodyD / 2 - 0.8), Vector3.new(1.0, bodyCentreY + 2.2, -bodyD / 2 - 0.8) }) do
			part("RideLight", Vector3.new(0.6, 0.6, 0.6), pos, Color3.fromRGB(255, 220, 60), Enum.PartType.Ball, Enum.Material.Neon)
		end
	elseif prop == "kebab" then
		-- Crown + skewer with meat chunks.
		part("Crown", Vector3.new(3.0, 0.7, 3.0), Vector3.new(0, headTopY + 0.35, 0), Color3.fromRGB(255, 210, 60), Enum.PartType.Block, Enum.Material.Neon)
		part("Skewer", Vector3.new(0.35, 0.35, 6.5), Vector3.new(0, bodyCentreY + 0.5, 0), Color3.fromRGB(200, 150, 100), Enum.PartType.Cylinder, nil, CFrame.Angles(math.pi / 2, 0, 0))
		for _, z in ipairs({ -1.8, 0, 1.8 }) do
			part("Meat", Vector3.new(1.0, 1.0, 1.0), Vector3.new(0, bodyCentreY + 0.5, z), Color3.fromRGB(160, 90, 50), Enum.PartType.Ball)
		end
	elseif prop == "wizard" then
		-- Wizard hat + spoon staff.
		part("WizardHat", Vector3.new(1.6, 2.2, 1.6), Vector3.new(0, headTopY + 1.0, 0), Color3.fromRGB(90, 40, 140), Enum.PartType.Cylinder)
		part("HatBrim", Vector3.new(3.4, 0.3, 3.4), Vector3.new(0, headTopY + 0.1, 0), Color3.fromRGB(90, 40, 140))
		part("Staff", Vector3.new(0.4, 4.5, 0.4), Vector3.new(armX + 0.6, 1.5, 0), Color3.fromRGB(150, 100, 60))
		part("StaffSpoon", Vector3.new(1.0, 0.4, 1.0), Vector3.new(armX + 0.6, 4.0, 0), Color3.fromRGB(220, 220, 230), Enum.PartType.Ball)
	elseif prop == "rendangzilla" then
		-- Back spikes + tail + rendang pot on the head.
		for _, y in ipairs({ 1.0, 2.2, 3.4 }) do
			part("Spike", Vector3.new(0.7, 1.2, 0.7), Vector3.new(0, y, -bodyD / 2 - 0.4), Color3.fromRGB(255, 220, 60), Enum.PartType.Cylinder)
		end
		part("Tail", Vector3.new(1.0, 1.0, 4.0), Vector3.new(0, -0.5, -bodyD / 2 - 2.0), bodyColour)
		part("RendangPot", Vector3.new(2.0, 1.2, 2.0), Vector3.new(0, headTopY + 0.6, 0), Color3.fromRGB(60, 60, 70), Enum.PartType.Cylinder)
	elseif prop == "ojek" then
		-- Motorcycle underfoot + helmet + exhaust.
		part("BikeBody", Vector3.new(3.4, 0.8, 1.2), Vector3.new(0, -1.0, 0), Color3.fromRGB(255, 200, 40))
		for _, wx in ipairs({ -1.2, 1.2 }) do
			part("BikeWheel", Vector3.new(0.5, 1.4, 1.4), Vector3.new(wx, -0.9, 0), Color3.fromRGB(25, 25, 25), Enum.PartType.Cylinder)
		end
		part("RiderHelm", Vector3.new(2.8, 1.2, 2.8), Vector3.new(0, headTopY + 0.4, 0), Color3.fromRGB(255, 120, 40), Enum.PartType.Ball)
		part("Exhaust", Vector3.new(1.6, 0.5, 0.5), Vector3.new(-bodyW / 2 - 0.6, -0.4, 0), Color3.fromRGB(150, 150, 160), Enum.PartType.Cylinder, nil, CFrame.Angles(0, 0, math.pi / 2))
	elseif prop == "ghostburger" then
		-- Burger layers between body and bun: patty + lettuce.
		part("Patty", Vector3.new(3.4, 0.7, 3.4), Vector3.new(0, bodyTopY + 0.1, 0), Color3.fromRGB(120, 70, 40), Enum.PartType.Block, nil, nil, 0.35)
		part("Lettuce", Vector3.new(3.8, 0.3, 3.8), Vector3.new(0, bodyTopY + 0.55, 0), Color3.fromRGB(90, 200, 80), Enum.PartType.Block, nil, nil, 0.35)
	elseif prop == "tuyul" then
		-- Cosmic robe + orbiting stars + money bag.
		part("Robe", Vector3.new(bodyW + 0.6, 2.0, bodyD + 0.6), Vector3.new(0, -0.5, 0), Color3.fromRGB(60, 60, 180), Enum.PartType.Cylinder)
		for i = 1, 3 do
			local angle = (i - 1) * (math.pi * 2 / 3)
			part("Star", Vector3.new(0.6, 0.6, 0.6), Vector3.new(math.cos(angle) * 3.4, 2.5, math.sin(angle) * 3.4), Color3.fromRGB(255, 240, 90), Enum.PartType.Ball, Enum.Material.Neon)
		end
		part("MoneyBag", Vector3.new(1.4, 1.4, 1.4), Vector3.new(armX + 0.4, -0.2, 0.3), Color3.fromRGB(200, 150, 90), Enum.PartType.Ball)
		part("BagGold", Vector3.new(0.7, 0.7, 0.7), Vector3.new(armX + 0.4, 0.7, 0.3), Color3.fromRGB(255, 210, 60), Enum.PartType.Ball, Enum.Material.Neon)
	elseif prop == "pocong" then
		-- Disco ball + ninja headband + shroud ties.
		part("DiscoBall", Vector3.new(1.8, 1.8, 1.8), Vector3.new(0, headTopY + 0.9, 0), Color3.fromRGB(220, 220, 240), Enum.PartType.Ball, Enum.Material.Metal)
		part("NinjaBand", Vector3.new(headW + 0.3, 0.6, headD + 0.3), Vector3.new(0, headCentreY + 0.5, 0), Color3.fromRGB(255, 60, 180), Enum.PartType.Block, Enum.Material.Neon)
		for _, y in ipairs({ 0.5, 1.8 }) do
			part("ShroudTie", Vector3.new(bodyW + 0.3, 0.3, bodyD + 0.3), Vector3.new(0, y, 0), Color3.fromRGB(220, 220, 240))
		end
	end

	-- Rarity glow disc under the feet.
	part("GlowDisc", Vector3.new(0.2, 6, 6), Vector3.new(0, -1.4, 0), rarityColour, Enum.PartType.Cylinder, Enum.Material.Neon, CFrame.Angles(0, 0, math.pi / 2), 0.15)

	-- Invisible Root part at the model origin as the PrimaryPart.
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(0.5, 0.5, 0.5)
	root.Position = Vector3.new(0, 0, 0)
	root.Color = Color3.fromRGB(255, 255, 255)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.Parent = model
	model.PrimaryPart = root

	-- Rarity aura: brighter and busier for higher rarities.
	local rarityRank = { Common = 1, Rare = 2, Epic = 3, Legendary = 4, Mythic = 5, Secret = 6 }
	local rank = rarityRank[entry.rarity] or 1
	local aura = Instance.new("ParticleEmitter")
	aura.Name = "RarityAura"
	aura.Color = ColorSequence.new(rarityColour)
	aura.Rate = 2 + rank * 6
	aura.Lifetime = NumberRange.new(0.6, 1.2)
	aura.Size = NumberSequence.new(0.4 + rank * 0.15)
	aura.Speed = NumberRange.new(1, 2)
	aura.Transparency = NumberSequence.new(0.3, 0.9)
	aura.Parent = body

	-- Every character carries its own light in its rarity colour.
	-- Mythic gets 2 lights, Secret gets 3 (biggest, brightest).
	local glow = Instance.new("PointLight")
	glow.Color = rarityColour
	glow.Range = 10 + rank
	glow.Brightness = 1 + rank * 0.2
	glow.Parent = body
	if rank >= 5 then
		local glow2 = Instance.new("PointLight")
		glow2.Color = Color3.fromRGB(255, 255, 255)
		glow2.Range = 14
		glow2.Brightness = 1
		glow2.Parent = body
	end
	if rank >= 6 then
		local glow3 = Instance.new("PointLight")
		glow3.Color = Color3.fromRGB(255, 120, 220)
		glow3.Range = 18
		glow3.Brightness = 1.2
		glow3.Parent = body
	end
	-- Gosong ember light: orange glow so the charred body still reads.
	if emberLight then
		local ember = Instance.new("PointLight")
		ember.Color = Color3.fromRGB(255, 90, 30)
		ember.Range = 10
		ember.Brightness = 1.5
		ember.Parent = body
	end

	-- ProximityPrompt buy (E key); the ClickDetector stays as fallback.
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Buy"
	prompt.ObjectText = entry.name
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 14
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = body

	-- Glitch mutation: a flickering Neon spark on the model.
	if mutationId == "Glitch" then
		part("GlitchSpark", Vector3.new(0.8, 0.8, 0.8), Vector3.new(1.8, headTopY + 0.5, 0), mutationColour, Enum.PartType.Ball, Enum.Material.Neon)
		aura.Color = ColorSequence.new(mutationColour)
	end
	-- Pelangi mutation: rainbow aura.
	if mutationId == "Pelangi" then
		aura.Color = ColorSequence.new(Color3.fromRGB(255, 120, 220))
	end

	-- Idle-animation marker + mutation marker for the walk loop.
	local idle = Instance.new("StringValue")
	idle.Name = "IdleType"
	idle.Value = idleType
	idle.Parent = model
	local mut = Instance.new("StringValue")
	mut.Name = "MutationType"
	mut.Value = mutationId
	mut.Parent = model
	local rar = Instance.new("StringValue")
	rar.Name = "RarityType"
	rar.Value = entry.rarity
	rar.Parent = model

	-- Floating label: name, rarity, mutation and $/second. The
	-- Adornee MUST be the Body part: a BillboardGui anchored to the
	-- Model itself never renders.
	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotLabel"
	gui.Size = UDim2.fromOffset(110, 40)
	gui.StudsOffsetWorldSpace = Vector3.new(0, (headTopY - bodyCentreY) * SCALE + 2.0, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 40
	gui.Adornee = body
	gui.Parent = body
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = entry.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.Parent = gui
	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "Rate"
	rateLabel.Position = UDim2.new(0, 0, 0.5, 0)
	rateLabel.Size = UDim2.new(1, 0, 0.5, 0)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = entry.rarity .. " " .. entry.mutation .. " - " .. Config.formatMoney(entry.rate * entry.mutationMult) .. "/s"
	rateLabel.TextColor3 = rarityColour
	rateLabel.TextScaled = true
	rateLabel.Font = Enum.Font.SourceSansBold
	rateLabel.Parent = gui

	-- Click to buy.
	local click = Instance.new("ClickDetector")
	click.Name = "BuyClick"
	click.MaxActivationDistance = 32
	click.Parent = model

	-- Scale the whole character up so it reads from across the street.
	-- Feet stay exactly on the floor (local y=-1.5) via FEET_LIFT.
	local FEET_LIFT = 1.5 * (SCALE - 1)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name ~= "Root" then
			descendant.Size = descendant.Size * SCALE
			local pos = descendant.Position
			descendant.Position = Vector3.new(pos.X * SCALE, pos.Y * SCALE + FEET_LIFT, pos.Z * SCALE)
		end
	end

	return model
end

-- Public entry: build a model, never throwing.
function BrainrotServer.buildModel(entry)
	local ok, model = pcall(buildModelInner, entry)
	if not ok then
		warn("[Brainrot] buildModel failed for " .. tostring(entry.castId) .. ": " .. tostring(model))
		return nil
	end
	return model
end

-- Showcase entry: a plain (Normal mutation) entry for one cast member.
local function showcaseEntry(castId)
	local cast = Config.findCast(castId)
	if not cast then
		return nil
	end
	return {
		castId = cast.id,
		name = cast.name,
		rarity = cast.rarity,
		rate = cast.rate,
		mutation = "Normal",
		mutationMult = 1,
		colour = cast.colour,
	}
end

-- Where a showcase model stands on a base slot, found at runtime
-- from the pad part WorldBuilder built.
local function pedestalPivot(baseIndex, slot)
	local base = workspace:FindFirstChild("Base" .. tostring(baseIndex))
	local pad = base and base:FindFirstChild("Slot" .. tostring(slot))
	if pad and pad:IsA("BasePart") then
		return CFrame.new(pad.Position + Vector3.new(0, pad.Size.Y / 2 + 1.5, 0))
	end
	return CFrame.new(WorldBuilder.slotPosition(baseIndex, slot))
end

-- Place one display-only model: built like any brainrot, then
-- stripped of its buy prompt and click (never for sale, earns
-- nothing, in no State table). key registers it for auto-clear
-- when a real purchase takes its slot.
local function placeShowcase(entry, cframe, key)
	local model = BrainrotServer.buildModel(entry)
	if not model then
		return
	end
	local prompt = model:FindFirstChild("BuyPrompt", true)
	if prompt then
		prompt:Destroy()
	end
	local click = model:FindFirstChild("BuyClick", true)
	if click then
		click:Destroy()
	end
	model:PivotTo(cframe)
	model.Parent = workspace
	if key then
		displayModels[key] = model
	end
end

-- Pre-place visible characters so the game opens with bodies in view:
-- six on Base 1's pedestals (front + middle rows) and four on the
-- belt near the spawn. Runs once at server start.
function BrainrotServer.preplaceShowcase()
	local pedestalCast = {
		{ 7, "pocongo-disco-ninja" }, -- Secret, front row
		{ 8, "tuyul-cosmico" }, -- Secret, front row
		{ 9, "rendangzilla-mamma" }, -- Mythic, front row
		{ 4, "sambalo-dragonelli" }, -- Legendary, middle row
		{ 5, "tahuro-turbino" }, -- Epic, middle row
		{ 6, "sandalo-pepino" }, -- Common, middle row
	}
	for _, pair in ipairs(pedestalCast) do
		local slot, castId = pair[1], pair[2]
		local entry = showcaseEntry(castId)
		if entry then
			placeShowcase(entry, pedestalPivot(1, slot), "1:" .. tostring(slot))
		end
	end

	local beltCast = { "kerupuko-dudu", "cilokko-bambino", "kopiccino-zoomzoom", "ojeklo-turbo-turbo" }
	local beltX = { -15, -5, 5, 15 }
	for i, castId in ipairs(beltCast) do
		local entry = showcaseEntry(castId)
		if entry then
			local pos = WorldBuilder.beltPosition(beltX[i] - Config.Belt.startX)
			placeShowcase(entry, CFrame.new(pos + Vector3.new(0, 0, 2)))
		end
	end
end

-- Walk a model from where it is to a target position, in small steps.
function BrainrotServer.walkModelTo(model, target)
	local primary = model.PrimaryPart
	if not primary then
		return
	end
	walking[model] = true
	idleBase[model] = nil
	pcall(function()
		local start = primary.Position
		local distance = (target - start).Magnitude
		local steps = math.max(1, math.floor(distance / 1.5))
		for i = 1, steps do
			if not model.Parent then
				return
			end
			local alpha = i / steps
			local pos = start:Lerp(target, alpha)
			local bob = math.sin(alpha * math.pi * 6) * 0.15
			model:PivotTo(CFrame.new(pos + Vector3.new(0, bob, 0)))
			task.wait(0.05)
		end
		if model.Parent then
			model:PivotTo(CFrame.new(target))
		end
	end)
	walking[model] = nil
	if model.Parent then
		idleBase[model] = CFrame.new(target)
	end
end

-- Spawn one brainrot at the west end of the belt and let it walk.
function BrainrotServer.spawnBrainrotOnBelt()
	if #State.belt >= Config.Belt.maxOnBelt then
		return
	end
	local entry = State.newBeltBrainrot(State.wavePhase == "warning")
	table.insert(State.belt, entry)

	-- Mythic/Secret spawn: announce to every client + play the sound.
	if entry.rarity == "Mythic" or entry.rarity == "Secret" then
		if BrainrotServer.remotes and BrainrotServer.remotes.Announce then
			BrainrotServer.remotes.Announce:FireAllClients({
				type = "mythic",
				name = entry.name,
				rarity = entry.rarity,
				rate = entry.rate * entry.mutationMult,
			})
		end
		playSound("MythicSound")
	end

	local model = BrainrotServer.buildModel(entry)
	if not model then
		BrainrotServer.removeBeltBrainrot(entry.uid)
		return
	end
	entry.model = model
	model:PivotTo(CFrame.new(WorldBuilder.beltPosition(0)))
	model.Parent = workspace

	local click = model:FindFirstChild("BuyClick", true)
	if click then
		click.MouseClick:Connect(function(player)
			for _, candidate in ipairs(State.belt) do
				if candidate.uid == entry.uid then
					BrainrotServer.buyBrainrot(player, entry.uid)
					return
				end
			end
		end)
	end

	local prompt = model:FindFirstChild("BuyPrompt", true)
	if prompt then
		prompt.Triggered:Connect(function(player)
			for _, candidate in ipairs(State.belt) do
				if candidate.uid == entry.uid then
					BrainrotServer.buyBrainrot(player, entry.uid)
					return
				end
			end
		end)
	end
end

-- Remove a belt brainrot and its model (bought, washed away, despawned).
function BrainrotServer.removeBeltBrainrot(uid)
	for i, entry in ipairs(State.belt) do
		if entry.uid == uid then
			table.remove(State.belt, i)
			if entry.model then
				entry.model:Destroy()
			end
			return entry
		end
	end
	return nil
end

-- The buy: cash, free slot, belt membership, all checked server-side.
function BrainrotServer.buyBrainrot(player, uid)
	local data = State.get(player)
	if not data then
		return false
	end
	local entry = nil
	for _, candidate in ipairs(State.belt) do
		if candidate.uid == uid then
			entry = candidate
			break
		end
	end
	if not entry then
		return false
	end
	if data.money < entry.cost then
		return false
	end
	local slot = State.freeSlot(data)
	if not slot then
		return false
	end

	for i, candidate in ipairs(State.belt) do
		if candidate.uid == uid then
			table.remove(State.belt, i)
			break
		end
	end

	if entry.model then
		local prompt = entry.model:FindFirstChild("BuyPrompt", true)
		if prompt then
			prompt:Destroy()
		end
	end

	data.money -= entry.cost
	data.boughtCount += 1
	data.contracts.buy3 += 1
	data.contracts.buy10 += 1
	data.dex[entry.castId] = true
	data.contracts.dex5 = State.dexCount(data)

	local owned = {
		castId = entry.castId,
		name = entry.name,
		rarity = entry.rarity,
		rate = entry.rate,
		mutation = entry.mutation,
		mutationMult = entry.mutationMult,
		colour = entry.colour,
		model = entry.model,
		owner = player,
		slot = slot,
	}
	data.brainrots[slot] = owned
	BrainrotServer.checkContracts(player)

	-- A showcase model on this slot steps aside for a real purchase.
	local showcaseKey = data.baseIndex .. ":" .. tostring(slot)
	local showcase = displayModels[showcaseKey]
	if showcase then
		displayModels[showcaseKey] = nil
		pcall(function()
			showcase:Destroy()
		end)
	end
	local target = WorldBuilder.slotPosition(data.baseIndex, slot)
	task.spawn(function()
		BrainrotServer.walkModelTo(entry.model, target)
	end)
	return true
end

-- Pay contract rewards when a goal is first reached.
function BrainrotServer.checkContracts(player)
	local data = State.get(player)
	if not data then
		return
	end
	for _, contract in ipairs(Config.Contracts) do
		if not data.contractsDone[contract.id] then
			local progress = data.contracts[contract.id] or 0
			if progress >= contract.goal then
				data.contractsDone[contract.id] = true
				data.money += contract.reward
			end
		end
	end
end

-- One second of income for every player, plus contract progress.
-- Floating "+$" popups ride above owned brainrots (capped at 6 per
-- player per tick); each popup animates on its own task.spawn.
function BrainrotServer.collectIncome()
	for player, data in pairs(State.players) do
		local income = State.incomePerSecond(data)
		if income > 0 then
			data.money += income
			data.earnedTotal += income
			data.contracts.earn1000 = data.earnedTotal
			data.contracts.earn50000 = data.earnedTotal
			BrainrotServer.checkContracts(player)
			local shown = 0
			for _, owned in pairs(data.brainrots) do
				if shown >= 6 then
					break
				end
				local model = owned.model
				if model and model.Parent then
					shown += 1
					local per = Config.incomePerSecond(owned, data.rebirths, data.upgrades.golden, State.rushMult())
					task.spawn(function()
						pcall(function()
							local gui = Instance.new("BillboardGui")
							gui.Name = "IncomePopup"
							gui.Size = UDim2.fromOffset(80, 28)
							gui.StudsOffsetWorldSpace = Vector3.new(0, 9.5, 0)
							gui.AlwaysOnTop = true
							local anchor = model:FindFirstChild("Body")
							if anchor then
								gui.Adornee = anchor
								gui.Parent = anchor
							else
								gui.Parent = model
							end
							local label = Instance.new("TextLabel")
							label.Size = UDim2.fromScale(1, 1)
							label.BackgroundTransparency = 1
							label.Text = "+$" .. tostring(per)
							label.TextColor3 = Color3.fromRGB(120, 255, 120)
							label.TextScaled = true
							label.Font = Enum.Font.SourceSansBold
							label.Parent = gui
							for _ = 1, 20 do
								task.wait(0.05)
								if not gui.Parent then
									return
								end
								gui.StudsOffsetWorldSpace += Vector3.new(0, 0.1, 0)
								label.TextTransparency += 0.05
							end
							gui:Destroy()
						end)
					end)
				end
			end
		end
	end
end

-- Rebirth: wipe cash and brainrots, keep a permanent +50% multiplier.
function BrainrotServer.doRebirth(player)
	local data = State.get(player)
	if not data then
		return false, "no state"
	end
	local cost = State.rebirthCost(data)
	if data.money < cost then
		return false, "need " .. Config.formatMoney(cost)
	end
	if State.ownedCount(data) < Config.Rebirth.minBrainrots then
		return false, "need at least " .. tostring(Config.Rebirth.minBrainrots) .. " brainrots"
	end
	for _, owned in pairs(data.brainrots) do
		if owned.model then
			owned.model:Destroy()
		end
	end
	data.brainrots = {}
	data.money = 0
	data.rebirths += 1
	return true, "rebirth " .. tostring(data.rebirths)
end

-- Buy one upgrade level, if the player can afford it and is not maxed.
function BrainrotServer.buyUpgrade(player, kind)
	local data = State.get(player)
	if not data then
		return false
	end
	local cost = State.upgradeCost(data, kind)
	if not cost then
		return false
	end
	if data.money < cost then
		return false
	end
	data.money -= cost
	data.upgrades[kind] += 1
	if kind == "beltSpeed" then
		State.beltSpeedBonus = (State.beltSpeedBonus or 0) + Config.Upgrades.beltSpeed.speedPerLevel
	end
	return true
end

-- Restore saved brainrots onto their base slots (called after load).
function BrainrotServer.restoreBrainrots(player, savedList)
	local data = State.get(player)
	if not data or type(savedList) ~= "table" then
		return
	end
	for _, saved in ipairs(savedList) do
		local cast = Config.findCast(saved.castId)
		if cast then
			local mutation = nil
			for _, mut in ipairs(Config.Mutations) do
				if mut.id == saved.mutation then
					mutation = mut
					break
				end
			end
			mutation = mutation or Config.Mutations[1]
			local slot = saved.slot
			if slot and not data.brainrots[slot] and slot <= State.slotCount(data) then
				local entry = {
					castId = cast.id,
					name = cast.name,
					rarity = cast.rarity,
					rate = cast.rate,
					mutation = mutation.id,
					mutationMult = mutation.mult,
					colour = cast.colour,
				}
				local model = BrainrotServer.buildModel(entry)
				if model then
					local prompt = model:FindFirstChild("BuyPrompt", true)
					if prompt then
						prompt:Destroy()
					end
					entry.model = model
					entry.owner = player
					entry.slot = slot
					data.brainrots[slot] = entry
					local showcaseKey = data.baseIndex .. ":" .. tostring(slot)
					local showcase = displayModels[showcaseKey]
					if showcase then
						displayModels[showcaseKey] = nil
						pcall(function()
							showcase:Destroy()
						end)
					end
					model:PivotTo(CFrame.new(WorldBuilder.slotPosition(data.baseIndex, slot)))
					model.Parent = workspace
				end
			end
		end
	end
end

-- Push a fresh snapshot to every player, twice a second is plenty.
function BrainrotServer.pushState()
	for player in pairs(State.players) do
		local snapshot = State.snapshotFor(player)
		if snapshot and BrainrotServer.remotes then
			BrainrotServer.remotes.StateSync:FireClient(player, snapshot)
		end
	end
end

-- The spawner loop: a new brainrot every few seconds while there is room.
function BrainrotServer.startSpawner()
	task.spawn(function()
		while true do
			task.wait(Config.Belt.spawnEvery)
			BrainrotServer.spawnBrainrotOnBelt()
		end
	end)
end

-- The belt walk loop + the idle animation loop (bob/bounce/spin,
-- Glitch flicker, Pelangi rainbow cycle, Secret rainbow glow).
function BrainrotServer.startBeltWalk()
	local function idleOffset(idleType, t)
		if idleType == "bounce" then
			return math.abs(math.sin(t * 4)) * 0.5, 0
		elseif idleType == "spin" then
			return 0, t * 1.5
		else -- "bob"
			return math.sin(t * 2) * 0.15, 0
		end
	end
	local function valueOf(model, name, default)
		local value = model:FindFirstChild(name)
		return value and value.Value or default
	end

	RunService.Heartbeat:Connect(function(dt)
		local beltSpeed = Config.Belt.walkSpeed + (State.beltSpeedBonus or 0)
		local t = os.clock()
		local toRemove = {}
		for _, entry in ipairs(State.belt) do
			entry.progress += beltSpeed * dt
			if entry.progress >= Config.Belt.length then
				table.insert(toRemove, entry.uid)
			elseif entry.model and entry.model.Parent then
				local base = WorldBuilder.beltPosition(entry.progress)
				local yOff, yaw = idleOffset(valueOf(entry.model, "IdleType", "bob"), t)
				entry.model:PivotTo(CFrame.new(base + Vector3.new(0, yOff, 0)) * CFrame.Angles(0, yaw, 0))
			end
		end
		for _, uid in ipairs(toRemove) do
			BrainrotServer.removeBeltBrainrot(uid)
		end
	end)

	RunService.Heartbeat:Connect(function(_dt)
		local t = os.clock()
		local rainbowIndex = math.floor(t / 0.4) % #RAINBOW_HUES + 1
		local glitchIndex = math.floor(t / 0.25) % #GLITCH_HUES + 1
		for _, data in pairs(State.players) do
			for _, owned in pairs(data.brainrots) do
				local model = owned.model
				if model and model.Parent and not walking[model] then
					local primary = model.PrimaryPart
					if primary and primary.Anchored then
						local base = idleBase[model]
						if not base then
							base = model:GetPivot()
							idleBase[model] = base
						end
						local yOff, yaw = idleOffset(valueOf(model, "IdleType", "bob"), t)
						model:PivotTo(CFrame.new(base.Position + Vector3.new(0, yOff, 0)) * CFrame.Angles(0, yaw, 0))
						-- Mutation + Secret colour cycling.
						local body = model:FindFirstChild("Body")
						if body then
							local mutation = valueOf(model, "MutationType", "Normal")
							local rarity = valueOf(model, "RarityType", "Common")
							if mutation == "Glitch" then
								body.Color = GLITCH_HUES[glitchIndex]
							elseif mutation == "Pelangi" then
								body.Color = RAINBOW_HUES[rainbowIndex]
							elseif rarity == "Secret" then
								body.Color = RAINBOW_HUES[rainbowIndex]
							end
						end
					end
				elseif model and not model.Parent then
					idleBase[model] = nil
				end
			end
		end
	end)
end

-- Wire the RemoteEvents the client is allowed to fire.
function BrainrotServer.bindRemotes(remotes)
	BrainrotServer.remotes = remotes
	remotes.BuyBrainrot.OnServerEvent:Connect(function(player, uid)
		BrainrotServer.buyBrainrot(player, uid)
	end)
	remotes.Rebirth.OnServerEvent:Connect(function(player)
		BrainrotServer.doRebirth(player)
	end)
	remotes.BuyUpgrade.OnServerEvent:Connect(function(player, kind)
		BrainrotServer.buyUpgrade(player, kind)
	end)
end

function BrainrotServer.start(remotes)
	BrainrotServer.bindRemotes(remotes)
	BrainrotServer.preplaceShowcase()
	BrainrotServer.startSpawner()
	BrainrotServer.startBeltWalk()
	task.spawn(function()
		while true do
			task.wait(1)
			BrainrotServer.collectIncome()
			BrainrotServer.pushState()
		end
	end)
end

return BrainrotServer
