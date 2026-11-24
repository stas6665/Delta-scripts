local Players = game:GetService("Players")
local player = Players:FindFirstChild("Stas_mine12") or Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local crossPlatform = playerGui:WaitForChild("CrossPlatform")
local newItemFolder = crossPlatform:WaitForChild("NewItem")
local newItem = newItemFolder:WaitForChild("Medium"):WaitForChild("Container"):WaitForChild("NewItem")

local items = {
	{
		Key = "travelergun",
		Name = "Traveler's Gun",
		Rarity = "Godly",
		Image = "rbxassetid://15091442039",
		ItemType = "Gun",
		ItemID = 15091442039,
		Event = "Halloween",
		Year = "2023",
	},
	{
		Key = "gingerscope",
		Name = "Gingerscope",
		Rarity = "Ancient",
		Image = "rbxassetid://15666596216",
		ItemType = "Gun",
		ItemID = 15666469505,
		Event = "Christmas",
		Year = "2023",
		FX = true,
	},
	{
		Key = "treegun2023",
		Name = "Evergun",
		Rarity = "Godly",
		Image = "rbxassetid://15694357721",
		ItemType = "Gun",
		ItemID = 15682703596,
		Event = "Christmas",
		Year = "2023",
		FX = true,
	},
	{
		Key = "treeknife2023",
		Name = "Evergreen",
		Rarity = "Godly",
		Image = "rbxassetid://15694357137",
		ItemType = "Knife",
		ItemID = 15667157715,
		Event = "Christmas",
		Year = "2023",
		FX = true,
	},
	{
		Key = "celestial",
		Name = "Celestial",
		Rarity = "Ancient",
		Image = "rbxthumb://type=Asset&w=150&h=150&id=136673966529736",
		ItemType = "Knife",
		ItemID = 136673966529736,
		Event = "Christmas",
		Year = "2024",
	},
	{
		Key = "raygun",
		Name = "Raygun",
		Rarity = "Godly",
		Image = "rbxthumb://type=Asset&w=150&h=150&id=139431943195380",
		ItemType = "Gun",
		ItemID = 139431943195380,
		Event = "Halloween",
		Year = "2025",
	},
}

local function setVisible(obj, state)
	if not obj then return end
	if obj:IsA("GuiObject") then
		obj.Visible = state
	elseif obj:IsA("LayerCollector") then
		obj.Enabled = state
	end
end

local function findItem(query)
	local q = string.lower(string.match(query or "", "^%s*(.-)%s*$") or "")
	if q == "" then
		return {
			Name = "Godly Item",
			Rarity = "Godly",
			Image = "rbxassetid://0",
			ItemType = "Gun",
			ItemID = 0,
			Event = "",
			Year = "",
		}
	end

	for _, item in ipairs(items) do
		if string.lower(item.Name) == q or item.Key == q then
			return item
		end
	end

	for _, item in ipairs(items) do
		if string.find(string.lower(item.Name), q, 1, true) or string.find(item.Key, q, 1, true) then
			return item
		end
	end

	return {
		Name = query,
		Rarity = "Godly",
		Image = "rbxassetid://0",
		ItemType = "Gun",
		ItemID = 0,
		Event = "",
		Year = "",
	}
end

local function applyEventAndYear(root, eventName, yearValue)
	local targetYear = tostring(yearValue or "")
	local isChristmas = (eventName == "Christmas")
	local isHalloween = (eventName == "Halloween")

	for _, obj in ipairs(root:GetDescendants()) do
		if obj.Name == "Christmas" then
			local bg = obj:FindFirstChild("BG")
			if bg then setVisible(bg, isChristmas) end
			setVisible(obj, isChristmas)
		elseif obj.Name == "Halloween" then
			local bg = obj:FindFirstChild("BG")
			if bg then setVisible(bg, isHalloween) end
			setVisible(obj, isHalloween)
		elseif obj.Name == "BG" and obj.Parent then
			if obj.Parent.Name == "Christmas" then
				setVisible(obj, isChristmas)
			elseif obj.Parent.Name == "Halloween" then
				setVisible(obj, isHalloween)
			end
		end
	end

	for _, obj in ipairs(root:GetDescendants()) do
		if obj.Name == "Year" then
			for _, child in ipairs(obj:GetChildren()) do
				if child:IsA("GuiObject") then
					child.Visible = (child.Name == targetYear)
				elseif child:IsA("TextLabel") then
					child.Text = targetYear
				end
			end
			if obj:IsA("TextLabel") then
				obj.Text = targetYear
			end
		elseif obj:IsA("GuiObject") and obj.Parent and obj.Parent.Name == "Year" then
			obj.Visible = (obj.Name == targetYear)
		end
	end
end

local function spawnNewItem(rawName)
	local item = findItem(rawName)

	for _, obj in ipairs(newItem:GetDescendants()) do
		if obj:IsA("TextLabel") then
			local n = string.lower(obj.Name)
			if string.find(n, "rarity") or string.find(n, "tier") then
				obj.Text = item.Rarity
			elseif string.find(n, "type") then
				obj.Text = item.ItemType
			elseif string.find(n, "event") then
				obj.Text = item.Event or ""
			elseif string.find(n, "year") then
				obj.Text = tostring(item.Year or "")
			elseif string.find(n, "id") then
				obj.Text = tostring(item.ItemID)
			else
				obj.Text = item.Name
			end
		elseif obj:IsA("ImageLabel") then
			local n = string.lower(obj.Name)
			if obj.Name ~= "BG" and not string.find(n, "bg") and item.Image ~= "rbxassetid://0" then
				obj.Image = item.Image
			end
		end
	end

	applyEventAndYear(newItemFolder, item.Event, item.Year)

	setVisible(newItemFolder, true)
	local medium = newItemFolder:FindFirstChild("Medium")
	setVisible(medium, true)
	local container = medium and medium:FindFirstChild("Container")
	setVisible(container, true)
	setVisible(newItem, true)
end

local gui = Instance.new("ScreenGui")
gui.Name = "GodlySpawnerMiniBox"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local box = Instance.new("Frame")
box.Size = UDim2.fromOffset(195, 108)
box.Position = UDim2.new(0.5, -97, 0.22, 0)
box.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
box.BorderSizePixel = 0
box.Active = true
box.Draggable = true
box.Parent = gui

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 8)
boxCorner.Parent = box

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -14, 0, 22)
title.Position = UDim2.fromOffset(7, 4)
title.BackgroundTransparency = 1
title.Text = "GODLY SPAWNER"
title.TextColor3 = Color3.fromRGB(255, 205, 70)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = box

local input = Instance.new("TextBox")
input.Size = UDim2.new(1, -14, 0, 30)
input.Position = UDim2.fromOffset(7, 28)
input.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
input.PlaceholderText = "Название предмета..."
input.Text = ""
input.TextColor3 = Color3.fromRGB(255, 255, 255)
input.PlaceholderColor3 = Color3.fromRGB(140, 140, 150)
input.Font = Enum.Font.Gotham
input.TextSize = 12
input.ClearTextOnFocus = false
input.Parent = box

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 6)
inputCorner.Parent = input

local spawnBtn = Instance.new("TextButton")
spawnBtn.Size = UDim2.new(1, -14, 0, 32)
spawnBtn.Position = UDim2.fromOffset(7, 65)
spawnBtn.BackgroundColor3 = Color3.fromRGB(220, 160, 25)
spawnBtn.Text = "Spawn"
spawnBtn.TextColor3 = Color3.fromRGB(15, 15, 15)
spawnBtn.Font = Enum.Font.GothamBold
spawnBtn.TextSize = 13
spawnBtn.Parent = box

local spawnCorner = Instance.new("UICorner")
spawnCorner.CornerRadius = UDim.new(0, 6)
spawnCorner.Parent = spawnBtn

spawnBtn.MouseButton1Click:Connect(function()
	spawnNewItem(input.Text)
end)
