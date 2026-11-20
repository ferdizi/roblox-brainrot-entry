-- BRAINROT BAZAAR: default camera.
-- A LocalScript: third-person camera, slightly above and behind the
-- player, looking north-west down the street, so the first view from
-- spawn shows the street, the belt with its brainrots, and the
-- player's base in one frame. The default Roblox camera sits low
-- behind the character at spawn, where the south stall's back wall
-- hides the belt and the view ends up aimed at the signs instead.
-- Scripted on purpose (CameraType Scriptable): the default camera
-- re-derives its own distance every frame, so a one-time CFrame set
-- would snap back low. Scriptable stands the default camera down
-- cleanly instead of fighting it.
-- CFrame.lookAt never rolls, so the horizon stays level. FOV 70.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Camera sits south-east of the player, above them, and looks
-- north-west down the belt: from spawn (0, 1, 48) the eye is near
-- (16, 22, 70) and the look point is (-30, 4, 4) on the belt, so
-- Base 1 (-60, 0, -32, the first player's base) lands near the
-- centre of the frame, the belt runs diagonally across it, and the
-- south stalls sit in the lower foreground.
local OFFSET = Vector3.new(16, 18, 22)
local LOOK_AHEAD = Vector3.new(-30, 0, -44)

local camera = workspace.CurrentCamera
while not camera do
	task.wait()
	camera = workspace.CurrentCamera
end
camera.FieldOfView = 70

local rootPart = nil
local snapped = false

local function bindCharacter(character)
	rootPart = nil
	snapped = false
	if not character then
		return
	end
	local ok, part = pcall(function()
		return character:WaitForChild("HumanoidRootPart")
	end)
	if ok and part and character.Parent then
		rootPart = part
		pcall(function()
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				camera.CameraSubject = humanoid
			end
		end)
	end
end

player.CharacterAdded:Connect(bindCharacter)
if player.Character then
	task.spawn(bindCharacter, player.Character)
end

RunService.RenderStepped:Connect(function()
	if not rootPart or not rootPart.Parent then
		return
	end
	pcall(function()
		camera.CameraType = Enum.CameraType.Scriptable
		camera.FieldOfView = 70
		local eye = rootPart.Position + OFFSET
		local target = rootPart.Position + LOOK_AHEAD
		local goal = CFrame.lookAt(eye, target)
		if not snapped then
			camera.CFrame = goal
			snapped = true
		else
			camera.CFrame = camera.CFrame:Lerp(goal, 0.25)
		end
	end)
end)

print("BRAINROT BAZAAR camera ready.")
