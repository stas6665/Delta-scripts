local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

_G.Cache = _G.Cache or {}
_G.SmallCache = _G.SmallCache or {}

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local ModulesFolder = ReplicatedStorage:WaitForChild("Modules")
local SyncDB = require(ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync"))
local _ = require(ModulesFolder:WaitForChild("ItemModule"))

local ITEMS_DB = {
	Raygun = {
		Key = "Raygun",
		ItemName = "Raygun",
		ItemType = "Weapons",
	},
	Celestial = {
		Key = "Celestial",
		ItemName = "Celestial",
		ItemType = "Weapons",
	},
	Turkey = {
		Key = "Turkey2023",
		ItemName = "Turkey",
		ItemType = "Weapons",
	},
	Gingerscope = {
		Key = "Gingerscope",
		ItemName = "Gingerscope",
		ItemType = "Weapons",
	},
}

local function findItem(rawName)
	if type(rawName) ~= "string" then return nil end
	local clean = string.lower(string.match(rawName, "^%s*(.-)%s*$") or "")
	if clean == "" then return nil end

	for key, data in pairs(ITEMS_DB) do
		if string.lower(key) == clean or string.lower(data.ItemName) == clean then
			return data
		end
	end

	for _, data in pairs(ITEMS_DB) do
		if string.find(string.lower(data.ItemName), clean, 1, true) then
			return data
		end
	end
	return nil
end

local function getSyncEntry(itemData)
	local cat = SyncDB[itemData.ItemType]
	if type(cat) == "table" then
		if cat[itemData.Key] then
			return itemData.Key, cat[itemData.Key]
		end
		if cat[itemData.ItemName] then
			return itemData.ItemName, cat[itemData.ItemName]
		end
		for k, v in pairs(cat) do
			if string.lower(tostring(k)) == string.lower(itemData.ItemName)
				or (type(v) == "table" and string.lower(tostring(v.ItemName or v.Name or "")) == string.lower(itemData.ItemName))
			then
				return k, v
			end
		end
	end
	return nil, nil
end

local function triggerNativeNewItem(itemData, amount)
	local dbKey, syncEntry = getSyncEntry(itemData)
	if not syncEntry then
		return false, "Нет в SyncDB."
	end
	if type(_G.NewItem) ~= "function" then
		return false, "_G.NewItem не найден."
	end

	_G.NewItem(tostring(dbKey or itemData.Key), "You Got...", nil, itemData.ItemType, amount > 1 and amount or nil)
	return true, "Вызван _G.NewItem: " .. itemData.ItemName .. " x" .. amount
end

local function buildGodlySpawner()
	local old = PlayerGui:FindFirstChild("GodlySpawnerUI")
	if old then old:Destroy() end

	local sg = Instance.new("ScreenGui")
	sg.Name = "GodlySpawnerUI"
	sg.ResetOnSpawn = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = PlayerGui

	local main = Instance.new("Frame")
	main.Name = "MainFrame"
	main.Size = UDim2.new(0, 268, 0, 194)
	main.Position = UDim2.new(0.5, -134, 0.25, -97)
	main.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
	main.BackgroundTransparency = 0.08
	main.BorderSizePixel = 0
	main.Active = true
	main.Draggable = true
	main.Parent = sg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = main

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(110, 65, 210)
	stroke.Thickness = 1.4
	stroke.Parent = main

	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, 0, 0, 32)
	topBar.BackgroundColor3 = Color3.fromRGB(22, 22, 29)
	topBar.BorderSizePixel = 0
	topBar.Parent = main

	local topCorner = Instance.new("UICorner")
	topCorner.CornerRadius = UDim.new(0, 10)
	topCorner.Parent = topBar

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -66, 1, 0)
	title.Position = UDim2.new(0, 10, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "Godly Spawner"
	title.TextColor3 = Color3.fromRGB(245, 242, 255)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Font = Enum.Font.GothamBold
	title.TextSize = 14
	title.Parent = topBar

	local collapseBtn = Instance.new("TextButton")
	collapseBtn.Size = UDim2.new(0, 26, 0, 24)
	collapseBtn.Position = UDim2.new(1, -32, 0.5, -12)
	collapseBtn.BackgroundColor3 = Color3.fromRGB(36, 36, 46)
	collapseBtn.Text = "-"
	collapseBtn.TextColor3 = Color3.fromRGB(235, 235, 245)
	collapseBtn.Font = Enum.Font.GothamBold
	collapseBtn.TextSize = 15
	collapseBtn.Parent = topBar

	local colCorner = Instance.new("UICorner")
	colCorner.CornerRadius = UDim.new(0, 6)
	colCorner.Parent = collapseBtn

	local body = Instance.new("Frame")
	body.Size = UDim2.new(1, -16, 1, -40)
	body.Position = UDim2.new(0, 8, 0, 36)
	body.BackgroundTransparency = 1
	body.Parent = main

	local weaponInput = Instance.new("TextBox")
	weaponInput.Name = "WeaponInput"
	weaponInput.Size = UDim2.new(1, 0, 0, 36)
	weaponInput.Position = UDim2.new(0, 0, 0, 2)
	weaponInput.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
	weaponInput.Text = ""
	weaponInput.PlaceholderText = "Raygun, Celestial, Turkey, Gingerscope"
	weaponInput.PlaceholderColor3 = Color3.fromRGB(130, 130, 150)
	weaponInput.TextColor3 = Color3.fromRGB(255, 255, 255)
	weaponInput.ClearTextOnFocus = false
	weaponInput.Font = Enum.Font.Gotham
	weaponInput.TextSize = 12
	weaponInput.Parent = body

	local wiCorner = Instance.new("UICorner")
	wiCorner.CornerRadius = UDim.new(0, 7)
	wiCorner.Parent = weaponInput

	local amountInput = Instance.new("TextBox")
	amountInput.Name = "AmountInput"
	amountInput.Size = UDim2.new(1, 0, 0, 36)
	amountInput.Position = UDim2.new(0, 0, 0, 44)
	amountInput.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
	amountInput.Text = "1"
	amountInput.PlaceholderText = "Количество"
	amountInput.PlaceholderColor3 = Color3.fromRGB(130, 130, 150)
	amountInput.TextColor3 = Color3.fromRGB(255, 255, 255)
	amountInput.ClearTextOnFocus = false
	amountInput.Font = Enum.Font.Gotham
	amountInput.TextSize = 12
	amountInput.Parent = body

	local aiCorner = Instance.new("UICorner")
	aiCorner.CornerRadius = UDim.new(0, 7)
	aiCorner.Parent = amountInput

	local statusLbl = Instance.new("TextLabel")
	statusLbl.Size = UDim2.new(1, 0, 0, 18)
	statusLbl.Position = UDim2.new(0, 0, 0, 84)
	statusLbl.BackgroundTransparency = 1
	statusLbl.Text = "Только родной код игры"
	statusLbl.TextColor3 = Color3.fromRGB(165, 155, 195)
	statusLbl.Font = Enum.Font.Gotham
	statusLbl.TextSize = 10
	statusLbl.Parent = body

	local spawnBtn = Instance.new("TextButton")
	spawnBtn.Name = "SpawnButton"
	spawnBtn.Size = UDim2.new(1, 0, 0, 38)
	spawnBtn.Position = UDim2.new(0, 0, 0, 106)
	spawnBtn.BackgroundColor3 = Color3.fromRGB(115, 65, 215)
	spawnBtn.Text = "Spawn"
	spawnBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	spawnBtn.Font = Enum.Font.GothamBold
	spawnBtn.TextSize = 14
	spawnBtn.Parent = body

	local sbCorner = Instance.new("UICorner")
	sbCorner.CornerRadius = UDim.new(0, 8)
	sbCorner.Parent = spawnBtn

	local collapsed = false
	collapseBtn.MouseButton1Click:Connect(function()
		collapsed = not collapsed
		body.Visible = not collapsed
		collapseBtn.Text = collapsed and "+" or "-"
		TweenService:Create(main, TweenInfo.new(0.18), {
			Size = collapsed and UDim2.new(0, 268, 0, 32) or UDim2.new(0, 268, 0, 194)
		}):Play()
	end)

	spawnBtn.MouseButton1Click:Connect(function()
		local itemData = findItem(weaponInput.Text)
		if not itemData then
			statusLbl.TextColor3 = Color3.fromRGB(255, 95, 110)
			statusLbl.Text = "Не найдено название предмета"
			return
		end

		local qty = math.max(1, math.floor(tonumber(amountInput.Text) or 1))
		local ok, msg = triggerNativeNewItem(itemData, qty)
		statusLbl.TextColor3 = ok and Color3.fromRGB(125, 255, 170) or Color3.fromRGB(255, 95, 110)
		statusLbl.Text = msg
	end)
end

buildGodlySpawner()
