-- BRAINROT KRAKATOA: stealing, slapping and locking a base.
-- The threat that makes a base worth defending. A thief clicks a
-- brainrot on someone else's base, carries it home on foot, and anyone
-- nearby can slap it out of their hands. A locked base cannot be
-- stolen from at all, but the lock only lasts half a minute and then
-- needs a long cooldown, so a lock is a decision, not a default.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local State = require(script.Parent:WaitForChild("State"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))
local BrainrotServer = require(script.Parent:WaitForChild("BrainrotServer"))

local StealServer = {}
StealServer.remotes = nil

-- Weld every loose part of a carried model to its PrimaryPart, so the
-- whole character rides overhead instead of only its body: unanchored
-- parts with no weld to anything fall off under gravity the moment the
-- thief starts moving. The welds are named, so deliver/drop can find
-- and remove exactly these and nothing else.
local function weldModelParts(model)
	local primary = model.PrimaryPart
	if not primary then
		return
	end
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part ~= primary then
			local weld = Instance.new("WeldConstraint")
			weld.Name = "CarryPartWeld"
			weld.Part0 = primary
			weld.Part1 = part
			weld.Parent = model
		end
	end
end

local function unweldModelParts(model)
	for _, weld in ipairs(model:GetDescendants()) do
		if weld:IsA("WeldConstraint") and (weld.Name == "CarryWeld" or weld.Name == "CarryPartWeld") then
			weld:Destroy()
		end
	end
end

-- Show or hide a base's red lock gate, so everyone can see it is shut.
local function setGateVisible(baseIndex, visible)
	local base = workspace:FindFirstChild("Base" .. tostring(baseIndex))
	if not base then
		return
	end
	local gate = base:FindFirstChild("LockGate")
	if gate then
		gate.Transparency = visible and 0 or 1
		gate.CanCollide = visible
	end
end

-- Lock your own base. Refused while the cooldown is still running.
function StealServer.lockBase(player)
	local data = State.get(player)
	if not data then
		return false
	end
	local now = os.time()
	if now < data.lockCooldownUntil then
		return false
	end
	if State.isLocked(data) then
		return false
	end
	data.lockedUntil = now + State.lockLength(data)
	data.lockCooldownUntil = now + State.lockLength(data) + Config.Steal.lockCooldownSeconds
	setGateVisible(data.baseIndex, true)
	task.delay(State.lockLength(data), function()
		setGateVisible(data.baseIndex, false)
	end)
	return true
end

-- Steal by model: find whose base and which slot a clicked model
-- belongs to, then run the same steal as the remote does.
function StealServer.stealByModel(player, model)
	for victim, victimData in pairs(State.players) do
		for slot, owned in pairs(victimData.brainrots) do
			if owned.model == model then
				StealServer.stealBrainrot(player, victim, slot)
				return true
			end
		end
	end
	return false
end

-- Steal a brainrot off another player's base slot. The thief carries it
-- above their head and must walk it back to their own base to keep it.
function StealServer.stealBrainrot(player, victim, slot)
	local thiefData = State.get(player)
	local victimData = State.get(victim)
	if not thiefData or not victimData then
		return false
	end
	if player == victim then
		return false
	end
	if thiefData.carrying ~= nil then
		return false -- one theft at a time
	end
	if State.isLocked(victimData) then
		return false -- a locked base cannot be stolen from
	end
	local owned = victimData.brainrots[slot]
	if not owned then
		return false
	end
	local character = player.Character
	if not character then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local model = owned.model
	if not model then
		return false
	end
	-- The thief must be standing next to the prize to grab it.
	local slotPos = WorldBuilder.slotPosition(victimData.baseIndex, slot)
	if (root.Position - slotPos).Magnitude > 14 then
		return false
	end

	victimData.brainrots[slot] = nil
	thiefData.carrying = {
		castId = owned.castId,
		name = owned.name,
		rarity = owned.rarity,
		rate = owned.rate,
		mutation = owned.mutation,
		mutationMult = owned.mutationMult,
		colour = owned.colour,
		hat = owned.hat,
		model = model,
		owner = victim,
		originalSlot = slot,
	}
	-- Carry it overhead: weld it to the thief's head, and weld its own
	-- loose parts to its body first, or the character falls apart.
	model:PivotTo(CFrame.new(root.Position + Vector3.new(0, 4, 0)))
	local weld = Instance.new("WeldConstraint")
	weld.Name = "CarryWeld"
	weld.Part0 = model.PrimaryPart
	weld.Part1 = root
	weld.Parent = model
	weldModelParts(model)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
		end
	end
	StealServer.applyWalkSpeed(player)
	return true
end

-- The carried brainrot reaches the thief's base: it is theirs now.
function StealServer.deliverCarried(player)
	local data = State.get(player)
	if not data or not data.carrying then
		return false
	end
	local slot = State.freeSlot(data)
	if not slot then
		return false -- base full: the prize stays in their hands
	end
	local carried = data.carrying
	data.carrying = nil
	local model = carried.model
	if model then
		unweldModelParts(model)
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
			end
		end
	end
	data.brainrots[slot] = {
		castId = carried.castId,
		name = carried.name,
		rarity = carried.rarity,
		rate = carried.rate,
		mutation = carried.mutation,
		mutationMult = carried.mutationMult,
		colour = carried.colour,
		hat = carried.hat,
		model = model,
		owner = player,
		slot = slot,
	}
	data.dex[carried.castId] = true
	if model then
		local target = WorldBuilder.slotPosition(data.baseIndex, slot)
		task.spawn(function()
			BrainrotServer.walkModelTo(model, target)
		end)
	end
	StealServer.applyWalkSpeed(player)
	return true
end

-- A carried brainrot is dropped: it walks back to its original owner's
-- base slot, if that slot is still free.
function StealServer.dropCarried(player)
	local data = State.get(player)
	if not data or not data.carrying then
		return false
	end
	local carried = data.carrying
	data.carrying = nil
	local victimData = State.get(carried.owner)
	local model = carried.model
	if model then
		unweldModelParts(model)
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
			end
		end
	end
	if victimData and victimData.brainrots[carried.originalSlot] == nil then
		victimData.brainrots[carried.originalSlot] = {
			castId = carried.castId,
			name = carried.name,
			rarity = carried.rarity,
			rate = carried.rate,
			mutation = carried.mutation,
			mutationMult = carried.mutationMult,
			colour = carried.colour,
			hat = carried.hat,
			model = model,
			owner = carried.owner,
			slot = carried.originalSlot,
		}
		if model then
			local target = WorldBuilder.slotPosition(victimData.baseIndex, carried.originalSlot)
			task.spawn(function()
				BrainrotServer.walkModelTo(model, target)
			end)
		end
	elseif model then
		model:Destroy()
	end
	StealServer.applyWalkSpeed(player)
	return true
end

-- Slap the nearest other player in range: knock them back, and if they
-- are carrying a stolen brainrot, make them drop it.
function StealServer.slapThief(player)
	local data = State.get(player)
	if not data then
		return false
	end
	local character = player.Character
	if not character then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local nearest = nil
	local nearestDist = Config.Steal.slapRange
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player and other.Character then
			local otherRoot = other.Character:FindFirstChild("HumanoidRootPart")
			if otherRoot then
				local dist = (otherRoot.Position - root.Position).Magnitude
				if dist < nearestDist then
					nearest = other
					nearestDist = dist
				end
			end
		end
	end
	if not nearest then
		return false
	end
	local otherRoot = nearest.Character:FindFirstChild("HumanoidRootPart")
	if not otherRoot then
		return false
	end
	local direction = (otherRoot.Position - root.Position).Unit
	otherRoot.AssemblyLinearVelocity = direction * State.slapPower(data) + Vector3.new(0, 12, 0)
	StealServer.dropCarried(nearest)
	return true
end

-- Apply this player's walk speed (upgrades, minus the carry penalty).
function StealServer.applyWalkSpeed(player)
	local data = State.get(player)
	local character = player and player.Character
	if not data or not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = State.walkSpeed(data)
	end
end

-- Check every second whether a carrier has reached their own base.
function StealServer.startDeliveryCheck()
	task.spawn(function()
		while true do
			task.wait(0.5)
			for player, data in pairs(State.players) do
				if data.carrying and player.Character then
					local root = player.Character:FindFirstChild("HumanoidRootPart")
					if root then
						local centre = WorldBuilder.basePositions[data.baseIndex]
						if centre and (root.Position - centre).Magnitude < 12 then
							StealServer.deliverCarried(player)
						end
					end
				end
			end
		end
	end)
end

function StealServer.bindRemotes(remotes)
	StealServer.remotes = remotes
	remotes.LockBase.OnServerEvent:Connect(function(player)
		StealServer.lockBase(player)
	end)
	remotes.Slap.OnServerEvent:Connect(function(player)
		StealServer.slapThief(player)
	end)
	remotes.StealBrainrot.OnServerEvent:Connect(function(player, victim, slot)
		StealServer.stealBrainrot(player, victim, slot)
	end)
end

function StealServer.start(remotes)
	StealServer.bindRemotes(remotes)
	StealServer.startDeliveryCheck()
end

return StealServer
