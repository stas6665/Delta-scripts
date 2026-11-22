local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Modules = ReplicatedStorage:WaitForChild("Modules")
local ClientServices = ReplicatedStorage:WaitForChild("ClientServices")

local ProfileData = require(Modules:WaitForChild("ProfileData"))
local ItemService = require(ClientServices:WaitForChild("ItemService"))
local InventoryModule = require(Modules:WaitForChild("InventoryModule"))

local MM2SpawnerSuite = {}

-- ============================================================================
-- 1. БАЗА ОРУЖИЯ СО СКРИНШОТОВ (С ВКЛАДКАМИ, РЕДКОСТЬЮ, ТЕГАМИ И ИКОНКАМИ)
-- ============================================================================
MM2SpawnerSuite.Items = {
	-- HALLOWEEN
	{
		ID = "Raygun",
		Name = "Raygun",
		Category = "Weapons",
		ItemType = "Gun",
		Event = "Halloween",
		Rarity = "Godly",
		Chroma = true,
		AssetId = 139431943195380,
		Image = "rbxthumb://type=Asset&w=150&h=150&id=139431943195380",
	},
	{
		ID = "RaygunRed",
		Name = "Red Raygun",
		Category = "Weapons",
		ItemType = "Gun",
		Event = "Halloween",
		Rarity = "Unique",
		AssetId = 132354489228618,
		Image = "rbxthumb://type=Asset&w=150&h=150&id=132354489228618",
	},
	{
		ID = "Alienbeam_Gun",
		Name = "Alienbeam",
		Category = "Weapons",
		ItemType = "Gun",
		Event = "Halloween",
		Rarity = "Godly",
		AssetId = 79722325448464,
		Image = "rbxthumb://type=Asset&w=150&h=150&id=79722325448464",
	},
	{
		ID = "Alienbeam_Knife",
		Name = "Alienbeam",
		Category = "Weapons",
		ItemType = "Knife",
		Event = "Halloween",
		Rarity = "Godly",
		AssetId = 77607127867154,
		Image = "rbxthumb://type=Asset&w=150&h=150&id=77607127867154",
	},
	{
		ID = "Alienbeam_Chroma",
		Name = "Alienbeam",
		Category = "Weapons",
		ItemType = "Knife",
		Event = "Halloween",
		Rarity = "Godly",
		Chroma = true,
		AssetId = 10425610,
		Image = "rbxthumb://type=Asset&w=150&h=150&id=10425610",
	},
	{
		ID = "Traveler_G_2023",
		Name = "Traveler",
		Category = "Weapons",
		ItemType = "Gun",
		Event = "Halloween",
		Rarity = "Legendary",
		ItemID = 15091344462,
	},
	{
		ID = "VampireAxe_Silver",
		Name = "Vampire's Axe",
		Category = "Weapons",
		ItemType = "Knife",
		Event = "Halloween",
		Rarity = "Unique",
		ItemID = 130837676383567,
	},

	-- CHRISTMAS
	{
		ID = "Celestial",
		Name = "Celestial",
		Category = "Weapons",
		ItemType = "Knife",
		Event = "Christmas",
		Rarity = "Ancient",
		ItemID = 136673966529736,
		AssetId = 136673966529736,
		Image = "rbxthumb://type=Asset&w=150&h=150&id=136673966529736",
	},
	{
		ID = "Constellation",
		Name = "Constellation",
		Category = "Weapons",
		ItemType = "Gun",
		Event = "Christmas",
		Rarity = "Godly",
		ItemID = 114197436469014,
		AssetId = 114197436469014,
		Image = "rbxthumb://type=Asset&w=150&h=150&id=114197436469014",
	},
	{
		ID = "Gingerscope",
		Name = "Gingerscope",
		Category = "Weapons",
		ItemType = "Gun",
		Event = "Christmas",
		Rarity = "Ancient",
		FX = true,
		ItemID = 15666469505,
		AssetId = 15666596216,
		Image = "rbxthumb://type=Asset&w=150&h=150&id=15666596216",
	},
	{
		ID = "TreeGun2023",
		Name = "Evergun",
		Category = "Weapons",
		ItemType = "Gun",
		Event = "Christmas",
		Rarity = "Godly",
		FX = true,
		ItemID = 15682703596,
		AssetId = 15694357721,
		Image = "rbxassetid://15694357721",
	},
	{
		ID = "TreeGun2023Chroma",
		Name = "Evergun",
		Category = "Weapons",
		ItemType = "Gun",
		Event = "Christmas",
		Rarity = "Godly",
		FX = true,
		Chroma = true,
		ItemID = 15682703596,
		AssetId = 15694208971,
		Image = "rbxassetid://15694208971",
	},
	{
		ID = "TreeKnife2023",
		Name = "Evergreen",
		Category = "Weapons",
		ItemType = "Knife",
		Event = "Christmas",
		Rarity = "Godly",
		FX = true,
		ItemID = 15667157715,
		AssetId = 15694357137,
		Image = "rbxassetid://15694357137",
	},
	{
		ID = "TreeKnife2023Chroma",
		Name = "Evergreen",
		Category = "Weapons",
		ItemType = "Knife",
		Event = "Christmas",
		Rarity = "Godly",
		FX = true,
		Chroma = true,
		ItemID = 15667157715,
		AssetId = 15694192241,
		Image = "rbxassetid://15694192241",
	},

	-- SEASON 1 / CURRENT
	{
		ID = "Turkey2023",
		Name = "Turkey",
		Category = "Weapons",
		ItemType = "Knife",
		Season = 1,
		Rarity = "Godly",
		ItemID = 15413149176,
		AssetId = 15413162319,
		Image = "rbxassetid://15413162319",
	},
}

local ActiveHandOverride = {
	Gun = nil,
	Knife = nil,
}

-- ============================================================================
-- 2. ПОИСК КОНТЕЙНЕРА, СЕТКА И ЗАЩИТА ОТ СМЕЩЕНИЯ В КУЧУ
-- ============================================================================
function MM2SpawnerSuite.GetInventoryMain()
	local gui = InventoryModule.GUI
	if gui and gui.MyInventory and gui.MyInventory.Main then
		return gui.MyInventory.Main
	end

	local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not playerGui then return nil end

	for _, desc in ipairs(playerGui:GetDescendants()) do
		if desc.Name == "Inventory" and desc:FindFirstChild("Main") then
			return desc.Main
		end
	end
	return nil
end

local function getTargetSubTab(itemData)
	local info = type(itemData.Info) == "table" and itemData.Info or {}
	local category = itemData.Category or info.DataType or "Weapons"
	local eventName = itemData.Event or info.Event

	if category == "Weapons" and eventName then
		if eventName == "Christmas" or eventName == "Halloween" then
			return eventName
		end
		return "Current"
	end

	local season = itemData.Season ~= nil and itemData.Season or info.Season
	return (season ~= nil) and "Current" or (category == "Weapons" and "Classic" or "Current")
end

function MM2SpawnerSuite.ResolveContainer(invMain, itemData)
	if not invMain or not itemData then return nil, nil end

	local info = type(itemData.Info) == "table" and itemData.Info or {}
	local category = itemData.Category or info.DataType or "Weapons"
	local subTab = getTargetSubTab(itemData)

	local catNode = invMain:FindFirstChild(category)
	if catNode and catNode:FindFirstChild("Items") and catNode.Items:FindFirstChild("Container") then
		local itemsCont = catNode.Items.Container
		local section = itemsCont:FindFirstChild(subTab)
			or (itemsCont:FindFirstChild("Holiday") and itemsCont.Holiday:FindFirstChild("Container") and itemsCont.Holiday.Container:FindFirstChild(subTab))

		if section and section:FindFirstChild("Container") then
			return section.Container, section
		end

		local fallback = itemsCont:FindFirstChild("Current") or itemsCont:FindFirstChild("Classic")
		if fallback and fallback:FindFirstChild("Container") then
			return fallback.Container, fallback
		end
	end

	if subTab == "Halloween" or subTab == "Christmas" then
		for _, desc in ipairs(invMain:GetDescendants()) do
			if desc:IsA("GuiObject") and desc.Name == subTab and desc:FindFirstChild("Container") then
				return desc.Container, desc
			end
		end
	end

	return nil, nil
end

function MM2SpawnerSuite.EnsureGridAndBounds(container, section)
	if not container then return end

	local grid = container:FindFirstChildOfClass("UIGridLayout")
	if not grid then
		local gridSrc = (InventoryModule.GUI and InventoryModule.GUI.ItemGridLayout)
			or Modules.InventoryModule:FindFirstChild("ItemGridLayout")
		grid = (gridSrc and gridSrc:IsA("UIGridLayout")) and gridSrc:Clone() or Instance.new("UIGridLayout")
		grid.SortOrder = Enum.SortOrder.LayoutOrder
		if not gridSrc then
			grid.CellSize = UDim2.new(0, 80, 0, 80)
			grid.CellPadding = UDim2.new(0, 6, 0, 6)
		end
		grid.Parent = container
	else
		grid.SortOrder = Enum.SortOrder.LayoutOrder
	end

	local function refreshBounds()
		if section and section:IsA("GuiObject") and section.Parent and section.Parent.Name == "Container" then
			section.Size = UDim2.new(1, 0, 0, grid.AbsoluteContentSize.Y + 49)
		elseif section and section:IsA("ScrollingFrame") then
			section.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y + 5)
		elseif container:IsA("ScrollingFrame") then
			container.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y + 5)
		end
	end

	refreshBounds()
	if not container:GetAttribute("SpawnerGridSynced") then
		container:SetAttribute("SpawnerGridSynced", true)
		grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshBounds)
	end
end

local function resolveSafeIcon(itemData, dbInfo)
	if type(itemData.Image) == "string" and itemData.Image ~= "" then
		return itemData.Image
	end
	if dbInfo and ItemService.GetItemImage then
		local ok, img = pcall(function()
			return ItemService:GetItemImage(dbInfo)
		end)
		if ok and type(img) == "string" and img ~= "" then
			return img
		end
	end
	local numId = tonumber(itemData.ItemID or itemData.AssetId or (dbInfo and dbInfo.ItemID))
	if numId then
		return "rbxthumb://type=Asset&w=150&h=150&id=" .. tostring(numId)
	end
	return ""
end

-- ============================================================================
-- 3. ЛОКАЛЬНОЕ НАДЕВАНИЕ В EQUIPPED И ПОДМЕНА МОДЕЛИ В РУКЕ
-- ============================================================================
local function detectToolSlotType(tool)
	local n = string.lower(tool.Name)
	if string.find(n, "knife", 1, true) or string.find(n, "blade", 1, true) or string.find(n, "dagger", 1, true) then
		return "Knife"
	end
	return "Gun"
end

local function findSourceModelForItem(itemData)
	if not itemData then return nil end
	local targetName = string.lower(tostring(itemData.Name or itemData.ID or ""))
	local targetId = tostring(itemData.ItemID or itemData.AssetId or itemData.ID or "")

	local searchRoots = {
		ReplicatedStorage,
		workspace:FindFirstChild("Weapons") or workspace,
	}

	for _, root in ipairs(searchRoots) do
		if not root then continue end
		for _, inst in ipairs(root:GetDescendants()) do
			local n = string.lower(inst.Name)
			local matchesName = targetName ~= "" and (n == targetName or string.find(n, targetName, 1, true) ~= nil)
			local matchesId = false

			if targetId ~= "" then
				if tostring(inst:GetAttribute("ItemID") or "") == targetId then
					matchesId = true
				elseif inst:IsA("MeshPart") and string.find(tostring(inst.MeshId), targetId, 1, true) then
					matchesId = true
				elseif inst:IsA("SpecialMesh") and string.find(tostring(inst.MeshId), targetId, 1, true) then
					matchesId = true
				end
			end

			if (matchesName or matchesId) and (inst:IsA("Tool") or inst:IsA("Model") or inst:IsA("BasePart")) then
				return inst
			end
		end
	end
	return nil
end

function MM2SpawnerSuite.ApplyVisualOverrideToTool(tool, itemData)
	if not tool or not tool:IsA("Tool") or not itemData then return false end
	local tagKey = tostring(itemData.ID or itemData.Name)
	if tool:GetAttribute("SpawnerToolApplied") == tagKey then
		return true
	end

	local handle = tool:FindFirstChild("Handle")
	if not handle or not handle:IsA("BasePart") then
		for _, child in ipairs(tool:GetChildren()) do
			if child:IsA("BasePart") then
				handle = child
				break
			end
		end
	end
	if not handle then return false end

	local source = findSourceModelForItem(itemData)

	for _, d in ipairs(handle:GetDescendants()) do
		if d:IsA("SpecialMesh") or d:IsA("Decal") or d:IsA("Texture") or d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") or d:IsA("Highlight") then
			d:Destroy()
		end
	end
	if handle:IsA("MeshPart") then
		handle.TextureID = ""
	end
	handle.Transparency = 1

	for _, child in ipairs(tool:GetChildren()) do
		if child ~= handle and (child:IsA("BasePart") or child:IsA("Model")) then
			child:Destroy()
		end
	end

	if source then
		local clone = source:Clone()
		clone.Name = "SpawnerVisual_" .. tagKey

		if clone:IsA("Tool") then
			for _, item in ipairs(clone:GetChildren()) do
				if item:IsA("BasePart") or item:IsA("Model") or item:IsA("Folder") then
					item.Parent = tool
				end
			end
			clone:Destroy()
		else
			clone.Parent = tool
		end

		local firstPart = nil
		for _, part in ipairs(tool:GetDescendants()) do
			if part:IsA("BasePart") and part ~= handle then
				if not firstPart then firstPart = part end
				part.Anchored = false
				part.CanCollide = false
				part.Massless = true

				local weld = Instance.new("WeldConstraint")
				weld.Part0 = handle
				weld.Part1 = part
				weld.Parent = part
			end
		end

		if firstPart then
			tool:PivotTo(handle.CFrame)
		end
	else
		handle.Transparency = 0
		if itemData.AssetId then
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.FileMesh
			mesh.MeshId = "rbxassetid://" .. tostring(itemData.AssetId)
			mesh.Parent = handle
		end
	end

	tool:SetAttribute("SpawnerToolApplied", tagKey)
	return true
end

local function scanToolsForOverride()
	local char = LocalPlayer.Character
	local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")

	for _, container in ipairs({ char, backpack }) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Tool") then
					local slotType = detectToolSlotType(child)
					local overrideData = ActiveHandOverride[slotType]
					if overrideData then
						MM2SpawnerSuite.ApplyVisualOverrideToTool(child, overrideData)
					end
				end
			end
		end
	end
end

local function hookCharacterTools(char)
	if not char then return end
	scanToolsForOverride()

	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			task.defer(function()
				local slotType = detectToolSlotType(child)
				local overrideData = ActiveHandOverride[slotType]
				if overrideData then
					MM2SpawnerSuite.ApplyVisualOverrideToTool(child, overrideData)
				end
			end)
		end
	end)

	local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
	if backpack then
		scanToolsForOverride()
		backpack.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				task.defer(function()
					local slotType = detectToolSlotType(child)
					local overrideData = ActiveHandOverride[slotType]
					if overrideData then
						MM2SpawnerSuite.ApplyVisualOverrideToTool(child, overrideData)
					end
				end)
			end
		end)
	end
end

if LocalPlayer.Character then
	hookCharacterTools(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(hookCharacterTools)

function MM2SpawnerSuite.EquipItem(itemData, invMain)
	if not itemData then return false end
	invMain = invMain or MM2SpawnerSuite.GetInventoryMain()

	local category = itemData.Category or "Weapons"
	local itemType = itemData.ItemType or "Gun"
	local itemId = itemData.ItemID or itemData.ID
	local displayName = itemData.Name or tostring(itemId)
	local iconImage = resolveSafeIcon(itemData, nil)

	if category == "Weapons" and ProfileData.Weapons and ProfileData.Weapons.Equipped then
		ProfileData.Weapons.Equipped[itemType] = itemId
	end

	if invMain then
		local weaponsEquippedCont = invMain:FindFirstChild("Weapons")
			and invMain.Weapons:FindFirstChild("Equipped")
			and invMain.Weapons.Equipped:FindFirstChild("Container")

		local slotHolder = weaponsEquippedCont and weaponsEquippedCont:FindFirstChild(itemType)
		local slotContainer = slotHolder and slotHolder:FindFirstChild("Container")

		if slotContainer then
			slotContainer.Visible = true
			if slotContainer:FindFirstChild("Icon") and iconImage ~= "" then
				slotContainer.Icon.Image = iconImage
			end
			if slotContainer:FindFirstChild("ItemName") and slotContainer.ItemName:FindFirstChild("Label") then
				slotContainer.ItemName.Label.Text = displayName
			end

			local mergedInfo = {
				Name = displayName,
				Rarity = itemData.Rarity or "Godly",
				Chroma = itemData.Chroma,
				FX = itemData.FX,
				Image = iconImage,
			}
			if ItemService.ApplyItemToFrame then
				pcall(function()
					ItemService:ApplyItemToFrame(slotContainer, mergedInfo, 1)
				end)
				if slotContainer:FindFirstChild("Icon") and iconImage ~= "" then
					slotContainer.Icon.Image = iconImage
				end
				if slotContainer:FindFirstChild("ItemName") and slotContainer.ItemName:FindFirstChild("Label") then
					slotContainer.ItemName.Label.Text = displayName
				end
			end
			if slotContainer:FindFirstChild("Tags") and ItemService.UpdateTags then
				pcall(function()
					ItemService:UpdateTags(slotContainer, mergedInfo)
				end)
			end
		end
	end

	-- Подменяем модель в руке/рюкзаке
	if itemType == "Gun" or itemType == "Knife" then
		ActiveHandOverride[itemType] = itemData
		scanToolsForOverride()
	end

	return true
end

-- ============================================================================
-- 4. ДОБАВЛЕНИЕ / НАРАЩИВАНИЕ КАРТОЧКИ В ИНВЕНТАРЕ ПОСЛЕ CLAIM
-- ============================================================================
function MM2SpawnerSuite.ClaimItem(itemData, addAmount, autoEquip)
	if not itemData then return nil end
	addAmount = addAmount or 1

	local invMain = MM2SpawnerSuite.GetInventoryMain()
	local container, section = MM2SpawnerSuite.ResolveContainer(invMain, itemData)
	if not container then return nil end

	MM2SpawnerSuite.EnsureGridAndBounds(container, section)

	local slot = nil
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("GuiObject") and tostring(child:GetAttribute("SpawnerItemKey") or "") == tostring(itemData.ID) then
			slot = child
			break
		end
	end

	local dbInfo = nil
	if ItemService.FindItemInfo then
		pcall(function()
			dbInfo = ItemService:FindItemInfo(itemData.ItemID or itemData.ID, itemData.Category or "Weapons")
		end)
	end

	if not slot then
		local template = Modules.InventoryModule:FindFirstChild("NewItem") or ItemService.BaseItemFrame
		if not template then return nil end

		slot = template:Clone()
		slot:SetAttribute("SpawnerItemKey", tostring(itemData.ID))
		slot:SetAttribute("SpawnCount", 0)
		slot.AnchorPoint = Vector2.new(0, 0)
		slot.Position = UDim2.new(0, 0, 0, 0)

		local mergedInfo = {}
		if type(dbInfo) == "table" then
			for k, v in pairs(dbInfo) do mergedInfo[k] = v end
		end
		mergedInfo.Name = itemData.Name or mergedInfo.Name or tostring(itemData.ID)
		mergedInfo.Rarity = itemData.Rarity or mergedInfo.Rarity or "Godly"
		mergedInfo.Chroma = itemData.Chroma or mergedInfo.Chroma
		mergedInfo.FX = itemData.FX or mergedInfo.FX
		mergedInfo.Image = resolveSafeIcon(itemData, dbInfo)

		if ItemService.ApplyItemToFrame then
			pcall(function()
				ItemService:ApplyItemToFrame(slot, mergedInfo, 1)
			end)
		end
		if slot:FindFirstChild("Container") and slot.Container:FindFirstChild("Icon") and mergedInfo.Image ~= "" then
			slot.Container.Icon.Image = mergedInfo.Image
		end
		if slot:FindFirstChild("ItemName") and slot.ItemName:FindFirstChild("Label") then
			slot.ItemName.Label.Text = mergedInfo.Name
		end
		if slot:FindFirstChild("Tags") and ItemService.ApplyTags then
			pcall(function()
				ItemService:ApplyTags(slot, mergedInfo)
			end)
		end

		slot.LayoutOrder = ItemService:GetLayoutOrder(itemData.ID, itemData.Category or "Weapons")
		slot.Visible = true
		slot.Parent = container

		-- При клике на карточку надеваем предмет в слот Equipped и подменяем модель в руке
		for _, d in ipairs(slot:GetDescendants()) do
			if d:IsA("GuiButton") then
				d.Activated:Connect(function()
					MM2SpawnerSuite.EquipItem(itemData, invMain)
				end)
			end
		end
	end

	local nextCount = (tonumber(slot:GetAttribute("SpawnCount")) or 0) + addAmount
	slot:SetAttribute("SpawnCount", nextCount)

	if slot:FindFirstChild("Container") and slot.Container:FindFirstChild("Amount") then
		slot.Container.Amount.Text = nextCount > 1 and ("x" .. tostring(nextCount)) or ""
	end

	if autoEquip then
		MM2SpawnerSuite.EquipItem(itemData, invMain)
	end

	return slot
end

return MM2SpawnerSuite
