-- BRAINROT KRAKATOA: the tsunami.
-- The clock the whole server lives by. A cycle of calm, warning and
-- wave, about every ninety seconds. The warning is the interesting
-- part: Storm-mutation brainrots only roll while it is live, so the
-- bravest players stay on the belt while everyone else runs for a
-- base or the safe hill. The wave itself sweeps the belt clean and
-- knocks anyone caught in the open back, costing them a slice of cash.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local State = require(script.Parent:WaitForChild("State"))
local BrainrotServer = require(script.Parent:WaitForChild("BrainrotServer"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

local WaveServer = {}
WaveServer.remotes = nil

-- Is this position safe from the wave: inside your own base, or on
-- the safe hill?
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

-- The wave wall: a huge translucent wall of water that sweeps the belt
-- from the volcano end to the lagoon end, washing the belt clean.
function WaveServer.runWaveWall()
	local wall = Instance.new("Part")
	wall.Name = "TsunamiWall"
	wall.Size = Vector3.new(6, 30, 60)
	wall.Position = Vector3.new(-95, 12, 0)
	wall.Color = Color3.fromRGB(40, 140, 220)
	wall.Material = Enum.Material.Water
	wall.Transparency = 0.35
	wall.Anchored = true
	wall.CanCollide = false
	wall.Parent = workspace

	local steps = 40
	for i = 1, steps do
		if not wall.Parent then
			return
		end
		local alpha = i / steps
		wall.Position = Vector3.new(-95 + alpha * 190, 12, 0)
		task.wait(Config.Wave.waveSeconds / steps)
	end
	wall:Destroy()
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
					local away = (root.Position - Vector3.new(0, 0, 0)).Unit
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
			end
			setPhase("warning", Config.Wave.warningSeconds)
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

function WaveServer.start(_remotes)
	WaveServer.startLoop()
end

return WaveServer
