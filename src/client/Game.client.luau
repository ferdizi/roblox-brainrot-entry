-- BRAINROT BAZAAR: client bootstrap.
-- One LocalScript starts the client: it waits for the server's
-- RemoteEvents, builds the HUD, binds the keys, and then does nothing
-- but paint the snapshots the server sends once a second. The client
-- never decides money, ownership or locks; it only asks, and the
-- server answers. Clicking a brainrot on the belt buys it, clicking
-- one on someone else's base tries to steal it - both through the
-- ClickDetectors the server put on the models.

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
local lockBase = remotes:WaitForChild("LockBase")
local slap = remotes:WaitForChild("Slap")
local rebirth = remotes:WaitForChild("Rebirth")
local buyUpgrade = remotes:WaitForChild("BuyUpgrade")

local callbacks = {
	lock = function()
		lockBase:FireServer()
	end,
	slap = function()
		slap:FireServer()
	end,
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
	lock = callbacks.lock,
	slap = callbacks.slap,
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

-- Every snapshot repaints the HUD: money, belt, wave, Dex, contracts.
stateSync.OnClientEvent:Connect(function(snapshot)
	Ui.update(snapshot)
end)

print("BRAINROT BAZAAR client ready. Buy brainrots, lock your base, outrun the wave.")
