-- BRAINROT BAZAAR v2: client bootstrap.
-- One LocalScript starts the client: it waits for the server's
-- RemoteEvents, builds the HUD, binds the keys, and then does nothing
-- but paint the snapshots the server sends once a second. The client
-- never decides money, ownership or rebirths; it only asks, and the
-- server answers. Clicking a brainrot on the belt buys it, through
-- the ClickDetectors the server put on the models. v2: no lock, no
-- slap, no stealing. The camera is the DEFAULT Roblox camera — the
-- spawn faces the belt, so the first view is already the good one,
-- and zoom + orbit keep working.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Ui = require(script.Parent:WaitForChild("Ui"))
local Input = require(script.Parent:WaitForChild("Input"))

-- The server creates these in init.server.luau before any client runs.
local remotes = ReplicatedStorage:WaitForChild("BazaarRemotes")
local stateSync = remotes:WaitForChild("StateSync")
local buyBrainrot = remotes:WaitForChild("BuyBrainrot")
local rebirth = remotes:WaitForChild("Rebirth")
local buyUpgrade = remotes:WaitForChild("BuyUpgrade")

local callbacks = {
	rebirth = function()
		rebirth:FireServer()
	end,
	upgrade = function(kind)
		buyUpgrade:FireServer(kind)
	end,
	-- Tapping a row in the belt list buys that brainrot: the server
	-- re-checks cash, free slot and belt membership before it moves.
	buy = function(uid)
		buyBrainrot:FireServer(uid)
	end,
}

Ui.build(playerGui, callbacks)

Input.bindGameKeys({
	rebirth = callbacks.rebirth,
	toggleUpgrades = function()
		Ui.togglePanel("upgrades")
	end,
	toggleDex = function()
		Ui.togglePanel("dex")
	end,
	toggleContracts = function()
		Ui.togglePanel("contracts")
	end,
})

-- Every snapshot repaints the HUD: money, belt, wave, Dex, quests.
stateSync.OnClientEvent:Connect(function(snapshot)
	Ui.update(snapshot)
end)

print("BRAINROT BAZAAR v2 client ready. Buy brainrots, outrun the wave.")
