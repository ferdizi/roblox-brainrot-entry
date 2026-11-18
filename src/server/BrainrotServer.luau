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
function BrainrotServer.buildModel(entry)
	local model = Instance.new("Model")
	model.Name = entry.name

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(3, 3, 3)
	body.Color = entry.colour
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2.2, 2, 2.2)
	head.Position = Vector3.new(0, 2.4, 0)
	head.Color = entry.colour
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.Parent = model

	-- Two eyes, so it reads as a character and not a box.
	for _, x in ipairs({ -0.55, 0.55 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Size = Vector3.new(0.5, 0.7, 0.3)
		eye.Position = Vector3.new(x, 2.6, 1.15)
		eye.Color = Color3.fromRGB(255, 255, 255)
		eye.Anchored = true
		eye.CanCollide = false
		eye.Parent = model
		local pupil = Instance.new("Part")
		pupil.Name = "Pupil"
		pupil.Size = Vector3.new(0.25, 0.35, 0.15)
		pupil.Position = Vector3.new(x, 2.6, 1.3)
		pupil.Color = Color3.fromRGB(20, 20, 20)
		pupil.Anchored = true
		pupil.CanCollide = false
		pupil.Parent = model
	end

	-- The hat: one part per cast member, in a colour of its own.
	local hat = Instance.new("Part")
	hat.Name = "Hat"
	if entry.hat == "Cup" then
		hat.Size = Vector3.new(1.6, 1.2, 1.6)
		hat.Color = Color3.fromRGB(255, 255, 255)
	elseif entry.hat == "Bandana" then
		hat.Size = Vector3.new(2.4, 0.5, 2.4)
		hat.Color = Color3.fromRGB(200, 40, 40)
	elseif entry.hat == "Bowl" then
		hat.Size = Vector3.new(2.6, 0.8, 2.6)
		hat.Color = Color3.fromRGB(240, 240, 220)
	elseif entry.hat == "Spikes" then
		hat.Size = Vector3.new(2.4, 1.4, 2.4)
		hat.Color = Color3.fromRGB(140, 200, 60)
	elseif entry.hat == "Straw" then
		hat.Size = Vector3.new(0.4, 2.2, 0.4)
		hat.Color = Color3.fromRGB(255, 90, 120)
	else -- Crown
		hat.Size = Vector3.new(2.2, 1, 2.2)
		hat.Color = Color3.fromRGB(255, 210, 60)
		hat.Material = Enum.Material.Neon
	end
	hat.Position = Vector3.new(0, 3.9, 0)
	hat.Anchored = true
	hat.CanCollide = false
	hat.Parent = model

	model.PrimaryPart = body

	-- Floating label: name, rarity, mutation and $/second.
	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotLabel"
	gui.Size = UDim2.fromOffset(180, 64)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 5.2, 0)
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
