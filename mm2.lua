local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

_G.Cache = _G.Cache or {}
_G.SmallCache = _G.SmallCache or {}

local SyncFolder = ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync")
local SyncDB = require(SyncFolder)
local ItemDB = SyncDB.Item or require(SyncFolder:WaitForChild("Item"))
local RarityDB = SyncDB.Rarities

local ItemModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ItemModule"))

local CrossPlatform = PlayerGui:WaitForChild("CrossPlatform")
local CrossSection = CrossPlatform:WaitForChild("NewItem")
local CrossMedium = CrossSection:WaitForChild("Medium")
local CrossContainer = CrossMedium:WaitForChild("Container")
local TargetCard = CrossContainer:WaitForChild("NewItem")

local SavedMediumState = {
	Size = CrossMedium.Size,
	Position = CrossMedium.Position,
	AnchorPoint = CrossMedium.AnchorPoint,
}

local function stretchMediumFullScreen(enabled)
	if not CrossMedium or not CrossMedium:IsA("GuiObject") then return end
	if enabled then
		local cam = workspace.CurrentCamera
		local viewSize = cam and cam.ViewportSize or Vector2.new(1920, 1080)
		local parentObj = CrossMedium.Parent
		local parentPos = (parentObj and parentObj:IsA("GuiObject")) and parentObj.AbsolutePosition or Vector2.new(0, 0)
		local parentSize = (parentObj and parentObj:IsA("GuiObject") and parentObj.AbsoluteSize.X > 0 and parentObj.AbsoluteSize.Y > 0)
			and parentObj.AbsoluteSize
			or viewSize

		local offsetX = -parentPos.X
		local offsetY = -parentPos.Y

		CrossMedium.AnchorPoint = Vector2.new(0, 0)
		CrossMedium.Position = UDim2.new(0, offsetX, 0, offsetY)
		CrossMedium.Size = UDim2.new(0, viewSize.X, 0, viewSize.Y)
	else
		CrossMedium.AnchorPoint = SavedMediumState.AnchorPoint
		CrossMedium.Position = SavedMediumState.Position
		CrossMedium.Size = SavedMediumState.Size
	end
end

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
			local nClean = cleanName(tostring(data.ItemName))
			if nClean ~= "" and not ItemLookup[nClean] then
				ItemLookup[nClean] = key
			end
		end
	end
end

local function resolveWeapon(inputText)
	local q = cleanName(inputText)
	if q == "" or q == "random" then
		if #NonChromaKeys == 0 then return nil end
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

local function findUI(names, className)
	for _, root in ipairs({ TargetCard, CrossContainer, CrossMedium, CrossSection }) do
		for _, nm in ipairs(names) do
			local obj = root:FindFirstChild(nm, true)
			if obj and (not className or obj:IsA(className)) then
				return obj
			end
		end
	end
	return nil
end

local Starburst = findUI({ "Starburst" }, "ImageLabel")
local TitleObj = findUI({ "Title" }, "TextLabel")
local ClaimBtn = findUI({ "Claim", "ClaimButton" }, "GuiButton")

local function getClaimTextObj(btn)
	if not btn then return nil end
	if btn:IsA("TextButton") or btn:IsA("TextLabel") or btn:IsA("TextBox") then
		return btn
	end
	for _, d in ipairs(btn:GetDescendants()) do
		if d:IsA("TextLabel") or d:IsA("TextBox") then
			return d
		end
	end
	return nil
end

local ClaimTextObj = getClaimTextObj(ClaimBtn)

local function setClaimText(txt)
	if ClaimTextObj then
		ClaimTextObj.Text = txt
	end
end

local function setPopupVisible(visible)
	stretchMediumFullScreen(visible)
	for _, obj in ipairs({ CrossSection, CrossMedium, CrossContainer, TargetCard }) do
		if obj and obj:IsA("GuiObject") then
			obj.Visible = visible
		end
	end
	local blur = Lighting:FindFirstChild("NewItemBlur")
	if blur and blur:IsA("BlurEffect") then
		blur.Enabled = visible
	end
end

local function populateNativeNewItem(itemKey, titleText, itemType, amount)
	local categoryTable = (SyncDB and SyncDB[itemType or "Weapons"]) or ItemDB
	local itemData = categoryTable[itemKey] or ItemDB[itemKey]
	if type(itemData) ~= "table" then return false end

	ItemModule.DisplayItem(TargetCard, itemData, amount)

	if Starburst and RarityDB and itemData.Rarity and RarityDB[itemData.Rarity] then
		local col = RarityDB[itemData.Rarity].Color
		if col then
			Starburst.ImageColor3 = Color3.fromRGB(col.r, col.g, col.b) or Color3.new(1, 1, 1)
		end
	end

	if TitleObj then
		TitleObj.Text = titleText or "You Got..."
	end

	setPopupVisible(true)
	return true
end

local Queue = {}
local TotalInBatch = 0
local CurrentIndex = 0
local IsShowing = false
local ClaimLock = false

local function refreshClaimLabel()
	if TotalInBatch > 1 then
		setClaimText("Claim (" .. CurrentIndex .. "/" .. TotalInBatch .. ")")
	else
		setClaimText("Claim")
	end
end

local function showNextInQueue()
	if #Queue == 0 then
		IsShowing = false
		TotalInBatch = 0
		CurrentIndex = 0
		setClaimText("Claim")
		setPopupVisible(false)
		return
	end

	IsShowing = true
	CurrentIndex += 1
	local entry = table.remove(Queue, 1)
	refreshClaimLabel()
	populateNativeNewItem(entry.ItemName, entry.TitleText, entry.Type, entry.Amount)
end

local function enqueueWeapon(itemKey, count)
	if not itemKey or not ItemDB[itemKey] then return end
	local qty = math.clamp(math.floor(tonumber(count) or 1), 1, 250)
	local wasEmpty = (#Queue == 0 and not IsShowing)

	if wasEmpty then
		TotalInBatch = qty
		CurrentIndex = 0
	else
		TotalInBatch += qty
	end

	for _ = 1, qty do
		table.insert(Queue, {
			ItemName = itemKey,
			TitleText = "You Got...",
			Type = "Weapons",
			Amount = nil
		})
	end

	if wasEmpty then
		showNextInQueue()
	else
		refreshClaimLabel()
	end
end

if ClaimBtn then
	ClaimBtn.MouseButton1Click:Connect(function()
		if not IsShowing or ClaimLock then return end
		ClaimLock = true

		local icon = TargetCard:FindFirstChild("Container") and TargetCard.Container:FindFirstChild("Icon")
		local mainGui = PlayerGui:FindFirstChild("MainGUI")
		local invDock = mainGui
			and mainGui:FindFirstChild("Lobby")
			and mainGui.Lobby:FindFirstChild("Dock")
			and mainGui.Lobby.Dock:FindFirstChild("Inventory")

		if icon and invDock and mainGui then
			ItemModule.AnimateItemIconIntoInventory(icon, invDock, mainGui)
		end

		_G.UnfinishedItem = nil
		_G.UnfinishedType = nil
		showNextInQueue()
		ClaimLock = false
	end)
end

-- GUI управления
local oldGui = PlayerGui:FindFirstChild("Native_NewItem_Spawner")
if oldGui then
	oldGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Native_NewItem_Spawner"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 20
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

	local amount = math.clamp(math.floor(tonumber(CountBox.Text) or 1), 1, 250)
	CountBox.Text = tostring(amount)
	enqueueWeapon(itemKey, amount)
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
		dragInput = input
		dragStart = input.Position
		startPos = Frame.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input == dragInput and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		Frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input == dragInput then
		dragging = false
		dragInput = nil
	end
end)
