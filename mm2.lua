local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local syncFolder = ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync")
local itemDB = require(syncFolder:WaitForChild("Item"))

local rarityModule = syncFolder:FindFirstChild("Rarity")
local nativeRarityDB = nil
if rarityModule and rarityModule:IsA("ModuleScript") then
	local ok, mod = pcall(require, rarityModule)
	if ok and typeof(mod) == "table" then
		nativeRarityDB = mod
	end
end

local oldGui = playerGui:FindFirstChild("GodlySpawnerOriginalOnlyUI")
if oldGui then
	oldGui:Destroy()
end

local function getMM2RarityColor(rarityName)
	if typeof(rarityName) ~= "string" or not nativeRarityDB then
		return nil
	end
	local entry = nativeRarityDB[rarityName]
	if typeof(entry) == "Color3" then
		return entry
	elseif typeof(entry) == "table" then
		if typeof(entry.Color) == "Color3" then
			return entry.Color
		end
		for _, v in pairs(entry) do
			if typeof(v) == "Color3" then
				return v
			end
		end
	end
	return nil
end

local function resolveItemKey(inputText)
	if typeof(inputText) ~= "string" then
		return nil, nil
	end
	local trimmed = inputText:match("^%s*(.-)%s*$")
	if trimmed == "" then
		return nil, nil
	end
	if itemDB[trimmed] then
		return trimmed, itemDB[trimmed]
	end
	local lowerInput = string.lower(trimmed)
	for key, data in pairs(itemDB) do
		if typeof(data) == "table" then
			if string.lower(key) == lowerInput
				or (typeof(data.ItemName) == "string" and string.lower(data.ItemName) == lowerInput)
			then
				return key, data
			end
		end
	end
	return nil, nil
end

-- Строгий поиск контейнера нужного раздела (например, Christmas) без попадания в Halloween
local function getStrictEventContainer(rootGui, requiredEvent)
	if typeof(requiredEvent) ~= "string" or requiredEvent == "" then
		return nil
	end

	local targetLower = string.lower(requiredEvent)
	local oppositeLower = nil
	if targetLower == "christmas" then
		oppositeLower = "halloween"
	elseif targetLower == "halloween" then
		oppositeLower = "christmas"
	end

	for _, desc in ipairs(rootGui:GetDescendants()) do
		if desc:IsA("ScrollingFrame") or desc:IsA("Frame") then
			local nameLower = string.lower(desc.Name)
			local hasLayout = desc:FindFirstChildOfClass("UIGridLayout") ~= nil
				or desc:FindFirstChildOfClass("UIListLayout") ~= nil
			if hasLayout and nameLower == targetLower then
				return desc
			end
		end
	end

	for _, desc in ipairs(rootGui:GetDescendants()) do
		if desc:IsA("ScrollingFrame") or desc:IsA("Frame") then
			local nameLower = string.lower(desc.Name)
			local hasLayout = desc:FindFirstChildOfClass("UIGridLayout") ~= nil
				or desc:FindFirstChildOfClass("UIListLayout") ~= nil
			local matchesTarget = string.find(nameLower, targetLower, 1, true) ~= nil
			local hasOpposite = oppositeLower ~= nil
				and string.find(nameLower, oppositeLower, 1, true) ~= nil
			if hasLayout and matchesTarget and not hasOpposite then
				return desc
			end
		end
	end

	return nil
end

-- Берёт ТОЛЬКО оригинальный TextLabel количества (Amount) внутри карточки предмета
local function findOriginalAmountLabel(card)
	if not card then
		return nil
	end

	local container = card:FindFirstChild("Container")
	if container then
		local amountObj = container:FindFirstChild("Amount")
		if amountObj and amountObj:IsA("TextLabel") then
			return amountObj
		end
	end

	for _, desc in ipairs(card:GetDescendants()) do
		if desc:IsA("TextLabel") and string.lower(desc.Name) == "amount" then
			local lowerPath = string.lower(desc:GetFullName())
			local isPrice = string.find(lowerPath, "price", 1, true) ~= nil
			local isCurrency = string.find(lowerPath, "coins", 1, true) ~= nil
				or string.find(lowerPath, "gems", 1, true) ~= nil
				or string.find(lowerPath, "tokens", 1, true) ~= nil
			if not isPrice and not isCurrency then
				return desc
			end
		end
	end

	return nil
end

-- Читает количество напрямую из оригинального Amount карточки
local function getOriginalCardAmount(card)
	local amountLabel = findOriginalAmountLabel(card)
	if amountLabel and amountLabel.Visible then
		local num = tonumber(string.match(tostring(amountLabel.Text), "%d+"))
		if num and num >= 2 then
			return math.floor(num)
		end
	end

	if card and card.Visible then
		return 1
	end

	return 0
end

-- Записывает только в оригинальный Amount карточки; x1 никогда не отображается (минимум x2)
local function setOriginalCardAmount(card, amount)
	local finalAmount = math.max(1, math.floor(amount))
	local amountLabel = findOriginalAmountLabel(card)
	if not amountLabel then
		return
	end

	if finalAmount >= 2 then
		amountLabel.Text = "x" .. tostring(finalAmount)
		amountLabel.Visible = true
	else
		amountLabel.Text = ""
		amountLabel.Visible = false
	end
end

local function findTemplateCard(container)
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("GuiObject")
			and not child:IsA("UIGridLayout")
			and not child:IsA("UIListLayout")
			and not child:IsA("UIPadding")
		then
			return child
		end
	end
	return nil
end

local function countVisibleCards(container)
	local count = 0
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("GuiObject")
			and not child:IsA("UIGridLayout")
			and not child:IsA("UIListLayout")
			and not child:IsA("UIPadding")
			and child.Visible
		then
			count += 1
		end
	end
	return count
end

local function refreshScrollingCanvas(container)
	if not container:IsA("ScrollingFrame") then
		return
	end
	local layout = container:FindFirstChildOfClass("UIGridLayout") or container:FindFirstChildOfClass("UIListLayout")
	if layout then
		container.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 24)
	end
end

local function applyNativeVisuals(card, itemKey, itemData)
	card.Name = itemKey
	card.Visible = true

	local rarityName = itemData.Rarity
	local rarityColor = getMM2RarityColor(rarityName)
	local amountLabel = findOriginalAmountLabel(card)

	if amountLabel then
		amountLabel.Text = ""
		amountLabel.Visible = false
	end

	local tagsFolder = card:FindFirstChild("Tags")
	if tagsFolder then
		for _, tagObj in ipairs(tagsFolder:GetChildren()) do
			if tagObj:IsA("GuiObject") then
				tagObj.Visible = (typeof(itemData.Event) == "string"
					and string.lower(tagObj.Name) == string.lower(itemData.Event))
			end
		end
	end

	for _, obj in ipairs(card:GetDescendants()) do
		if obj == amountLabel then
			continue
		end

		if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
			local n = string.lower(obj.Name)
			local isRarityPart = string.find(n, "rarity", 1, true) ~= nil
				or string.find(n, "glow", 1, true) ~= nil
				or string.find(n, "frame", 1, true) ~= nil
				or string.find(n, "border", 1, true) ~= nil
				or string.find(n, "bg", 1, true) ~= nil
				or string.find(n, "back", 1, true) ~= nil

			if isRarityPart then
				if rarityColor then
					obj.ImageColor3 = rarityColor
				end
			elseif itemData.Image and itemData.Image ~= "" then
				obj.Image = itemData.Image
			end

		elseif obj:IsA("TextLabel") then
			local n = string.lower(obj.Name)
			if string.find(n, "rarity", 1, true) then
				if rarityName then
					obj.Text = rarityName
				end
				if rarityColor then
					obj.TextColor3 = rarityColor
				end
			else
				obj.Text = itemData.ItemName or itemKey
			end

		elseif obj:IsA("Frame") and rarityColor then
			local n = string.lower(obj.Name)
			if string.find(n, "rarity", 1, true)
				or string.find(n, "bar", 1, true)
				or string.find(n, "line", 1, true)
			then
				obj.BackgroundColor3 = rarityColor
			end
		end
	end
end

local function addQuantityToEventCard(itemKey, itemData, deltaAmount)
	local eventName = itemData.Event
	if typeof(eventName) ~= "string" or eventName == "" then
		return false, "У предмета не указан Event"
	end

	local container = getStrictEventContainer(playerGui, eventName)
	if not container then
		return false, "Не найден контейнер для раздела: " .. tostring(eventName)
	end

	local addNum = math.max(1, math.floor(deltaAmount or 1))
	local existingCard = container:FindFirstChild(itemKey)

	if existingCard and existingCard:IsA("GuiObject") then
		existingCard.Visible = true
		local newTotal = getOriginalCardAmount(existingCard) + addNum
		setOriginalCardAmount(existingCard, newTotal)
		refreshScrollingCanvas(container)
		return true, newTotal
	end

	local template = findTemplateCard(container)
	if not template then
		return false, "Нет шаблона карточки в разделе: " .. tostring(eventName)
	end

	local nextOrder = countVisibleCards(container) + 1
	local newCard = template:Clone()
	if newCard:IsA("GuiObject") then
		newCard.LayoutOrder = nextOrder
		newCard.Position = UDim2.new(0, 0, 0, 0)
	end

	applyNativeVisuals(newCard, itemKey, itemData)
	setOriginalCardAmount(newCard, addNum)
	newCard.Parent = container

	task.defer(function()
		refreshScrollingCanvas(container)
	end)

	return true, addNum
end

local function collectNativeNewItemPopups()
	local popups = {}

	local gameNewItem = playerGui:FindFirstChild("MainGUI")
		and playerGui.MainGUI:FindFirstChild("Game")
		and playerGui.MainGUI.Game:FindFirstChild("NewItem")
	if gameNewItem and gameNewItem:IsA("GuiObject") then
		local container = gameNewItem:FindFirstChild("Container")
		local claimBtn = container and container:FindFirstChild("Claim")
		local cardHolder = container and container:FindFirstChild("NewItem")
		if claimBtn and claimBtn:IsA("GuiButton") then
			table.insert(popups, {
				root = gameNewItem,
				claimBtn = claimBtn,
				cardHolder = cardHolder,
			})
		end
	end

	local crossNewItem = playerGui:FindFirstChild("CrossPlatform")
		and playerGui.CrossPlatform:FindFirstChild("NewItem")
	if crossNewItem and crossNewItem:IsA("GuiObject") then
		local medium = crossNewItem:FindFirstChild("Medium")
		local container = medium and medium:FindFirstChild("Container")
		local claimBtn = container and container:FindFirstChild("Claim")
		local cardHolder = container and container:FindFirstChild("NewItem")
		if claimBtn and claimBtn:IsA("GuiButton") then
			table.insert(popups, {
				root = crossNewItem,
				claimBtn = claimBtn,
				cardHolder = cardHolder,
			})
		end
	end

	return popups
end

-- === ОКНО GODLY SPAWNER ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GodlySpawnerOriginalOnlyUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local mainWindow = Instance.new("Frame")
mainWindow.Size = UDim2.new(0, 310, 0, 225)
mainWindow.Position = UDim2.new(0.5, -155, 0.5, -112)
mainWindow.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
mainWindow.BorderSizePixel = 0
mainWindow.Active = true
mainWindow.Draggable = true
mainWindow.Parent = screenGui

Instance.new("UICorner", mainWindow).CornerRadius = UDim.new(0, 12)
local mainStroke = Instance.new("UIStroke", mainWindow)
mainStroke.Color = Color3.fromRGB(165, 65, 255)
mainStroke.Thickness = 1.6

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 36)
topBar.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
topBar.BorderSizePixel = 0
topBar.Parent = mainWindow
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 12)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -82, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Godly spawner"
titleLabel.TextColor3 = Color3.fromRGB(245, 245, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 15
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 30, 0, 26)
minBtn.Position = UDim2.new(1, -68, 0.5, -13)
minBtn.BackgroundColor3 = Color3.fromRGB(36, 36, 46)
minBtn.Text = "-"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.Parent = topBar
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 26)
closeBtn.Position = UDim2.new(1, -34, 0.5, -13)
closeBtn.BackgroundColor3 = Color3.fromRGB(190, 45, 65)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Parent = topBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -20, 1, -44)
content.Position = UDim2.new(0, 10, 0, 40)
content.BackgroundTransparency = 1
content.Parent = mainWindow

local nameBox = Instance.new("TextBox")
nameBox.Size = UDim2.new(1, 0, 0, 34)
nameBox.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
nameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
nameBox.PlaceholderText = "Имя предмета (например, Gingerscope)"
nameBox.PlaceholderColor3 = Color3.fromRGB(135, 135, 155)
nameBox.Text = ""
nameBox.ClearTextOnFocus = false
nameBox.Font = Enum.Font.Gotham
nameBox.TextSize = 13
nameBox.Parent = content
Instance.new("UICorner", nameBox).CornerRadius = UDim.new(0, 8)

local amountBox = Instance.new("TextBox")
amountBox.Size = UDim2.new(1, 0, 0, 34)
amountBox.Position = UDim2.new(0, 0, 0, 40)
amountBox.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
amountBox.TextColor3 = Color3.fromRGB(255, 255, 255)
amountBox.PlaceholderText = "Количество (например, 8)"
amountBox.PlaceholderColor3 = Color3.fromRGB(135, 135, 155)
amountBox.Text = ""
amountBox.ClearTextOnFocus = false
amountBox.Font = Enum.Font.Gotham
amountBox.TextSize = 13
amountBox.Parent = content
Instance.new("UICorner", amountBox).CornerRadius = UDim.new(0, 8)

local spawnBtn = Instance.new("TextButton")
spawnBtn.Size = UDim2.new(1, 0, 0, 38)
spawnBtn.Position = UDim2.new(0, 0, 0, 82)
spawnBtn.BackgroundColor3 = Color3.fromRGB(130, 45, 235)
spawnBtn.Text = "Spawn"
spawnBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
spawnBtn.Font = Enum.Font.GothamBold
spawnBtn.TextSize = 15
spawnBtn.Parent = content
Instance.new("UICorner", spawnBtn).CornerRadius = UDim.new(0, 8)

local alphaBtn = Instance.new("TextButton")
alphaBtn.Size = UDim2.new(1, 0, 0, 22)
alphaBtn.Position = UDim2.new(0, 0, 0, 126)
alphaBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
alphaBtn.Text = "Прозрачность окна: 0%"
alphaBtn.TextColor3 = Color3.fromRGB(220, 220, 235)
alphaBtn.Font = Enum.Font.GothamMedium
alphaBtn.TextSize = 11
alphaBtn.Parent = content
Instance.new("UICorner", alphaBtn).CornerRadius = UDim.new(0, 6)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 18)
statusLabel.Position = UDim2.new(0, 0, 1, -18)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = Color3.fromRGB(255, 110, 120)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11
statusLabel.Parent = content

local activeConnections = {}
local activePopups = {}

local function clearNativeBindings()
	for _, conn in ipairs(activeConnections) do
		conn:Disconnect()
	end
	table.clear(activeConnections)

	for _, entry in ipairs(activePopups) do
		if entry.root then
			entry.root.Visible = false
		end
	end
	table.clear(activePopups)
end

local function bindNativeNewItemWindows(itemKey, itemData, totalQty)
	clearNativeBindings()

	local popups = collectNativeNewItemPopups()
	if #popups == 0 then
		statusLabel.Text = "Родные окна NewItem не найдены в PlayerGui"
		return false
	end

	local remaining = totalQty
	activePopups = popups

	local function enforcePopupsVisible(visible)
		for _, entry in ipairs(activePopups) do
			if entry.root then
				if visible then
					local p = entry.root.Parent
					while p and p ~= playerGui do
						if p:IsA("GuiObject") then
							p.Visible = true
						end
						p = p.Parent
					end
				end
				entry.root.Visible = visible
			end
		end
	end

	for _, entry in ipairs(activePopups) do
		if entry.cardHolder then
			applyNativeVisuals(entry.cardHolder, itemKey, itemData)
		end

		local conn = entry.claimBtn.MouseButton1Click:Connect(function()
			if remaining <= 0 then
				return
			end

			local ok, errOrTotal = addQuantityToEventCard(itemKey, itemData, 1)
			if not ok then
				statusLabel.Text = tostring(errOrTotal)
				return
			end

			remaining -= 1

			if remaining > 0 then
				task.defer(function()
					if remaining > 0 then
						enforcePopupsVisible(true)
					end
				end)
			else
				clearNativeBindings()
			end
		end)

		table.insert(activeConnections, conn)
	end

	enforcePopupsVisible(true)
	statusLabel.Text = ""
	return true
end

local minimized = false
minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	content.Visible = not minimized
	mainWindow.Size = minimized and UDim2.new(0, 310, 0, 36) or UDim2.new(0, 310, 0, 225)
	minBtn.Text = minimized and "+" or "-"
end)

closeBtn.MouseButton1Click:Connect(function()
	clearNativeBindings()
	screenGui:Destroy()
end)

local alphaPercent = 0
alphaBtn.MouseButton1Click:Connect(function()
	alphaPercent = (alphaPercent + 20) % 80
	mainWindow.BackgroundTransparency = alphaPercent / 100
	alphaBtn.Text = "Прозрачность окна: " .. tostring(alphaPercent) .. "%"
end)

spawnBtn.MouseButton1Click:Connect(function()
	statusLabel.Text = ""

	local itemKey, itemData = resolveItemKey(nameBox.Text)
	if not itemKey or not itemData then
		statusLabel.Text = "Предмет не найден в базе Item"
		return
	end

	local qty = tonumber(amountBox.Text)
	if not qty or qty < 1 then
		statusLabel.Text = "Введи количество от 1 и выше"
		return
	end

	if not itemData.Event or itemData.Event == "" then
		statusLabel.Text = "У предмета не указан Event"
		return
	end

	bindNativeNewItemWindows(itemKey, itemData, math.floor(qty))
end)
