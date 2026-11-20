-- BRAINROT KRAKATOA: the belt, the buying and the money.
-- Owns every brainrot that is walking the belt, every brainrot sitting
-- on a base, and the one-second income tick that pays for them. Buying
-- is server-authoritative: the client only asks, the server checks the
-- cash, the free slot and the belt, and only then moves the model.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local State = require(script.Parent:WaitForChild("State"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

local BrainrotServer = {}
BrainrotServer.remotes = nil

-- Build the 3D model for one brainrot: a chunky body, a head, eyes,
-- a hat that says what it is, and a floating label with its name,
-- rarity and $/second, so a buyer can read it from across the belt.
-- Build the 3D model for one brainrot: a distinct character per cast
-- member (round turtle, flat cracker, ninja rice, noodle mobster...),
-- with arms and legs, a head with eyes on its front face, a big hat,
-- and a floating label with name, rarity and $/second. The mutation
-- colours the whole body, so a Gold or Diamond brainrot reads at a
-- glance. Feet sit at local y=-1.5: the body centre is (bodyH-3)/2
-- above the model pivot, and PivotOffset shifts the pivot down to the
-- feet, so every PivotTo target (belt y=2.7, pad y=2.9) lands the feet
-- on the floor instead of sinking the body into it.
function BrainrotServer.buildModel(entry)
	local model = Instance.new("Model")
	model.Name = entry.name

	-- Mutation colour: the mutation shows on the body, not just the label.
	local bodyColour = entry.colour
	if entry.mutation and entry.mutation ~= "Normal" then
		for _, mut in ipairs(Config.Mutations) do
			if mut.id == entry.mutation then
				bodyColour = mut.colour
				break
			end
		end
	end
	local darkColour = Color3.new(bodyColour.R * 0.65, bodyColour.G * 0.65, bodyColour.B * 0.65)

	-- One helper builds every part: anchored, non-colliding, parented.
	local function part(name, size, pos, colour, shape, material, rot)
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
	if id == "kopi-kura" then
		bodyShape = Enum.PartType.Ball
		headShape = Enum.PartType.Ball
		headW, headH, headD = 2.4, 2.4, 2.4
	elseif id == "kerupuk-krak" then
		bodyShape = Enum.PartType.Ball
		bodyW, bodyD = 5.2, 5.2
	elseif id == "bakso-blast" then
		bodyShape = Enum.PartType.Ball
		headShape = Enum.PartType.Ball
		headW, headH, headD = 2.4, 2.4, 2.4
	elseif id == "durian-doom" then
		bodyShape = Enum.PartType.Ball
	elseif id == "es-teh" then
		bodyShape = Enum.PartType.Cylinder
		headShape = Enum.PartType.Ball
		headW, headH, headD = 2.0, 2.0, 2.0
	elseif id == "rendang-raksasa" then
		bodyW, bodyH, bodyD = 5.2, 5.0, 4.4
		headW, headH, headD = 3.0, 2.4, 3.0
	elseif id == "gado-golem" then
		bodyW, bodyH, bodyD = 5.2, 5.0, 4.6
		headW, headH, headD = 3.0, 2.4, 3.0
	elseif id == "lava-lontong" then
		bodyShape = Enum.PartType.Cylinder
		bodyW, bodyD = 4.2, 4.2
		bodyMaterial = Enum.Material.Neon
		headShape = Enum.PartType.Ball
		headW, headH, headD = 2.2, 2.2, 2.2
	end

	local bodyCentreY = (bodyH - 3) / 2
	local bodyTopY = bodyH - 1.5
	local bodySize = Vector3.new(bodyW, bodyH, bodyD)
	local bodyRot = nil
	if bodyShape == Enum.PartType.Cylinder then
		-- A cylinder's axis runs along X; stand it upright.
		bodySize = Vector3.new(bodyH, bodyW, bodyD)
		bodyRot = CFrame.Angles(0, 0, math.pi / 2)
	end
	local body = part("Body", bodySize, Vector3.new(0, bodyCentreY, 0), bodyColour, bodyShape, bodyMaterial, bodyRot)

	-- Legs end at local y=-1.5, the belt/pad top, for every cast member.
	local legX = bodyW / 2 - 0.9
	local legSize = Vector3.new(1, 1.5, 1)
	local legY = -0.75
	if id == "kopi-kura" then
		legSize = Vector3.new(1.2, 1.2, 1.2)
		legY = -0.9
	elseif id == "rendang-raksasa" or id == "gado-golem" then
		legSize = Vector3.new(1.4, 1.5, 1.4)
	end
	for _, sx in ipairs({ -1, 1 }) do
		part("Leg", legSize, Vector3.new(sx * legX, legY, 0), darkColour)
	end

	-- Arms stick out of the body's sides so it reads as a character.
	local armX = bodyW / 2 + 0.45
	local armSize = Vector3.new(0.9, 2.2, 0.9)
	local armY = 0.9
	if id == "kopi-kura" then
		armSize = Vector3.new(1.6, 0.5, 2.0)
		armX = bodyW / 2 + 0.6
		armY = 0.4
	elseif id == "rendang-raksasa" or id == "gado-golem" then
		armSize = Vector3.new(1.3, 2.6, 1.3)
		armX = bodyW / 2 + 0.65
		armY = 1.0
	end
	for _, sx in ipairs({ -1, 1 }) do
		part("Arm", armSize, Vector3.new(sx * armX, armY, 0), darkColour)
	end

	-- Head, clearly separate on top of the body.
	local headCentreY = bodyTopY + headH / 2
	local headTopY = bodyTopY + headH
	part("Head", Vector3.new(headW, headH, headD), Vector3.new(0, headCentreY, 0), bodyColour, headShape)

	-- Eyes on the front face of the head, with pupils.
	local eyeZ = headD / 2 + 0.1
	if headShape == Enum.PartType.Ball then
		eyeZ = headD / 2 - 0.15
	end
	for _, x in ipairs({ -0.62, 0.62 }) do
		part("Eye", Vector3.new(0.55, 0.75, 0.35), Vector3.new(x, headCentreY + 0.3, eyeZ), Color3.fromRGB(255, 255, 255))
		part("Pupil", Vector3.new(0.28, 0.4, 0.16), Vector3.new(x, headCentreY + 0.3, eyeZ + 0.19), Color3.fromRGB(20, 20, 20))
	end

	-- A mouth on the ones that read better with one.
	local mouthY = headCentreY - headH / 2 + 0.35
	if id == "kerupuk-krak" or id == "gado-golem" or id == "es-teh" then
		part("Mouth", Vector3.new(1.1, 0.35, 0.2), Vector3.new(0, mouthY, headD / 2 + 0.1), Color3.fromRGB(60, 30, 20))
	elseif id == "sambal-setan" then
		part("Mouth", Vector3.new(1.3, 0.4, 0.2), Vector3.new(0, mouthY, headD / 2 + 0.1), Color3.fromRGB(40, 10, 10))
		for _, x in ipairs({ -0.35, 0.35 }) do
			part("Fang", Vector3.new(0.35, 0.6, 0.2), Vector3.new(x, mouthY - 0.35, headD / 2 + 0.1), Color3.fromRGB(255, 255, 255))
		end
	elseif id == "nasi-ninja" then
		part("Mask", Vector3.new(2.2, 0.8, 0.2), Vector3.new(0, mouthY, headD / 2 + 0.1), Color3.fromRGB(40, 40, 40))
	elseif id == "kopi-kura" then
		part("Beak", Vector3.new(0.8, 0.45, 0.4), Vector3.new(0, mouthY, headD / 2 - 0.4), Color3.fromRGB(220, 170, 90))
	end

	-- The hat: one BIG part per cast member, so the silhouette reads.
	if entry.hat == "Cup" then
		-- White coffee cup on the head, coffee showing on top.
		part("Hat", Vector3.new(1.7, 2.2, 2.2), Vector3.new(0, headTopY + 0.85, 0), Color3.fromRGB(255, 255, 255), Enum.PartType.Cylinder, nil, CFrame.Angles(0, 0, math.pi / 2))
		part("Coffee", Vector3.new(0.25, 1.8, 1.8), Vector3.new(0, headTopY + 1.65, 0), Color3.fromRGB(90, 50, 20), Enum.PartType.Cylinder, nil, CFrame.Angles(0, 0, math.pi / 2))
	elseif entry.hat == "Bandana" then
		-- Red band around the upper head, knot tails sticking up behind.
		part("Hat", Vector3.new(headW + 0.3, 0.8, headD + 0.3), Vector3.new(0, headTopY - 0.5, 0), Color3.fromRGB(200, 40, 40))
		for _, x in ipairs({ -0.5, 0.5 }) do
			part("BandanaTail", Vector3.new(0.5, 1.6, 0.2), Vector3.new(x, headTopY + 0.3, -headD / 2 - 0.15), Color3.fromRGB(200, 40, 40))
		end
	elseif entry.hat == "Bowl" then
		-- Wide flat bowl, like a rice bowl balanced on the head.
		local bowlD = 3.8
		if id == "rendang-raksasa" then
			bowlD = 4.4
		end
		part("Hat", Vector3.new(0.9, bowlD, bowlD), Vector3.new(0, headTopY + 0.45, 0), Color3.fromRGB(240, 240, 220), Enum.PartType.Cylinder, nil, CFrame.Angles(0, 0, math.pi / 2))
	elseif entry.hat == "Spikes" then
		-- Three spikes across the top of the head.
		part("Hat", Vector3.new(0.8, 1.8, 0.8), Vector3.new(0, headTopY + 0.9, 0), bodyColour)
		part("Spike", Vector3.new(0.8, 2.2, 0.8), Vector3.new(-1.1, headTopY + 1.0, 0), bodyColour)
		part("Spike", Vector3.new(0.8, 2.2, 0.8), Vector3.new(1.1, headTopY + 1.0, 0), bodyColour)
	elseif entry.hat == "Straw" then
		-- Wide straw hat brim, with a pink straw poking out of the top.
		part("Hat", Vector3.new(0.4, 4.4, 4.4), Vector3.new(0, headTopY + 0.2, 0), Color3.fromRGB(230, 200, 90), Enum.PartType.Cylinder, nil, CFrame.Angles(0, 0, math.pi / 2))
		part("Straw", Vector3.new(2.4, 0.45, 0.45), Vector3.new(0.7, headTopY + 1.3, 0), Color3.fromRGB(255, 90, 120), Enum.PartType.Cylinder, nil, CFrame.Angles(0, 0, math.pi / 2 - 0.35))
	else -- Crown
		-- Big gold crown: wide base plus three points.
		part("Hat", Vector3.new(3.4, 0.9, 3.4), Vector3.new(0, headTopY + 0.45, 0), Color3.fromRGB(255, 210, 60), Enum.PartType.Block, Enum.Material.Neon)
		for _, x in ipairs({ -1.2, 0, 1.2 }) do
			part("CrownPoint", Vector3.new(0.7, 1.1, 0.7), Vector3.new(x, headTopY + 1.4, 0), Color3.fromRGB(255, 210, 60), Enum.PartType.Block, Enum.Material.Neon)
		end
	end

	-- Extras that make each cast member its own character.
	if id == "kopi-kura" then
		-- Turtle shell on the back, darker than the body.
		part("Shell", Vector3.new(4.9, 3.4, 1.4), Vector3.new(0, bodyCentreY + 0.2, -1.9), Color3.fromRGB(90, 60, 30), Enum.PartType.Ball)
	elseif id == "kerupuk-krak" then
		-- Cracker freckles across the front.
		part("Crackle", Vector3.new(0.5, 0.5, 0.5), Vector3.new(-1.2, 1.6, 2.0), Color3.fromRGB(190, 150, 90), Enum.PartType.Ball)
		part("Crackle", Vector3.new(0.5, 0.5, 0.5), Vector3.new(0.9, 2.1, 1.85), Color3.fromRGB(190, 150, 90), Enum.PartType.Ball)
		part("Crackle", Vector3.new(0.5, 0.5, 0.5), Vector3.new(0, 0.6, 2.45), Color3.fromRGB(190, 150, 90), Enum.PartType.Ball)
	elseif id == "mie-mafia" then
		-- Noodle hair across the head, plus a mobster tie.
		for _, x in ipairs({ -0.8, 0, 0.8 }) do
			part("Noodle", Vector3.new(2.6, 0.5, 0.5), Vector3.new(x, headTopY + 0.15, 0), Color3.fromRGB(240, 200, 80), Enum.PartType.Cylinder, nil, CFrame.Angles(0, math.pi / 2, 0))
		end
		part("Tie", Vector3.new(0.6, 1.6, 0.2), Vector3.new(0, bodyTopY - 1.0, bodyD / 2 + 0.1), Color3.fromRGB(30, 30, 30))
	elseif id == "bakso-blast" then
		-- A fuse out of the bowl, with a spark on its tip.
		part("Fuse", Vector3.new(1.6, 0.4, 0.4), Vector3.new(0, headTopY + 1.7, 0), Color3.fromRGB(60, 40, 20), Enum.PartType.Cylinder, nil, CFrame.Angles(0, 0, math.pi / 2))
		part("Spark", Vector3.new(0.7, 0.7, 0.7), Vector3.new(0, headTopY + 2.6, 0), Color3.fromRGB(255, 220, 60), Enum.PartType.Ball, Enum.Material.Neon)
	elseif id == "durian-doom" then
		-- Spikes all over the body, not just the head.
		part("BodySpike", Vector3.new(0.7, 1.5, 0.7), Vector3.new(0, bodyTopY + 0.4, 0), bodyColour)
		for _, sx in ipairs({ -1, 1 }) do
			part("BodySpike", Vector3.new(0.7, 1.5, 0.7), Vector3.new(sx * 1.6, 2.3, 0), bodyColour, Enum.PartType.Block, nil, CFrame.Angles(0, 0, -sx * 0.5))
			part("BodySpike", Vector3.new(0.7, 1.5, 0.7), Vector3.new(0, 2.3, sx * 1.6), bodyColour, Enum.PartType.Block, nil, CFrame.Angles(sx * 0.5, 0, 0))
		end
	elseif id == "sambal-setan" then
		-- Two horns on the head, leaning outward.
		for _, sx in ipairs({ -1, 1 }) do
			part("Horn", Vector3.new(0.7, 1.8, 0.7), Vector3.new(sx * 1.0, headTopY + 0.7, 0), bodyColour, Enum.PartType.Block, nil, CFrame.Angles(0, 0, -sx * 0.45))
		end
	elseif id == "es-teh" then
		-- Iced tea: amber tea top and ice cubes floating in the glass.
		part("TeaTop", Vector3.new(0.3, 3.8, 3.8), Vector3.new(0, bodyTopY + 0.05, 0), Color3.fromRGB(180, 110, 40), Enum.PartType.Cylinder, nil, CFrame.Angles(0, 0, math.pi / 2))
		for _, sx in ipairs({ -1, 1 }) do
			part("Ice", Vector3.new(0.9, 0.9, 0.9), Vector3.new(sx * 1.1, bodyTopY + 0.3, 0), Color3.fromRGB(235, 245, 255))
		end
	elseif id == "gado-golem" then
		-- Wide shoulders on the gentle giant.
		for _, sx in ipairs({ -1, 1 }) do
			part("Shoulder", Vector3.new(1.6, 1.2, 3.0), Vector3.new(sx * 3.0, bodyTopY - 0.3, 0), bodyColour)
		end
	elseif id == "krakatoa-king" then
		-- Lava cracks glowing down the chest.
		for _, x in ipairs({ -0.8, 0.8 }) do
			part("LavaCrack", Vector3.new(0.4, 2.2, 0.2), Vector3.new(x, bodyCentreY + 0.2, bodyD / 2 + 0.1), Color3.fromRGB(255, 140, 40), Enum.PartType.Block, Enum.Material.Neon)
		end
	elseif id == "lava-lontong" then
		-- Lava drips running down the rice cake.
		for _, x in ipairs({ -1.2, 0, 1.2 }) do
			part("LavaDrip", Vector3.new(0.8, 0.8, 0.8), Vector3.new(x, bodyCentreY + 0.5, bodyD / 2 - 0.1), Color3.fromRGB(255, 200, 60), Enum.PartType.Ball, Enum.Material.Neon)
		end
	end

	model.PrimaryPart = body
	-- Shift the pivot down to the feet (local y=0), so every PivotTo
	-- target lands the feet on the floor: belt y=2.7 -> feet at 1.2,
	-- pad y=2.9 -> feet at 1.4. Set after PrimaryPart, so it sticks.
	model.PivotOffset = CFrame.new(0, -bodyCentreY, 0)

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
	local rarityColour = Config.RarityColour[entry.rarity] or Color3.fromRGB(255, 255, 255)
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
function BrainrotServer.walkModelTo(model, target)
	local primary = model.PrimaryPart
	if not primary then
		return
	end
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
end

-- Spawn one brainrot at the volcano end of the belt and let it walk.
-- Its uid comes from State.newBeltBrainrot alone; stamping a second
-- number here once gave two spawns the same uid.
function BrainrotServer.spawnBrainrotOnBelt()
	if #State.belt >= Config.Belt.maxOnBelt then
		return
	end
	local entry = State.newBeltBrainrot(State.wavePhase == "warning")
	table.insert(State.belt, entry)

	local model = BrainrotServer.buildModel(entry)
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
function BrainrotServer.collectIncome()
	for player, data in pairs(State.players) do
		local income = State.incomePerSecond(data)
		if income > 0 then
			data.money += income
			data.earnedTotal += income
			data.contracts.earn1000 = data.earnedTotal
			BrainrotServer.checkContracts(player)
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

-- The belt walk loop: every live brainrot shuffles towards the lagoon.
function BrainrotServer.startBeltWalk()
	RunService.Heartbeat:Connect(function(dt)
		local toRemove = {}
		for _, entry in ipairs(State.belt) do
			entry.progress += Config.Belt.walkSpeed * dt
			if entry.progress >= Config.Belt.length then
				table.insert(toRemove, entry.uid)
			elseif entry.model and entry.model.Parent then
				entry.model:PivotTo(CFrame.new(WorldBuilder.beltPosition(entry.progress)))
			end
		end
		for _, uid in ipairs(toRemove) do
			BrainrotServer.removeBeltBrainrot(uid)
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
