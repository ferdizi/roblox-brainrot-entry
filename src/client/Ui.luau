-- BRAINROT BAZAAR v2: the client HUD.
-- Everything the player reads lives here, over the 3D world and clear
-- of the top-left corner where Roblox puts its own menu buttons. Dense
-- like the top games: a feature bar across the top, a big wave banner,
-- a Golden Rush banner, a rich money panel top-right, the belt list
-- and a persistent quest panel down the right edge, and action buttons
-- with live counts along the bottom. update(snapshot) is the only way
-- the HUD changes: the server sends a snapshot, this module paints it.
-- v2: no lock, no slap, no carrying. Added: tutorial frame, rush banner.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Ui = {}
Ui.callbacks = {}

local function makeLabel(parent, name, text, size, position, colour, textSize)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 0.4
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
	label.TextColor3 = colour or Color3.fromRGB(255, 255, 255)
	label.Text = text
	label.TextSize = textSize or 18
	label.Font = Enum.Font.GothamBold
	label.TextWrapped = true
	label.Parent = parent
	return label
end

local function makeButton(parent, name, text, size, position, colour)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = colour or Color3.fromRGB(60, 120, 200)
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Text = text
	button.TextSize = 17
	button.Font = Enum.Font.GothamBold
	button.TextWrapped = true
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button
	return button
end

local function round(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = instance
	return corner
end

local function stroke(instance, colour, thickness)
	local outline = Instance.new("UIStroke")
	outline.Color = colour or Color3.fromRGB(255, 210, 60)
	outline.Thickness = thickness or 2
	outline.Parent = instance
	return outline
end

local function countRarities()
	local n = 0
	for _ in pairs(Config.RarityColour) do
		n = n + 1
	end
	return n
end

local function countUpgradesMax()
	local n = 0
	for _, def in pairs(Config.Upgrades) do
		n = n + def.maxLevel
	end
	return n
end

local function countDexFound(snapshot)
	local n = 0
	for _, entry in ipairs(Config.Cast) do
		if snapshot.dex and snapshot.dex[entry.id] then
			n = n + 1
		end
	end
	return n
end

local function countUpgradesBought(snapshot)
	local n = 0
	for _, level in pairs(snapshot.upgrades or {}) do
		n = n + level
	end
	return n
end

local function countQuestsDone(snapshot)
	local n = 0
	for _, contract in ipairs(Config.Contracts) do
		if snapshot.contractsDone and snapshot.contractsDone[contract.id] then
			n = n + 1
		end
	end
	return n
end

function Ui.build(playerGui, callbacks)
	Ui.callbacks = callbacks or {}

	local gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotBazaarGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.Parent = playerGui
	Ui.gui = gui

	-- Feature bar, top centre: what this game is, in one line.
	local featureText = "BRAINROT BAZAAR · " .. tostring(#Config.Cast) .. " BRAINROTS · " .. tostring(countRarities()) .. " RARITIES · " .. tostring(#Config.Mutations) .. " MUTATIONS · WAVE · REBIRTH"
	Ui.featureBar = makeLabel(gui, "FeatureBar", featureText, UDim2.new(0, 600, 0, 30), UDim2.new(0.5, -300, 0, 8), Color3.fromRGB(255, 220, 90), 15)
	Ui.featureBar.BackgroundColor3 = Color3.fromRGB(50, 20, 90)
	Ui.featureBar.BackgroundTransparency = 0.2
	round(Ui.featureBar, 8)

	-- Money panel, top-right, clear of Roblox's top-left menu.
	local moneyPanel = Instance.new("Frame")
	moneyPanel.Name = "MoneyPanel"
	moneyPanel.AnchorPoint = Vector2.new(1, 0)
	moneyPanel.Position = UDim2.new(1, -12, 0, 12)
	moneyPanel.Size = UDim2.fromOffset(210, 108)
	moneyPanel.BackgroundTransparency = 0.4
	moneyPanel.BackgroundColor3 = Color3.fromRGB(16, 12, 30)
	moneyPanel.Parent = gui
	round(moneyPanel, 8)
	stroke(moneyPanel, Color3.fromRGB(255, 215, 80), 3)
	Ui.moneyLabel = makeLabel(moneyPanel, "Money", "$100", UDim2.new(1, -12, 0, 36), UDim2.new(0, 6, 0, 6), Color3.fromRGB(255, 215, 80), 28)
	Ui.moneyLabel.BackgroundTransparency = 1
	Ui.incomeLabel = makeLabel(moneyPanel, "Income", "+$0/s", UDim2.new(1, -12, 0, 24), UDim2.new(0, 6, 0, 42), Color3.fromRGB(80, 230, 255), 18)
	Ui.incomeLabel.BackgroundTransparency = 1
	Ui.slotsLabel = makeLabel(moneyPanel, "Slots", "0/4 slots", UDim2.new(1, -12, 0, 18), UDim2.new(0, 6, 0, 66), Color3.fromRGB(255, 255, 255), 15)
	Ui.slotsLabel.BackgroundTransparency = 1
	Ui.rebirthLabel = makeLabel(moneyPanel, "Rebirths", "REBIRTH 0 · x1.0", UDim2.new(1, -12, 0, 20), UDim2.new(0, 6, 0, 84), Color3.fromRGB(200, 160, 255), 15)
	Ui.rebirthLabel.BackgroundTransparency = 1

	-- Wave banner, top centre: the countdown the whole game watches.
	-- ONE label, ONE line, ONE font, NO UIStroke on the text.
	Ui.waveBanner = makeLabel(gui, "WaveBanner", "Calm seas... for now", UDim2.new(0, 520, 0, 40), UDim2.new(0.5, -260, 0, 44), Color3.fromRGB(255, 255, 255), 20)
	Ui.waveBanner.BackgroundTransparency = 0.4
	Ui.waveBanner.TextWrapped = false
	round(Ui.waveBanner, 8)

	-- Golden Rush banner, under the wave banner: only visible during
	-- a rush (2x income).
	Ui.rushBanner = makeLabel(gui, "RushBanner", "GOLDEN RUSH! 2x INCOME!", UDim2.new(0, 360, 0, 34), UDim2.new(0.5, -180, 0, 92), Color3.fromRGB(255, 220, 60), 18)
	Ui.rushBanner.BackgroundColor3 = Color3.fromRGB(120, 80, 0)
	Ui.rushBanner.BackgroundTransparency = 0.2
	Ui.rushBanner.Visible = false
	round(Ui.rushBanner, 8)

	-- Belt list, right edge: what is walking, what it pays, what it costs.
	local beltPanel = Instance.new("Frame")
	beltPanel.Name = "BeltPanel"
	beltPanel.AnchorPoint = Vector2.new(1, 0)
	beltPanel.Position = UDim2.new(1, -12, 0, 144)
	beltPanel.Size = UDim2.new(0, 200, 0, 302)
	beltPanel.BackgroundTransparency = 0.4
	beltPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
	beltPanel.Parent = gui
	round(beltPanel, 8)
	stroke(beltPanel, Color3.fromRGB(255, 210, 60), 2)
	local beltTitle = makeLabel(beltPanel, "Title", "ON THE BELT", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), Color3.fromRGB(255, 240, 120), 14)
	beltTitle.BackgroundTransparency = 1
	Ui.beltList = Instance.new("Frame")
	Ui.beltList.Name = "List"
	Ui.beltList.Size = UDim2.new(1, 0, 1, -30)
	Ui.beltList.Position = UDim2.new(0, 0, 0, 30)
	Ui.beltList.BackgroundTransparency = 1
	Ui.beltList.Parent = beltPanel

	-- Quest panel, right edge under the belt list: always visible,
	-- the six quests with live progress.
	local questPanel = Instance.new("Frame")
	questPanel.Name = "QuestPanel"
	questPanel.AnchorPoint = Vector2.new(1, 0)
	questPanel.Position = UDim2.new(1, -12, 0, 454)
	questPanel.Size = UDim2.new(0, 200, 0, 234)
	questPanel.BackgroundTransparency = 0.4
	questPanel.BackgroundColor3 = Color3.fromRGB(30, 25, 15)
	questPanel.Parent = gui
	round(questPanel, 8)
	stroke(questPanel, Color3.fromRGB(255, 210, 60), 2)
	Ui.questTitle = makeLabel(questPanel, "Title", "QUESTS  0/6 done", UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 0), Color3.fromRGB(255, 220, 90), 15)
	Ui.questTitle.BackgroundTransparency = 1
	Ui.questRows = {}
	for i, contract in ipairs(Config.Contracts) do
		local row = makeLabel(questPanel, "Quest_" .. contract.id, contract.name, UDim2.new(1, -12, 0, 32), UDim2.new(0, 6, 0, 28 + (i - 1) * 34), Color3.fromRGB(255, 255, 255), 12)
		row.TextXAlignment = Enum.TextXAlignment.Left
		Ui.questRows[contract.id] = row
	end

	-- Action buttons along the bottom, with live counts.
	local bar = Instance.new("Frame")
	bar.Name = "ActionBar"
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 1, -12)
	bar.Size = UDim2.new(0, 640, 0, 56)
	bar.BackgroundTransparency = 1
	bar.Parent = gui
	Ui.rebirthButton = makeButton(bar, "Rebirth", "REBIRTH (R)", UDim2.new(0, 150, 1, 0), UDim2.new(0, 0, 0, 0), Color3.fromRGB(170, 60, 255))
	Ui.upgradeButton = makeButton(bar, "Upgrades", "UPGRADES (U)", UDim2.new(0, 160, 1, 0), UDim2.new(0, 155, 0, 0), Color3.fromRGB(40, 170, 255))
	Ui.dexButton = makeButton(bar, "Dex", "DEX (B)", UDim2.new(0, 150, 1, 0), UDim2.new(0, 320, 0, 0), Color3.fromRGB(40, 220, 120))
	Ui.questButton = makeButton(bar, "Quests", "QUESTS (C)", UDim2.new(0, 150, 1, 0), UDim2.new(0, 475, 0, 0), Color3.fromRGB(255, 180, 40))
	stroke(Ui.rebirthButton, Color3.fromRGB(200, 140, 255), 2)
	stroke(Ui.upgradeButton, Color3.fromRGB(120, 220, 255), 2)
	stroke(Ui.dexButton, Color3.fromRGB(120, 255, 170), 2)
	stroke(Ui.questButton, Color3.fromRGB(255, 210, 120), 2)

	-- Rarity legend, left edge (y=252): one compact panel, six rows.
	local legendPanel = Instance.new("Frame")
	legendPanel.Name = "LegendPanel"
	legendPanel.Position = UDim2.new(0, 12, 0, 252)
	legendPanel.Size = UDim2.new(0, 170, 0, 124)
	legendPanel.BackgroundTransparency = 0.4
	legendPanel.BackgroundColor3 = Color3.fromRGB(16, 12, 30)
	legendPanel.Parent = gui
	round(legendPanel, 8)
	stroke(legendPanel, Color3.fromRGB(255, 80, 180), 2)
	local legendTitle = makeLabel(legendPanel, "Title", "RARITY LEGEND", UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 0), Color3.fromRGB(255, 240, 120), 14)
	legendTitle.BackgroundTransparency = 1
	local rarityOrder = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Secret" }
	Ui.legendRows = {}
	for i, rarity in ipairs(rarityOrder) do
		local minRate, maxRate
		for _, entry in ipairs(Config.Cast) do
			if entry.rarity == rarity then
				if not minRate or entry.rate < minRate then
					minRate = entry.rate
				end
				if not maxRate or entry.rate > maxRate then
					maxRate = entry.rate
				end
			end
		end
		local rangeText
		if minRate and maxRate then
			if minRate == maxRate then
				rangeText = Config.formatMoney(minRate) .. "/s"
			else
				rangeText = Config.formatMoney(minRate) .. "–" .. Config.formatMoney(maxRate) .. "/s"
			end
		else
			rangeText = "?/s"
		end
		local row = makeLabel(legendPanel, "Legend_" .. rarity, rarity .. "  " .. rangeText, UDim2.new(1, -12, 0, 16), UDim2.new(0, 6, 0, 22 + (i - 1) * 16), Config.RarityColour[rarity] or Color3.fromRGB(255, 255, 255), 12)
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.BackgroundTransparency = 1
		Ui.legendRows[rarity] = row
	end

	-- Tutorial frame, centre screen, shown once at start.
	Ui.tutorial = Instance.new("Frame")
	Ui.tutorial.Name = "Tutorial"
	Ui.tutorial.AnchorPoint = Vector2.new(0.5, 0.5)
	Ui.tutorial.Position = UDim2.new(0.5, 0, 0.5, 0)
	Ui.tutorial.Size = UDim2.new(0, 420, 0, 260)
	Ui.tutorial.BackgroundColor3 = Color3.fromRGB(20, 16, 40)
	Ui.tutorial.BackgroundTransparency = 0.1
	Ui.tutorial.Parent = gui
	round(Ui.tutorial, 10)
	stroke(Ui.tutorial, Color3.fromRGB(255, 210, 60), 3)
	local tutTitle = makeLabel(Ui.tutorial, "Title", "HOW TO PLAY", UDim2.new(1, 0, 0, 36), UDim2.new(0, 0, 0, 0), Color3.fromRGB(255, 220, 90), 22)
	tutTitle.BackgroundTransparency = 1
	local tutBody = makeLabel(Ui.tutorial, "Body", "1. Brainrots walk the golden belt. Hold E (or click) to BUY one.\n2. It waddles to your base and earns $ every second.\n3. When the WAVE warning sounds, RUN to your base or the cyan plaza!\n4. Buy upgrades, finish quests, REBIRTH for a permanent x1.5 boost.", UDim2.new(1, -24, 0, 150), UDim2.new(0, 12, 0, 44), Color3.fromRGB(255, 255, 255), 16)
	tutBody.BackgroundTransparency = 1
	tutBody.TextXAlignment = Enum.TextXAlignment.Left
	tutBody.TextYAlignment = Enum.TextYAlignment.Top
	local tutButton = makeButton(Ui.tutorial, "GotIt", "GOT IT! LET'S GO", UDim2.new(0, 220, 0, 44), UDim2.new(0.5, -110, 0, 200), Color3.fromRGB(40, 200, 90))
	tutButton.MouseButton1Click:Connect(function()
		Ui.tutorial.Visible = false
	end)

	Ui.rebirthButton.MouseButton1Click:Connect(function()
		if Ui.callbacks.rebirth then
			Ui.callbacks.rebirth()
		end
	end)
	Ui.upgradeButton.MouseButton1Click:Connect(function()
		Ui.togglePanel("upgrades")
	end)
	Ui.dexButton.MouseButton1Click:Connect(function()
		Ui.togglePanel("dex")
	end)
	Ui.questButton.MouseButton1Click:Connect(function()
		Ui.togglePanel("contracts")
	end)

	-- Side panels: upgrades, BrainrotDex, quests. One visible at most.
	Ui.panels = {}
	Ui.panels.upgrades = Ui.buildUpgradesPanel(gui)
	Ui.panels.dex = Ui.buildDexPanel(gui)
	Ui.panels.contracts = Ui.buildContractsPanel(gui)
	Ui.currentPanel = nil

	return gui
end

function Ui.togglePanel(name)
	if Ui.currentPanel == name then
		Ui.panels[name].Visible = false
		Ui.currentPanel = nil
		return
	end
	for panelName, panel in pairs(Ui.panels) do
		panel.Visible = panelName == name
	end
	Ui.currentPanel = name
end

-- Upgrades panel: four upgrades, each with its next cost on the button.
function Ui.buildUpgradesPanel(gui)
	local panel = Instance.new("Frame")
	panel.Name = "UpgradesPanel"
	panel.AnchorPoint = Vector2.new(0, 1)
	panel.Position = UDim2.new(0, 12, 1, -76)
	panel.Size = UDim2.new(0, 240, 0, 272)
	panel.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
	panel.BackgroundTransparency = 0.4
	panel.Visible = false
	panel.Parent = gui
	round(panel, 8)
	stroke(panel, Color3.fromRGB(255, 210, 60), 2)
	Ui.upgradesTitle = makeLabel(panel, "Title", "UPGRADES", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), Color3.fromRGB(255, 240, 120), 18)
	Ui.upgradesTitle.BackgroundTransparency = 1
	Ui.upgradeRows = {}
	local order = { "slot", "speed", "beltSpeed", "golden" }
	for i, kind in ipairs(order) do
		local def = Config.Upgrades[kind]
		local row = makeButton(panel, "Upgrade_" .. kind, def.name, UDim2.new(1, -12, 0, 52), UDim2.new(0, 6, 0, 34 + (i - 1) * 58), Color3.fromRGB(60, 120, 200))
		row.TextWrapped = true
		Ui.upgradeRows[kind] = row
		row.MouseButton1Click:Connect(function()
			if Ui.callbacks.upgrade then
				Ui.callbacks.upgrade(kind)
			end
		end)
	end
	return panel
end

-- BrainrotDex: the whole cast, ticked once owned. A scrolling list.
function Ui.buildDexPanel(gui)
	local panel = Instance.new("Frame")
	panel.Name = "DexPanel"
	panel.AnchorPoint = Vector2.new(0, 1)
	panel.Position = UDim2.new(0, 12, 1, -76)
	panel.Size = UDim2.new(0, 240, 0, 300)
	panel.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
	panel.BackgroundTransparency = 0.4
	panel.Visible = false
	panel.Parent = gui
	round(panel, 8)
	stroke(panel, Color3.fromRGB(255, 210, 60), 2)
	Ui.dexTitle = makeLabel(panel, "Title", "BRAINROTDEX", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), Color3.fromRGB(255, 240, 120), 18)
	Ui.dexTitle.BackgroundTransparency = 1
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "List"
	scroll.Size = UDim2.new(1, 0, 1, -30)
	scroll.Position = UDim2.new(0, 0, 0, 30)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 6
	scroll.CanvasSize = UDim2.new(0, 0, 0, #Config.Cast * 36)
	scroll.Parent = panel
	Ui.dexRows = {}
	for i, entry in ipairs(Config.Cast) do
		local row = makeLabel(scroll, "Dex_" .. entry.id, entry.name, UDim2.new(1, -12, 0, 34), UDim2.new(0, 6, 0, (i - 1) * 36), Config.RarityColour[entry.rarity], 16)
		row.TextXAlignment = Enum.TextXAlignment.Left
		Ui.dexRows[entry.id] = row
	end
	return panel
end

-- Quest Board: six goals with live progress.
function Ui.buildContractsPanel(gui)
	local panel = Instance.new("Frame")
	panel.Name = "ContractsPanel"
	panel.AnchorPoint = Vector2.new(0, 1)
	panel.Position = UDim2.new(0, 12, 1, -76)
	panel.Size = UDim2.new(0, 240, 0, 330)
	panel.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
	panel.BackgroundTransparency = 0.4
	panel.Visible = false
	panel.Parent = gui
	round(panel, 8)
	stroke(panel, Color3.fromRGB(255, 210, 60), 2)
	local contractsTitle = makeLabel(panel, "Title", "QUEST BOARD", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), Color3.fromRGB(255, 240, 120), 18)
	contractsTitle.BackgroundTransparency = 1
	Ui.contractRows = {}
	for i, contract in ipairs(Config.Contracts) do
		local row = makeLabel(panel, "Contract_" .. contract.id, contract.name, UDim2.new(1, -12, 0, 46), UDim2.new(0, 6, 0, 34 + (i - 1) * 48), Color3.fromRGB(255, 255, 255), 15)
		Ui.contractRows[contract.id] = row
	end
	return panel
end

-- Paint one server snapshot onto the HUD.
function Ui.update(snapshot)
	if not Ui.gui then
		return
	end

	Ui.moneyLabel.Text = Config.formatMoney(snapshot.money)
	Ui.incomeLabel.Text = "+" .. Config.formatMoney(snapshot.income) .. "/s"
	Ui.slotsLabel.Text = tostring(snapshot.slotsUsed) .. "/" .. tostring(snapshot.slotsMax) .. " slots"
	local rebirthMult = 1 + Config.Rebirth.multPerRebirth * (snapshot.rebirths or 0)
	Ui.rebirthLabel.Text = "REBIRTH " .. tostring(snapshot.rebirths) .. " · x" .. string.format("%.1f", rebirthMult)

	-- The wave banner: calm, warning, or wave, with its countdown.
	if snapshot.wavePhase == "warning" then
		Ui.waveBanner.Text = "BRAINROT WAVE IN " .. tostring(snapshot.waveCountdown) .. "s! RUN HOME!"
		Ui.waveBanner.BackgroundColor3 = Color3.fromRGB(220, 30, 110)
	elseif snapshot.wavePhase == "wave" then
		Ui.waveBanner.Text = "BRAINROT WAVE! STAY ON HIGH GROUND!"
		Ui.waveBanner.BackgroundColor3 = Color3.fromRGB(75, 45, 210)
	else
		Ui.waveBanner.Text = "Next wave in " .. tostring(snapshot.waveCountdown) .. "s"
		Ui.waveBanner.BackgroundColor3 = Color3.fromRGB(30, 18, 55)
	end

	-- Golden Rush banner.
	if snapshot.goldenRush then
		Ui.rushBanner.Visible = true
	else
		Ui.rushBanner.Visible = false
	end

	-- Belt list: up to eight rows, name, rarity, mutation, rate, cost.
	for _, child in ipairs(Ui.beltList:GetChildren()) do
		child:Destroy()
	end
	for i, entry in ipairs(snapshot.belt) do
		if i > 8 then
			break
		end
		local row = makeButton(
			Ui.beltList,
			"Belt_" .. tostring(entry.uid),
			entry.name .. " [" .. entry.mutation .. "] " .. Config.formatMoney(entry.rate) .. "/s - " .. Config.formatMoney(entry.cost),
			UDim2.new(1, -8, 0, 32),
			UDim2.new(0, 4, 0, (i - 1) * 34)
		)
		row.TextColor3 = Config.RarityColour[entry.rarity] or Color3.fromRGB(255, 255, 255)
		row.TextSize = 13
		row.TextXAlignment = Enum.TextXAlignment.Left
		local uid = entry.uid
		row.MouseButton1Click:Connect(function()
			if Ui.callbacks.buy then
				Ui.callbacks.buy(uid)
			end
		end)
	end

	-- Dex ticks: a check mark once a cast member has been owned.
	local dexFound = countDexFound(snapshot)
	if Ui.dexTitle then
		Ui.dexTitle.Text = "BRAINROTDEX  " .. tostring(dexFound) .. "/" .. tostring(#Config.Cast) .. " found"
	end
	for _, entry in ipairs(Config.Cast) do
		local row = Ui.dexRows and Ui.dexRows[entry.id]
		if row then
			local owned = snapshot.dex and snapshot.dex[entry.id]
			row.Text = (owned and "[x] " or "[ ] ") .. entry.name .. " - " .. entry.rarity .. " " .. Config.formatMoney(entry.rate) .. "/s"
		end
	end

	-- Quest progress, in the side panel and the persistent quest panel.
	local questsDone = countQuestsDone(snapshot)
	if Ui.questTitle then
		Ui.questTitle.Text = "QUESTS  " .. tostring(questsDone) .. "/" .. tostring(#Config.Contracts) .. " done"
	end
	for _, contract in ipairs(Config.Contracts) do
		local progress = snapshot.contracts and snapshot.contracts[contract.id] or 0
		local done = snapshot.contractsDone and snapshot.contractsDone[contract.id]
		local row = Ui.contractRows and Ui.contractRows[contract.id]
		if row then
			row.Text = contract.name .. ": " .. tostring(progress) .. "/" .. tostring(contract.goal) .. (done and " DONE +" .. Config.formatMoney(contract.reward) or " - reward " .. Config.formatMoney(contract.reward))
		end
		local questRow = Ui.questRows and Ui.questRows[contract.id]
		if questRow then
			if done then
				questRow.Text = contract.name .. "\nDONE! +" .. Config.formatMoney(contract.reward)
				questRow.TextColor3 = Color3.fromRGB(120, 255, 120)
			else
				questRow.Text = contract.name .. "\n" .. tostring(progress) .. "/" .. tostring(contract.goal) .. "  -  reward " .. Config.formatMoney(contract.reward)
				questRow.TextColor3 = Color3.fromRGB(255, 255, 255)
			end
		end
	end

	-- Upgrade rows: name, level owned, and the next level's price.
	for kind, row in pairs(Ui.upgradeRows or {}) do
		local def = Config.Upgrades[kind]
		local level = snapshot.upgrades and snapshot.upgrades[kind] or 0
		local cost = Config.upgradeCost(kind, level)
		if cost then
			row.Text = def.name .. "  Lv " .. tostring(level) .. "  -  " .. Config.formatMoney(cost)
		else
			row.Text = def.name .. "  Lv " .. tostring(level) .. "  -  MAX"
		end
	end
	local upgradesBought = countUpgradesBought(snapshot)
	if Ui.upgradesTitle then
		Ui.upgradesTitle.Text = "UPGRADES  " .. tostring(upgradesBought) .. "/" .. tostring(countUpgradesMax())
	end

	-- Action buttons with live counts.
	Ui.rebirthButton.Text = "REBIRTH (R) " .. Config.formatMoney(snapshot.rebirthCost)
	Ui.upgradeButton.Text = "UPGRADES (U) " .. tostring(upgradesBought) .. "/" .. tostring(countUpgradesMax())
	Ui.dexButton.Text = "DEX (B) " .. tostring(dexFound) .. "/" .. tostring(#Config.Cast)
	Ui.questButton.Text = "QUESTS (C) " .. tostring(questsDone) .. "/" .. tostring(#Config.Contracts)
end

return Ui
