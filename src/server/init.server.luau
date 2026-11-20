-- BRAINROT BAZAAR: server bootstrap.
-- One script starts the game: it builds the bazaar, creates the
-- RemoteEvents the client may use, hands each joining player a base
-- and a fresh state, and starts the belt, the stealing and the wave.
-- Nothing else runs on the server without going through here first.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local State = require(script:WaitForChild("State"))
local WorldBuilder = require(script:WaitForChild("WorldBuilder"))
local BrainrotServer = require(script:WaitForChild("BrainrotServer"))
local StealServer = require(script:WaitForChild("StealServer"))
local WaveServer = require(script:WaitForChild("WaveServer"))

print("BRAINROT BAZAAR starting: building the bazaar...")

-- The bazaar, the belt, the arch, the safe plaza and six stall-bases.
WorldBuilder.build()

-- The RemoteEvents. The client may only fire the ones listed here;
-- every one is validated again on the server before it does anything.
local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "BazaarRemotes"
remotesFolder.Parent = ReplicatedStorage

local remoteNames = {
	"BuyBrainrot",
	"LockBase",
	"Slap",
	"StealBrainrot",
	"Rebirth",
	"BuyUpgrade",
	"StateSync",
	"Announce",
}
local remotes = {}
for _, name in ipairs(remoteNames) do
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotesFolder
	remotes[name] = remote
end

-- Server sounds: the mythic-spawn sting and the wave siren, both
-- played from the server modules via a pcall-guarded Play.
local function makeSound(name)
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = "rbxassetid://9120386436"
	sound.Volume = 0.5
	sound.Parent = SoundService
	return sound
end
makeSound("MythicSound")
makeSound("SirenSound")

-- Clicking a brainrot that lives on a base is a steal attempt, not a
-- buy. The belt module does not know about stealing, so the bootstrap
-- wires the two together here, with no require circle between them.
BrainrotServer.onBaseClick = function(player, model)
	StealServer.stealByModel(player, model)
end

-- A wave that catches a thief mid-carry makes them drop the prize.
WaveServer.onWaveDrop = function(player)
	StealServer.dropCarried(player)
end

-- A rebirth while carrying hands the stolen brainrot back first, so
-- the wipe cannot leave a carried model with nowhere to go.
BrainrotServer.onRebirthDrop = function(player)
	StealServer.dropCarried(player)
end

-- Bases are handed out in join order, first come first served. Past
-- eight players the ring wraps and two players share a base: the game
-- is built for eight plots, and a ninth player still gets to play.
local nextBase = 1

local function onPlayerAdded(player)
	local baseIndex = nextBase
	nextBase += 1
	if nextBase > Config.Bases.count then
		nextBase = 1
	end
	State.addPlayer(player, baseIndex)
	StealServer.applyWalkSpeed(player)

	-- Keep the walk speed right after every respawn.
	player.CharacterAdded:Connect(function(_character)
		task.wait(0.5)
		StealServer.applyWalkSpeed(player)
	end)

	-- A first snapshot right away, so the HUD is never empty.
	task.wait(1)
	local snapshot = State.snapshotFor(player)
	if snapshot then
		remotes.StateSync:FireClient(player, snapshot)
	end
	print(player.Name .. " joined BRAINROT BAZAAR on base " .. tostring(baseIndex))
end

local function onPlayerRemoving(player)
	local data = State.get(player)
	if data and data.carrying then
		-- A thief who leaves drops the prize back where it came from.
		StealServer.dropCarried(player)
	end
	State.removePlayer(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- Start the three systems that run the game.
BrainrotServer.start(remotes)
StealServer.start(remotes)
WaveServer.start(remotes)

print("BRAINROT BAZAAR live: belt, bases, stealing and wave running.")
