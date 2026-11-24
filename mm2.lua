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

-- Обычная версия TreeKnife2023 (Evergreen)
local Items = {
	["TreeKnife2023"] = {
		ItemName = "Evergreen",
		Image = "rbxassetid://15694357137",
		ItemType = "Knife",
		Rarity = "Godly",
		ItemID = 15667157715,
		Event = "Christmas",
		Year = "2023",
		FX = true,
		Amount = 1,
	},
}

local function findTreeKnife2023(inputText: string)
	local clean = string.lower((inputText:gsub("^%s+", ""):gsub("%s+$", "")))
	if clean == "treeknife2023" or clean == "evergreen" then
		local item = table.clone(Items.TreeKnife2023)
		item.Key = "TreeKnife2023"
		item.Category = "Weapons"
		return item
	end
	return nil
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
	local card = root
		and root:FindFirstChild("Container")
		and root.Container:FindFirstChild("NewItem")

	return root, card
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

local function addCardToInventory(itemData)
	local targetContainer = getInventoryTargetContainer()
	if not targetContainer or not ItemService or not ItemService.BaseItemFrame then
		return nil
	end

	local card = ItemService.BaseItemFrame:Clone()
	card.Name = itemData.Key or itemData.ItemName or "TreeKnife2023"

	local amount = itemData.Amount or 1
	local category = itemData.Category or "Weapons"

	if ItemService.ApplyItemToFrame then
		pcall(function()
			ItemService:ApplyItemToFrame(card, itemData, amount)
		end)
	end

	if ItemService.ApplyTags then
		pcall(function()
			ItemService:ApplyTags(card, itemData)
		end)
	end

	if ItemService.GetLayoutOrder then
		local ok, order = pcall(function()
			return ItemService:GetLayoutOrder(card.Name, category)
		end)
		if ok and type(order) == "number" then
			card.LayoutOrder = order
		end
	end

	card.Visible = true
	card.Parent = targetContainer
	return card
end

local function claimItemToInventory(itemData)
	local _, popupCard = getPopupNewItemGui()
	local invButton = getInventoryButton()

	if popupCard and invButton and ItemModule and ItemModule.AnimateItemIconIntoInventory then
		local sourceObj = popupCard:FindFirstChild("Container")
			and popupCard.Container:FindFirstChild("Icon")
			or popupCard

		pcall(function()
			ItemModule.AnimateItemIconIntoInventory(sourceObj, invButton, playerGui)
		end)
	end

	local createdCard = addCardToInventory(itemData)

	if ItemPopupService and ItemPopupService.ItemClaimsComplete then
		pcall(function()
			ItemPopupService.ItemClaimsComplete:Fire(itemData)
		end)
	end

	return createdCard ~= nil
end

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
box.PlaceholderText = "Введите: TreeKnife2023"
box.Text = "TreeKnife2023"
box.ClearTextOnFocus = false
box.TextScaled = true
box.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
box.TextColor3 = Color3.fromRGB(255, 255, 255)
box.Parent = frame
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

local spawnBtn = Instance.new("TextButton")
spawnBtn.Size = UDim2.new(0.5, -14, 0, 34)
spawnBtn.Position = UDim2.fromOffset(10, 50)
spawnBtn.Text = "Spawn"
spawnBtn.TextScaled = true
spawnBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
spawnBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
spawnBtn.Parent = frame
Instance.new("UICorner", spawnBtn).CornerRadius = UDim.new(0, 6)

local claimBtn = Instance.new("TextButton")
claimBtn.Size = UDim2.new(0.5, -14, 0, 34)
claimBtn.Position = UDim2.new(0.5, 4, 0, 50)
claimBtn.Text = "Claim"
claimBtn.TextScaled = true
claimBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 90)
claimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
claimBtn.Parent = frame
Instance.new("UICorner", claimBtn).CornerRadius = UDim.new(0, 6)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 20)
status.Position = UDim2.fromOffset(10, 90)
status.BackgroundTransparency = 1
status.TextScaled = true
status.TextColor3 = Color3.fromRGB(200, 200, 210)
status.Text = "Введите TreeKnife2023"
status.Parent = frame

local activeItem = nil

spawnBtn.MouseButton1Click:Connect(function()
	local item = findTreeKnife2023(box.Text)
	if not item then
		status.Text = "Нужен TreeKnife2023"
		return
	end

	activeItem = item
	local newItemRoot, card = getPopupNewItemGui()

	if newItemRoot then
		if newItemRoot:IsA("GuiObject") then
			newItemRoot.Visible = true
		elseif newItemRoot:IsA("LayerCollector") then
			newItemRoot.Enabled = true
		end
		applyRarityToStarburst(newItemRoot, item.Rarity)
	end

	if card and ItemModule and ItemModule.DisplayItem then
		pcall(function()
			ItemModule.DisplayItem(card, item, item.Amount, false)
		end)
	end

	if ItemPopupService and ItemPopupService.AddNewItem then
		pcall(function()
			ItemPopupService:AddNewItem(item, item.Amount)
		end)
	end

	status.Text = "Показано: TreeKnife2023"
end)

claimBtn.MouseButton1Click:Connect(function()
	local item = activeItem or findTreeKnife2023(box.Text)
	if not item then
		status.Text = "Сначала нажмите Spawn"
		return
	end

	local added = claimItemToInventory(item)

	local newItemRoot = getPopupNewItemGui()
	if newItemRoot then
		if newItemRoot:IsA("GuiObject") then
			newItemRoot.Visible = false
		elseif newItemRoot:IsA("LayerCollector") then
			newItemRoot.Enabled = false
		end
	end

	activeItem = nil
	status.Text = added and "Карточка Evergreen добавлена" or "Контейнер инвентаря не найден"
end)
