-- BRAINROT KRAKATOA: the client HUD.
-- Everything the player reads lives here, over the 3D world and clear
-- of the top-left corner where Roblox puts its own menu buttons. The
-- layout is deliberately dense, like the top games: a feature bar
-- across the top, a big wave banner, a carrying bar, a rich money
-- panel top-right, the belt list and a persistent quest panel down
-- the right edge, and action buttons with live counts along the
-- bottom. update(snapshot) is the only way the HUD changes: the
-- server sends a snapshot, this module paints it.

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
	label.Font = Enum.Font.SourceSansBold
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
	button.TextSize = 16
	button.Font = Enum.Font.SourceSansBold
	button.TextWrapped = true
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button
	return button
end

-- Rounded corners and a bright outline, the two cheap tricks that
-- make a plain dark panel read as a finished game UI.
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

-- Build the whole HUD once. callbacks: lock, slap, rebirth, upgrade.
function Ui.build(playerGui, callbacks)
	Ui.callbacks = callbacks or {}

	local gui = Instance.new("ScreenGui")
	gui.Name = "KrakatoaGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.Parent = playerGui
	Ui.gui = gui

	-- Feature bar, top centre: what this game is, in one line.
	-- The counts come from Config, so they stay true if the cast grows.
	local featureText = "KRAKATOA · " .. tostring(#Config.Cast) .. " BRAINROTS · " .. tostring(countRarities()) .. " RARITIES · " .. tostring(#Config.Mutations) .. " MUTATIONS · STEAL · LOCK · REBIRTH"
	Ui.featureBar = makeLabel(gui, "FeatureBar", featureText, UDim2.new(0, 600, 0, 30), UDim2.new(0.5, -300, 0, 8), Color3.fromRGB(255, 220, 90), 15)
	Ui.featureBar.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
	Ui.featureBar.BackgroundTransparency = 0.2
	round(Ui.featureBar, 8)
	stroke(Ui.featureBar, Color3.fromRGB(255, 210, 60), 2)

	-- Money panel, top-right, clear of Roblox's top-left menu.
	-- Four lines now: cash, income, slots, and the rebirth multiplier.
	local moneyPanel = Instance.new("Frame")
	moneyPanel.Name = "MoneyPanel"
	moneyPanel.AnchorPoint = Vector2.new(1, 0)
	moneyPanel.Position = UDim2.new(1, -12, 0, 12)
	moneyPanel.Size = UDim2.fromOffset(280, 124)
	moneyPanel.BackgroundTransparency = 0.25
	moneyPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
	moneyPanel.Parent = gui
	round(moneyPanel, 8)
	stroke(moneyPanel, Color3.fromRGB(255, 210, 60), 2)
	Ui.moneyLabel = makeLabel(moneyPanel, "Money", "$100", UDim2.new(1, -12, 0, 42), UDim2.new(0, 6, 0, 6), Color3.fromRGB(120, 255, 120), 30)
	Ui.moneyLabel.BackgroundTransparency = 1
	Ui.incomeLabel = makeLabel(moneyPanel, "Income", "+$0/s", UDim2.new(1, -12, 0, 26), UDim2.new(0, 6, 0, 48), Color3.fromRGB(255, 240, 120), 18)
	Ui.incomeLabel.BackgroundTransparency = 1
	Ui.slotsLabel = makeLabel(moneyPanel, "Slots", "0/4 slots", UDim2.new(1, -12, 0, 20), UDim2.new(0, 6, 0, 74), Color3.fromRGB(255, 255, 255), 15)
	Ui.slotsLabel.BackgroundTransparency = 1
	Ui.rebirthLabel = makeLabel(moneyPanel, "Rebirths", "REBIRTH 0 · x1.0", UDim2.new(1, -12, 0, 22), UDim2.new(0, 6, 0, 94), Color3.fromRGB(200, 160, 255), 15)
	Ui.rebirthLabel.BackgroundTransparency = 1

	-- Tsunami banner, top centre: the countdown the whole game watches.
	-- Bigger than before, and its colour shouts the phase.
	Ui.waveBanner = makeLabel(gui, "WaveBanner", "Calm seas... for now", UDim2.new(0, 560, 0, 52), UDim2.new(0.5, -280, 0, 44), Color3.fromRGB(160, 220, 255), 20)
	Ui.waveBanner.BackgroundTransparency = 0.15
	round(Ui.waveBanner, 8)
	stroke(Ui.waveBanner, Color3.fromRGB(255, 255, 255), 2)

	-- Carrying bar, under the banner: only visible while the player
	-- carries a stolen brainrot. Big, red, impossible to miss. The
	-- snapshot only says whether the player is carrying, not which
	-- brainrot, so the text stays generic.
	Ui.alertLabel = makeLabel(gui, "Alert", "", UDim2.new(0, 560, 0, 38), UDim2.new(0.5, -280, 0, 102), Color3.fromRGB(255, 255, 255), 20)
	Ui.alertLabel.BackgroundTransparency = 0.1
	Ui.alertLabel.BackgroundColor3 = Color3.fromRGB(200, 60, 40)
	Ui.alertLabel.Visible = false
	round(Ui.alertLabel, 8)
	stroke(Ui.alertLabel, Color3.fromRGB(255, 220, 60), 2)

	-- Belt list, right edge: what is walking, what it pays, what it costs.
	local beltPanel = Instance.new("Frame")
	beltPanel.Name = "BeltPanel"
	beltPanel.AnchorPoint = Vector2.new(1, 0)
	beltPanel.Position = UDim2.new(1, -12, 0, 144)
	beltPanel.Size = UDim2.new(0, 260, 0, 336)
	beltPanel.BackgroundTransparency = 0.25
	beltPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
	beltPanel.Parent = gui
	round(beltPanel, 8)
	stroke(beltPanel, Color3.fromRGB(255, 210, 60), 2)
	local beltTitle = makeLabel(beltPanel, "Title", "ON THE BELT - click to buy", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), Color3.fromRGB(255, 240, 120), 16)
	beltTitle.BackgroundTransparency = 1
	Ui.beltList = Instance.new("Frame")
	Ui.beltList.Name = "List"
	Ui.beltList.Size = UDim2.new(1, 0, 1, -30)
	Ui.beltList.Position = UDim2.new(0, 0, 0, 30)
	Ui.beltList.BackgroundTransparency = 1
	Ui.beltList.Parent = beltPanel

	-- Quest panel, right edge under the belt list: always visible,
	-- the three contracts with live progress, like the top games.
	local questPanel = Instance.new("Frame")
	questPanel.Name = "QuestPanel"
	questPanel.AnchorPoint = Vector2.new(1, 0)
	questPanel.Position = UDim2.new(1, -12, 0, 488)
	questPanel.Size = UDim2.new(0, 260, 0, 200)
	questPanel.BackgroundTransparency = 0.25
	questPanel.BackgroundColor3 = Color3.fromRGB(30, 25, 15)
	questPanel.Parent = gui
	round(questPanel, 8)
	stroke(questPanel, Color3.fromRGB(255, 210, 60), 2)
	Ui.questTitle = makeLabel(questPanel, "Title", "QUESTS  0/3 done", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), Color3.fromRGB(255, 220, 90), 18)
	Ui.questTitle.BackgroundTransparency = 1
	Ui.questRows = {}
	for i, contract in ipairs(Config.Contracts) do
		local row = makeLabel(questPanel, "Quest_" .. contract.id, contract.name, UDim2.new(1, -12, 0, 50), UDim2.new(0, 6, 0, 34 + (i - 1) * 54), Color3.fromRGB(255, 255, 255), 15)
		row.TextXAlignment = Enum.TextXAlignment.Left
		Ui.questRows[contract.id] = row
	end

	-- Action buttons along the bottom, with live counts.
	local bar = Instance.new("Frame")
	bar.Name = "ActionBar"
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 1, -12)
	bar.Size = UDim2.new(0, 720, 0, 56)
	bar.BackgroundTransparency = 1
	bar.Parent = gui
	Ui.lockButton = makeButton(bar, "Lock", "LOCK BASE (L)", UDim2.new(0, 130, 1, 0), UDim2.new(0, 0, 0, 0), Color3.fromRGB(200, 60, 60))
	Ui.slapButton = makeButton(bar, "Slap", "SLAP (F)", UDim2.new(0, 110, 1, 0), UDim2.new(0, 135, 0, 0), Color3.fromRGB(220, 130, 40))
	Ui.rebirthButton = makeButton(bar, "Rebirth", "REBIRTH (R)", UDim2.new(0, 150, 1, 0), UDim2.new(0, 250, 0, 0), Color3.fromRGB(150, 60, 200))
	Ui.upgradeButton = makeButton(bar, "Upgrades", "UPGRADES (U)", UDim2.new(0, 160, 1, 0), UDim2.new(0, 405, 0, 0), Color3.fromRGB(60, 120, 200))
	Ui.dexButton = makeButton(bar, "Dex", "DEX (B)", UDim2.new(0, 150, 1, 0), UDim2.new(0, 570, 0, 0), Color3.fromRGB(60, 180, 120))
	-- Contract button lives on the left edge, above the Dex panel.
	Ui.contractButton = makeButton(gui, "Contracts", "CONTRACTS (C)", UDim2.new(0, 150, 0, 44), UDim2.new(0, 12, 0, 200), Color3.fromRGB(60, 180, 120))

	Ui.lockButton.MouseButton1Click:Connect(function()
		if Ui.callbacks.lock then
			Ui.callbacks.lock()
		end
	end)
	Ui.slapButton.MouseButton1Click:Connect(function()
		if Ui.callbacks.slap then
			Ui.callbacks.slap()
		end
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
	Ui.contractButton.MouseButton1Click:Connect(function()
		Ui.togglePanel("contracts")
	end)

	-- Side panels: upgrades, BrainrotDex, contracts. One visible at most.
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
	panel.Size = UDim2.new(0, 300, 0, 300)
	panel.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
	panel.BackgroundTransparency = 0.15
	panel.Visible = false
	panel.Parent = gui
	round(panel, 8)
	stroke(panel, Color3.fromRGB(255, 210, 60), 2)
	Ui.upgradesTitle = makeLabel(panel, "Title", "UPGRADES", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), Color3.fromRGB(255, 240, 120), 18)
	Ui.upgradesTitle.BackgroundTransparency = 1
	Ui.upgradeRows = {}
	local order = { "slot", "speed", "slap", "lock" }
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

-- BrainrotDex: the whole cast, ticked once owned. A scrolling list,
-- because the cast is bigger than the panel now.
function Ui.buildDexPanel(gui)
	local panel = Instance.new("Frame")
	panel.Name = "DexPanel"
	panel.AnchorPoint = Vector2.new(0, 1)
	panel.Position = UDim2.new(0, 12, 1, -76)
	panel.Size = UDim2.new(0, 300, 0, 300)
	panel.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
	panel.BackgroundTransparency = 0.15
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

-- Contract Board: three goals with live progress.
function Ui.buildContractsPanel(gui)
	local panel = Instance.new("Frame")
	panel.Name = "ContractsPanel"
	panel.AnchorPoint = Vector2.new(0, 1)
	panel.Position = UDim2.new(0, 12, 1, -76)
	panel.Size = UDim2.new(0, 300, 0, 300)
	panel.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
	panel.BackgroundTransparency = 0.15
	panel.Visible = false
	panel.Parent = gui
	round(panel, 8)
	stroke(panel, Color3.fromRGB(255, 210, 60), 2)
	local contractsTitle = makeLabel(panel, "Title", "CONTRACT BOARD", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), Color3.fromRGB(255, 240, 120), 18)
	contractsTitle.BackgroundTransparency = 1
	Ui.contractRows = {}
	for i, contract in ipairs(Config.Contracts) do
		local row = makeLabel(panel, "Contract_" .. contract.id, contract.name, UDim2.new(1, -12, 0, 52), UDim2.new(0, 6, 0, 34 + (i - 1) * 58), Color3.fromRGB(255, 255, 255), 16)
		Ui.contractRows[contract.id] = row
	end
	return panel
end

-- Paint one server snapshot onto the HUD.
function Ui.update(snapshot)
	if not Ui.gui then
		return
	end

	-- Money panel: cash, income, slots, and the rebirth multiplier.
	-- The multiplier is +50% income per rebirth.
	Ui.moneyLabel.Text = Config.formatMoney(snapshot.money)
	Ui.incomeLabel.Text = "+" .. Config.formatMoney(snapshot.income) .. "/s"
	Ui.slotsLabel.Text = tostring(snapshot.slotsUsed) .. "/" .. tostring(snapshot.slotsMax) .. " slots"
	local rebirthMult = 1 + Config.Rebirth.multPerRebirth * (snapshot.rebirths or 0)
	Ui.rebirthLabel.Text = "REBIRTH " .. tostring(snapshot.rebirths) .. " · x" .. string.format("%.1f", rebirthMult)

	-- The wave banner: calm, warning, or wave, with its countdown.
	-- Warning and wave are two lines, so the danger is impossible to miss.
	if snapshot.wavePhase == "warning" then
		Ui.waveBanner.Text = "TSUNAMI IN " .. tostring(snapshot.waveCountdown) .. "s!\nRUN TO YOUR BASE OR THE SAFE HILL!"
		Ui.waveBanner.BackgroundColor3 = Color3.fromRGB(200, 60, 40)
	elseif snapshot.wavePhase == "wave" then
		Ui.waveBanner.Text = "TSUNAMI!\nHOLD ON - STAY ON HIGH GROUND!"
		Ui.waveBanner.BackgroundColor3 = Color3.fromRGB(40, 100, 220)
	else
		Ui.waveBanner.Text = "Next tsunami in " .. tostring(snapshot.waveCountdown) .. "s"
		Ui.waveBanner.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
	end

	-- Belt list: up to eight rows, name, rarity, mutation, rate, cost.
	-- Each row is a button: tapping it buys that brainrot, the same
	-- buy as clicking its 3D model on the belt.
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
			UDim2.new(1, -8, 0, 36),
			UDim2.new(0, 4, 0, (i - 1) * 38)
		)
		-- Rarity colours the text, not the button: white-on-purple and
		-- dark-on-yellow both read badly, one dark button does not.
		row.TextColor3 = Config.RarityColour[entry.rarity] or Color3.fromRGB(255, 255, 255)
		row.TextSize = 15
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

	-- Contract progress, in the side panel and the persistent quest panel.
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

	-- Upgrade rows: name, level owned, and the next level's price, so
	-- a player can tell what a button costs before tapping it. The
	-- price comes from Config.upgradeCost, the same helper the server
	-- charges with, so the two can never disagree.
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

	-- Action buttons with live counts: rebirth shows its cost, upgrades
	-- shows total levels bought, Dex shows how many cast members are found.
	Ui.rebirthButton.Text = "REBIRTH (R) " .. Config.formatMoney(snapshot.rebirthCost)
	Ui.upgradeButton.Text = "UPGRADES (U) " .. tostring(upgradesBought) .. "/" .. tostring(countUpgradesMax())
	Ui.dexButton.Text = "DEX (B) " .. tostring(dexFound) .. "/" .. tostring(#Config.Cast)

	-- Lock button: locked, cooling down, or ready, with its seconds.
	local now = os.time()
	if snapshot.lockedUntil and now < snapshot.lockedUntil then
		Ui.lockButton.Text = "LOCKED (" .. tostring(snapshot.lockedUntil - now) .. "s)"
	elseif snapshot.lockCooldownUntil and now < snapshot.lockCooldownUntil then
		Ui.lockButton.Text = "LOCK IN " .. tostring(snapshot.lockCooldownUntil - now) .. "s"
	else
		Ui.lockButton.Text = "LOCK BASE (L)"
	end

	-- Carrying a stolen brainrot: say so, loudly, in a big red bar.
	if snapshot.carrying then
		Ui.alertLabel.Visible = true
		Ui.alertLabel.Text = "CARRYING: STOLEN BRAINROT - RUN TO YOUR BASE!"
	else
		Ui.alertLabel.Visible = false
		Ui.alertLabel.Text = ""
	end
end

return Ui
