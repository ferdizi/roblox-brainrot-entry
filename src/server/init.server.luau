-- BRAINROT BAZAAR v2: server bootstrap.
-- One script starts the game: it builds the bazaar, creates the
-- RemoteEvents the client may use, hands each joining player a base
-- and a fresh state (or their saved state), and starts the belt and
-- the wave. Nothing else runs on the server without going through
-- here first. v2: no stealing anywhere.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local State = require(script:WaitForChild("State"))
local DataStore = require(script:WaitForChild("DataStore"))
local WorldBuilder = require(script:WaitForChild("WorldBuilder"))
local BrainrotServer = require(script:WaitForChild("BrainrotServer"))
local WaveServer = require(script:WaitForChild("WaveServer"))

print("BRAINROT BAZAAR v2 starting: building the bazaar...")

-- The bazaar, the belt, the arch, the safe plaza and six stall-bases.
WorldBuilder.build()

-- The RemoteEvents. The client may only fire the ones listed here;
-- every one is validated again on the server before it does anything.
local remotesFolder = Instance.new("Folder")
remotesFolder.Name = "BazaarRemotes"
remotesFolder.Parent = ReplicatedStorage

local remoteNames = {
	"BuyBrainrot",
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

-- Bases are handed out in join order, first come first served. Past
-- six players the ring wraps and two players share a base.
local nextBase = 1

local function onPlayerAdded(player)
	local baseIndex = nextBase
	nextBase += 1
	if nextBase > Config.Bases.count then
		nextBase = 1
	end
	State.addPlayer(player, baseIndex)
	local data = State.get(player)

	-- Load the save (pcall-wrapped inside; nil when there is none),
	-- then rebuild the saved brainrots onto their base slots.
	local savedBrainrots = DataStore.load(player, data)
	if savedBrainrots then
		BrainrotServer.restoreBrainrots(player, savedBrainrots)
	end

	-- Keep the walk speed right after every respawn.
	player.CharacterAdded:Connect(function(_character)
		task.wait(0.5)
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = State.walkSpeed(data)
			end
		end
	end)

	-- A first snapshot right away, so the HUD is never empty.
	task.wait(1)
	local snapshot = State.snapshotFor(player)
	if snapshot then
		remotes.StateSync:FireClient(player, snapshot)
	end
	print(player.Name .. " joined BRAINROT BAZAAR v2 on base " .. tostring(baseIndex))
end

local function onPlayerRemoving(player)
	-- Save before the state is dropped (pcall-wrapped inside).
	DataStore.save(player)
	State.removePlayer(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- Start the systems that run the game.
BrainrotServer.start(remotes)
WaveServer.start(remotes)

-- Autosave every 60 seconds (pcall-wrapped inside DataStore).
task.spawn(function()
	while true do
		task.wait(60)
		DataStore.saveAll()
	end
end)

print("BRAINROT BAZAAR v2 live: belt, bases, wave, golden rush running.")
