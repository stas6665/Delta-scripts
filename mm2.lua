local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

_G.Cache = _G.Cache or {}
_G.SmallCache = _G.SmallCache or {}

local SyncFolder = ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync")
local ItemDB = require(SyncFolder:WaitForChild("Item"))

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

local function spawnNativeNewItem(itemKey, count)
	if type(_G.NewItem) ~= "function" then
		return false
	end

	local qty = math.clamp(math.floor(tonumber(count) or 1), 1, 250)
	for _ = 1, qty do
		_G.NewItem(itemKey, "You Got...", nil, "Weapons", nil)
	end
	return true
end

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

	local ok = spawnNativeNewItem(itemKey, amount)
	if not ok then
		SpawnBtn.Text = "_G.NewItem nil"
		task.delay(1.2, function() SpawnBtn.Text = "Spawn" end)
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
