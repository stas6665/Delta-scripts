local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ClientServices = ReplicatedStorage:FindFirstChild("ClientServices")
local ModulesFolder = ReplicatedStorage:FindFirstChild("Modules")
local DatabaseFolder = ReplicatedStorage:FindFirstChild("Database")

local function safeRequire(inst)
	if not inst or not inst:IsA("ModuleScript") then
		return nil
	end
	local ok, res = pcall(require, inst)
	return ok and res or nil
end

local ItemService = ClientServices and safeRequire(ClientServices:FindFirstChild("ItemService"))
local ItemPopupService = ClientServices and safeRequire(ClientServices:FindFirstChild("ItemPopupService"))
local ItemModule = ModulesFolder and safeRequire(ModulesFolder:FindFirstChild("ItemModule"))
local DatabaseSync = DatabaseFolder and safeRequire(DatabaseFolder:FindFirstChild("Sync"))

_G.Cache = _G.Cache or {}
_G.SmallCache = _G.SmallCache or {}

local function findItemInDatabaseItem(inputText)
	local itemDb = DatabaseSync and DatabaseSync.Item
	if type(itemDb) ~= "table" then
		return nil, nil
	end

	local clean = string.lower((tostring(inputText or ""):gsub("^%s+", ""):gsub("%s+$", "")))
	if clean == "" then
		return nil, nil
	end

	for key, data in pairs(itemDb) do
		if type(key) == "string" and string.lower(key) == clean and type(data) == "table" then
			return key, data
		end
	end

	for key, data in pairs(itemDb) do
		if type(data) == "table" then
			local displayName = data.ItemName or data.Name or data.DisplayName
			if type(displayName) == "string" and string.lower(displayName) == clean then
				return key, data
			end
		end
	end

	return nil, nil
end

local function getRarityColor(rarityName)
	local rName = rarityName or "Common"
	if rName == "Common" then
		return Color3.fromRGB(95, 95, 95)
	end

	if DatabaseSync and type(DatabaseSync.Rarity) == "table" and typeof(DatabaseSync.Rarity[rName]) == "Color3" then
		return DatabaseSync.Rarity[rName]
	end

	local raritiesTable = DatabaseSync and DatabaseSync.Rarities
	local colorData = raritiesTable and (raritiesTable[rName] or raritiesTable["Common"])
	if type(colorData) == "table" and type(colorData.Color) == "table" then
		local c = colorData.Color
		if c.r and c.g and c.b then
			return Color3.fromRGB(c.r, c.g, c.b)
		end
	end

	if string.lower(tostring(rName)) == "godly" then
		return Color3.fromRGB(255, 0, 85)
	end

	return Color3.fromRGB(255, 255, 255)
end

local function getPopupGui()
	local crossPlatform = playerGui:FindFirstChild("CrossPlatform")
	local popupRoot = crossPlatform and crossPlatform:FindFirstChild("NewItem")
	if popupRoot then
		local medium = popupRoot:FindFirstChild("Medium")
		local container = medium and medium:FindFirstChild("Container")
		local card = container and container:FindFirstChild("NewItem")
		return crossPlatform, popupRoot, medium, container, card
	end

	local mainGui = playerGui:FindFirstChild("MainGUI")
	local invNewItem = mainGui
		and mainGui:FindFirstChild("Inventory")
		and mainGui.Inventory:FindFirstChild("NewItem")

	if invNewItem then
		local medium = invNewItem:FindFirstChild("Medium")
		local container = (medium and medium:FindFirstChild("Container")) or invNewItem:FindFirstChild("Container")
		local card = container and container:FindFirstChild("NewItem")
		return mainGui, invNewItem, medium, container, card
	end

	return nil, nil, nil, nil, nil
end

local function stretchBackdrop(obj)
	if not obj or not obj:IsA("GuiObject") then
		return
	end
	for _, c in ipairs(obj:GetChildren()) do
		if c:IsA("UIAspectRatioConstraint") or c:IsA("UISizeConstraint") then
			c:Destroy()
		end
	end
	obj.AnchorPoint = Vector2.new(0, 0)
	obj.Position = UDim2.fromScale(-0.1, -0.1)
	obj.Size = UDim2.fromScale(1.2, 1.2)
end

local function fixBackdropFullScreen(screenGui, popupRoot)
	if screenGui and screenGui:IsA("ScreenGui") then
		screenGui.IgnoreGuiInset = true
	end
	if not popupRoot then
		return
	end

	if popupRoot:IsA("GuiObject") and popupRoot.BackgroundTransparency < 1 then
		stretchBackdrop(popupRoot)
	end

	for _, desc in ipairs(popupRoot:GetDescendants()) do
		if desc:IsA("GuiObject") then
			local lname = string.lower(desc.Name)
			local isDimName = lname:find("backdrop")
				or lname:find("darken")
				or lname:find("dim")
				or lname:find("overlay")
				or lname:find("shadow")
				or lname:find("fade")
				or lname:find("background")
				or lname == "bg"

			local isNotCardPart = desc.Name ~= "ItemName"
				and desc.Name ~= "RarityBar"
				and desc.Name ~= "Container"
				and desc.Name ~= "Medium"
				and desc.Name ~= "NewItem"

			if isDimName and isNotCardPart then
				stretchBackdrop(desc)
			elseif isNotCardPart and desc.BackgroundTransparency < 1 and desc.AbsoluteSize.X > 200 and desc.AbsoluteSize.Y > 200 then
				stretchBackdrop(desc)
			end
		end
	end
end

local function setPopupVisible(screenGui, popupRoot, medium, container, card, state)
	if screenGui and screenGui:IsA("LayerCollector") and state then
		screenGui.Enabled = true
	end
	if popupRoot and popupRoot:IsA("GuiObject") then
		popupRoot.Visible = state
	end
	if medium and medium:IsA("GuiObject") then
		medium.Visible = state
	end
	if container and container:IsA("GuiObject") then
		container.Visible = state
	end
	if card and card:IsA("GuiObject") then
		card.Visible = state
	end
	if state then
		fixBackdropFullScreen(screenGui, popupRoot)
	end
end

local function showPopupWindow(itemKey, itemData, amount)
	local screenGui, popupRoot, medium, container, card = getPopupGui()
	if not popupRoot then
		return false
	end

	setPopupVisible(screenGui, popupRoot, medium, container, card, true)

	local rarityColor = getRarityColor(itemData.Rarity)
	local starburst = popupRoot:FindFirstChild("Starburst", true)
	if starburst and (starburst:IsA("ImageLabel") or starburst:IsA("ImageButton")) then
		starburst.ImageColor3 = rarityColor
	end

	local count = amount or 1
	if card then
		if ItemService and type(ItemService.ApplyItemToFrame) == "function" then
			pcall(function()
				ItemService:ApplyItemToFrame(card, itemData, count)
			end)
		end
		if ItemService and type(ItemService.ApplyTags) == "function" then
			pcall(function()
				ItemService:ApplyTags(card, itemData)
			end)
		end
		if ItemModule and type(ItemModule.DisplayItem) == "function" then
			pcall(function()
				ItemModule.DisplayItem(card, itemData, count, false)
			end)
		end
	end

	if ItemPopupService and type(ItemPopupService.AddNewItem) == "function" then
		pcall(function()
			ItemPopupService:AddNewItem(itemKey, itemData, count)
		end)
	end

	return true
end

local function findPopupClaimButton(popupRoot, card)
	if card then
		for _, desc in ipairs(card:GetDescendants()) do
			if (desc:IsA("TextButton") or desc:IsA("ImageButton")) and string.lower(desc.Name) == "claim" then
				return desc
			end
		end
	end
	if popupRoot then
		for _, desc in ipairs(popupRoot:GetDescendants()) do
			if (desc:IsA("TextButton") or desc:IsA("ImageButton")) and string.lower(desc.Name) == "claim" then
				return desc
			end
		end
	end
	return nil
end

local function getInventoryTargetContainer()
	local weaponsNode = playerGui:FindFirstChild("Weapons", true)
	if not weaponsNode then
		return nil
	end

	local branch = weaponsNode:FindFirstChild("Current", true) or weaponsNode:FindFirstChild("Classic", true)
	return branch and branch:FindFirstChild("Container", true)
end

local function getInventoryButton()
	local mainGui = playerGui:FindFirstChild("MainGUI")
	local dockInv = mainGui
		and mainGui:FindFirstChild("Lobby")
		and mainGui.Lobby:FindFirstChild("Dock")
		and mainGui.Lobby.Dock:FindFirstChild("Inventory")

	if dockInv and dockInv:IsA("GuiObject") then
		return dockInv
	end

	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") then
			local inv = gui:FindFirstChild("Inventory", true) or gui:FindFirstChild("INVENTORY", true)
			if inv and inv:IsA("GuiObject") then
				return inv
			end
		end
	end
	return nil
end

local function spawnAndPlaceInventoryCard(itemKey, itemData, amount)
	local targetContainer = getInventoryTargetContainer()
	if not targetContainer or not ItemService or not ItemService.BaseItemFrame then
		return nil
	end

	local card = ItemService.BaseItemFrame:Clone()
	card.Name = "NewItem"
	local count = amount or 1

	if type(ItemService.ApplyItemToFrame) == "function" then
		pcall(function()
			ItemService:ApplyItemToFrame(card, itemData, count)
		end)
	end

	if type(ItemService.ApplyTags) == "function" then
		pcall(function()
			ItemService:ApplyTags(card, itemData)
		end)
	end

	if type(ItemService.GetLayoutOrder) == "function" then
		local category = itemData.DataType or (itemData.ItemType and "Weapons") or "Weapons"
		local ok, order = pcall(function()
			return ItemService:GetLayoutOrder(itemKey, category)
		end)
		if ok and type(order) == "number" then
			card.LayoutOrder = order
		end
	end

	if ItemModule and type(ItemModule.DisplayItem) == "function" then
		pcall(function()
			ItemModule.DisplayItem(card, itemData, count, false)
		end)
	end

	card.Visible = true
	card.Parent = targetContainer
	return card
end

local activeKey, activeData, activeAmount = nil, nil, 1
local statusLabel = nil

local function onPopupClaimClicked()
	if not activeKey or not activeData then
		return
	end

	local key, data, amount = activeKey, activeData, activeAmount
	activeKey, activeData, activeAmount = nil, nil, 1

	local screenGui, popupRoot, medium, container, popupCard = getPopupGui()
	local invButton = getInventoryButton()

	if popupCard and invButton and ItemModule and type(ItemModule.AnimateItemIconIntoInventory) == "function" then
		local sourceObj = popupCard:FindFirstChild("Container")
			and popupCard.Container:FindFirstChild("Icon")
			or popupCard

		pcall(function()
			ItemModule.AnimateItemIconIntoInventory(sourceObj, invButton, playerGui)
		end)
	end

	local placedCard = spawnAndPlaceInventoryCard(key, data, amount)

	if ItemPopupService and ItemPopupService.ItemClaimsComplete then
		pcall(function()
			ItemPopupService.ItemClaimsComplete:Fire(data)
		end)
	end

	setPopupVisible(screenGui, popupRoot, medium, container, popupCard, false)

	if statusLabel then
		statusLabel.Text = placedCard
			and ("Добавлено: " .. tostring(data.ItemName or data.Name or key))
			or "Контейнер инвентаря не найден"
	end
end

local hookedButtons = setmetatable({}, { __mode = "k" })

local function hookClaimButton(btn)
	if not btn or hookedButtons[btn] or not btn:IsA("GuiButton") then
		return
	end
	hookedButtons[btn] = true
	btn.MouseButton1Click:Connect(onPopupClaimClicked)
end

local function bindPopupClaimListeners()
	local _, popupRoot, _, _, card = getPopupGui()
	if not popupRoot and not card then
		return
	end

	local existingClaim = findPopupClaimButton(popupRoot, card)
	if existingClaim then
		hookClaimButton(existingClaim)
	end

	local watchRoot = popupRoot or card
	if watchRoot then
		watchRoot.DescendantAdded:Connect(function(desc)
			if (desc:IsA("TextButton") or desc:IsA("ImageButton")) and string.lower(desc.Name) == "claim" then
				hookClaimButton(desc)
			end
		end)
	end
end

bindPopupClaimListeners()
playerGui.DescendantAdded:Connect(function(desc)
	if desc.Name == "NewItem" then
		task.defer(bindPopupClaimListeners)
	end
end)

local oldGui = playerGui:FindFirstChild("TreeKnifeSpawnerGui")
if oldGui then
	oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "TreeKnifeSpawnerGui"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(250, 120)
frame.Position = UDim2.new(0.5, -125, 0.78, 0)
frame.BackgroundColor3 = Color3.fromRGB(36, 16, 62)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
local frameStroke = Instance.new("UIStroke", frame)
frameStroke.Color = Color3.fromRGB(165, 70, 255)
frameStroke.Thickness = 1.5

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -20, 0, 32)
box.Position = UDim2.fromOffset(10, 10)
box.PlaceholderText = "Введите: TreeKnife2023 или Evergreen"
box.Text = "TreeKnife2023"
box.ClearTextOnFocus = false
box.TextScaled = true
box.BackgroundColor3 = Color3.fromRGB(62, 28, 105)
box.TextColor3 = Color3.fromRGB(245, 235, 255)
box.Parent = frame
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

local spawnBtn = Instance.new("TextButton")
spawnBtn.Size = UDim2.new(1, -20, 0, 34)
spawnBtn.Position = UDim2.fromOffset(10, 50)
spawnBtn.Text = "Spawn"
spawnBtn.TextScaled = true
spawnBtn.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
spawnBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
spawnBtn.Parent = frame
Instance.new("UICorner", spawnBtn).CornerRadius = UDim.new(0, 6)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 20)
status.Position = UDim2.fromOffset(10, 90)
status.BackgroundTransparency = 1
status.TextScaled = true
status.TextColor3 = Color3.fromRGB(220, 195, 255)
status.Text = (DatabaseSync and DatabaseSync.Item) and "Готово" or "Нет Database.Sync.Item"
status.Parent = frame
statusLabel = status

spawnBtn.MouseButton1Click:Connect(function()
	bindPopupClaimListeners()

	if not DatabaseSync or not DatabaseSync.Item then
		status.Text = "Database.Sync.Item не загружен"
		return
	end

	local key, data = findItemInDatabaseItem(box.Text)
	if not key or not data then
		activeKey, activeData = nil, nil
		status.Text = "Не найдено в Database.Sync.Item"
		return
	end

	activeKey, activeData, activeAmount = key, data, 1
	local opened = showPopupWindow(key, data, activeAmount)
	if not opened then
		status.Text = "Окно NewItem не найдено"
		return
	end

	status.Text = "Нажмите Claim в окне NewItem"
end)
