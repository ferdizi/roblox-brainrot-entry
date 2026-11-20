-- BRAINROT BAZAAR v2: mythic/warning/rush banner, richest
-- leaderboard, wave shake. A LocalScript: it only paints what the
-- server announces or snapshots. The banner sits below the wave
-- banner area (y ~160); the RICHEST panel sits on the left edge
-- below the rarity legend (y 384..514). Screen shake runs only while
-- wavePhase == "wave".

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("BazaarRemotes")
local announce = remotes:WaitForChild("Announce")
local stateSync = remotes:WaitForChild("StateSync")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local gui = Instance.new("ScreenGui")
gui.Name = "AnnounceGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = -1
gui.Parent = playerGui

-- Big top-centre banner, below the wave banner area. ONE label, one
-- font (GothamBold), NO UIStroke on the text.
local banner = Instance.new("TextLabel")
banner.Name = "AnnounceBanner"
banner.Size = UDim2.new(0, 520, 0, 40)
banner.Position = UDim2.new(0.5, -260, 0, 160)
banner.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
banner.BackgroundTransparency = 0.4
banner.TextColor3 = Color3.fromRGB(255, 255, 255)
banner.TextSize = 20
banner.Font = Enum.Font.GothamBold
banner.TextWrapped = true
banner.Visible = false
banner.Parent = gui
local bannerCorner = Instance.new("UICorner")
bannerCorner.CornerRadius = UDim.new(0, 8)
bannerCorner.Parent = banner

-- A token so a newer banner can't be hidden by an older one's timer.
local bannerToken = 0
local function showBanner(text, colour, seconds)
	bannerToken += 1
	local token = bannerToken
	banner.Text = text
	banner.TextColor3 = colour
	banner.Visible = true
	task.delay(seconds, function()
		if token == bannerToken then
			banner.Visible = false
		end
	end)
end

announce.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" then
		return
	end
	if data.type == "mythic" then
		local colour = Config.RarityColour[data.rarity] or Color3.fromRGB(255, 70, 120)
		showBanner(
			"MYTHIC SPAWNED! " .. tostring(data.name) .. " — " .. Config.formatMoney(data.rate or 0) .. "/s on the belt!",
			colour,
			5
		)
	elseif data.type == "warning" then
		showBanner("THE WAVE IS COMING — RUN HOME!", Color3.fromRGB(255, 80, 60), 3)
	elseif data.type == "rush" then
		showBanner("GOLDEN RUSH! 2x INCOME FOR 30 SECONDS!", Color3.fromRGB(255, 220, 60), 5)
	end
end)

-- RICHEST leaderboard panel, left edge below the rarity legend.
local panel = Instance.new("Frame")
panel.Name = "LeadersPanel"
panel.Position = UDim2.new(0, 12, 0, 384)
panel.Size = UDim2.new(0, 170, 0, 130)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
panel.BackgroundTransparency = 0.4
panel.Parent = gui
local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 8)
panelCorner.Parent = panel
local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(255, 210, 60)
panelStroke.Thickness = 2
panelStroke.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 24)
title.BackgroundTransparency = 1
title.Text = "RICHEST"
title.TextColor3 = Color3.fromRGB(255, 240, 120)
title.TextSize = 15
title.Font = Enum.Font.GothamBold
title.Parent = panel

local rows = {}
for i = 1, 5 do
	local row = Instance.new("TextLabel")
	row.Name = "Leader_" .. tostring(i)
	row.Size = UDim2.new(1, -12, 0, 18)
	row.Position = UDim2.new(0, 6, 0, 26 + (i - 1) * 20)
	row.BackgroundTransparency = 1
	row.Text = ""
	row.TextColor3 = Color3.fromRGB(255, 255, 255)
	row.TextSize = 13
	row.Font = Enum.Font.GothamBold
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.Parent = panel
	rows[i] = row
end

-- Screen shake: only while the snapshot says the wave is live. The
-- offset is applied relative to the previous frame's offset, so the
-- camera never drifts; leaving "wave" unwinds the last offset once.
local waveActive = false
local prevShake = Vector3.new(0, 0, 0)

stateSync.OnClientEvent:Connect(function(snapshot)
	if type(snapshot) ~= "table" then
		return
	end
	waveActive = snapshot.wavePhase == "wave"
	local leaders = snapshot.leaders or {}
	for i = 1, 5 do
		local entry = leaders[i]
		if entry then
			rows[i].Text = tostring(i) .. ". " .. tostring(entry.name) .. " — " .. Config.formatMoney(entry.money or 0)
		else
			rows[i].Text = ""
		end
	end
end)

RunService.RenderStepped:Connect(function()
	if not waveActive then
		if prevShake ~= Vector3.new(0, 0, 0) then
			pcall(function()
				local camera = workspace.CurrentCamera
				if camera then
					camera.CFrame = camera.CFrame * CFrame.new(-prevShake)
				end
			end)
			prevShake = Vector3.new(0, 0, 0)
		end
		return
	end
	pcall(function()
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		local offset = Vector3.new((math.random() - 0.5) * 0.5, (math.random() - 0.5) * 0.5, 0)
		camera.CFrame = camera.CFrame * CFrame.new(offset - prevShake)
		prevShake = offset
	end)
end)

print("BRAINROT BAZAAR v2 announce client ready.")
