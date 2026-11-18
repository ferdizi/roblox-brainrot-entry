-- BRAINROT KRAKATOA: keyboard shortcuts.
-- Bound with ContextActionService, not UserInputService.InputBegan:
-- Roblox's default camera scripts eat the arrow keys through
-- gameProcessedEvent, and a handler that returns on it never sees
-- them. ContextActionService bindings fire regardless, so L, F, R, U,
-- B and C always reach the game. Movement itself stays on the default
-- controls (WASD / arrows) and needs no binding at all.

local ContextActionService = game:GetService("ContextActionService")

local Input = {}

-- Bind one key to one action. actionName must be unique per binding.
function Input.bindKey(actionName, keyCode, fn)
	ContextActionService:BindAction(actionName, function(_action, state, _input)
		if state == Enum.UserInputState.Begin then
			fn()
		end
		return Enum.ContextActionResult.Pass
	end, false, keyCode)
end

-- The game's keys: lock, slap, rebirth, upgrades, dex, contracts.
function Input.bindGameKeys(callbacks)
	Input.bindKey("KrakatoaLock", Enum.KeyCode.L, function()
		if callbacks.lock then
			callbacks.lock()
		end
	end)
	Input.bindKey("KrakatoaSlap", Enum.KeyCode.F, function()
		if callbacks.slap then
			callbacks.slap()
		end
	end)
	Input.bindKey("KrakatoaRebirth", Enum.KeyCode.R, function()
		if callbacks.rebirth then
			callbacks.rebirth()
		end
	end)
	Input.bindKey("KrakatoaUpgrades", Enum.KeyCode.U, function()
		if callbacks.toggleUpgrades then
			callbacks.toggleUpgrades()
		end
	end)
	Input.bindKey("KrakatoaDex", Enum.KeyCode.B, function()
		if callbacks.toggleDex then
			callbacks.toggleDex()
		end
	end)
	Input.bindKey("KrakatoaContracts", Enum.KeyCode.C, function()
		if callbacks.toggleContracts then
			callbacks.toggleContracts()
		end
	end)
end

return Input
