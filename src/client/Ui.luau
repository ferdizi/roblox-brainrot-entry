-- BRAINROT KRAKATOA: the client HUD.
-- Everything the player reads lives here, over the 3D world and clear
-- of the top-left corner where Roblox puts its own menu buttons. The
-- money panel sits top-right, the belt list down the right edge, the
-- action buttons along the bottom, and the tsunami banner across the
-- top centre. update(snapshot) is the only way the HUD changes: the
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
	button.TextSize = 18
	button.Font = Enum.Font.SourceSansBold
	button.Parent = parent
	return button
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

	-- Money panel, top-right, clear of Roblox's top-left menu.
	local moneyPanel = Instance.new("Frame")
	moneyPanel.Name = "MoneyPanel"
	moneyPanel.AnchorPoint = Vector2.new(1, 0)
	moneyPanel.Position = UDim2.new(1, -12, 0, 12)
	moneyPanel.Size = UDim2.fromOffset(260, 92)
	moneyPanel.BackgroundTransparency = 0.3
	moneyPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
	moneyPanel.Parent = gui
	Ui.moneyLabel = makeLabel(moneyPanel, "Money", "$100", UDim2.new(1, -12, 0, 36), UDim2.new(0, 6, 0, 6), Color3.fromRGB(120, 255, 120), 26)
	Ui.incomeLabel = makeLabel(moneyPanel, "Income", "+$0/s", UDim2.new(1, -12, 0, 24), UDim2.new(0, 6, 0, 44), Color3.fromRGB(255, 240, 120), 18)
	Ui.rebirthLabel = makeLabel(moneyPanel, "Rebirths", "Rebirths: 0", UDim2.new(1, -12, 0, 20), UDim2.new(0, 6, 0, 68), Color3.fromRGB(200, 200, 255), 15)

	-- Tsunami banner, top centre: the countdown the whole game watches.
	Ui.waveBanner = makeLabel(gui, "WaveBanner", "Calm seas... for now", UDim2.new(0, 420, 0, 40), UDim2.new(0.5, -210, 0, 12), Color3.fromRGB(160, 220, 255), 20)
	Ui.waveBanner.BackgroundTransparency = 0.3

	-- Steal alert, just under the banner.
	Ui.alertLabel = makeLabel(gui, "Alert", "", UDim2.new(0, 420, 0, 30), UDim2.new(0.5, -210, 0, 58), Color3.fromRGB(255, 120, 120), 17)
	Ui.alertLabel.BackgroundTransparency = 1
	Ui.alertLabel.Text = ""

	-- Belt list, right edge: what is walking, what it pays, what it costs.
	local beltPanel = Instance.new("Frame")
	beltPanel.Name = "BeltPanel"
	beltPanel.AnchorPoint = Vector2.new(1, 0)
	beltPanel.Position = UDim2.new(1, -12, 0, 116)
	beltPanel.Size = UDim2.new(0, 260, 0, 300)
	beltPanel.BackgroundTransparency = 0.3
	beltPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
	beltPanel.Parent = gui
	makeLabel(beltPanel, "Title", "ON THE BELT - click to buy", UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 0, 0), Color3.fromRGB(255, 240, 120), 16)
	Ui.beltList = Instance.new("Frame")
	Ui.beltList.Name = "List"
	Ui.beltList.Size = UDim2.new(1, 0, 1, -28)
	Ui.beltList.Position = UDim2.new(0, 0, 0, 28)
	Ui.beltList.BackgroundTransparency = 1
	Ui.beltList.Parent = beltPanel

	-- Action buttons along the bottom.
	local bar = Instance.new("Frame")
	bar.Name = "ActionBar"
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 1, -12)
	bar.Size = UDim2.new(0, 640, 0, 52)
	bar.BackgroundTransparency = 1
	bar.Parent = gui
	Ui.lockButton = makeButton(bar, "Lock", "LOCK BASE (L)", UDim2.new(0, 130, 1, 0), UDim2.new(0, 0, 0, 0), Color3.fromRGB(200, 60, 60))
	Ui.slapButton = makeButton(bar, "Slap", "SLAP (F)", UDim2.new(0, 110, 1, 0), UDim2.new(0, 140, 0, 0), Color3.fromRGB(220, 130, 40))
	Ui.rebirthButton = makeButton(bar, "Rebirth", "REBIRTH (R)", UDim2.new(0, 130, 1, 0), UDim2.new(0, 260, 0, 0), Color3.fromRGB(150, 60, 200))
	Ui.upgradeButton = makeButton(bar, "Upgrades", "UPGRADES (U)", UDim2.new(0, 130, 1, 0), UDim2.new(0, 400, 0, 0), Color3.fromRGB(60, 120, 200))
	Ui.dexButton = makeButton(bar, "Dex", "DEX (B)", UDim2.new(0, 120, 1, 0), UDim2.new(0, 540, 0, 0), Color3.fromRGB(60, 180, 120))
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
	makeLabel(panel, "Title", "UPGRADES", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), Color3.fromRGB(255, 240, 120), 18)
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

-- BrainrotDex: all six cast members, ticked once owned.
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
	makeLabel(panel, "Title", "BRAINROTDEX", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), Color3.fromRGB(255, 240, 120), 18)
	Ui.dexRows = {}
	for i, entry in ipairs(Config.Cast) do
		local row = makeLabel(panel, "Dex_" .. entry.id, entry.name, UDim2.new(1, -12, 0, 34), UDim2.new(0, 6, 0, 34 + (i - 1) * 40), Config.RarityColour[entry.rarity], 16)
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
	makeLabel(panel, "Title", "CONTRACT BOARD", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), Color3.fromRGB(255, 240, 120), 18)
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
	Ui.moneyLabel.Text = Config.formatMoney(snapshot.money)
	Ui.incomeLabel.Text = "+" .. Config.formatMoney(snapshot.income) .. "/s  -  " .. tostring(snapshot.slotsUsed) .. "/" .. tostring(snapshot.slotsMax) .. " slots"
	Ui.rebirthLabel.Text = "Rebirths: " .. tostring(snapshot.rebirths) .. "  (+50% each)  -  next: " .. Config.formatMoney(snapshot.rebirthCost)

	-- The wave banner: calm, warning, or wave, with its countdown.
	if snapshot.wavePhase == "warning" then
		Ui.waveBanner.Text = "TSUNAMI IN " .. tostring(snapshot.waveCountdown) .. "s - RUN TO YOUR BASE OR THE SAFE HILL!"
		Ui.waveBanner.BackgroundColor3 = Color3.fromRGB(200, 60, 40)
	elseif snapshot.wavePhase == "wave" then
		Ui.waveBanner.Text = "TSUNAMI! HOLD ON!"
		Ui.waveBanner.BackgroundColor3 = Color3.fromRGB(40, 100, 220)
	else
		Ui.waveBanner.Text = "Next tsunami in " .. tostring(snapshot.waveCountdown) .. "s"
		Ui.waveBanner.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
	end

	-- Belt list: up to eight rows, name, rarity, mutation, rate, cost.
	for _, child in ipairs(Ui.beltList:GetChildren()) do
		child:Destroy()
	end
	for i, entry in ipairs(snapshot.belt) do
		if i > 8 then
			break
		end
		local row = makeLabel(
			Ui.beltList,
			"Belt_" .. tostring(entry.uid),
			entry.name .. " [" .. entry.mutation .. "] " .. Config.formatMoney(entry.rate) .. "/s - " .. Config.formatMoney(entry.cost),
			UDim2.new(1, -8, 0, 30),
			UDim2.new(0, 4, 0, (i - 1) * 34),
			Config.RarityColour[entry.rarity] or Color3.fromRGB(255, 255, 255),
			14
		)
		row.TextXAlignment = Enum.TextXAlignment.Left
	end

	-- Dex ticks: a check mark once a cast member has been owned.
	for _, entry in ipairs(Config.Cast) do
		local row = Ui.dexRows and Ui.dexRows[entry.id]
		if row then
			local owned = snapshot.dex and snapshot.dex[entry.id]
			row.Text = (owned and "[x] " or "[ ] ") .. entry.name .. " - " .. entry.rarity .. " " .. Config.formatMoney(entry.rate) .. "/s"
		end
	end

	-- Contract progress.
	for _, contract in ipairs(Config.Contracts) do
		local row = Ui.contractRows and Ui.contractRows[contract.id]
		if row then
			local progress = snapshot.contracts and snapshot.contracts[contract.id] or 0
			local done = snapshot.contractsDone and snapshot.contractsDone[contract.id]
			row.Text = contract.name .. ": " .. tostring(progress) .. "/" .. tostring(contract.goal) .. (done and " DONE +" .. Config.formatMoney(contract.reward) or " - reward " .. Config.formatMoney(contract.reward))
		end
	end

	-- Carrying a stolen brainrot: say so, loudly.
	if snapshot.carrying then
		Ui.alertLabel.Text = "YOU ARE CARRYING A STOLEN BRAINROT - RUN HOME!"
	else
		Ui.alertLabel.Text = ""
	end
end

return Ui
