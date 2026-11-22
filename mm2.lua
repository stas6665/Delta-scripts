local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local ITEMS_DB = {
	Raygun = {
		Key = "Raygun",
		ItemName = "Raygun",
		ItemType = "Gun",
		Rarity = "Godly",
		ItemID = 139431943195380,
		Event = "Halloween",
		Year = "2025",
		Icon = "rbxthumb://type=Asset&w=150&h=150&id=139431943195380",
	},
	Celestial = {
		Key = "Celestial",
		ItemName = "Celestial",
		ItemType = "Knife",
		Rarity = "Ancient",
		ItemID = 136673966529736,
		Event = "Christmas",
		Year = "2024",
		Icon = "rbxthumb://type=Asset&w=150&h=150&id=136673966529736",
	},
	Turkey = {
		Key = "Turkey2023",
		ItemName = "Turkey",
		ItemType = "Knife",
		Rarity = "Godly",
		ItemID = 15413149176,
		Event = "Christmas",
		Year = "2023",
		Season = 1,
		Icon = "rbxassetid://15413162319",
	},
	Gingerscope = {
		Key = "Gingerscope",
		ItemName = "Gingerscope",
		ItemType = "Gun",
		Rarity = "Ancient",
		ItemID = 15666469505,
		Event = "Christmas",
		Year = "2023",
		FX = true,
		Icon = "rbxthumb://type=Asset&w=250&h=250&id=15666596216",
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

local function findDefaultCardTemplate(itemType)
	local targetPhrase = string.lower("Default " .. tostring(itemType or "Knife"))
	local fallbackDefault = nil

	for _, desc in ipairs(PlayerGui:GetDescendants()) do
		if desc:IsA("GuiObject") and not desc:GetAttribute("SpawnedCard") then
			local lowName = string.lower(desc.Name)
			if string.find(lowName, targetPhrase, 1, true) then
				return desc
			end

			for _, child in ipairs(desc:GetDescendants()) do
				if child:IsA("TextLabel") or child:IsA("TextButton") then
					local lowText = string.lower(child.Text)
					if lowText == targetPhrase or string.find(lowText, targetPhrase, 1, true) then
						return desc
					end
					if not fallbackDefault and string.find(lowText, "default ", 1, true) then
						fallbackDefault = desc
					end
				end
			end
		end
	end

	return fallbackDefault
end

local function applyDefaultCardData(cardObj, itemData, amount)
	cardObj.Name = "NewItem_" .. itemData.ItemName
	cardObj.Visible = true
	cardObj:SetAttribute("SpawnedCard", true)
	cardObj:SetAttribute("ItemName", itemData.ItemName)
	cardObj:SetAttribute("ItemType", itemData.ItemType)
	cardObj:SetAttribute("ItemID", itemData.ItemID or 0)
	cardObj:SetAttribute("Event", itemData.Event or "")
	cardObj:SetAttribute("Year", itemData.Year or "")
	cardObj:SetAttribute("Amount", amount)

	for _, desc in ipairs(cardObj:GetDescendants()) do
		if desc:IsA("GuiObject") then
			desc.Visible = true
		end

		if desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
			local low = string.lower(desc.Name)
			if not string.find(low, "bg", 1, true)
				and not string.find(low, "frame", 1, true)
				and not string.find(low, "stroke", 1, true)
				and not string.find(low, "gradient", 1, true)
			then
				if itemData.Icon and itemData.Icon ~= "" then
					desc.Image = itemData.Icon
				end
			end
		elseif desc:IsA("TextLabel") or desc:IsA("TextButton") then
			local low = string.lower(desc.Name)
			if low == "rarity" then
				desc.Text = itemData.Rarity
				desc.Visible = true
			elseif string.find(low, "amount", 1, true) or string.find(low, "count", 1, true) or string.find(low, "qty", 1, true) or string.find(low, "stack", 1, true) then
				desc.Text = amount > 1 and ("x" .. tostring(amount)) or ""
			elseif string.find(low, "year", 1, true) then
				desc.Text = tostring(itemData.Year or "")
			else
				desc.Text = itemData.ItemName
			end
		end
	end
end

local function rectsOverlap(ax, ay, aw, ah, bx, by, bw, bh)
	return ax < (bx + bw - 1) and (ax + aw - 1) > bx and ay < (by + bh - 1) and (ay + ah - 1) > by
end

local function expandContainerSafely(containerObj, bottomRequiredY, padY)
	if not containerObj or not containerObj:IsA("GuiObject") then return end

	if containerObj.AutomaticSize == Enum.AutomaticSize.Y or containerObj.AutomaticSize == Enum.AutomaticSize.XY then
		return
	end

	if containerObj:FindFirstChildWhichIsA("UIGridLayout") or containerObj:FindFirstChildWhichIsA("UIListLayout") then
		if containerObj:IsA("ScrollingFrame") then
			local curCanvas = containerObj.CanvasSize.Y.Offset
			if curCanvas < bottomRequiredY + padY then
				containerObj.CanvasSize = UDim2.new(
					containerObj.CanvasSize.X.Scale,
					containerObj.CanvasSize.X.Offset,
					0,
					bottomRequiredY + padY
				)
			end
		end
		return
	end

	local oldHeight = containerObj.AbsoluteSize.Y > 4 and containerObj.AbsoluteSize.Y or containerObj.Size.Y.Offset
	local newHeight = math.max(oldHeight, bottomRequiredY + padY)

	if newHeight > oldHeight then
		containerObj.Size = UDim2.new(
			containerObj.Size.X.Scale,
			containerObj.Size.X.Offset,
			0,
			newHeight
		)
	end

	if containerObj:IsA("ScrollingFrame") then
		local curCanvas = containerObj.CanvasSize.Y.Offset
		if curCanvas < newHeight + padY then
			containerObj.CanvasSize = UDim2.new(0, 0, 0, newHeight + padY)
		end
	end
end

local function placeCardInRowWithoutOverlap(targetParent, cardObj)
	if not targetParent:IsA("GuiObject") then return end

	local gridLayout = targetParent:FindFirstChildWhichIsA("UIGridLayout")
	local listLayout = targetParent:FindFirstChildWhichIsA("UIListLayout")

	local maxOrder = 0
	for _, child in ipairs(targetParent:GetChildren()) do
		if child ~= cardObj and child:IsA("GuiObject") then
			local order = child.LayoutOrder or 0
			if order > maxOrder then
				maxOrder = order
			end
		end
	end

	if gridLayout then
		cardObj.LayoutOrder = maxOrder + 1
		local cellH = gridLayout.CellSize.Y.Offset > 0 and gridLayout.CellSize.Y.Offset or 124
		local padY = gridLayout.CellPadding.Y.Offset > 0 and gridLayout.CellPadding.Y.Offset or 8
		local cellW = gridLayout.CellSize.X.Offset > 0 and gridLayout.CellSize.X.Offset or 106
		local padX = gridLayout.CellPadding.X.Offset > 0 and gridLayout.CellPadding.X.Offset or 8
		local cols = math.max(1, math.floor((targetParent.AbsoluteSize.X + padX) / math.max(1, cellW + padX)))
		local rows = math.max(1, math.ceil((maxOrder + 1) / cols))
		expandContainerSafely(targetParent, padY + rows * (cellH + padY), padY)
		return
	elseif listLayout then
		cardObj.LayoutOrder = maxOrder + 1
		local absSize = listLayout.AbsoluteContentSize
		expandContainerSafely(targetParent, absSize.Y, listLayout.Padding.Offset > 0 and listLayout.Padding.Offset or 8)
		return
	end

	local cardW = cardObj.AbsoluteSize.X > 4 and cardObj.AbsoluteSize.X or (cardObj.Size.X.Offset > 0 and cardObj.Size.X.Offset or 106)
	local cardH = cardObj.AbsoluteSize.Y > 4 and cardObj.AbsoluteSize.Y or (cardObj.Size.Y.Offset > 0 and cardObj.Size.Y.Offset or 124)

	local padX = 8
	local padY = 8
	local stepX = cardW + padX
	local stepY = cardH + padY

	local containerW = targetParent.AbsoluteSize.X
	if containerW < stepX then
		containerW = stepX * 4
	end
	local cols = math.max(1, math.floor((containerW + padX) / stepX))

	local existingCards = {}
	for _, child in ipairs(targetParent:GetChildren()) do
		if child ~= cardObj and child:IsA("GuiObject") and child.Visible then
			table.insert(existingCards, child)
		end
	end
	table.sort(existingCards, function(a, b)
		if (a.LayoutOrder or 0) ~= (b.LayoutOrder or 0) then
			return (a.LayoutOrder or 0) < (b.LayoutOrder or 0)
		end
		if a.Position.Y.Offset ~= b.Position.Y.Offset then
			return a.Position.Y.Offset < b.Position.Y.Offset
		end
		return a.Position.X.Offset < b.Position.X.Offset
	end)

	local occupied = {}
	for _, child in ipairs(existingCards) do
		local cx = child.Position.X.Offset
		local cy = child.Position.Y.Offset
		local cw = child.AbsoluteSize.X > 4 and child.AbsoluteSize.X or (child.Size.X.Offset > 0 and child.Size.X.Offset or cardW)
		local ch = child.AbsoluteSize.Y > 4 and child.AbsoluteSize.Y or (child.Size.Y.Offset > 0 and child.Size.Y.Offset or cardH)
		table.insert(occupied, { x = cx, y = cy, w = cw, h = ch })
	end

	local chosenX, chosenY = padX, padY
	local chosenSlot = 0
	for slotIndex = 0, 500 do
		local col = slotIndex % cols
		local row = math.floor(slotIndex / cols)
		local candX = padX + col * stepX
		local candY = padY + row * stepY

		local isFree = true
		for _, box in ipairs(occupied) do
			if rectsOverlap(candX, candY, cardW, cardH, box.x, box.y, box.w, box.h) then
				isFree = false
				break
			end
		end

		if isFree then
			chosenX = candX
			chosenY = candY
			chosenSlot = slotIndex
			break
		end
	end

	cardObj.Position = UDim2.fromOffset(chosenX, chosenY)
	cardObj.LayoutOrder = chosenSlot + 1
	expandContainerSafely(targetParent, chosenY + cardH, padY)
end

local function cloneDefaultCardToContainer(targetParent, itemData, amount)
	if not targetParent then return nil end

	local cardName = "NewItem_" .. itemData.ItemName
	local existing = targetParent:FindFirstChild(cardName)
	if existing then
		local cur = tonumber(existing:GetAttribute("Amount")) or 1
		applyDefaultCardData(existing, itemData, cur + amount)
		placeCardInRowWithoutOverlap(targetParent, existing)
		return existing
	end

	local template = findDefaultCardTemplate(itemData.ItemType)
	if not template then
		warn("[Godly Spawner] Не найдена карточка Default " .. tostring(itemData.ItemType))
		return nil
	end

	local cloned = template:Clone()
	cloned.Parent = targetParent
	applyDefaultCardData(cloned, itemData, amount)
	placeCardInRowWithoutOverlap(targetParent, cloned)
	return cloned
end

local function findEventContainerInGame(eventName)
	if not eventName or eventName == "" then return nil end
	local lowEvent = string.lower(eventName)

	for _, desc in ipairs(PlayerGui:GetDescendants()) do
		if desc.Name ~= "GodlySpawnerUI" and string.lower(desc.Name) == lowEvent then
			local container = desc:FindFirstChild("Container")
			if container and container:IsA("GuiObject") then
				return container
			end
		end
	end

	return nil
end

local function findInventoryTabContainer(itemData)
	for _, desc in ipairs(PlayerGui:GetDescendants()) do
		if desc.Name ~= "GodlySpawnerUI" and string.lower(desc.Name) == "current" then
			local container = desc:FindFirstChild("Container")
			if container and container:IsA("GuiObject") then
				return container
			end
		end
	end

	return nil
end

local function sendClaimedItem(itemData, amount)
	local eventContainer = findEventContainerInGame(itemData.Event)
	if eventContainer then
		eventContainer.Visible = true
		cloneDefaultCardToContainer(eventContainer, itemData, amount)
	end

	local invTab = findInventoryTabContainer(itemData)
	if invTab and invTab ~= eventContainer then
		invTab.Visible = true
		cloneDefaultCardToContainer(invTab, itemData, amount)
	end
end

local function getOriginalNewItem()
	local crossPlatform = PlayerGui:FindFirstChild("CrossPlatform")
	if not crossPlatform then return nil end
	return crossPlatform:FindFirstChild("NewItem")
end

local function getOriginalClaimButton(newItemRoot)
	for _, desc in ipairs(newItemRoot:GetDescendants()) do
		if desc:IsA("GuiButton") then
			local lowName = string.lower(desc.Name)
			if string.find(lowName, "claim", 1, true) then
				return desc
			end
			if desc:IsA("TextButton") and string.find(string.lower(desc.Text), "claim", 1, true) then
				return desc
			end
		end
	end
	return nil
end

local pendingSpawn = nil
local originalClaimConnected = false

local function openOriginalNewItem(itemData, amount)
	local newItemRoot = getOriginalNewItem()
	if not newItemRoot then
		warn("[Godly Spawner] Не найден PlayerGui.CrossPlatform.NewItem")
		return false
	end

	pendingSpawn = { item = itemData, amount = amount }

	if newItemRoot:IsA("ScreenGui") then
		newItemRoot.Enabled = true
	elseif newItemRoot:IsA("GuiObject") then
		newItemRoot.Visible = true
	end

	for _, child in ipairs(newItemRoot:GetChildren()) do
		if child:IsA("GuiObject") then
			local low = string.lower(child.Name)
			if low == "halloween" or low == "christmas" or low == "chroma" or low == "unique" then
				child.Visible = itemData.Event and string.lower(itemData.Event) == low or false
			else
				child.Visible = true
			end
		end
	end

	for _, desc in ipairs(newItemRoot:GetDescendants()) do
		if desc:IsA("GuiObject") then
			local low = string.lower(desc.Name)
			if low == "halloween" or low == "christmas" or low == "chroma" or low == "unique" then
				desc.Visible = itemData.Event and string.lower(itemData.Event) == low or false
			end
		end

		if desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
			local low = string.lower(desc.Name)
			if (string.find(low, "icon", 1, true) or string.find(low, "item", 1, true) or string.find(low, "image", 1, true))
				and not string.find(low, "starburst", 1, true)
				and not string.find(low, "bg", 1, true)
			then
				if itemData.Icon and itemData.Icon ~= "" then
					desc.Image = itemData.Icon
				end
			end
		elseif desc:IsA("TextLabel") then
			local low = string.lower(desc.Name)
			if low == "rarity" then
				desc.Text = itemData.Rarity
				desc.Visible = true
			elseif low == "year" or low == "year2" then
				if itemData.Year then
					desc.Text = tostring(itemData.Year)
					desc.Visible = true
				else
					desc.Visible = false
				end
			elseif string.find(low, "name", 1, true) or string.find(low, "title", 1, true) then
				desc.Text = amount > 1 and (itemData.ItemName .. " x" .. amount) or itemData.ItemName
			end
		end
	end

	if not originalClaimConnected then
		local claimBtn = getOriginalClaimButton(newItemRoot)
		if claimBtn then
			originalClaimConnected = true
			claimBtn.MouseButton1Click:Connect(function()
				if pendingSpawn then
					sendClaimedItem(pendingSpawn.item, pendingSpawn.amount)
					pendingSpawn = nil
				end
			end)
		end
	end

	return true
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
	weaponInput.PlaceholderText = "Название (Raygun, Celestial, Turkey, Gingerscope)"
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
	statusLbl.Text = "Предметы: Raygun, Celestial, Turkey, Gingerscope"
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
			statusLbl.Text = "Не найдено: проверь название предмета"
			return
		end

		local qty = math.max(1, math.floor(tonumber(amountInput.Text) or 1))
		local ok = openOriginalNewItem(itemData, qty)
		if ok then
			statusLbl.TextColor3 = Color3.fromRGB(125, 255, 170)
			statusLbl.Text = "Открыт NewItem: " .. itemData.ItemName .. " x" .. qty
		else
			statusLbl.TextColor3 = Color3.fromRGB(255, 95, 110)
			statusLbl.Text = "CrossPlatform.NewItem не найден в PlayerGui"
		end
	end)
end

buildGodlySpawner()
