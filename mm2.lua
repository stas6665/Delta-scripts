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

-- Родной путь: PlayerGui.CrossPlatform.NewItem.Medium.Container.NewItem
local function getNativeNewItem()
	local cross = PlayerGui:FindFirstChild("CrossPlatform")
	if not cross then return nil, nil end
	local section = cross:FindFirstChild("NewItem")
	if not section then return nil, nil end
	local medium = section:FindFirstChild("Medium")
	local container = medium and medium:FindFirstChild("Container")
	local frame = container and container:FindFirstChild("NewItem")
	return frame, section
end

local NewItemFrame, NewItemSection = getNativeNewItem()

local function findNativeElements(root)
	if not root then return {} end

	local claimBtn = root:FindFirstChild("Claim", true)
		or root:FindFirstChild("ClaimButton", true)
		or root:FindFirstChildWhichIsA("TextButton", true)
		or root:FindFirstChildWhichIsA("ImageButton", true)

	local iconLabel = root:FindFirstChild("ItemImage", true)
		or root:FindFirstChild("Icon", true)
		or root:FindFirstChild("ImageLabel", true)

	if not iconLabel then
		for _, d in ipairs(root:GetDescendants()) do
			if d:IsA("ImageLabel") and d.Name ~= "Starburst" and (not claimBtn or not d:IsDescendantOf(claimBtn)) then
				iconLabel = d
				break
			end
		end
	end

	local nameLabel = root:FindFirstChild("ItemName", true)
		or root:FindFirstChild("Title", true)
		or root:FindFirstChild("WeaponName", true)

	local rarityLabel = root:FindFirstChild("Rarity", true)
		or root:FindFirstChild("RarityText", true)

	local amountLabel = root:FindFirstChild("Amount", true)
		or root:FindFirstChild("Count", true)
		or root:FindFirstChild("Quantity", true)

	local starburst = root:FindFirstChild("Starburst", true)

	if not nameLabel or not rarityLabel then
		for _, d in ipairs(root:GetDescendants()) do
			if (d:IsA("TextLabel") or d:IsA("TextBox")) and (not claimBtn or not d:IsDescendantOf(claimBtn)) and d ~= amountLabel then
				if not nameLabel then
					nameLabel = d
				elseif not rarityLabel and d ~= nameLabel then
					rarityLabel = d
				end
			end
		end
	end

	return {
		ClaimBtn = claimBtn,
		IconLabel = iconLabel,
		NameLabel = nameLabel,
		RarityLabel = rarityLabel,
		AmountLabel = amountLabel,
		Starburst = starburst,
	}
end

local Native = findNativeElements(NewItemFrame or NewItemSection)

local function setClaimText(text)
	local btn = Native.ClaimBtn
	if not btn then return end
	if btn:IsA("TextButton") then
		btn.Text = text
	end
	local lbl = btn:FindFirstChildWhichIsA("TextLabel", true)
	if lbl then
		lbl.Text = text
	end
end

local function setNativeVisible(visible)
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
	if NewItemFrame and NewItemFrame:IsA("GuiObject") then
		NewItemFrame.Visible = visible
	end
end

local function setBlur(enabled)
	local blur = Lighting:FindFirstChild("NewItemBlur")
	if blur and blur:IsA("BlurEffect") then
		blur.Enabled = enabled
	end
end

local Queue = {}
local TotalInBatch = 0
local CurrentIndex = 0
local IsShowing = false

local function renderSingleItem(itemKey, indexNum, totalNum)
	local info = ItemDB[itemKey] or {}
	local displayName = info.ItemName or itemKey
	local rarity = info.Rarity or "Common"
	local imageId = info.Image or ""
	local rColor = getRarityColor(rarity)

	if Native.IconLabel and Native.IconLabel:IsA("ImageLabel") then
		Native.IconLabel.Image = imageId
	end

	if Native.NameLabel and (Native.NameLabel:IsA("TextLabel") or Native.NameLabel:IsA("TextBox")) then
		Native.NameLabel.Text = displayName
	end

	if Native.RarityLabel and (Native.RarityLabel:IsA("TextLabel") or Native.RarityLabel:IsA("TextBox")) then
		Native.RarityLabel.Text = rarity
		if Native.RarityLabel:IsA("TextLabel") then
			Native.RarityLabel.TextColor3 = rColor
		end
	end

	if Native.AmountLabel and (Native.AmountLabel:IsA("TextLabel") or Native.AmountLabel:IsA("TextBox")) then
		Native.AmountLabel.Text = "x1"
		Native.AmountLabel.Visible = true
	end

	if Native.Starburst and Native.Starburst:IsA("ImageLabel") then
		Native.Starburst.ImageColor3 = rColor
	end

	if totalNum > 1 then
		setClaimText(string.format("Claim (%d/%d)", indexNum, totalNum))
	else
		setClaimText("Claim")
	end

	setNativeVisible(true)
	setBlur(true)

	if NewItemFrame and NewItemFrame:IsA("GuiObject") then
		local origSize = NewItemFrame.Size
		NewItemFrame.Size = UDim2.new(origSize.X.Scale * 0.85, origSize.X.Offset * 0.85, origSize.Y.Scale * 0.85, origSize.Y.Offset * 0.85)
		TweenService:Create(NewItemFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = origSize
		}):Play()
	end
end

local function stepQueue()
	if #Queue == 0 then
		IsShowing = false
		TotalInBatch = 0
		CurrentIndex = 0
		setNativeVisible(false)
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
	elseif TotalInBatch > 1 then
		setClaimText(string.format("Claim (%d/%d)", CurrentIndex, TotalInBatch))
	end
end

if Native.ClaimBtn and (Native.ClaimBtn:IsA("TextButton") or Native.ClaimBtn:IsA("ImageButton")) then
	Native.ClaimBtn.MouseButton1Click:Connect(function()
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
local oldGui = PlayerGui:FindFirstChild("Native_NewItem_Spawner")
if oldGui then
	oldGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Native_NewItem_Spawner"
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
