-- BRAINROT KRAKATOA: the tsunami.
-- The clock the whole server lives by. A cycle of calm, warning and
-- wave, about every ninety seconds. The warning is the interesting
-- part: Glitch-mutation brainrots only roll while it is live, so the
-- bravest players stay on the belt while everyone else runs for a
-- base or the safe plaza. The wave itself sweeps the belt clean and
-- knocks anyone caught in the open back, costing them a slice of cash.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local State = require(script.Parent:WaitForChild("State"))
local BrainrotServer = require(script.Parent:WaitForChild("BrainrotServer"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

local WaveServer = {}
WaveServer.remotes = nil

-- Play a SoundService sound by name; pcall-guarded so a sound that
-- fails to load never errors the wave loop.
local function playSound(name)
	pcall(function()
		local sound = SoundService:FindFirstChild(name)
		if sound then
			sound:Play()
		end
	end)
end

-- Is this position safe from the wave: inside your own base, or on
-- the safe plaza?
local function isSafePosition(player, position)
	local data = State.get(player)
	if not data then
		return false
	end
	local baseCentre = WorldBuilder.basePositions[data.baseIndex]
	if baseCentre and (position - baseCentre).Magnitude < 12 then
		return true
	end
	local hill = Vector3.new(0, 15, -96)
	if (position - hill).Magnitude < 16 then
		return true
	end
	return false
end

-- The wave wall: a giant hot-pink GOO/SAUCE wall (Neon, slightly
-- transparent) with 3 drip spheres hanging off its bottom edge, that
-- sweeps the belt from the volcano end to the lagoon end, washing the
-- belt clean. Its path comes from Config.Belt, the same numbers the
-- belt itself uses.
function WaveServer.runWaveWall()
	local wall = Instance.new("Part")
	wall.Name = "GooWall"
	wall.Size = Vector3.new(6, 30, 60)
	wall.Position = Vector3.new(Config.Belt.startX, 12, 0)
	wall.Color = Color3.fromRGB(255, 46, 136)
	wall.Material = Enum.Material.Neon
	wall.Transparency = 0.15
	wall.Anchored = true
	wall.CanCollide = false
	wall.Parent = workspace

	-- Drip spheres off the bottom edge (uniform Ball sizes).
	local dripSpecs = { { -20, 5 }, { 0, 4 }, { 20, 3 } }
	local drips = {}
	for _, spec in ipairs(dripSpecs) do
		local drip = Instance.new("Part")
		drip.Name = "GooDrip"
		drip.Shape = Enum.PartType.Ball
		drip.Size = Vector3.new(spec[2], spec[2], spec[2])
		drip.Position = Vector3.new(Config.Belt.startX, -2, spec[1])
		drip.Color = Color3.fromRGB(255, 46, 136)
		drip.Material = Enum.Material.Neon
		drip.Transparency = 0.15
		drip.Anchored = true
		drip.CanCollide = false
		drip.Parent = workspace
		table.insert(drips, drip)
	end

	local steps = 40
	for i = 1, steps do
		if not wall.Parent then
			for _, drip in ipairs(drips) do
				drip:Destroy()
			end
			return
		end
		local alpha = i / steps
		local x = Config.Belt.startX + alpha * Config.Belt.length
		wall.Position = Vector3.new(x, 12, 0)
		for j, drip in ipairs(drips) do
			drip.Position = Vector3.new(x, -2, dripSpecs[j][1])
		end
		task.wait(Config.Wave.waveSeconds / steps)
	end
	wall:Destroy()
	for _, drip in ipairs(drips) do
		drip:Destroy()
	end
end

-- The wave hits: wash away every brainrot still on the belt, knock
-- back anyone caught in the open, and count a survived wave for the
-- players who were safe.
function WaveServer.strikeWave()
	-- Wash the belt clean.
	local uids = {}
	for _, entry in ipairs(State.belt) do
		table.insert(uids, entry.uid)
	end
	for _, uid in ipairs(uids) do
		BrainrotServer.removeBeltBrainrot(uid)
	end

	for _, player in ipairs(Players:GetPlayers()) do
		local data = State.get(player)
		local character = player.Character
		if data and character then
			local root = character:FindFirstChild("HumanoidRootPart")
			if root then
				if isSafePosition(player, root.Position) then
					data.survivedWaves += 1
					data.contracts.survive2 = data.survivedWaves
					BrainrotServer.checkContracts(player)
				else
					-- Caught in the open: thrown back and fined 10% of cash.
					-- The push is horizontal, away from the island centre;
					-- a player standing on the centre line gets pushed
					-- south instead of a zero-length direction erroring.
					local flat = Vector3.new(root.Position.X, 0, root.Position.Z)
					local away = flat.Magnitude > 1 and flat.Unit or Vector3.new(0, 0, 1)
					root.AssemblyLinearVelocity = away * 30 + Vector3.new(0, 18, 0)
					data.money = math.floor(data.money * (1 - Config.Wave.knockbackCashLoss))
					-- A thief caught by the wave drops what they were carrying.
					if data.carrying and WaveServer.onWaveDrop then
						WaveServer.onWaveDrop(player)
					end
				end
			end
		end
	end
end

-- Hook set by init.server: what the wave does to a carried brainrot.
-- Kept as a hook (not a require) so this module and StealServer never
-- require each other in a circle.
WaveServer.onWaveDrop = nil

-- Reviewer shortcut, used by TOUR.json only: jump the calm straight
-- to its warning, so a reviewer can reach the tsunami screen without
-- waiting out a full calm. It changes no money, brainrot or lock.
WaveServer.skipRequested = false
function WaveServer.skipToWarning(_arg)
	WaveServer.skipRequested = true
end

-- Announce the phase to every client through the state snapshots.
local function setPhase(phase, countdown)
	State.wavePhase = phase
	State.waveCountdown = countdown
end

-- The loop: calm, then warning, then wave, then calm again.
function WaveServer.startLoop()
	task.spawn(function()
		while true do
			setPhase("calm", Config.Wave.calmSeconds)
			for _ = 1, Config.Wave.calmSeconds do
				task.wait(1)
				State.waveCountdown -= 1
				if WaveServer.skipRequested then
					WaveServer.skipRequested = false
					break
				end
			end
			setPhase("warning", Config.Wave.warningSeconds)
			playSound("SirenSound")
			if WaveServer.remotes and WaveServer.remotes.Announce then
				WaveServer.remotes.Announce:FireAllClients({ type = "warning" })
			end
			for _ = 1, Config.Wave.warningSeconds do
				task.wait(1)
				State.waveCountdown -= 1
			end
			setPhase("wave", Config.Wave.waveSeconds)
			task.spawn(function()
				WaveServer.runWaveWall()
			end)
			WaveServer.strikeWave()
			for _ = 1, Config.Wave.waveSeconds do
				task.wait(1)
				State.waveCountdown -= 1
			end
		end
	end)
end

function WaveServer.start(remotes)
	WaveServer.remotes = remotes
	WaveServer.startLoop()
end

return WaveServer
