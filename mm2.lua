local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ClientServices = ReplicatedStorage:WaitForChild("ClientServices")
local ItemService = require(ClientServices:WaitForChild("ItemService"))
local ItemPopupService = require(ClientServices:WaitForChild("ItemPopupService"))
local ItemModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ItemModule"))
local DatabaseSync = require(ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync"))

_G.Cache = _G.Cache or {}
_G.SmallCache = _G.SmallCache or {}

local function findItemInDatabaseItem(inputText: string)
	local itemDb = DatabaseSync.Item
	if type(itemDb) ~= "table" then
		return nil, nil
	end

	local clean = string.lower((inputText:gsub("^%s+", ""):gsub("%s+$", "")))
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

local function getRarityColor(rarityName: string?)
	local raritiesTable = DatabaseSync.Rarities or DatabaseSync.Rarity
	local colorData = raritiesTable and (raritiesTable[rarityName or "Common"] or raritiesTable["Common"])

	if typeof(colorData) == "Color3" then
		return colorData
	elseif type(colorData) == "table" then
		if colorData.Color then
			local c = colorData.Color
			if typeof(c) == "Color3" then
				return c
			elseif type(c) == "table" and c.r and c.g and c.b then
				return Color3.fromRGB(c.r, c.g, c.b)
			end
		elseif colorData.r and colorData.g and colorData.b then
			return Color3.fromRGB(colorData.r, colorData.g, colorData.b)
		end
	end

	return Color3.fromRGB(255, 255, 255)
end

local function applyRarityToStarburst(newItemRoot: Instance?, rarityName: string?)
	if not newItemRoot then
		return
	end

	local starburst = newItemRoot:FindFirstChild("Starburst", true)
	local color = getRarityColor(rarityName)

	if starburst and (starburst:IsA("ImageLabel") or starburst:IsA("ImageButton")) then
		starburst.ImageColor3 = color
	end
end

local function getPopupNewItemGui()
	local mainGui = playerGui:FindFirstChild("MainGUI")
	local invNewItem = mainGui
		and mainGui:FindFirstChild("Inventory")
		and mainGui.Inventory:FindFirstChild("NewItem")

	local crossPlatformNewItem = playerGui:FindFirstChild("CrossPlatform")
		and playerGui.CrossPlatform:FindFirstChild("NewItem")

	local root = invNewItem or crossPlatformNewItem
	if not root then
		return nil, nil
	end

	local medium = root:FindFirstChild("Medium")
	local container = (medium and medium:FindFirstChild("Container")) or root:FindFirstChild("Container")
	local card = container and container:FindFirstChild("NewItem")

	return root, card
end

local function findPopupClaimButton(newItemRoot: Instance?)
	if not newItemRoot then
		return nil
	end

	for _, desc in ipairs(newItemRoot:GetDescendants()) do
		if (desc:IsA("TextButton") or desc:IsA("ImageButton")) and string.lower(desc.Name) == "claim" then
			return desc
		end
	end

	return nil
end

local function hidePopupNewItemGui(newItemRoot: Instance?)
	if not newItemRoot then
		return
	end

	if newItemRoot:IsA("GuiObject") then
		newItemRoot.Visible = false
	elseif newItemRoot:IsA("LayerCollector") then
		newItemRoot.Enabled = false
	end
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
		and mainGui:FindFirstChild("Dock")
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

local function addCardToInventory(itemKey: string, itemData: table, amount: number?)
	local targetContainer = getInventoryTargetContainer()
	if not targetContainer or not ItemService or not ItemService.BaseItemFrame then
		return nil
	end

	local card = ItemService.BaseItemFrame:Clone()
	card.Name = itemKey
	local count = amount or 1

	if ItemService.ApplyItemToFrame then
		pcall(function()
			ItemService:ApplyItemToFrame(card, itemData, count)
		end)
	end

	if ItemService.ApplyTags then
		pcall(function()
			ItemService:ApplyTags(card, itemData)
		end)
	end

	if ItemService.GetLayoutOrder then
		local ok, order = pcall(function()
			return ItemService:GetLayoutOrder(itemKey, "Item")
		end)
		if ok and type(order) == "number" then
			card.LayoutOrder = order
		end
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

	local newItemRoot, popupCard = getPopupNewItemGui()
	local invButton = getInventoryButton()

	if popupCard and invButton and ItemModule and ItemModule.AnimateItemIconIntoInventory then
		local sourceObj = popupCard:FindFirstChild("Container")
			and popupCard.Container:FindFirstChild("Icon")
			or popupCard

		pcall(function()
			ItemModule.AnimateItemIconIntoInventory(sourceObj, invButton, playerGui)
		end)
	end

	local createdCard = addCardToInventory(key, data, amount)

	if ItemPopupService and ItemPopupService.ItemClaimsComplete then
		pcall(function()
			ItemPopupService.ItemClaimsComplete:Fire(data)
		end)
	end

	hidePopupNewItemGui(newItemRoot)

	if statusLabel then
		statusLabel.Text = createdCard
			and ("Добавлено: " .. tostring(data.ItemName or key))
			or "Контейнер инвентаря не найден"
	end
end

local hookedButtons = setmetatable({}, { __mode = "k" })

local function hookClaimButton(btn: Instance?)
	if not btn or hookedButtons[btn] then
		return
	end
	if not (btn:IsA("GuiButton")) then
		return
	end

	hookedButtons[btn] = true
	btn.MouseButton1Click:Connect(onPopupClaimClicked)
end

local function bindPopupClaimListeners()
	local newItemRoot = getPopupNewItemGui()
	if not newItemRoot then
		return
	end

	local existingClaim = findPopupClaimButton(newItemRoot)
	if existingClaim then
		hookClaimButton(existingClaim)
	end

	newItemRoot.DescendantAdded:Connect(function(desc)
		if (desc:IsA("TextButton") or desc:IsA("ImageButton")) and string.lower(desc.Name) == "claim" then
			hookClaimButton(desc)
		end
	end)
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
frame.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -20, 0, 32)
box.Position = UDim2.fromOffset(10, 10)
box.PlaceholderText = "Введите: TreeKnife2023 или Evergreen"
box.Text = "TreeKnife2023"
box.ClearTextOnFocus = false
box.TextScaled = true
box.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
box.TextColor3 = Color3.fromRGB(255, 255, 255)
box.Parent = frame
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

local spawnBtn = Instance.new("TextButton")
spawnBtn.Size = UDim2.new(1, -20, 0, 34)
spawnBtn.Position = UDim2.fromOffset(10, 50)
spawnBtn.Text = "Spawn"
spawnBtn.TextScaled = true
spawnBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
spawnBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
spawnBtn.Parent = frame
Instance.new("UICorner", spawnBtn).CornerRadius = UDim.new(0, 6)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 20)
status.Position = UDim2.fromOffset(10, 90)
status.BackgroundTransparency = 1
status.TextScaled = true
status.TextColor3 = Color3.fromRGB(200, 200, 210)
status.Text = "Введите название и нажмите Spawn"
status.Parent = frame
statusLabel = status

spawnBtn.MouseButton1Click:Connect(function()
	bindPopupClaimListeners()

	local key, data = findItemInDatabaseItem(box.Text)
	if not key or not data then
		activeKey, activeData = nil, nil
		status.Text = "Не найдено в Database.Sync.Item"
		return
	end

	activeKey, activeData, activeAmount = key, data, 1
	local newItemRoot, card = getPopupNewItemGui()

	if newItemRoot then
		if newItemRoot:IsA("GuiObject") then
			newItemRoot.Visible = true
		elseif newItemRoot:IsA("LayerCollector") then
			newItemRoot.Enabled = true
		end
		applyRarityToStarburst(newItemRoot, data.Rarity)
	end

	if card and ItemModule and ItemModule.DisplayItem then
		pcall(function()
			ItemModule.DisplayItem(card, data, 1, false)
		end)
	end

	status.Text = "Нажмите Claim в окне NewItem"
end)
