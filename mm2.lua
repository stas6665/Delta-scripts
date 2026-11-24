local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local SyncFolder = ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync")
local ItemDB = require(SyncFolder:WaitForChild("Item"))
local RarityDB = nil
pcall(function()
	RarityDB = require(SyncFolder:WaitForChild("Rarities"))
end)

local function cleanName(str)
	if type(str) ~= "string" then return "" end
	local s = string.lower(str)
	s = s:gsub("\\", "")
	s = s:gsub("['’`]", "")
	s = s:gsub("[^%w]+", " ")
	return (s:match("^%s*(.-)%s*$") or "")
end

local ItemLookup = {}
local NonChromaKeys = {}

for key, data in pairs(ItemDB) do
	if type(data) == "table" and not data.Chroma then
		table.insert(NonChromaKeys, key)

		local kClean = cleanName(key)
		if kClean ~= "" and not ItemLookup[kClean] then
			ItemLookup[kClean] = key
		end

		if data.ItemName then
			local nClean = cleanName(data.ItemName)
			if nClean ~= "" and not ItemLookup[nClean] then
				ItemLookup[nClean] = key
			end
		end
	end
end

local function resolveWeapon(inputText)
	local q = cleanName(inputText)
	if q == "" or q == "random" then
		return NonChromaKeys[math.random(1, #NonChromaKeys)]
	end

	if ItemLookup[q] then
		return ItemLookup[q]
	end

	for norm, key in pairs(ItemLookup) do
		if string.find(norm, q, 1, true) then
			return key
		end
	end

	return nil
end

local function getRarityColor(rarityName)
	if RarityDB and rarityName and RarityDB[rarityName] then
		local entry = RarityDB[rarityName]
		if typeof(entry) == "Color3" then
			return entry
		elseif type(entry) == "table" and typeof(entry.Color) == "Color3" then
			return entry.Color
		end
	end

	local r = string.lower(tostring(rarityName or ""))
	if r == "ancient" then
		return Color3.fromRGB(165, 55, 255)
	elseif r == "godly" then
		return Color3.fromRGB(255, 65, 165)
	elseif r == "unique" then
		return Color3.fromRGB(255, 55, 55)
	elseif r == "legendary" then
		return Color3.fromRGB(255, 145, 30)
	elseif r == "rare" then
		return Color3.fromRGB(65, 175, 255)
	elseif r == "uncommon" then
		return Color3.fromRGB(75, 225, 105)
	end
	return Color3.fromRGB(200, 200, 210)
end

-- Поиск шаблона CrossPlatform.NewItem.Medium.Container.NewItem
local function getTargetFrame()
	local cross = PlayerGui:FindFirstChild("CrossPlatform")
	if not cross then return nil, nil end
	local section = cross:FindFirstChild("NewItem")
	if not section then return nil, nil end
	local medium = section:FindFirstChild("Medium")
	local container = medium and medium:FindFirstChild("Container")
	local target = container and container:FindFirstChild("NewItem")
	return target, section
end

local TargetFrame, NewItemSection = getTargetFrame()

-- Заполняем пустой шаблон NewItem через внутренний слой SpawnerCardOverlay
local CardHolder = TargetFrame and TargetFrame:FindFirstChild("SpawnerCardOverlay")
if TargetFrame and TargetFrame:IsA("GuiObject") and not CardHolder then
	CardHolder = Instance.new("Frame")
	CardHolder.Name = "SpawnerCardOverlay"
	CardHolder.Size = UDim2.fromScale(1, 1)
	CardHolder.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	CardHolder.BackgroundTransparency = 0.1
	CardHolder.BorderSizePixel = 0
	CardHolder.Parent = TargetFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = CardHolder

	local stroke = Instance.new("UIStroke")
	stroke.Name = "RarityStroke"
	stroke.Thickness = 2.5
	stroke.Color = Color3.fromRGB(255, 200, 0)
	stroke.Parent = CardHolder

	local rarityLbl = Instance.new("TextLabel")
	rarityLbl.Name = "RarityLabel"
	rarityLbl.Size = UDim2.new(1, -16, 0, 22)
	rarityLbl.Position = UDim2.new(0, 8, 0, 8)
	rarityLbl.BackgroundTransparency = 1
	rarityLbl.Font = Enum.Font.GothamBold
	rarityLbl.TextSize = 14
	rarityLbl.Text = ""
	rarityLbl.Parent = CardHolder

	local imgLbl = Instance.new("ImageLabel")
	imgLbl.Name = "ItemIcon"
	imgLbl.Size = UDim2.new(0, 120, 0, 120)
	imgLbl.Position = UDim2.new(0.5, -60, 0.5, -68)
	imgLbl.BackgroundTransparency = 1
	imgLbl.ScaleType = Enum.ScaleType.Fit
	imgLbl.Image = ""
	imgLbl.Parent = CardHolder

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Name = "ItemNameLabel"
	nameLbl.Size = UDim2.new(1, -16, 0, 24)
	nameLbl.Position = UDim2.new(0, 8, 1, -72)
	nameLbl.BackgroundTransparency = 1
	nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextSize = 15
	nameLbl.Text = ""
	nameLbl.Parent = CardHolder

	local claimBtn = Instance.new("TextButton")
	claimBtn.Name = "ClaimButton"
	claimBtn.Size = UDim2.new(1, -24, 0, 34)
	claimBtn.Position = UDim2.new(0, 12, 1, -42)
	claimBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
	claimBtn.TextColor3 = Color3.fromRGB(15, 15, 15)
	claimBtn.Font = Enum.Font.GothamBold
	claimBtn.TextSize = 14
	claimBtn.Text = "Claim"
	claimBtn.Parent = CardHolder

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = claimBtn
end

local ClaimBtn = CardHolder and CardHolder:FindFirstChild("ClaimButton")
local IconLabel = CardHolder and CardHolder:FindFirstChild("ItemIcon")
local NameLabel = CardHolder and CardHolder:FindFirstChild("ItemNameLabel")
local RarityLabel = CardHolder and CardHolder:FindFirstChild("RarityLabel")
local RarityStroke = CardHolder and CardHolder:FindFirstChild("RarityStroke")

local Queue = {}
local TotalInBatch = 0
local CurrentIndex = 0
local IsShowing = false

local function setBlur(enabled)
	local blur = Lighting:FindFirstChild("NewItemBlur")
	if blur and blur:IsA("BlurEffect") then
		blur.Enabled = enabled
	end
end

local function setPopupVisible(visible)
	if NewItemSection and NewItemSection:IsA("GuiObject") then
		NewItemSection.Visible = visible
	end
	local medium = NewItemSection and NewItemSection:FindFirstChild("Medium")
	if medium and medium:IsA("GuiObject") then
		medium.Visible = visible
	end
	local container = medium and medium:FindFirstChild("Container")
	if container and container:IsA("GuiObject") then
		container.Visible = visible
	end
	if TargetFrame and TargetFrame:IsA("GuiObject") then
		TargetFrame.Visible = visible
	end
	if CardHolder and CardHolder:IsA("GuiObject") then
		CardHolder.Visible = visible
	end
end

local function renderSingleItem(itemKey, indexNum, totalNum)
	local info = ItemDB[itemKey] or {}
	local displayName = info.ItemName or itemKey
	local rarity = info.Rarity or "Common"
	local imageId = info.Image or ""
	local rColor = getRarityColor(rarity)

	if IconLabel and IconLabel:IsA("ImageLabel") then
		IconLabel.Image = imageId
	end

	if NameLabel and NameLabel:IsA("TextLabel") then
		NameLabel.Text = displayName
	end

	if RarityLabel and RarityLabel:IsA("TextLabel") then
		RarityLabel.Text = rarity
		RarityLabel.TextColor3 = rColor
	end

	if RarityStroke and RarityStroke:IsA("UIStroke") then
		RarityStroke.Color = rColor
	end

	if ClaimBtn and ClaimBtn:IsA("TextButton") then
		if totalNum > 1 then
			ClaimBtn.Text = string.format("Claim (%d/%d)", indexNum, totalNum)
		else
			ClaimBtn.Text = "Claim"
		end
	end

	setPopupVisible(true)
	setBlur(true)

	if TargetFrame and TargetFrame:IsA("GuiObject") then
		TargetFrame.Size = UDim2.fromScale(0.75, 0.75)
		TweenService:Create(TargetFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(1, 1)
		}):Play()
	end
end

local function stepQueue()
	if #Queue == 0 then
		IsShowing = false
		TotalInBatch = 0
		CurrentIndex = 0
		setPopupVisible(false)
		setBlur(false)
		return
	end

	IsShowing = true
	CurrentIndex += 1
	local nextKey = table.remove(Queue, 1)
	renderSingleItem(nextKey, CurrentIndex, TotalInBatch)
end

local function enqueueItems(itemKey, amount)
	local wasEmpty = (#Queue == 0 and not IsShowing)
	if wasEmpty then
		TotalInBatch = amount
		CurrentIndex = 0
	else
		TotalInBatch += amount
	end

	for _ = 1, amount do
		table.insert(Queue, itemKey)
	end

	if wasEmpty then
		stepQueue()
	elseif ClaimBtn and ClaimBtn:IsA("TextButton") and TotalInBatch > 1 then
		ClaimBtn.Text = string.format("Claim (%d/%d)", CurrentIndex, TotalInBatch)
	end
end

if ClaimBtn and ClaimBtn:IsA("TextButton") then
	ClaimBtn.MouseButton1Click:Connect(function()
		if IsShowing then
			stepQueue()
		end
	end)
end

_G.NewItem = function(itemKey, _, _, _, count)
	local key = itemKey
	if type(key) == "string" then
		key = resolveWeapon(key) or itemKey
	end
	local qty = tonumber(count) or 1
	if qty < 1 then qty = 1 end
	enqueueItems(key, qty)
end

-- GUI управления: название оружия, ниже количество, кнопка Spawn
local oldGui = PlayerGui:FindFirstChild("Full_NewItem_Spawner")
if oldGui then
	oldGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Full_NewItem_Spawner"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 250, 0, 162)
Frame.Position = UDim2.new(0.5, -125, 0.25, 0)
Frame.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
Frame.BackgroundTransparency = 0.06
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 10)
FrameCorner.Parent = Frame

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(255, 200, 0)
Stroke.Thickness = 1.5
Stroke.Parent = Frame

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 30)
TopBar.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
TopBar.BorderSizePixel = 0
TopBar.Parent = Frame

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 10)
TopCorner.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -38, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "NewItem Spawner"
Title.TextColor3 = Color3.fromRGB(255, 215, 60)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 24, 0, 22)
MinBtn.Position = UDim2.new(1, -28, 0, 4)
MinBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 15
MinBtn.Parent = TopBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinBtn

local Body = Instance.new("Frame")
Body.Size = UDim2.new(1, -16, 1, -38)
Body.Position = UDim2.new(0, 8, 0, 34)
Body.BackgroundTransparency = 1
Body.Parent = Frame

local WeaponBox = Instance.new("TextBox")
WeaponBox.Size = UDim2.new(1, 0, 0, 34)
WeaponBox.Position = UDim2.new(0, 0, 0, 0)
WeaponBox.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
WeaponBox.PlaceholderText = "Название оружия"
WeaponBox.Text = ""
WeaponBox.TextColor3 = Color3.fromRGB(255, 255, 255)
WeaponBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 140)
WeaponBox.Font = Enum.Font.Gotham
WeaponBox.TextSize = 13
WeaponBox.ClearTextOnFocus = false
WeaponBox.Parent = Body

local WeaponCorner = Instance.new("UICorner")
WeaponCorner.CornerRadius = UDim.new(0, 7)
WeaponCorner.Parent = WeaponBox

local CountBox = Instance.new("TextBox")
CountBox.Size = UDim2.new(1, 0, 0, 34)
CountBox.Position = UDim2.new(0, 0, 0, 40)
CountBox.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
CountBox.PlaceholderText = "Количество (1 или больше)"
CountBox.Text = "1"
CountBox.TextColor3 = Color3.fromRGB(255, 215, 60)
CountBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 140)
CountBox.Font = Enum.Font.GothamBold
CountBox.TextSize = 13
CountBox.ClearTextOnFocus = false
CountBox.Parent = Body

local CountCorner = Instance.new("UICorner")
CountCorner.CornerRadius = UDim.new(0, 7)
CountCorner.Parent = CountBox

CountBox:GetPropertyChangedSignal("Text"):Connect(function()
	local digits = CountBox.Text:gsub("%D+", "")
	if CountBox.Text ~= digits then
		CountBox.Text = digits
	end
end)

local SpawnBtn = Instance.new("TextButton")
SpawnBtn.Size = UDim2.new(1, 0, 0, 36)
SpawnBtn.Position = UDim2.new(0, 0, 0, 82)
SpawnBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
SpawnBtn.Text = "Spawn"
SpawnBtn.TextColor3 = Color3.fromRGB(15, 15, 15)
SpawnBtn.Font = Enum.Font.GothamBold
SpawnBtn.TextSize = 14
SpawnBtn.Parent = Body

local SpawnCorner = Instance.new("UICorner")
SpawnCorner.CornerRadius = UDim.new(0, 8)
SpawnCorner.Parent = SpawnBtn

SpawnBtn.MouseButton1Click:Connect(function()
	local itemKey = resolveWeapon(WeaponBox.Text)
	if not itemKey then
		SpawnBtn.Text = "Not found"
		task.delay(1.2, function() SpawnBtn.Text = "Spawn" end)
		return
	end

	local amount = tonumber(CountBox.Text) or 1
	if amount < 1 then amount = 1 end

	if amount == 1 then
		enqueueItems(itemKey, 1)
	else
		local safeCount = math.min(amount, 250)
		CountBox.Text = tostring(safeCount)
		enqueueItems(itemKey, safeCount)
	end
end)

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	Body.Visible = not minimized
	Frame.Size = minimized and UDim2.new(0, 250, 0, 30) or UDim2.new(0, 250, 0, 162)
	MinBtn.Text = minimized and "+" or "-"
end)

local dragging, dragInput, dragStart, startPos

TopBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = Frame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

TopBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		Frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)
