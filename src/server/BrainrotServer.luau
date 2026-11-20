-- BRAINROT BAZAAR: the belt, the buying and the money.
-- Owns every brainrot that is walking the belt, every brainrot sitting
-- on a base, and the one-second income tick that pays for them. Buying
-- is server-authoritative: the client only asks, the server checks the
-- cash, the free slot and the belt, and only then moves the model.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local State = require(script.Parent:WaitForChild("State"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

local BrainrotServer = {}
BrainrotServer.remotes = nil

-- Models currently mid-walk (walkModelTo): the idle loop skips these.
local walking = {}
-- Owned models' rest CFrame (pedestal), so the idle loop never drifts.
local idleBase = {}

-- Play a SoundService sound by name; a sound that fails to load must
-- never error the spawner, so the Play is pcall-guarded.
local function playSound(name)
	pcall(function()
		local sound = SoundService:FindFirstChild(name)
		if sound then
			sound:Play()
		end
	end)
end

-- Build the 3D model for one brainrot: a distinct character per cast
-- member of "Brainrot Bazaar" (toaster, pigeon, noodle pirate, cone,
-- crab knight, flamingo, log robot, cactus diva, ghost burger, race
-- car, blob boss), with arms and legs, a head with eyes on its front
-- face, a rarity aura, and a floating label with name, rarity and
-- $/second. The mutation colours the body, head and limbs, so a Gold
-- or Diamond brainrot reads at a glance. Feet sit at local y=-1.5:
-- the body centre is (bodyH-3)/2 above the model pivot, and
-- PivotOffset shifts the pivot down to the feet, so every PivotTo
-- target (belt y=2.7, pad y=2.9) lands the feet on the floor instead
-- of sinking the body into it.
-- HARD RULES (a non-cubic Ball once errored and killed the spawner):
-- every Ball part has a UNIFORM Size (X=Y=Z); every Cylinder has
-- Y==Z. Anything that needs to be non-uniform is a Block.
function BrainrotServer.buildModel(entry)
	local model = Instance.new("Model")
	model.Name = entry.name

	-- Mutation colour: the mutation shows on the body, head and limbs.
	local mutationId = entry.mutation or "Normal"
	local mutationColour = nil
	if mutationId ~= "Normal" then
		for _, mut in ipairs(Config.Mutations) do
			if mut.id == mutationId then
				mutationColour = mut.colour
				break
			end
		end
	end
	local bodyColour = mutationColour or entry.colour
	local darkColour = Color3.new(bodyColour.R * 0.65, bodyColour.G * 0.65, bodyColour.B * 0.65)
	local rarityColour = Config.RarityColour[entry.rarity] or Color3.fromRGB(255, 255, 255)

	-- One helper builds every part: anchored, non-colliding, parented.
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

	-- Body shape per cast member. bodyH drives the belt math below:
	-- body centre y = (bodyH - 3) / 2, body bottom at local y = -1.5.
	local id = entry.castId
	local bodyW, bodyH, bodyD = 4.5, 4.5, 4.5
	local bodyShape = Enum.PartType.Block
	local bodyMaterial = Enum.Material.SmoothPlastic
	local headShape = Enum.PartType.Block
	local headW, headH, headD = 2.6, 2.2, 2.6
	local eyeScale = 1
	local legSize = Vector3.new(1, 1.5, 1)
	local armSize = Vector3.new(0.9, 2.2, 0.9)
	local armShape = Enum.PartType.Block
	local idleType = "bob"
	local ghostly = false -- translucent body + head (Glorpo)
	if id == "soggy-toastino" then
		bodyW, bodyH, bodyD = 4.2, 4.5, 3.0
		headW, headH, headD = 2.6, 2.6, 1.0
	elseif id == "bonk-pigeon" then
		bodyShape = Enum.PartType.Ball
		headShape = Enum.PartType.Ball
		headW, headH, headD = 2.4, 2.4, 2.4
		eyeScale = 1.8
		legSize = Vector3.new(0.6, 1.0, 0.6)
		armSize = Vector3.new(0.7, 1.8, 1.6)
		idleType = "bounce"
	elseif id == "captain-noodlebeard" then
		bodyW, bodyH, bodyD = 4.5, 4.5, 3.6
		headShape = Enum.PartType.Cylinder
		headW, headH, headD = 3.0, 2.2, 3.0
	elseif id == "lil-wobblecone" then
		bodyShape = Enum.PartType.Cylinder
		headW, headH, headD = 2.2, 1.8, 2.2
		legSize = Vector3.new(0.8, 1.0, 0.8)
		idleType = "bounce"
	elseif id == "sir-crustacio" then
		bodyW, bodyH, bodyD = 4.5, 4.5, 4.0
		armShape = Enum.PartType.Ball
		armSize = Vector3.new(1.6, 1.6, 1.6)
	elseif id == "madame-flamingatto" then
		bodyShape = Enum.PartType.Ball
		bodyW, bodyH, bodyD = 4.2, 4.2, 4.2
		headShape = Enum.PartType.Ball
		headW, headH, headD = 2.2, 2.2, 2.2
		legSize = Vector3.new(0.7, 1.5, 0.7)
		idleType = "spin"
	elseif id == "turbo-tungtung" then
		bodyW, bodyH, bodyD = 4.0, 4.5, 3.4
		headW, headH, headD = 2.4, 2.2, 2.4
		legSize = Vector3.new(1, 1.5, 1)
		idleType = "bounce"
	elseif id == "duchess-cactoona" then
		bodyW, bodyH, bodyD = 4.2, 4.5, 3.6
		headShape = Enum.PartType.Ball
		headW, headH, headD = 2.4, 2.4, 2.4
		idleType = "spin"
	elseif id == "glorpo-ghost-burger" then
		bodyShape = Enum.PartType.Ball
		bodyW, bodyH, bodyD = 4.8, 4.8, 4.8
		headShape = Enum.PartType.Ball
		headW, headH, headD = 2.6, 2.6, 2.6
		ghostly = true
	elseif id == "baron-vroomvroom" then
		bodyW, bodyH, bodyD = 5.0, 3.2, 3.0
		headW, headH, headD = 2.6, 1.6, 2.2
		idleType = "bounce"
	elseif id == "blobfather" then
		bodyShape = Enum.PartType.Ball
		bodyW, bodyH, bodyD = 5.2, 5.2, 5.2
		headShape = Enum.PartType.Ball
		headW, headH, headD = 2.4, 2.4, 2.4
		eyeScale = 1.2
		idleType = "spin"
	end

	local bodyCentreY = (bodyH - 3) / 2
	local bodyTopY = bodyH - 1.5
	local bodySize = Vector3.new(bodyW, bodyH, bodyD)
	local bodyRot = nil
	if bodyShape == Enum.PartType.Cylinder then
		-- A cylinder's axis runs along X; stand it upright.
		-- bodyW == bodyD keeps Y==Z after the rotation.
		bodySize = Vector3.new(bodyH, bodyW, bodyD)
		bodyRot = CFrame.Angles(0, 0, math.pi / 2)
	end
	local bodyTransparency = ghostly and 0.35 or nil
	local body = part("Body", bodySize, Vector3.new(0, bodyCentreY, 0), bodyColour, bodyShape, bodyMaterial, bodyRot, bodyTransparency)

	-- Legs end at local y=-1.5, the belt/pad top, for every cast member.
	local legX = bodyW / 2 - 0.9
	local legY = -0.75
	if id == "bonk-pigeon" or id == "lil-wobblecone" then
		legY = -1.0
	elseif id == "baron-vroomvroom" then
		legX = bodyW / 2 - 1.2
	end
	for _, sx in ipairs({ -1, 1 }) do
		part("Leg", legSize, Vector3.new(sx * legX, legY, 0), darkColour)
	end

	-- Arms stick out of the body's sides so it reads as a character.
	-- (Sir Crustacio's arms are claw Balls: uniform 1.6 size.)
	local armX = bodyW / 2 + 0.45
	local armY = 0.9
	if id == "sir-crustacio" then
		armX = bodyW / 2 + 0.7
		armY = 0.6
	elseif id == "madame-flamingatto" then
		armX = bodyW / 2 + 0.3
		armY = 0.6
	end
	for _, sx in ipairs({ -1, 1 }) do
		part("Arm", armSize, Vector3.new(sx * armX, armY, 0), darkColour, armShape)
	end

	-- Head, clearly separate on top of the body.
	local headCentreY = bodyTopY + headH / 2
	local headTopY = bodyTopY + headH
	local headSize = Vector3.new(headW, headH, headD)
	local headRot = nil
	if headShape == Enum.PartType.Cylinder then
		-- Bowl head: axis along X, stood upright; headW == headD.
		headSize = Vector3.new(headH, headW, headD)
		headRot = CFrame.Angles(0, 0, math.pi / 2)
	end
	part("Head", headSize, Vector3.new(0, headCentreY, 0), bodyColour, headShape, Enum.Material.SmoothPlastic, headRot, bodyTransparency)

	-- Eyes on the front face of the head, with pupils.
	local eyeZ = headD / 2 + 0.1
	if headShape == Enum.PartType.Ball then
		eyeZ = headD / 2 - 0.15
	end
	local eyeW, eyeH = 0.55 * eyeScale, 0.75 * eyeScale
	for _, x in ipairs({ -0.62, 0.62 }) do
		part("Eye", Vector3.new(eyeW, eyeH, 0.35), Vector3.new(x, headCentreY + 0.3, eyeZ), Color3.fromRGB(255, 255, 255))
		part("Pupil", Vector3.new(0.28 * eyeScale, 0.4 * eyeScale, 0.16), Vector3.new(x, headCentreY + 0.3, eyeZ + 0.19), Color3.fromRGB(20, 20, 20))
	end

	-- A mouth on the ones that read better with one.
	local mouthY = headCentreY - headH / 2 + 0.35
	if id == "soggy-toastino" then
		-- Sad frown: two short bars angled down toward the middle.
		for _, sx in ipairs({ -1, 1 }) do
			part("Frown", Vector3.new(0.55, 0.22, 0.2), Vector3.new(sx * 0.35, mouthY, headD / 2 + 0.1), Color3.fromRGB(60, 30, 20), Enum.PartType.Block, nil, CFrame.Angles(0, 0, sx * 0.5))
		end
	elseif id == "glorpo-ghost-burger" then
		-- Glowing smile.
		part("Smile", Vector3.new(1.2, 0.3, 0.2), Vector3.new(0, mouthY, headD / 2 + 0.1), Color3.fromRGB(255, 230, 90), Enum.PartType.Block, Enum.Material.Neon)
	elseif id ~= "bonk-pigeon" and id ~= "captain-noodlebeard" and id ~= "baron-vroomvroom" then
		part("Mouth", Vector3.new(1.1, 0.35, 0.2), Vector3.new(0, mouthY, headD / 2 + 0.1), Color3.fromRGB(60, 30, 20))
	end

	-- Character details: what makes each cast member its own character.
	if id == "soggy-toastino" then
		-- Toaster slots on top of the body, lever on the side.
		for _, x in ipairs({ -0.9, 0.9 }) do
			part("Slot", Vector3.new(1.4, 0.2, 2.0), Vector3.new(x, bodyTopY - 0.05, 0), Color3.fromRGB(40, 40, 40))
		end
		part("Lever", Vector3.new(0.5, 0.5, 0.5), Vector3.new(bodyW / 2 + 0.25, 1.4, 0), Color3.fromRGB(220, 60, 60), Enum.PartType.Ball)
	elseif id == "bonk-pigeon" then
		-- Tiny helmet: a grey disc on the head, plus an orange beak.
		part("Helmet", Vector3.new(0.5, 2.6, 2.6), Vector3.new(0, headTopY + 0.1, 0), Color3.fromRGB(120, 130, 140), Enum.PartType.Cylinder, nil, CFrame.Angles(0, 0, math.pi / 2))
		part("Beak", Vector3.new(0.7, 0.4, 0.5), Vector3.new(0, headCentreY - 0.2, headD / 2 + 0.1), Color3.fromRGB(255, 170, 40))
	elseif id == "captain-noodlebeard" then
		-- Black pirate hat: wide brim + top, and ramen noodle whiskers
		-- hanging from the bowl's rim down over the face.
		part("PirateHat", Vector3.new(3.6, 0.4, 3.6), Vector3.new(0, headTopY + 0.2, 0), Color3.fromRGB(30, 30, 35))
		part("PirateHatTop", Vector3.new(1.8, 1.0, 1.8), Vector3.new(0, headTopY + 0.9, 0), Color3.fromRGB(30, 30, 35))
		for _, x in ipairs({ -0.9, 0, 0.9 }) do
			part("Noodle", Vector3.new(1.6, 0.3, 0.3), Vector3.new(x, headCentreY - 1.0, headD / 2 + 0.15), Color3.fromRGB(240, 200, 80), Enum.PartType.Cylinder, nil, CFrame.Angles(0, 0, math.pi / 2))
		end
	elseif id == "lil-wobblecone" then
		-- White stripe around the cone head, and a skateboard underfoot:
		-- deck at y=-1.35 (bottom exactly at -1.5) with four Ball wheels.
		part("Stripe", Vector3.new(headW + 0.15, 0.5, headD + 0.15), Vector3.new(0, headCentreY + 0.3, 0), Color3.fromRGB(255, 255, 255))
		part("Skateboard", Vector3.new(3.4, 0.3, 1.4), Vector3.new(0, -1.35, 0), Color3.fromRGB(60, 60, 70))
		for _, wx in ipairs({ -1.2, 1.2 }) do
			for _, wz in ipairs({ -0.55, 0.55 }) do
				part("Wheel", Vector3.new(0.6, 0.6, 0.6), Vector3.new(wx, -1.2, wz), Color3.fromRGB(30, 30, 30), Enum.PartType.Ball)
			end
		end
	elseif id == "sir-crustacio" then
		-- Knight helmet + red plume, and a baguette sword held high.
		part("KnightHelm", Vector3.new(headW + 0.2, 0.8, headD + 0.2), Vector3.new(0, headTopY + 0.4, 0), Color3.fromRGB(180, 180, 190))
		part("Plume", Vector3.new(0.5, 1.2, 1.2), Vector3.new(0, headTopY + 1.4, 0), Color3.fromRGB(255, 60, 60))
		part("Baguette", Vector3.new(0.7, 3.4, 0.7), Vector3.new(armX + 0.5, 2.6, 0), Color3.fromRGB(220, 170, 90), Enum.PartType.Block, nil, CFrame.Angles(0, 0, -0.4))
	elseif id == "madame-flamingatto" then
		-- Long neck, black sunglasses, and a handbag on one arm.
		part("Neck", Vector3.new(2.0, 0.9, 0.9), Vector3.new(0, bodyTopY + 0.5, 0), bodyColour, Enum.PartType.Cylinder, nil, CFrame.Angles(0, 0, math.pi / 2))
		part("Sunglasses", Vector3.new(2.4, 0.6, 0.3), Vector3.new(0, headCentreY + 0.3, eyeZ + 0.1), Color3.fromRGB(20, 20, 20))
		part("Handbag", Vector3.new(1.4, 1.2, 0.5), Vector3.new(armX + 0.3, -0.2, 0.3), Color3.fromRGB(200, 60, 140))
		part("BagHandle", Vector3.new(0.8, 0.15, 0.15), Vector3.new(armX + 0.3, 0.5, 0.3), Color3.fromRGB(200, 60, 140))
	elseif id == "turbo-tungtung" then
		-- Antenna with a glowing tip, and a rocket pack on the back
		-- with Neon flames underneath.
		part("Antenna", Vector3.new(1.2, 0.25, 0.25), Vector3.new(0, headTopY + 0.6, 0), Color3.fromRGB(120, 120, 120), Enum.PartType.Cylinder, nil, CFrame.Angles(0, 0, math.pi / 2))
		part("AntennaTip", Vector3.new(0.5, 0.5, 0.5), Vector3.new(0, headTopY + 1.4, 0), Color3.fromRGB(255, 120, 40), Enum.PartType.Ball, Enum.Material.Neon)
		for _, sx in ipairs({ -1, 1 }) do
			part("Rocket", Vector3.new(1.8, 0.9, 0.9), Vector3.new(sx * 1.0, bodyCentreY + 0.6, -bodyD / 2 - 0.5), Color3.fromRGB(160, 160, 170), Enum.PartType.Cylinder, nil, CFrame.Angles(0, 0, math.pi / 2))
			part("Flame", Vector3.new(0.8, 0.8, 0.8), Vector3.new(sx * 1.0, bodyCentreY - 0.6, -bodyD / 2 - 0.5), Color3.fromRGB(255, 140, 40), Enum.PartType.Ball, Enum.Material.Neon)
		end
	elseif id == "duchess-cactoona" then
		-- Cactus branch arms, a pink flower on top, and two floating
		-- musical notes (white Neon) drifting by her head.
		for _, sx in ipairs({ -1, 1 }) do
			part("Branch", Vector3.new(0.8, 1.6, 0.8), Vector3.new(sx * (armX + 0.3), armY + 1.2, 0), bodyColour, Enum.PartType.Block, nil, CFrame.Angles(0, 0, sx * 0.5))
		end
		part("Flower", Vector3.new(0.9, 0.9, 0.9), Vector3.new(0, headTopY + 0.45, 0), Color3.fromRGB(255, 120, 200), Enum.PartType.Ball)
		for _, sx in ipairs({ -1, 1 }) do
			part("NoteStem", Vector3.new(0.2, 0.9, 0.2), Vector3.new(sx * 1.8, headTopY + 1.2, 0.5), Color3.fromRGB(255, 255, 255), Enum.PartType.Block, Enum.Material.Neon)
			part("NoteHead", Vector3.new(0.45, 0.45, 0.45), Vector3.new(sx * 1.8, headTopY + 0.7, 0.5), Color3.fromRGB(255, 255, 255), Enum.PartType.Ball, Enum.Material.Neon)
		end
	elseif id == "glorpo-ghost-burger" then
		-- Burger layers between body and bun: patty + lettuce.
		part("Patty", Vector3.new(3.4, 0.7, 3.4), Vector3.new(0, bodyTopY + 0.1, 0), Color3.fromRGB(120, 70, 40), Enum.PartType.Block, nil, nil, 0.35)
		part("Lettuce", Vector3.new(3.8, 0.3, 3.8), Vector3.new(0, bodyTopY + 0.55, 0), Color3.fromRGB(90, 200, 80), Enum.PartType.Block, nil, nil, 0.35)
	elseif id == "baron-vroomvroom" then
		-- Windshield, moustache, headlights, four wheels and a spoiler.
		part("Windshield", Vector3.new(2.2, 1.0, 0.2), Vector3.new(0, headCentreY + 0.1, headD / 2 + 0.1), Color3.fromRGB(40, 80, 140))
		for _, sx in ipairs({ -1, 1 }) do
			part("Moustache", Vector3.new(0.9, 0.3, 0.2), Vector3.new(sx * 0.45, 1.0, bodyD / 2 + 0.1), Color3.fromRGB(30, 20, 10), Enum.PartType.Block, nil, CFrame.Angles(0, 0, -sx * 0.35))
			part("Headlight", Vector3.new(0.5, 0.5, 0.5), Vector3.new(sx * 1.5, 0.6, bodyD / 2 + 0.1), Color3.fromRGB(255, 240, 150), Enum.PartType.Ball, Enum.Material.Neon)
			for _, wz in ipairs({ -1.2, 1.2 }) do
				part("Wheel", Vector3.new(0.5, 1.4, 1.4), Vector3.new(sx * 1.9, -0.6, wz), Color3.fromRGB(25, 25, 25), Enum.PartType.Cylinder)
			end
		end
		part("Spoiler", Vector3.new(3.0, 0.3, 0.8), Vector3.new(0, 2.0, -bodyD / 2 - 0.2), Color3.fromRGB(180, 20, 20))
	elseif id == "blobfather" then
		-- Gold crown, a tiny tilted hat on top of it, and three
		-- orbiting glitch cubes (a systems phase animates the orbit).
		part("Crown", Vector3.new(3.0, 0.7, 3.0), Vector3.new(0, headTopY + 0.35, 0), Color3.fromRGB(255, 210, 60), Enum.PartType.Block, Enum.Material.Neon)
		for _, x in ipairs({ -1.1, 0, 1.1 }) do
			part("CrownPoint", Vector3.new(0.6, 1.0, 0.6), Vector3.new(x, headTopY + 1.2, 0), Color3.fromRGB(255, 210, 60), Enum.PartType.Block, Enum.Material.Neon)
		end
		part("TinyHat", Vector3.new(1.2, 0.5, 1.2), Vector3.new(1.3, headTopY + 1.7, 0), Color3.fromRGB(30, 30, 30), Enum.PartType.Block, nil, CFrame.Angles(0, 0, 0.4))
		part("GlitchCube", Vector3.new(0.7, 0.7, 0.7), Vector3.new(3.4, 1.5, 0), Color3.fromRGB(80, 230, 255), Enum.PartType.Block, Enum.Material.Neon)
		part("GlitchCube", Vector3.new(0.7, 0.7, 0.7), Vector3.new(-2.4, 2.8, 2.4), Color3.fromRGB(255, 120, 220), Enum.PartType.Block, Enum.Material.Neon)
		part("GlitchCube", Vector3.new(0.7, 0.7, 0.7), Vector3.new(0, 3.6, -3.4), Color3.fromRGB(255, 240, 90), Enum.PartType.Block, Enum.Material.Neon)
	end

	model.PrimaryPart = body
	-- Shift the pivot down to the feet (local y=0), so every PivotTo
	-- target lands the feet on the floor: belt y=2.7 -> feet at 1.2,
	-- pad y=2.9 -> feet at 1.4. Set after PrimaryPart, so it sticks.
	model.PivotOffset = CFrame.new(0, -bodyCentreY, 0)

	-- Rarity aura: a ParticleEmitter on the body, brighter and busier
	-- for higher rarities. Secret gets the biggest show.
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

	-- Rare glow: Epic+ models carry a small PointLight so they shine
	-- on the belt. The RarityAura emitter already scales with rank.
	if rank >= 3 then
		local glow = Instance.new("PointLight")
		glow.Color = rarityColour
		glow.Range = 8
		glow.Brightness = 1
		glow.Parent = body
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

	-- Glitch mutation: a flickering Neon spark on the model, and the
	-- aura tinted glitch-purple. The colour cycling itself is done by
	-- the walk loop (a systems phase), which owns the flicker.
	if mutationId == "Glitch" then
		part("GlitchSpark", Vector3.new(0.8, 0.8, 0.8), Vector3.new(1.8, headTopY + 0.5, 0), mutationColour, Enum.PartType.Ball, Enum.Material.Neon)
		aura.Color = ColorSequence.new(mutationColour)
	end

	-- Idle-animation marker: a systems phase animates this in the walk
	-- loop ("bob" | "spin" | "bounce"). No Heartbeat here.
	local idle = Instance.new("StringValue")
	idle.Name = "IdleType"
	idle.Value = idleType
	idle.Parent = model

	-- Floating label: name, rarity, mutation and $/second.
	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotLabel"
	gui.Size = UDim2.fromOffset(150, 56)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 9.2, 0)
	gui.AlwaysOnTop = false
	gui.Parent = model
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

	-- Click to buy: the belt's shop front.
	local click = Instance.new("ClickDetector")
	click.Name = "BuyClick"
	click.MaxActivationDistance = 32
	click.Parent = model

	return model
end

-- Walk a model from where it is to a target position, in small steps,
-- so a bought brainrot visibly waddles home instead of teleporting.
-- The walking set marks it mid-walk (the idle loop skips it); the
-- pcall guarantees a failure never leaves it stuck in the set.
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
-- Its uid comes from State.newBeltBrainrot alone; stamping a second
-- number here once gave two spawns the same uid.
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

	-- A bad model must never kill the spawner loop: skip that one spawn.
	local ok, model = pcall(BrainrotServer.buildModel, entry)
	if not ok then
		warn("[Brainrot] buildModel failed for " .. tostring(entry.castId) .. ": " .. tostring(model))
		BrainrotServer.removeBeltBrainrot(entry.uid)
		return
	end
	entry.model = model
	model:PivotTo(CFrame.new(WorldBuilder.beltPosition(0)))
	model.Parent = workspace

	-- Clicking the model: while it walks the belt, that is a buy. Once
	-- it lives on a base, the same click is a steal attempt, wired up
	-- by init.server through the onBaseClick hook below.
	local click = model:FindFirstChild("BuyClick", true)
	if click then
		click.MouseClick:Connect(function(player)
			for _, candidate in ipairs(State.belt) do
				if candidate.uid == entry.uid then
					BrainrotServer.buyBrainrot(player, entry.uid)
					return
				end
			end
			if BrainrotServer.onBaseClick then
				BrainrotServer.onBaseClick(player, entry.model)
			end
		end)
	end

	-- ProximityPrompt buy (E key): the same buy as the ClickDetector.
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

-- Hook set by init.server: what a click on a base brainrot means.
-- Kept as a hook (not a require) so this module and StealServer never
-- require each other in a circle.
BrainrotServer.onBaseClick = nil

-- Hook set by init.server: what happens to a stolen brainrot a player
-- is still carrying when they rebirth. Same no-circle reason.
BrainrotServer.onRebirthDrop = nil

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

	-- Take it off the belt first, so two buyers can never share one.
	for i, candidate in ipairs(State.belt) do
		if candidate.uid == uid then
			table.remove(State.belt, i)
			break
		end
	end

	-- Kill the buy prompt: an owned brainrot can't be "bought" again.
	if entry.model then
		local prompt = entry.model:FindFirstChild("BuyPrompt", true)
		if prompt then
			prompt:Destroy()
		end
	end

	data.money -= entry.cost
	data.boughtCount += 1
	data.contracts.buy3 += 1
	data.dex[entry.castId] = true

	local owned = {
		castId = entry.castId,
		name = entry.name,
		rarity = entry.rarity,
		rate = entry.rate,
		mutation = entry.mutation,
		mutationMult = entry.mutationMult,
		colour = entry.colour,
		hat = entry.hat,
		model = entry.model,
		owner = player,
		slot = slot,
	}
	data.brainrots[slot] = owned
	BrainrotServer.checkContracts(player)

	-- Waddle home to its slot, then settle on the pad.
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

-- One second of income for every player, plus contract progress on it.
-- Floating "+$" popups ride above owned brainrots (capped at 6 per
-- player per tick); each popup animates on its own task.spawn, so the
-- income loop itself never yields.
function BrainrotServer.collectIncome()
	for player, data in pairs(State.players) do
		local income = State.incomePerSecond(data)
		if income > 0 then
			data.money += income
			data.earnedTotal += income
			data.contracts.earn1000 = data.earnedTotal
			BrainrotServer.checkContracts(player)
			local shown = 0
			for _, owned in pairs(data.brainrots) do
				if shown >= 6 then
					break
				end
				local model = owned.model
				if model and model.Parent then
					shown += 1
					local per = Config.incomePerSecond(owned, data.rebirths)
					task.spawn(function()
						pcall(function()
							local gui = Instance.new("BillboardGui")
							gui.Name = "IncomePopup"
							gui.Size = UDim2.fromOffset(80, 28)
							gui.StudsOffsetWorldSpace = Vector3.new(0, 9.5, 0)
							gui.AlwaysOnTop = true
							gui.Parent = model
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
	-- A stolen brainrot still in hand goes back to its owner first,
	-- or the rebirth would wipe the base and leave a ghost carried.
	if data.carrying and BrainrotServer.onRebirthDrop then
		BrainrotServer.onRebirthDrop(player)
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

-- The belt walk loop: every live brainrot shuffles towards the lagoon,
-- with its IdleType ("bob" | "bounce" | "spin") composed onto the belt
-- position. A second Heartbeat animates owned pedestal models in place
-- (Glitch flicker + Blobfather cube orbit included); it skips models
-- mid-walk and carried models (unanchored), and never yields.
function BrainrotServer.startBeltWalk()
	-- Returns (yOffset, yaw) for an idle type at time t.
	local function idleOffset(idleType, t)
		if idleType == "bounce" then
			return math.abs(math.sin(t * 4)) * 0.5, 0
		elseif idleType == "spin" then
			return 0, t * 1.5
		else -- "bob"
			return math.sin(t * 2) * 0.15, 0
		end
	end
	local function idleTypeOf(model)
		local value = model:FindFirstChild("IdleType")
		return value and value.Value or "bob"
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
				local yOff, yaw = idleOffset(idleTypeOf(entry.model), t)
				entry.model:PivotTo(CFrame.new(base + Vector3.new(0, yOff, 0)) * CFrame.Angles(0, yaw, 0))
			end
		end
		for _, uid in ipairs(toRemove) do
			BrainrotServer.removeBeltBrainrot(uid)
		end
	end)

	RunService.Heartbeat:Connect(function(_dt)
		local t = os.clock()
		local glitchHues = {
			Color3.fromRGB(160, 100, 255),
			Color3.fromRGB(80, 230, 255),
			Color3.fromRGB(255, 120, 220),
		}
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
						local yOff, yaw = idleOffset(idleTypeOf(model), t)
						model:PivotTo(CFrame.new(base.Position + Vector3.new(0, yOff, 0)) * CFrame.Angles(0, yaw, 0))
						-- Glitch mutation: cycle the body colour every ~0.25s.
						if owned.mutation == "Glitch" then
							local body = model:FindFirstChild("Body")
							if body then
								body.Color = glitchHues[math.floor(t / 0.25) % 3 + 1]
							end
						end
						-- Blobfather: rotate its 3 GlitchCubes around the centre.
						if owned.castId == "blobfather" then
							local centre = model:GetPivot().Position
							local cubes = {}
							for _, descendant in ipairs(model:GetDescendants()) do
								if descendant.Name == "GlitchCube" then
									table.insert(cubes, descendant)
								end
							end
							for i, cube in ipairs(cubes) do
								local angle = t * 1.2 + (i - 1) * (math.pi * 2 / 3)
								cube.Position = centre + Vector3.new(math.cos(angle) * 3.4, 2 + math.sin(t * 2 + i) * 0.5, math.sin(angle) * 3.4)
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
