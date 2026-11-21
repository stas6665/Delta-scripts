local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local mainGui = playerGui:WaitForChild("MainGUI")
local gameGui = mainGui:WaitForChild("Game")
local newItemFrame = gameGui:WaitForChild("NewItem")
local claimBtn = newItemFrame:WaitForChild("Container"):WaitForChild("Claim")

local itemModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ItemModule"))
local syncDb = require(ReplicatedStorage:WaitForChild("Database"):WaitForChild("Sync"))

local equipService = nil
pcall(function()
	local clientServices = ReplicatedStorage:FindFirstChild("ClientServices")
	if clientServices and clientServices:FindFirstChild("EquipService") then
		equipService = require(clientServices.EquipService)
	end
end)

local TARGET_KEY = "Gingerscope"
local TARGET_ID = 15617843269
local ASSET_ID_URI = "rbxassetid://" .. tostring(TARGET_ID)
local ANCIENT_COLOR = Color3.fromRGB(115, 35, 225)
local ANCIENT_DARK = Color3.fromRGB(65, 15, 145)

local isClaimed = false
local isEquipped = false
local itemCount = 0
local holdTrack = nil
local currentCardNameLabel = nil
local currentCardRoot = nil
local currentCardContainer = nil
local attachedByHandle = setmetatable({}, { __mode = "k" })
local hiddenPartsState = setmetatable({}, { __mode = "k" })
local hookedButtons = setmetatable({}, { __mode = "k" })
local hookedCardSignals = setmetatable({}, { __mode = "k" })

local function findEntryByItemIdOrKey(targetId, fallbackKey)
	local idStr = tostring(targetId)
	if syncDb and typeof(syncDb.Weapons) == "table" then
		for key, entry in pairs(syncDb.Weapons) do
			if typeof(entry) == "table" and tostring(entry.ItemID or "") == idStr then
				return tostring(key), entry
			end
		end
		if syncDb.Weapons[fallbackKey] then
			return fallbackKey, syncDb.Weapons[fallbackKey]
		end
	end

	return fallbackKey, {
		ItemName = fallbackKey,
		ItemType = "Gun",
		Rarity = "Ancient",
		Event = "Christmas",
		Year = 2023,
		ItemID = targetId,
	}
end

local resolvedDefaultKey, gsEntry = findEntryByItemIdOrKey(TARGET_ID, TARGET_KEY)
TARGET_KEY = resolvedDefaultKey
gsEntry.Rarity = gsEntry.Rarity or "Ancient"
gsEntry.Event = gsEntry.Event or "Christmas"

local function isChristmasName(str)
	local lower = string.lower(tostring(str or ""))
	return string.find(lower, "christmas", 1, true) ~= nil
		or string.find(lower, "chrismas", 1, true) ~= nil
		or string.find(lower, "xmas", 1, true) ~= nil
end

local function getItemIdValue(obj)
	if not obj then return "" end
	local attr = obj:GetAttribute("ItemID")
	if attr ~= nil then
		return tostring(attr)
	end
	local valObj = obj:FindFirstChild("ItemID")
	if valObj and valObj:IsA("ValueBase") then
		return tostring(valObj.Value)
	end
	return ""
end

local function getWholeModelAsset(obj)
	if not obj then return nil end
	local parentTool = obj:FindFirstAncestorOfClass("Tool")
	if parentTool then
		return parentTool
	end
	local parentModel = obj:FindFirstAncestorOfClass("Model")
	if parentModel and parentModel ~= workspace and parentModel ~= ReplicatedStorage then
		return parentModel
	end
	if obj:IsA("Model") or obj:IsA("Tool") or obj:IsA("MeshPart") or obj:IsA("BasePart") then
		return obj
	end
	return nil
end

local function findWholeAssetByItemId(targetId, itemKey)
	local idStr = tostring(targetId)
	local keyLower = string.lower(tostring(itemKey or TARGET_KEY))
	local found = {
		Item = nil,
		Sound = nil,
		Anim = nil,
		Beam = nil,
		Image = (typeof(gsEntry) == "table" and gsEntry.Image) or ASSET_ID_URI,
	}

	-- 1. Приоритет: точное совпадение по ItemID -> берём целую модель/тул с текстурой
	for _, root in ipairs({ ReplicatedStorage, workspace }) do
		for _, obj in ipairs(root:GetDescendants()) do
			if getItemIdValue(obj) == idStr then
				local whole = getWholeModelAsset(obj)
				if whole and not found.Item then
					found.Item = whole
				end
				if obj:IsA("Sound") and not found.Sound then
					found.Sound = obj
				elseif obj:IsA("Animation") and not found.Anim then
					found.Anim = obj
				elseif obj:IsA("Beam") and not found.Beam then
					found.Beam = obj
				end
			end
		end
	end

	-- 2. Запасной поиск по имени ключа (например Gingerscope), если ItemID висит выше/в таблице
	if not found.Item and keyLower ~= "" then
		for _, root in ipairs({ ReplicatedStorage, workspace }) do
			for _, obj in ipairs(root:GetDescendants()) do
				if obj.Name:lower():find(keyLower, 1, true) then
					local whole = getWholeModelAsset(obj)
					if whole and not found.Item then
						found.Item = whole
					elseif obj:IsA("Sound") and not found.Sound then
						found.Sound = obj
					elseif obj:IsA("Animation") and not found.Anim then
						found.Anim = obj
					elseif obj:IsA("Beam") and not found.Beam then
						found.Beam = obj
					end
				end
			end
		end
	end

	return found
end

local assets = findWholeAssetByItemId(TARGET_ID, TARGET_KEY)

local function resolveWeaponData(rawName)
	local clean = tostring(rawName or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if clean == "" then
		clean = TARGET_KEY
	end

	if syncDb and typeof(syncDb.Weapons) == "table" then
		-- Если ввели сам ItemID цифрами
		for key, entry in pairs(syncDb.Weapons) do
			if typeof(entry) == "table" and tostring(entry.ItemID or "") == clean then
				return tostring(key), entry
			end
		end
		if syncDb.Weapons[clean] then
			return clean, syncDb.Weapons[clean]
		end
		for key, entry in pairs(syncDb.Weapons) do
			if tostring(key):lower() == clean:lower() or (typeof(entry) == "table" and tostring(entry.ItemName or ""):lower() == clean:lower()) then
				return tostring(key), entry
			end
		end
	end

	return clean, {
		ItemName = clean,
		ItemType = "Gun",
		Rarity = "Ancient",
		Event = "Christmas",
		Year = gsEntry.Year or 2023,
		ItemID = TARGET_ID,
		Image = gsEntry.Image or ASSET_ID_URI,
	}
end

local function centerNewItemWindow()
	if newItemFrame:IsA("GuiObject") then
		newItemFrame.AnchorPoint = Vector2.new(0.5, 0.5)
		newItemFrame.Position = UDim2.fromScale(0.5, 0.5)
	end
	local container = newItemFrame:FindFirstChild("Container")
	if container and container:IsA("GuiObject") and container.Size ~= UDim2.fromScale(1, 1) then
		container.AnchorPoint = Vector2.new(0.5, 0.5)
		container.Position = UDim2.fromScale(0.5, 0.5)
	end
end

local function isPistolTool(tool)
	if not tool or not tool:IsA("Tool") then return false end
	if tool.Name == "GS_Gingerscope_Tool" then return false end
	local n = tool.Name:lower()
	if n:find("knife", 1, true) or n:find("blade", 1, true) or n:find("dagger", 1, true) or n:find("scythe", 1, true) or n:find("axe", 1, true) or n:find("sword", 1, true) then
		return false
	end
	if n:find("gun", 1, true) or n:find("pistol", 1, true) or n:find("revolver", 1, true) or n:find("gingerscope", 1, true) or n:find("blaster", 1, true) or n:find("raygun", 1, true) then
		return true
	end
	local itemType = tostring(tool:GetAttribute("ItemType") or tool:GetAttribute("Type") or ""):lower()
	if itemType == "gun" then
		return true
	end
	return tool:FindFirstChild("Handle", true) ~= nil
end

local function collectPistolHandles()
	local handles = {}
	local seen = {}

	local function scanContainer(container)
		if not container then return end
		for _, desc in ipairs(container:GetDescendants()) do
			if desc:IsA("BasePart") and desc.Name == "Handle" and desc.Name ~= "GS_Gingerscope_Handle" then
				local tool = desc:FindFirstAncestorOfClass("Tool")
				if isPistolTool(tool) and not seen[desc] then
					seen[desc] = true
					table.insert(handles, { handle = desc, tool = tool })
				end
			end
		end
	end

	scanContainer(player.Character)
	scanContainer(player:FindFirstChild("Backpack"))

	return handles
end

-- Клонируем цельную модель с текстурой по ItemID; если модель не найдена — возвращаем nil (без резервного куба)
local function createUnifiedItemClone()
	if not assets.Item then
		assets = findWholeAssetByItemId(gsEntry.ItemID or TARGET_ID, TARGET_KEY)
	end
	if not assets.Item then
		return nil
	end

	local ok, clone = pcall(function()
		return assets.Item:Clone()
	end)
	if not ok or not clone then
		return nil
	end

	-- Если клонировался Tool, извлекаем его содержимое в цельную Model, чтобы сохранить все детали и текстуры
	if clone:IsA("Tool") then
		local modelWrap = Instance.new("Model")
		modelWrap.Name = "GS_Gingerscope_Handle"
		for _, child in ipairs(clone:GetChildren()) do
			if not child:IsA("LuaSourceContainer") then
				child.Parent = modelWrap
			end
		end
		clone:Destroy()
		clone = modelWrap
	end

	local parts = {}
	for _, desc in ipairs(clone:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.LocalTransparencyModifier = 0
			desc.Transparency = 0
			desc.Anchored = false
			desc.CanCollide = false
			desc.Massless = true
			table.insert(parts, desc)
		end
	end

	if clone:IsA("BasePart") then
		clone.Name = "GS_Gingerscope_Handle"
		clone.LocalTransparencyModifier = 0
		clone.Transparency = 0
		clone.Anchored = false
		clone.CanCollide = false
		clone.Massless = true
	elseif clone:IsA("Model") then
		clone.Name = "GS_Gingerscope_Handle"
		local primary = clone.PrimaryPart or clone:FindFirstChild("Handle", true) or parts[1]
		if primary then
			clone.PrimaryPart = primary
			-- Скрепляем все детали цельной модели с PrimaryPart, чтобы текстурированная модель не рассыпалась
			for _, part in ipairs(parts) do
				if part ~= primary then
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = primary
					weld.Part1 = part
					weld.Parent = part
				end
			end
		end
	end

	return clone
end

local function hideToolOriginalParts(tool, keepHandle)
	if not tool then return end
	for _, desc in ipairs(tool:GetDescendants()) do
		if desc:IsA("BasePart") and desc ~= keepHandle and desc.Name ~= "GS_Gingerscope_Handle" and not desc:IsDescendantOf(attachedByHandle[keepHandle] or workspace) then
			if not hiddenPartsState[desc] then
				hiddenPartsState[desc] = {
					mod = desc.LocalTransparencyModifier,
					tr = desc.Transparency,
				}
			end
			desc.LocalTransparencyModifier = 1
			desc.Transparency = 1
		end
	end
end

local function restoreHiddenParts()
	for part, state in pairs(hiddenPartsState) do
		if part and part.Parent then
			part.LocalTransparencyModifier = state.mod or 0
			part.Transparency = state.tr or 0
		end
		hiddenPartsState[part] = nil
	end
end

local function attachReplacementToHandle(handle, tool)
	if attachedByHandle[handle] and attachedByHandle[handle].Parent then
		hideToolOriginalParts(tool, handle)
		return attachedByHandle[handle]
	end

	local clone = createUnifiedItemClone()
	if not clone then
		return nil
	end

	clone.Name = "GS_Gingerscope_Handle"

	local primary = nil
	if clone:IsA("BasePart") then
		clone.CFrame = handle.CFrame
		clone.Parent = handle.Parent
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = clone
		weld.Parent = clone
		primary = clone
	elseif clone:IsA("Model") then
		local rootPart = clone.PrimaryPart or clone:FindFirstChild("Handle", true) or clone:FindFirstChildWhichIsA("BasePart", true)
		if rootPart then
			clone.PrimaryPart = rootPart
			clone:PivotTo(handle.CFrame)
			clone.Parent = handle.Parent
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = handle
			weld.Part1 = rootPart
			weld.Parent = rootPart
			primary = rootPart
		end
	end

	if primary then
		attachedByHandle[handle] = clone
		hideToolOriginalParts(tool, handle)
	else
		clone:Destroy()
	end

	return primary
end

local function clearAllHandleReplacements()
	for handle, repl in pairs(attachedByHandle) do
		if repl and repl.Parent then
			repl:Destroy()
		end
		attachedByHandle[handle] = nil
	end
	restoreHiddenParts()
end

local function isOwnedByLocalPlayer(obj)
	if not obj then return false end
	if obj:IsDescendantOf(playerGui) then
		return true
	end
	local char = player.Character
	if char and obj:IsDescendantOf(char) then
		return true
	end

	local pName = player.Name:lower()
	local uidStr = tostring(player.UserId)

	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			local oChar = other.Character
			if oChar and obj:IsDescendantOf(oChar) then
				return false
			end
			local oName = other.Name:lower()
			if obj.Name:lower():find(oName, 1, true) then
				return false
			end
		end
	end

	if obj.Name:lower():find(pName, 1, true) then
		return true
	end

	local cur = obj
	while cur and cur ~= workspace and cur ~= game do
		local cName = cur.Name:lower()
		if cName:find(pName, 1, true) or cur.Name == uidStr then
			return true
		end
		local ownerAttr = tostring(cur:GetAttribute("Owner") or cur:GetAttribute("Player") or cur:GetAttribute("UserId") or "")
		if ownerAttr == uidStr or ownerAttr:lower() == pName then
			return true
		end
		local ownerVal = cur:FindFirstChild("Owner") or cur:FindFirstChild("Player") or cur:FindFirstChild("UserId")
		if ownerVal and ownerVal:IsA("ValueBase") then
			local vStr = tostring(ownerVal.Value)
			if vStr == uidStr or vStr:lower() == pName then
				return true
			end
		end
		cur = cur.Parent
	end

	return false
end

local function updateGunDisplay()
	for _, container in ipairs({ workspace, playerGui }) do
		for _, d in ipairs(container:GetDescendants()) do
			if d.Name == "GS_GunDisplay_Handle" then
				d:Destroy()
			end
		end
	end

	if not isEquipped then
		return
	end

	for _, container in ipairs({ workspace, playerGui }) do
		for _, d in ipairs(container:GetDescendants()) do
			if d.Name:lower():find("gundisplay", 1, true) and isOwnedByLocalPlayer(d) then
				if d:IsA("BasePart") or d:IsA("Model") then
					local anchor = d:IsA("Model") and (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart")) or d
					if anchor then
						local itemClone = createUnifiedItemClone()
						if itemClone then
							itemClone.Name = "GS_GunDisplay_Handle"
							if itemClone:IsA("BasePart") then
								itemClone.Anchored = true
								itemClone.CFrame = anchor.CFrame * CFrame.new(0, 1.5, 0)
								itemClone.Parent = d
							elseif itemClone:IsA("Model") then
								local p = itemClone.PrimaryPart or itemClone:FindFirstChildWhichIsA("BasePart", true)
								if p then
									itemClone.PrimaryPart = p
									itemClone:PivotTo(anchor.CFrame * CFrame.new(0, 1.5, 0))
									for _, part in ipairs(itemClone:GetDescendants()) do
										if part:IsA("BasePart") then
											part.Anchored = true
										end
									end
								end
								itemClone.Parent = d
							end
						end
					end
				elseif d:IsA("GuiObject") then
					local lbl = Instance.new("TextLabel")
					lbl.Name = "GS_GunDisplay_Handle"
					lbl.Size = UDim2.fromScale(1, 1)
					lbl.BackgroundTransparency = 0.3
					lbl.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
					lbl.Text = tostring(gsEntry.ItemName or TARGET_KEY)
					lbl.TextColor3 = Color3.fromRGB(255, 215, 110)
					lbl.Font = Enum.Font.GothamBold
					lbl.TextScaled = true
					lbl.Parent = d
				end
			end
		end
	end
end

local function syncHoldAnimation()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")

	if not isEquipped or not hum or not assets.Anim then
		if holdTrack then
			holdTrack:Stop()
			holdTrack:Destroy()
			holdTrack = nil
		end
		return
	end

	if not holdTrack then
		local ok, tr = pcall(function() return hum:LoadAnimation(assets.Anim) end)
		if ok and tr then
			tr.Priority = Enum.AnimationPriority.Action
			tr.Looped = true
			tr:Play()
			holdTrack = tr
		end
	elseif not holdTrack.IsPlaying then
		holdTrack:Play()
	end
end

local function syncPistolReplacements()
	if not isEquipped then
		clearAllHandleReplacements()
		syncHoldAnimation()
		updateGunDisplay()
		return
	end

	local entries = collectPistolHandles()
	local activeHandles = {}
	for _, entry in ipairs(entries) do
		activeHandles[entry.handle] = true
		attachReplacementToHandle(entry.handle, entry.tool)
	end

	for handle, repl in pairs(attachedByHandle) do
		if not activeHandles[handle] or not handle.Parent then
			if repl and repl.Parent then
				repl:Destroy()
			end
			attachedByHandle[handle] = nil
		end
	end

	syncHoldAnimation()
	updateGunDisplay()
end

local function updateCardAmountVisual(card)
	if not card then return end
	local countText = tostring(math.max(0, math.floor(itemCount)))

	local cont = card:FindFirstChild("Container")
	local nativeAmount = cont and cont:FindFirstChild("Amount")
	if nativeAmount and nativeAmount:IsA("TextLabel") then
		nativeAmount.Text = (itemCount > 1) and ("x" .. countText) or ""
		nativeAmount.Visible = itemCount > 1
	end

	local badge = card:FindFirstChild("GS_CountBadge")
	if not badge then
		badge = Instance.new("TextLabel")
		badge.Name = "GS_CountBadge"
		badge.Size = UDim2.new(0, 44, 0, 18)
		badge.Position = UDim2.new(1, -48, 1, -22)
		badge.BackgroundColor3 = Color3.fromRGB(20, 16, 32)
		badge.BackgroundTransparency = 0.15
		badge.BorderSizePixel = 0
		badge.TextColor3 = Color3.fromRGB(255, 240, 150)
		badge.Font = Enum.Font.GothamBold
		badge.TextSize = 11
		badge.ZIndex = 20
		badge.Parent = card

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 5)
		corner.Parent = badge

		local stroke = Instance.new("UIStroke")
		stroke.Color = ANCIENT_COLOR
		stroke.Thickness = 1.2
		stroke.Parent = badge
	end

	if badge:IsA("TextLabel") then
		badge.Text = countText
		badge.Visible = itemCount > 0
	end
end

local setEquipped
local addGingerscopeToInventoryUI

local function consumeOneOnUnequip()
	if itemCount <= 0 then return end
	itemCount -= 1

	if itemCount <= 0 then
		itemCount = 0
		isClaimed = false
		if currentCardRoot and currentCardRoot.Parent then
			currentCardRoot:Destroy()
		end
		currentCardRoot = nil
	elseif currentCardRoot and currentCardRoot.Parent then
		updateCardAmountVisual(currentCardRoot)
	end
end

local invSlotGui = Instance.new("ScreenGui")
invSlotGui.Name = "GS_InventorySlot_UI"
invSlotGui.ResetOnSpawn = false
invSlotGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
invSlotGui.Parent = playerGui

local slotBtn = Instance.new("TextButton")
slotBtn.Visible = false
slotBtn.Size = UDim2.fromOffset(175, 36)
slotBtn.Position = UDim2.new(0.5, -87.5, 1, -54)
slotBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
slotBtn.Text = tostring(gsEntry.ItemName or TARGET_KEY)
slotBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
slotBtn.Font = Enum.Font.GothamBold
slotBtn.TextSize = 12
slotBtn.Parent = invSlotGui

-- Кнопка Spawn для открытия окошка
local openSpawnBtn = Instance.new("TextButton")
openSpawnBtn.Name = "GS_OpenSpawnButton"
openSpawnBtn.Size = UDim2.fromOffset(96, 36)
openSpawnBtn.Position = UDim2.new(1, -108, 1, -54)
openSpawnBtn.BackgroundColor3 = ANCIENT_COLOR
openSpawnBtn.BorderSizePixel = 0
openSpawnBtn.Text = "Spawn"
openSpawnBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
openSpawnBtn.Font = Enum.Font.GothamBold
openSpawnBtn.TextSize = 14
openSpawnBtn.ZIndex = 30
openSpawnBtn.Parent = invSlotGui

local openSpawnCorner = Instance.new("UICorner")
openSpawnCorner.CornerRadius = UDim.new(0, 8)
openSpawnCorner.Parent = openSpawnBtn

-- Перетаскиваемое окошко Spawn
local spawnWindow = Instance.new("Frame")
spawnWindow.Name = "GS_SpawnWindow"
spawnWindow.Size = UDim2.fromOffset(244, 178)
spawnWindow.Position = UDim2.new(0.5, -122, 0.5, -89)
spawnWindow.AnchorPoint = Vector2.new(0, 0)
spawnWindow.BackgroundColor3 = Color3.fromRGB(22, 20, 30)
spawnWindow.BorderSizePixel = 0
spawnWindow.Visible = false
spawnWindow.ZIndex = 40
spawnWindow.Parent = invSlotGui

local spawnCorner = Instance.new("UICorner")
spawnCorner.CornerRadius = UDim.new(0, 10)
spawnCorner.Parent = spawnWindow

local spawnStroke = Instance.new("UIStroke")
spawnStroke.Color = ANCIENT_COLOR
spawnStroke.Thickness = 2
spawnStroke.Parent = spawnWindow

local spawnHeader = Instance.new("TextLabel")
spawnHeader.Name = "DragHeader"
spawnHeader.Size = UDim2.new(1, -38, 0, 30)
spawnHeader.Position = UDim2.fromOffset(10, 4)
spawnHeader.BackgroundTransparency = 1
spawnHeader.Text = "Spawn"
spawnHeader.TextXAlignment = Enum.TextXAlignment.Left
spawnHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
spawnHeader.Font = Enum.Font.GothamBold
spawnHeader.TextSize = 14
spawnHeader.ZIndex = 41
spawnHeader.Parent = spawnWindow

local closeSpawnBtn = Instance.new("TextButton")
closeSpawnBtn.Size = UDim2.fromOffset(24, 24)
closeSpawnBtn.Position = UDim2.new(1, -30, 0, 7)
closeSpawnBtn.BackgroundColor3 = Color3.fromRGB(55, 24, 34)
closeSpawnBtn.BorderSizePixel = 0
closeSpawnBtn.Text = "X"
closeSpawnBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeSpawnBtn.Font = Enum.Font.GothamBold
closeSpawnBtn.TextSize = 12
closeSpawnBtn.ZIndex = 42
closeSpawnBtn.Parent = spawnWindow

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeSpawnBtn

local weaponInput = Instance.new("TextBox")
weaponInput.Name = "WeaponNameBox"
weaponInput.Size = UDim2.new(1, -20, 0, 34)
weaponInput.Position = UDim2.fromOffset(10, 38)
weaponInput.BackgroundColor3 = Color3.fromRGB(36, 33, 48)
weaponInput.BorderSizePixel = 0
weaponInput.Text = TARGET_KEY
weaponInput.PlaceholderText = "Название (Gingerscope)"
weaponInput.TextColor3 = Color3.fromRGB(255, 255, 255)
weaponInput.PlaceholderColor3 = Color3.fromRGB(150, 145, 170)
weaponInput.Font = Enum.Font.GothamMedium
weaponInput.TextSize = 13
weaponInput.ClearTextOnFocus = false
weaponInput.ZIndex = 41
weaponInput.Parent = spawnWindow

local weaponCorner = Instance.new("UICorner")
weaponCorner.CornerRadius = UDim.new(0, 6)
weaponCorner.Parent = weaponInput

local amountInput = Instance.new("TextBox")
amountInput.Name = "AmountBox"
amountInput.Size = UDim2.new(1, -20, 0, 34)
amountInput.Position = UDim2.fromOffset(10, 80)
amountInput.BackgroundColor3 = Color3.fromRGB(36, 33, 48)
amountInput.BorderSizePixel = 0
amountInput.Text = "10"
amountInput.PlaceholderText = "Количество (например 100)"
amountInput.TextColor3 = Color3.fromRGB(255, 240, 150)
amountInput.PlaceholderColor3 = Color3.fromRGB(150, 145, 170)
amountInput.Font = Enum.Font.GothamBold
amountInput.TextSize = 13
amountInput.ClearTextOnFocus = false
amountInput.ZIndex = 41
amountInput.Parent = spawnWindow

local amountCorner = Instance.new("UICorner")
amountCorner.CornerRadius = UDim.new(0, 6)
amountCorner.Parent = amountInput

local confirmSpawnBtn = Instance.new("TextButton")
confirmSpawnBtn.Name = "SpawnActionButton"
confirmSpawnBtn.Size = UDim2.new(1, -20, 0, 36)
confirmSpawnBtn.Position = UDim2.fromOffset(10, 124)
confirmSpawnBtn.BackgroundColor3 = Color3.fromRGB(95, 35, 205)
confirmSpawnBtn.BorderSizePixel = 0
confirmSpawnBtn.Text = "Spawn"
confirmSpawnBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
confirmSpawnBtn.Font = Enum.Font.GothamBold
confirmSpawnBtn.TextSize = 14
confirmSpawnBtn.ZIndex = 41
confirmSpawnBtn.Parent = spawnWindow

local confirmCorner = Instance.new("UICorner")
confirmCorner.CornerRadius = UDim.new(0, 7)
confirmCorner.Parent = confirmSpawnBtn

-- Плавное перетаскивание окна пальцем (Touch) или мышью (MouseButton1)
do
	local dragging = false
	local dragInput = nil
	local dragStart = Vector2.zero
	local startPos = UDim2.new(0, 0, 0, 0)

	local function beginDrag(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragInput = input
			dragStart = input.Position
			startPos = spawnWindow.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					if dragInput == input then
						dragging = false
						dragInput = nil
					end
				end
			end)
		end
	end

	spawnWindow.InputBegan:Connect(beginDrag)
	spawnHeader.InputBegan:Connect(beginDrag)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input == dragInput then
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				local delta = input.Position - dragStart
				spawnWindow.Position = UDim2.new(
					startPos.X.Scale,
					startPos.X.Offset + delta.X,
					startPos.Y.Scale,
					startPos.Y.Offset + delta.Y
				)
			end
		end
	end)
end

openSpawnBtn.Activated:Connect(function()
	spawnWindow.Visible = not spawnWindow.Visible
end)

closeSpawnBtn.Activated:Connect(function()
	spawnWindow.Visible = false
end)

local function spawnWeaponAmount(rawWeaponName, rawAmount)
	local qty = tonumber(rawAmount)
	if not qty or qty <= 0 then
		qty = 1
	end
	qty = math.floor(qty)

	local resolvedName, resolvedEntry = resolveWeaponData(rawWeaponName)
	TARGET_KEY = resolvedName
	gsEntry = resolvedEntry
	if typeof(gsEntry) == "table" then
		gsEntry.ItemName = gsEntry.ItemName or resolvedName
		gsEntry.Rarity = gsEntry.Rarity or "Ancient"
		gsEntry.Event = gsEntry.Event or "Christmas"
		if gsEntry.ItemID then
			TARGET_ID = gsEntry.ItemID
		end
		if gsEntry.Image and tostring(gsEntry.Image) ~= "" then
			assets.Image = tostring(gsEntry.Image)
		end
	end

	assets = findWholeAssetByItemId(gsEntry.ItemID or TARGET_ID, TARGET_KEY)

	isClaimed = true
	itemCount += qty

	local addedToUi = addGingerscopeToInventoryUI()
	if currentCardRoot and currentCardRoot.Parent then
		updateCardAmountVisual(currentCardRoot)
	end
	if not addedToUi then
		slotBtn.Visible = true
	end

	syncPistolReplacements()
end

confirmSpawnBtn.Activated:Connect(function()
	spawnWeaponAmount(weaponInput.Text, amountInput.Text)
	spawnWindow.Visible = false
end)

local function findLayoutContainer(node)
	if not node then return nil end
	if node:IsA("UIGridLayout") or node:IsA("UIListLayout") then
		if node.Parent and node.Parent:IsA("GuiObject") then
			return node.Parent
		end
	end
	local layout = node:FindFirstChildWhichIsA("UIGridLayout", true) or node:FindFirstChildWhichIsA("UIListLayout", true)
	if layout and layout.Parent and layout.Parent:IsA("GuiObject") then
		return layout.Parent
	end
	if node:IsA("ScrollingFrame") or node:IsA("GuiObject") then
		return node
	end
	return nil
end

local function findChristmasContainer()
	local inv2 = gameGui:FindFirstChild("Inventory2")
	local main = inv2 and inv2:FindFirstChild("Main")
	local weapons = main and main:FindFirstChild("Weapons")
	local items = weapons and weapons:FindFirstChild("Items")
	local itemList = items and items:FindFirstChild("ItemList")

	for _, root in ipairs({ mainGui, playerGui }) do
		for _, desc in ipairs(root:GetDescendants()) do
			local n = desc.Name:lower()
			if isChristmasName(n) and not n:find("halloween", 1, true) then
				local cont = findLayoutContainer(desc)
				if cont then
					return cont
				end
			end
		end
	end

	for _, root in ipairs({ mainGui, playerGui }) do
		for _, desc in ipairs(root:GetDescendants()) do
			if desc:IsA("TextLabel") then
				local t = desc.Text:lower()
				if isChristmasName(t) or t:find("рождество", 1, true) then
					local parent = desc.Parent
					if parent then
						for _, sib in ipairs(parent:GetChildren()) do
							if sib ~= desc and sib:IsA("GuiObject") then
								local cont = findLayoutContainer(sib)
								if cont then
									return cont
								end
							end
						end
						local grand = parent.Parent
						if grand then
							for _, sib in ipairs(grand:GetChildren()) do
								if sib ~= parent and sib:IsA("GuiObject") then
									local cont = findLayoutContainer(sib)
									if cont then
										return cont
									end
								end
							end
						end
					end
				end
			end
		end
	end

	if itemList and itemList:IsA("GuiObject") then
		return itemList
	end

	return nil
end

local function getBottomLayoutOrder(container)
	local maxOrder = 0
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("GuiObject") and child.Name ~= "GS_InventoryCard" then
			if child.LayoutOrder > maxOrder then
				maxOrder = child.LayoutOrder
			end
		end
	end
	return maxOrder + 1
end

local function isEventTabSelected()
	local inv2 = gameGui:FindFirstChild("Inventory2")
	local main = inv2 and inv2:FindFirstChild("Main")
	local weapons = main and main:FindFirstChild("Weapons")
	local items = weapons and weapons:FindFirstChild("Items")
	local tabs = items and items:FindFirstChild("Tabs")
	local eventTab = tabs and tabs:FindFirstChild("Event")
	local border = eventTab and eventTab:FindFirstChild("ViewBorder")
	if border and border:IsA("GuiObject") then
		return border.Visible
	end
	return true
end

local function enforceFxBadge(card)
	if not card then return end
	local tagsFolder = card:FindFirstChild("Tags")
	local foundFx = false

	if tagsFolder then
		for _, tag in ipairs(tagsFolder:GetChildren()) do
			if tag:IsA("GuiObject") then
				local tagLower = tag.Name:lower()
				local isFx = (tagLower == "fx" or tagLower:find("fx", 1, true) ~= nil)
				local isChristmas = isChristmasName(tagLower)
				local showTag = isFx or isChristmas
				tag.Visible = showTag
				if isFx then
					foundFx = true
				end
				if showTag then
					for _, sub in ipairs(tag:GetDescendants()) do
						if sub:IsA("GuiObject") then
							sub.Visible = true
						end
						if sub:IsA("TextLabel") then
							if sub.Name:lower():find("year", 1, true) then
								sub.Text = tostring(gsEntry.Year or 2023)
							elseif isFx and (sub.Name:lower():find("tag", 1, true) or sub.Name:lower():find("label", 1, true) or sub.Text == "") then
								sub.Text = "FX"
							end
						end
					end
				end
			end
		end
	end

	if not foundFx then
		local existingBadge = card:FindFirstChild("GS_FX_Badge")
		if not existingBadge then
			local badge = Instance.new("TextLabel")
			badge.Name = "GS_FX_Badge"
			badge.Size = UDim2.fromOffset(32, 16)
			badge.Position = UDim2.new(1, -36, 0, 4)
			badge.BackgroundColor3 = Color3.fromRGB(145, 55, 255)
			badge.BorderSizePixel = 0
			badge.Text = "FX"
			badge.TextColor3 = Color3.fromRGB(255, 255, 255)
			badge.Font = Enum.Font.GothamBold
			badge.TextSize = 10
			badge.ZIndex = 15
			badge.Parent = card

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 4)
			corner.Parent = badge
		elseif existingBadge:IsA("GuiObject") then
			existingBadge.Visible = true
		end
	end
end

local function syncCardVisibility()
	if not isClaimed or itemCount <= 0 then return end
	local container = findChristmasContainer()
	if container then
		currentCardContainer = container
	end

	if not currentCardRoot or not currentCardRoot.Parent then
		if container then
			addGingerscopeToInventoryUI()
		end
		return
	end

	if currentCardContainer and currentCardRoot.Parent ~= currentCardContainer then
		pcall(function()
			currentCardRoot.Parent = currentCardContainer
		end)
	end

	enforceFxBadge(currentCardRoot)
	updateCardAmountVisual(currentCardRoot)

	local shouldBeVisible = isEventTabSelected()
	if currentCardRoot:IsA("GuiObject") and currentCardRoot.Visible ~= shouldBeVisible then
		currentCardRoot.Visible = shouldBeVisible
	end
end

local function updateEquippedGunSlot()
	local inv2 = gameGui:FindFirstChild("Inventory2")
	local main = inv2 and inv2:FindFirstChild("Main")
	local weapons = main and main:FindFirstChild("Weapons")
	local equipped = weapons and weapons:FindFirstChild("Equipped")
	local container = equipped and equipped:FindFirstChild("Container")
	local gunSlot = container and container:FindFirstChild("Gun")
	if not gunSlot then return end

	local slotCont = gunSlot:FindFirstChild("Container")
	local slotIcon = slotCont and slotCont:FindFirstChild("Icon")
	local slotName = gunSlot:FindFirstChild("ItemName") and gunSlot.ItemName:FindFirstChild("Label")

	if isEquipped then
		if not gunSlot:GetAttribute("GS_PrevIcon") and slotIcon and slotIcon:IsA("ImageLabel") then
			gunSlot:SetAttribute("GS_PrevIcon", slotIcon.Image)
		end
		if not gunSlot:GetAttribute("GS_PrevName") and slotName and slotName:IsA("TextLabel") then
			gunSlot:SetAttribute("GS_PrevName", slotName.Text)
		end
		if slotIcon and slotIcon:IsA("ImageLabel") then
			slotIcon.Image = assets.Image
		end
		if slotName and slotName:IsA("TextLabel") then
			slotName.Text = tostring(gsEntry.ItemName or TARGET_KEY)
		end
		if equipService and equipService.EquipItem then
			pcall(function()
				equipService:EquipItem("Weapons", tostring(gsEntry.ItemName or TARGET_KEY))
			end)
		end
	else
		local prevIcon = gunSlot:GetAttribute("GS_PrevIcon")
		local prevName = gunSlot:GetAttribute("GS_PrevName")
		if prevIcon and slotIcon and slotIcon:IsA("ImageLabel") then
			slotIcon.Image = prevIcon
		end
		if prevName and slotName and slotName:IsA("TextLabel") then
			slotName.Text = prevName
		end
	end
end

local function refreshEquipVisuals()
	local baseName = tostring(gsEntry.ItemName or TARGET_KEY)
	if currentCardNameLabel and currentCardNameLabel:IsA("TextLabel") then
		currentCardNameLabel.Text = baseName
	end
	if currentCardRoot then
		local stroke = currentCardRoot:FindFirstChildOfClass("UIStroke") or (currentCardRoot:FindFirstChild("Container") and currentCardRoot.Container:FindFirstChildOfClass("UIStroke"))
		if stroke then
			stroke.Color = isEquipped and Color3.fromRGB(255, 255, 255) or ANCIENT_COLOR
			stroke.Thickness = isEquipped and 2.5 or 1.5
		end
		enforceFxBadge(currentCardRoot)
		updateCardAmountVisual(currentCardRoot)
	end
	slotBtn.BackgroundColor3 = isEquipped and Color3.fromRGB(65, 130, 220) or Color3.fromRGB(32, 32, 40)
	slotBtn.Text = baseName
end

setEquipped = function(state)
	local wasEquipped = isEquipped
	isEquipped = state
	if wasEquipped and not state then
		consumeOneOnUnequip()
	end
	refreshEquipVisuals()
	updateEquippedGunSlot()
	syncPistolReplacements()
	syncCardVisibility()
end

local function toggleGingerscopeEquip()
	if not isClaimed or itemCount <= 0 then return end
	setEquipped(not isEquipped)
end

slotBtn.MouseButton1Click:Connect(toggleGingerscopeEquip)

local function bindOtherItemButton(btn)
	if hookedButtons[btn] then return end
	if currentCardRoot and btn:IsDescendantOf(currentCardRoot) then return end
	if btn.Name == "Claim" then return end

	hookedButtons[btn] = true
	if btn:IsA("GuiButton") then
		btn.Activated:Connect(function()
			if isEquipped then
				setEquipped(false)
			end
			task.defer(syncCardVisibility)
		end)
		btn.MouseButton1Click:Connect(function()
			if isEquipped then
				setEquipped(false)
			end
			task.defer(syncCardVisibility)
		end)
	end
end

local function hookOtherInventoryButtons(rootScope)
	if not rootScope then return end
	for _, desc in ipairs(rootScope:GetDescendants()) do
		if desc:IsA("GuiButton") then
			bindOtherItemButton(desc)
		end
	end
end

local function findInventoryCardTemplate()
	local inv2 = gameGui:FindFirstChild("Inventory2")
	if inv2 and inv2:FindFirstChild("EquipContainer") and inv2.EquipContainer:FindFirstChild("ItemFrame") then
		return inv2.EquipContainer.ItemFrame
	end

	local rsMain = ReplicatedStorage:FindFirstChild("MainGUI")
	local rsInv2 = rsMain and rsMain:FindFirstChild("Inventory2")
	if rsInv2 and rsInv2:FindFirstChild("EquipContainer") and rsInv2.EquipContainer:FindFirstChild("ItemFrame") then
		return rsInv2.EquipContainer.ItemFrame
	end

	local rsInv = rsMain and rsMain:FindFirstChild("Inventory")
	local rsInvScript = rsInv and rsInv:FindFirstChild("Inventory")
	if rsInvScript and rsInvScript:FindFirstChild("ItemOld") then
		return rsInvScript.ItemOld
	end

	return nil
end

local function applyAncientCardStyle(card)
	local itemNameFrame = card:FindFirstChild("ItemName")
	if itemNameFrame and itemNameFrame:IsA("GuiObject") then
		itemNameFrame.BackgroundColor3 = ANCIENT_COLOR
		local bg = itemNameFrame:FindFirstChild("BG")
		if bg and bg:IsA("GuiObject") then
			bg.BackgroundColor3 = ANCIENT_COLOR
			if bg:IsA("ImageLabel") then
				bg.ImageColor3 = ANCIENT_COLOR
			end
		end
		for _, sub in ipairs(itemNameFrame:GetDescendants()) do
			if sub:IsA("UIGradient") then
				sub.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, ANCIENT_DARK),
					ColorSequenceKeypoint.new(0.5, ANCIENT_COLOR),
					ColorSequenceKeypoint.new(1, ANCIENT_DARK),
				})
			elseif sub:IsA("UIStroke") then
				sub.Color = ANCIENT_DARK
			end
		end
	end

	local cont = card:FindFirstChild("Container")
	if cont then
		for _, sub in ipairs(cont:GetDescendants()) do
			if sub:IsA("UIGradient") then
				sub.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, ANCIENT_DARK),
					ColorSequenceKeypoint.new(1, ANCIENT_COLOR),
				})
			elseif sub:IsA("UIStroke") then
				sub.Color = ANCIENT_COLOR
			end
		end
	end
end

local function attachCardGuards(card)
	if not card or hookedCardSignals[card] then return end
	hookedCardSignals[card] = true

	card:GetPropertyChangedSignal("Visible"):Connect(function()
		if not isClaimed or itemCount <= 0 or card ~= currentCardRoot then return end
		local expected = isEventTabSelected()
		if card:IsA("GuiObject") and card.Visible ~= expected then
			task.defer(function()
				if currentCardRoot == card and card.Parent then
					card.Visible = isEventTabSelected()
					enforceFxBadge(card)
					updateCardAmountVisual(card)
				end
			end)
		end
	end)

	card:GetPropertyChangedSignal("Parent"):Connect(function()
		if not isClaimed or itemCount <= 0 or card ~= currentCardRoot then return end
		if not card.Parent then
			task.defer(function()
				if isClaimed and itemCount > 0 and currentCardRoot == card and not card.Parent then
					currentCardRoot = nil
					addGingerscopeToInventoryUI()
				end
			end)
		else
			local container = currentCardContainer or findChristmasContainer()
			if container and card.Parent ~= container then
				task.defer(function()
					if isClaimed and itemCount > 0 and currentCardRoot == card and container.Parent then
						card.Parent = container
						card.Visible = isEventTabSelected()
						enforceFxBadge(card)
						updateCardAmountVisual(card)
					end
				end)
			end
		end
	end)
end

addGingerscopeToInventoryUI = function()
	if itemCount <= 0 then
		return false
	end

	local targetContainer = findChristmasContainer()
	local template = findInventoryCardTemplate()
	if not targetContainer or not template then
		return false
	end

	currentCardContainer = targetContainer

	for _, root in ipairs({ mainGui, playerGui }) do
		for _, obj in ipairs(root:GetDescendants()) do
			if obj.Name == "GS_InventoryCard" then
				obj:Destroy()
			end
		end
	end

	local card = template:Clone()
	card.Name = "GS_InventoryCard"
	card.Visible = isEventTabSelected()
	card.LayoutOrder = getBottomLayoutOrder(targetContainer)
	card.Parent = targetContainer
	currentCardRoot = card

	local itemNameFrame = card:FindFirstChild("ItemName")
	local nameLabel = itemNameFrame and itemNameFrame:FindFirstChild("Label")
	currentCardNameLabel = nameLabel
	if nameLabel and nameLabel:IsA("TextLabel") then
		nameLabel.Text = tostring(gsEntry.ItemName or TARGET_KEY)
	end

	local cont = card:FindFirstChild("Container")
	local icon = cont and cont:FindFirstChild("Icon")
	if icon and icon:IsA("ImageLabel") then
		icon.Image = assets.Image
		icon.Visible = true
	end

	enforceFxBadge(card)
	applyAncientCardStyle(card)
	updateCardAmountVisual(card)
	refreshEquipVisuals()
	attachCardGuards(card)

	local actionBtn = cont and cont:FindFirstChild("ActionButton")
	local clickTarget = (actionBtn and actionBtn:IsA("GuiButton") and actionBtn) or (card:IsA("GuiButton") and card)

	if clickTarget then
		clickTarget.Activated:Connect(toggleGingerscopeEquip)
		clickTarget.MouseButton1Click:Connect(toggleGingerscopeEquip)
	else
		for _, desc in ipairs(card:GetDescendants()) do
			if desc:IsA("GuiButton") then
				desc.Activated:Connect(toggleGingerscopeEquip)
				desc.MouseButton1Click:Connect(toggleGingerscopeEquip)
			end
		end
	end

	hookOtherInventoryButtons(mainGui)
	slotBtn.Visible = false
	return true
end

local function openNativeNewItem()
	centerNewItemWindow()
	if _G.NewItem then
		_G.NewItem(TARGET_KEY, "You Got...", nil, "Weapons", 1)
	end

	local container = newItemFrame:FindFirstChild("Container")
	local innerItem = container and container:FindFirstChild("NewItem")
	if innerItem and itemModule.DisplayItem then
		pcall(itemModule.DisplayItem, innerItem, gsEntry, 1)
	end

	local icon = innerItem and innerItem:FindFirstChild("Container") and innerItem.Container:FindFirstChild("Icon")
	if icon and icon:IsA("ImageLabel") and (icon.Image == "" or icon.Image == "rbxassetid://0") then
		icon.Image = assets.Image
	end

	if Lighting:FindFirstChild("NewItemBlur") then
		Lighting.NewItemBlur.Enabled = true
	end
	newItemFrame.Visible = true
end

local function playFallbackFlyToTarget(iconObj, targetGuiObj)
	local flyer = Instance.new("ImageLabel")
	flyer.Name = "GS_FlyIcon"
	flyer.Size = UDim2.fromOffset(64, 64)
	flyer.Position = UDim2.fromScale(0.5, 0.5)
	flyer.AnchorPoint = Vector2.new(0.5, 0.5)
	flyer.BackgroundTransparency = 1
	flyer.Image = (iconObj and iconObj:IsA("ImageLabel") and iconObj.Image ~= "" and iconObj.Image) or assets.Image
	flyer.ZIndex = 70
	flyer.Parent = invSlotGui

	local dest = targetGuiObj or slotBtn
	local targetPos = UDim2.fromOffset(
		dest.AbsolutePosition.X + dest.AbsoluteSize.X * 0.5,
		dest.AbsolutePosition.Y + dest.AbsoluteSize.Y * 0.5
	)

	local tw = TweenService:Create(flyer, TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = targetPos,
		Size = UDim2.fromOffset(32, 32),
	})
	tw:Play()
	tw.Completed:Connect(function()
		flyer:Destroy()
	end)
end

claimBtn.Activated:Connect(function()
	if isClaimed then return end
	isClaimed = true
	itemCount = math.max(itemCount, 1)

	local container = newItemFrame:FindFirstChild("Container")
	local innerItem = container and container:FindFirstChild("NewItem")
	local iconObj = innerItem and innerItem:FindFirstChild("Container") and innerItem.Container:FindFirstChild("Icon")
	local dockInv = gameGui:FindFirstChild("Dock") and gameGui.Dock:FindFirstChild("Inventory")

	local nativeAnimOk = false
	if iconObj and dockInv and itemModule.AnimateItemIconIntoInventory then
		nativeAnimOk = pcall(itemModule.AnimateItemIconIntoInventory, iconObj, dockInv, gameGui)
	end

	newItemFrame.Visible = false
	if Lighting:FindFirstChild("NewItemBlur") then
		Lighting.NewItemBlur.Enabled = false
	end

	local addedToUi = addGingerscopeToInventoryUI()
	if not addedToUi then
		slotBtn.Visible = true
	end

	if not nativeAnimOk then
		playFallbackFlyToTarget(iconObj, addedToUi and dockInv or slotBtn)
	end

	syncPistolReplacements()
end)

mainGui.DescendantAdded:Connect(function(desc)
	if desc:IsA("GuiButton") then
		bindOtherItemButton(desc)
	end
	if isClaimed and itemCount > 0 and (desc:IsA("UIGridLayout") or desc:IsA("UIListLayout")) then
		task.defer(function()
			syncCardVisibility()
		end)
	end
end)

task.spawn(function()
	local inv2 = gameGui:FindFirstChild("Inventory2")
	if inv2 and inv2:IsA("GuiObject") then
		inv2:GetPropertyChangedSignal("Visible"):Connect(function()
			if isClaimed and itemCount > 0 then
				task.defer(function()
					addGingerscopeToInventoryUI()
				end)
			end
		end)
	end

	local main = inv2 and inv2:FindFirstChild("Main")
	local weapons = main and main:FindFirstChild("Weapons")
	local items = weapons and weapons:FindFirstChild("Items")
	local tabs = items and items:FindFirstChild("Tabs")
	if tabs then
		for _, tab in ipairs(tabs:GetChildren()) do
			if tab.Name ~= "Search" and tab.Name ~= "UIListLayout" then
				local btn = tab:FindFirstChild("View")
				if btn and btn:IsA("GuiButton") then
					btn.Activated:Connect(function()
						task.defer(syncCardVisibility)
					end)
				end
			end
		end
	end
end)

local function hookCharacter(char)
	char.ChildAdded:Connect(function()
		task.defer(syncPistolReplacements)
	end)
	char.ChildRemoved:Connect(function()
		task.defer(syncPistolReplacements)
	end)
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		backpack.ChildAdded:Connect(function()
			task.defer(syncPistolReplacements)
		end)
		backpack.ChildRemoved:Connect(function()
			task.defer(syncPistolReplacements)
		end)
	end
	syncPistolReplacements()
end

if player.Character then
	hookCharacter(player.Character)
end
player.CharacterAdded:Connect(hookCharacter)

local lastCardGuardTick = 0
RunService.Heartbeat:Connect(function(dt)
	if isEquipped then
		syncPistolReplacements()
	end
	if isClaimed and itemCount > 0 then
		lastCardGuardTick += dt
		if lastCardGuardTick >= 1 then
			lastCardGuardTick = 0
			syncCardVisibility()
		end
	end
end)

openNativeNewItem()
